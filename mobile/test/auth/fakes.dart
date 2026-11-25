import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vpnexues_partner/core/token_vault.dart';

class MemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> values = {};
  bool failWrites = false;

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    if (failWrites) throw StateError('secure storage unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async => values.remove(key);
}

class MemoryVault implements TokenVault {
  TokenPair? pair;
  String? pendingRevocation;
  bool initialized = false;

  MemoryVault({this.pair, this.pendingRevocation});

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<TokenPair?> read() async => pair;

  @override
  Future<void> write(TokenPair tokens) async => pair = tokens;

  @override
  Future<void> clear() async => pair = null;

  @override
  Future<String?> readPendingRevocation() async => pendingRevocation;

  @override
  Future<void> writePendingRevocation(String refreshToken) async =>
      pendingRevocation = refreshToken;

  @override
  Future<void> clearPendingRevocation() async => pendingRevocation = null;
}

http.Response jsonResponse(int status, Map<String, dynamic> body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'Content-Type': 'application/json'},
    );

Map<String, dynamic> tokenResponse(String access, String refresh) => {
      'accessToken': access,
      'refreshToken': refresh,
      'tokenType': 'Bearer',
      'expiresIn': 300,
    };

/// Mirrors the real Fastify `/v1/auth/*` response: `expiresIn` is the string
/// from config (`15m`), not a numeric Dart duration.
Map<String, dynamic> backendTokenResponse(String access, String refresh) => {
      'accessToken': access,
      'refreshToken': refresh,
      'tokenType': 'Bearer',
      'expiresIn': '15m',
    };
