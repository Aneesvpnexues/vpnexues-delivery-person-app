import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'token_vault.dart';

class ApiException implements Exception {
  ApiException(this.status, this.code, this.message, [this.details]);

  final int status;
  final String code;
  final String message;
  final dynamic details;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(
    SharedPreferences prefs, {
    TokenVault? vault,
    http.Client? httpClient,
  })  : _vault = vault ?? SecureTokenVault(FlutterSecureKeyValueStore(), prefs),
        _http = httpClient ?? http.Client();

  /// Point the app at another host with `--dart-define=API_BASE_URL=http://192.168.1.7:8080`.
  /// Defaults: `10.0.2.2` (Android emulator → host machine), `localhost` (web/desktop).
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const Duration _defaultTimeout = Duration(seconds: 25);
  static const Duration _authTimeout = Duration(seconds: 15);

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  final TokenVault _vault;
  final http.Client _http;

  String? accessToken;
  String? refreshToken;
  DateTime? expiresAt;
  void Function()? onSessionExpired;

  Future<bool>? _refreshing;
  Future<void>? _expiring;
  int _generation = 0;

  /// Refresh tokens are the source of truth for a restorable session.
  bool get hasSession => accessToken != null || refreshToken != null;

  /// True shortly before the access token expires; the refresh is single-flight.
  bool get needsRefresh {
    final expiry = expiresAt;
    if (expiry == null) return false;
    final soon = DateTime.now().toUtc().add(const Duration(seconds: 30));
    return !soon.isBefore(expiry);
  }

  /// Load tokens from platform-backed secure storage and run one-time migration.
  Future<void> restore() async {
    await _vault.initialize();
    final pair = await _vault.read();
    accessToken = pair?.accessToken;
    refreshToken = pair?.refreshToken;
    expiresAt = pair?.expiresAt;
  }

  Future<void> setTokens(Map<String, dynamic> tokens) async {
    // Login/OTP verification always issues a new refresh token. Requiring it
    // prevents a new login from silently reusing a stale refresh token.
    final applied = await _applyTokenResponse(tokens, requireRefreshToken: true);
    if (!applied) {
      throw ApiException(401, 'UNAUTHENTICATED', 'Invalid authentication response');
    }
  }

  /// Clear active credentials. Offline logout keeps only a one-shot revocation
  /// token in secure storage so the server session can be revoked on reconnect.
  Future<void> clear({bool retainForRevocation = false}) async {
    if (retainForRevocation && refreshToken != null && refreshToken!.isNotEmpty) {
      await _vault.writePendingRevocation(refreshToken!);
    }
    accessToken = null;
    refreshToken = null;
    expiresAt = null;
    await _vault.clear();
  }

  /// Called on boot and on app resume. Never deletes credentials on failure.
  Future<void> expireSession() {
    return _expiring ??= _doExpire().whenComplete(() => _expiring = null);
  }

  Future<void> _doExpire() async {
    await clear();
    onSessionExpired?.call();
  }

  /// Proactively renew a token that is about to expire.
  Future<void> ensureFreshToken() async {
    if (!needsRefresh || refreshToken == null) return;
    await _ensureRefreshed(refreshToken!, _generation);
  }

  /// Flush a logout that could not reach the server earlier.
  Future<void> flushPendingLogout() async {
    final token = await _vault.readPendingRevocation();
    if (token == null) return;
    try {
      await _send(
        'POST',
        '/v1/auth/logout',
        body: {'refreshToken': token},
        auth: false,
        retry: false,
        timeout: _authTimeout,
      );
    } on ApiException catch (e) {
      if (e.status == 0 || e.status >= 500) return; // keep for a later retry
    }
    await _vault.clearPendingRevocation();
  }

