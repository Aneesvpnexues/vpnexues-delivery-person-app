import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vpnexues_partner/core/api_client.dart';
import 'package:vpnexues_partner/state/app_state.dart';

import 'fakes.dart';

Future<AppState> buildState(http.Client httpClient) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return AppState(ApiClient(prefs, vault: MemoryVault(), httpClient: httpClient));
}

http.Response partnerPayload() => jsonResponse(200, {
      'fullName': 'Contract Partner',
      'isOnline': false,
      'kycStatus': 'not_started',
    });

void main() {
  test('login sends the backend login body and consumes its token response', () async {
    final seen = <String, dynamic>{};
    final authHeaders = <String?>[];
    final state = await buildState(
      MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/v1/auth/login')) {
          seen['path'] = path;
          seen['method'] = request.method;
          seen['body'] = jsonDecode(request.body);
          seen['authHeader'] = request.headers['Authorization'];
          return jsonResponse(200, backendTokenResponse('access-login', 'refresh-login'));
        }
        if (path.endsWith('/v1/me')) {
          authHeaders.add(request.headers['Authorization']);
          return partnerPayload();
        }
        if (path.endsWith('/v1/me/settings')) return jsonResponse(200, {});
        if (path.endsWith('/v1/notifications')) {
          return jsonResponse(200, {'unreadCount': 0});
        }
        return jsonResponse(500, {'error': {'code': 'ERROR', 'message': 'Unexpected'}});
      }),
    );

    await state.login('9000000000', 'Passw0rd!');

    expect(seen['path'], '/v1/auth/login');
    expect(seen['method'], 'POST');
    expect(seen['body'], {'phone': '9000000000', 'password': 'Passw0rd!'});
    expect(seen['authHeader'], isNull);
    expect(state.api.accessToken, 'access-login');
    expect(state.api.refreshToken, 'refresh-login');
    expect(state.api.expiresAt, isNotNull);
    expect(
      state.api.expiresAt!.difference(DateTime.now().toUtc()).inMinutes,
      inInclusiveRange(14, 15),
    );
    expect(authHeaders, contains('Bearer access-login'));
    expect(state.name, 'Contract Partner');
  });

  test('refresh sends only the refresh token and accepts a rotated pair', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final vault = MemoryVault();
    var refreshAttempts = 0;
    Map<String, dynamic>? refreshBody;
    String? refreshAuthHeader;
    final client = ApiClient(
      prefs,
      vault: vault,
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/v1/me')) {
          if (refreshAttempts == 0) {
            return jsonResponse(401, {
              'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in again'},
            });
          }
          return partnerPayload();
        }
        if (path.endsWith('/v1/auth/refresh')) {
          refreshAttempts++;
          refreshBody = jsonDecode(request.body);
          refreshAuthHeader = request.headers['Authorization'];
          return jsonResponse(200, backendTokenResponse('access-rotated', 'refresh-rotated'));
        }
        return jsonResponse(500, {'error': {'code': 'ERROR', 'message': 'Unexpected'}});
      }),
    );

    await client.setTokens(backendTokenResponse('access-old', 'refresh-old'));
    await client.get('/v1/me');

    expect(refreshBody, {'refreshToken': 'refresh-old'});
    expect(refreshAuthHeader, isNull);
    expect(client.accessToken, 'access-rotated');
    expect(client.refreshToken, 'refresh-rotated');
    expect(vault.pair?.refreshToken, 'refresh-rotated');
    expect(
      client.expiresAt!.difference(DateTime.now().toUtc()).inMinutes,
      inInclusiveRange(14, 15),
    );
  });

  test('logout sends the backend logout body without an access token', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = ApiClient(
      prefs,
      vault: MemoryVault(),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/auth/logout');
        expect(jsonDecode(request.body), {'refreshToken': 'refresh-login'});
        expect(request.headers['Authorization'], isNull);
        return jsonResponse(200, {'ok': true});
      }),
    );

    await client.setTokens(backendTokenResponse('access-login', 'refresh-login'));
    final res = await client.post(
      '/v1/auth/logout',
      body: {'refreshToken': client.refreshToken},
      auth: false,
    );

    expect(res, {'ok': true});
  });

  test('OTP and signup verification use the backend verify routes', () async {
    final calls = <String, Map<String, dynamic>>{};
    final state = await buildState(
      MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/v1/auth/signup/verify') ||
            path.endsWith('/v1/auth/login/otp/verify')) {
          calls[path] = jsonDecode(request.body);
          return jsonResponse(200, backendTokenResponse('access-verify', 'refresh-verify'));
        }
        if (path.endsWith('/v1/me')) return partnerPayload();
        if (path.endsWith('/v1/me/settings')) return jsonResponse(200, {});
        if (path.endsWith('/v1/notifications')) {
          return jsonResponse(200, {'unreadCount': 0});
        }
        return jsonResponse(500, {'error': {'code': 'ERROR', 'message': 'Unexpected'}});
      }),
    );

    await state.signupVerify('9000000000', '123456');
    await state.loginOtpVerify('9000000000', '654321');

    expect(calls['/v1/auth/signup/verify'], {
      'phone': '9000000000',
      'code': '123456',
    });
    expect(calls['/v1/auth/login/otp/verify'], {
      'phone': '9000000000',
      'code': '654321',
    });
    expect(state.api.refreshToken, 'refresh-verify');
  });
}
