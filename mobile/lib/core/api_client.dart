import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  ApiClient(this._prefs) {
    accessToken = _prefs.getString(_kAccess);
    refreshToken = _prefs.getString(_kRefresh);
  }

  /// Point the app at another host with `--dart-define=API_BASE_URL=http://192.168.1.7:8080`.
  /// Defaults: `10.0.2.2` (Android emulator → host machine), `localhost` (web/desktop).
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  static const _kAccess = 'vpnexues.accessToken';
  static const _kRefresh = 'vpnexues.refreshToken';

  final SharedPreferences _prefs;
  final http.Client _http = http.Client();

  String? accessToken;
  String? refreshToken;
  void Function()? onSessionExpired;

  bool get hasSession => accessToken != null;

  Future<void> setTokens(Map<String, dynamic> tokens) async {
    accessToken = tokens['accessToken'] as String?;
    refreshToken = tokens['refreshToken'] as String? ?? refreshToken;
    await _persist();
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    await _persist();
  }

  Future<void> _persist() async {
    if (accessToken == null) {
      await _prefs.remove(_kAccess);
    } else {
      await _prefs.setString(_kAccess, accessToken!);
    }
    if (refreshToken == null) {
      await _prefs.remove(_kRefresh);
    } else {
      await _prefs.setString(_kRefresh, refreshToken!);
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path,
          {Object? body, Map<String, String>? headers}) =>
      _send('POST', path, body: body, headers: headers);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

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
  }) async {
    final base = Uri.parse('$baseUrl$path');
    final uri = query == null
        ? base
        : base.replace(queryParameters: {...base.queryParameters, ...query});
    final h = <String, String>{'Accept': 'application/json', ...?headers};
    if (body != null) h['Content-Type'] = 'application/json';
    if (accessToken != null) h['Authorization'] = 'Bearer $accessToken';

    late http.Response res;
    try {
      final req = http.Request(method, uri)..headers.addAll(h);
      if (body != null) req.body = jsonEncode(body);
      final streamed = await _http.send(req).timeout(const Duration(seconds: 25));
      res = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException(0, 'NETWORK',
          'Cannot reach the server. Check your connection and API address.');
    }

    if (res.statusCode == 401 &&
        retry &&
        refreshToken != null &&
        !path.contains('/auth/refresh')) {
      final ok = await _refresh();
      if (ok) {
        return _send(method, path,
            body: body, query: query, headers: headers, retry: false);
      }
      await clear();
      onSessionExpired?.call();
    }
    return _decode(res);
  }

  Future<bool> _refresh() async {
    try {
      final res = await _http.post(
        Uri.parse('$baseUrl/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        accessToken = m['accessToken'] as String?;
        refreshToken = m['refreshToken'] as String? ?? refreshToken;
        await _persist();
        return accessToken != null;
      }
    } catch (_) {}
    return false;
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
    throw ApiException(res.statusCode, 'HTTP_${res.statusCode}',
        'Request failed (${res.statusCode}). Please try again.');
  }

  Future<void> upload(String url, Uint8List bytes, String contentType) async {
    late http.Response res;
    try {
      res = await _http.put(
        Uri.parse(url),
        headers: {
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          'Content-Type': contentType,
        },
        body: bytes,
      );
    } catch (_) {
      throw ApiException(0, 'NETWORK', 'Upload failed. Check your connection.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, 'UPLOAD_FAILED',
          'Could not upload the file. Please try again.');
    }
  }
}