  Future<dynamic> get(String path,
          {Map<String, String>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path,
          {Object? body,
          Map<String, String>? headers,
          bool auth = true,
          Duration timeout = _defaultTimeout}) =>
      _send('POST', path,
          body: body, headers: headers, auth: auth, timeout: timeout);

  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    bool retry = true,
    bool auth = true,
    Duration timeout = _defaultTimeout,
  }) async {
    final base = Uri.parse('$baseUrl$path');
    final uri = query == null
        ? base
        : base.replace(queryParameters: {...base.queryParameters, ...query});
    final h = <String, String>{'Accept': 'application/json', ...?headers};
    if (body != null) h['Content-Type'] = 'application/json';
    if (auth && accessToken != null) h['Authorization'] = 'Bearer $accessToken';

    late http.Response res;
    try {
      final req = http.Request(method, uri)..headers.addAll(h);
      if (body != null) req.body = jsonEncode(body);
      res = await (() async {
        final streamed = await _http.send(req);
        return http.Response.fromStream(streamed);
      })().timeout(timeout);
    } catch (_) {
      throw ApiException(0, 'NETWORK',
          'Cannot reach the server. Check your connection and API address.');
    }

    if (res.statusCode == 401 &&
        retry &&
        auth &&
        refreshToken != null &&
        !path.contains('/auth/refresh')) {
      final usedToken = refreshToken!;
      final usedGeneration = _generation;
      final refreshed = await _ensureRefreshed(usedToken, usedGeneration);
      if (refreshed) {
        return _send(method, path,
            body: body,
            query: query,
            headers: headers,
            retry: false,
            auth: auth,
            timeout: timeout);
      }
    }
    return _decode(res);
  }

  /// All refresh paths funnel through here so no two requests rotate the same
  /// refresh token. Callers that arrive after a rotation simply reuse the new
  /// access token instead of replaying the old refresh token.
  Future<bool> _ensureRefreshed(String usedToken, int usedGeneration) async {
    if (usedGeneration != _generation || usedToken != refreshToken) return true;

    final pending = _refreshing ??=
        _performRefresh(usedToken).whenComplete(() => _refreshing = null);
    final ok = await pending;
    if (!ok) {
      await expireSession();
      throw ApiException(
          401, 'UNAUTHENTICATED', 'Your session has expired. Sign in again.');
    }
    return true;
  }

  Future<bool> _performRefresh(String usedToken) async {
    try {
      final res = await _http
          .post(
            Uri.parse('$baseUrl/v1/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': usedToken}),
          )
          .timeout(_authTimeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final applied = await _applyTokenResponse(_decode(res),
            requireRefreshToken: true);
        if (!applied) return false;
        _generation++;
        return true;
      }
      if (res.statusCode >= 500) {
        throw ApiException(
            res.statusCode, 'SERVER', 'Server error while renewing the session.');
      }
      return false;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(0, 'NETWORK',
          'Cannot reach the server. Check your connection and API address.');
    }
  }

  Future<bool> _applyTokenResponse(dynamic decoded,
      {required bool requireRefreshToken}) async {
    if (decoded is! Map) return false;
    final access = decoded['accessToken'] as String?;
    final rotated = decoded['refreshToken'] as String?;
    if (access == null || access.isEmpty) return false;
    if (requireRefreshToken && (rotated == null || rotated.isEmpty)) return false;

    final refresh = (rotated != null && rotated.isNotEmpty) ? rotated : refreshToken;
    if (refresh == null || refresh.isEmpty) return false;

    accessToken = access;
    refreshToken = refresh;
    expiresAt = _parseExpiry(decoded['expiresIn']);
    await _vault.write(TokenPair(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: expiresAt,
    ));
    return true;
  }

  static DateTime? _parseExpiry(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    final match = RegExp(r'^(\d+)\s*([smhd])$').firstMatch(text.toLowerCase());
    Duration? duration;
    if (match != null) {
      final amount = int.tryParse(match.group(1)!) ?? 0;
      duration = switch (match.group(2)) {
        's' => Duration(seconds: amount),
        'm' => Duration(minutes: amount),
        'h' => Duration(hours: amount),
        'd' => Duration(days: amount),
        _ => null,
      };
    } else {
      duration = Duration(seconds: int.tryParse(text) ?? 0);
    }
    if (duration == null || duration.inSeconds <= 0) return null;
    return DateTime.now().toUtc().add(duration);
  }

  String _errorCode(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map && decoded['error'] is Map) {
        return '${decoded['error']['code'] ?? 'ERROR'}';
      }
    } catch (_) {}
    return 'HTTP_${res.statusCode}';
  }

  dynamic _decode(http.Response res) {
    dynamic data;
    if (res.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        data = utf8.decode(res.bodyBytes, allowMalformed: true);
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    if (data is Map && data['error'] is Map) {
      final e = data['error'] as Map;
      throw ApiException(
        res.statusCode,
        '${e['code'] ?? 'ERROR'}',
        '${e['message'] ?? 'Something went wrong'}',
        e['details'],
      );
    }
    throw ApiException(res.statusCode, _errorCode(res),
        'Request failed (${res.statusCode}). Please try again.');
  }

  Future<void> upload(String url, Uint8List bytes, String contentType) async {
    late http.Response res;
    try {
      res = await _http
          .put(
            Uri.parse(url),
            headers: {
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
              'Content-Type': contentType,
            },
            body: bytes,
          )
          .timeout(_defaultTimeout);
    } catch (_) {
      throw ApiException(0, 'NETWORK', 'Upload failed. Check your connection.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, 'UPLOAD_FAILED',
          'Could not upload the file. Please try again.');
    }
  }
}
