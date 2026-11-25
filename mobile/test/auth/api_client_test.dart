import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vpnexues_partner/core/api_client.dart';

import 'fakes.dart';

Future<ApiClient> buildClient(MemoryVault vault, http.Client httpClient) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ApiClient(prefs, vault: vault, httpClient: httpClient);
}

void main() {
  test('concurrent 401s rotate the refresh token only once', () async {
    var refreshCalls = 0;
    var refreshed = false;
    final authHeaders = <String?>[];
    final vault = MemoryVault();
    final client = await buildClient(
      vault,
      MockClient((request) async {
        if (request.url.path.endsWith('/v1/auth/refresh')) {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          refreshed = true;
          return jsonResponse(200, tokenResponse('access-new', 'refresh-new'));
        }
        if (request.url.path.endsWith('/v1/me')) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          authHeaders.add(request.headers['Authorization']);
          if (!refreshed) {
            return jsonResponse(401, {
              'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in again'},
            });
          }
          return jsonResponse(200, {'fullName': 'Partner'});
        }
        return jsonResponse(500, {'error': {'code': 'ERROR', 'message': 'Unexpected'}});
      }),
    );

    await client.setTokens(tokenResponse('access-old', 'refresh-old'));
    final results = await Future.wait([client.get('/v1/me'), client.get('/v1/me')]);

    expect(results.length, 2);
    expect(refreshCalls, 1, reason: 'refresh must be single-flight');
    expect(authHeaders.where((h) => h == 'Bearer access-new').length, 2);
    expect(client.accessToken, 'access-new');
    expect(client.refreshToken, 'refresh-new');
    expect(vault.pair?.refreshToken, 'refresh-new');
  });

  test('network failure keeps credentials and does not expire the session', () async {
    var expiries = 0;
    final vault = MemoryVault();
    final client = await buildClient(
      vault,
      MockClient((request) async => throw http.ClientException('offline')),
    );
    client.onSessionExpired = () => expiries++;

    await client.setTokens(tokenResponse('access-old', 'refresh-old'));

    await expectLater(
      client.get('/v1/me'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NETWORK')),
    );
    expect(client.refreshToken, 'refresh-old');
    expect(vault.pair?.refreshToken, 'refresh-old');
    expect(expiries, 0);
  });

  test('refresh network failure keeps credentials', () async {
    var expiries = 0;
    final vault = MemoryVault();
    final client = await buildClient(
      vault,
      MockClient((request) async {
        if (request.url.path.endsWith('/v1/auth/refresh')) {
          throw http.ClientException('offline');
        }
        return jsonResponse(401, {
          'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in again'},
        });
      }),
    );
    client.onSessionExpired = () => expiries++;

    await client.setTokens(tokenResponse('access-old', 'refresh-old'));

    await expectLater(
      client.get('/v1/me'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NETWORK')),
    );
    expect(client.refreshToken, 'refresh-old');
    expect(expiries, 0);
  });

  test('refresh 5xx keeps credentials for a later attempt', () async {
    final vault = MemoryVault();
    final client = await buildClient(
      vault,
      MockClient((request) async {
        if (request.url.path.endsWith('/v1/auth/refresh')) {
          return jsonResponse(500, {
            'error': {'code': 'SERVER', 'message': 'Temporary failure'},
          });
        }
        return jsonResponse(401, {
          'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in again'},
        });
      }),
    );

    await client.setTokens(tokenResponse('access-old', 'refresh-old'));

    await expectLater(
      client.get('/v1/me'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
    );
    expect(client.refreshToken, 'refresh-old');
    expect(vault.pair?.refreshToken, 'refresh-old');
  });

  test('definitive 401 clears credentials once', () async {
    var expiries = 0;
    final vault = MemoryVault();
    final client = await buildClient(
      vault,
      MockClient((request) async {
        if (request.url.path.endsWith('/v1/me')) {
          return jsonResponse(401, {
            'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in again'},
          });
        }
        return jsonResponse(401, {
          'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in again'},
        });
      }),
    );
    client.onSessionExpired = () => expiries++;

    await client.setTokens(tokenResponse('access-old', 'refresh-old'));

    await expectLater(
      client.get('/v1/me'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    expect(client.accessToken, isNull);
    expect(client.refreshToken, isNull);
    expect(vault.pair, isNull);
    expect(expiries, 1);
  });

  test('refresh response without a rotated token is rejected', () async {
    final vault = MemoryVault();
    final client = await buildClient(
      vault,
      MockClient((request) async {
        if (request.url.path.endsWith('/v1/auth/refresh')) {
          return jsonResponse(200, {
            'accessToken': 'access-new',
            'tokenType': 'Bearer',
            'expiresIn': 300,
          });
        }
        return jsonResponse(401, {
          'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in again'},
        });
      }),
    );

    await client.setTokens(tokenResponse('access-old', 'refresh-old'));

    await expectLater(
      client.get('/v1/me'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    expect(client.refreshToken, isNull);
    expect(vault.pair, isNull);
  });

  test('login response without a refresh token cannot reuse a stale one', () async {
    final vault = MemoryVault();
    final client = await buildClient(vault, MockClient((request) async {
      return jsonResponse(200, {'ok': true});
    }));

    await expectLater(
      client.setTokens({
        'accessToken': 'access-new',
        'tokenType': 'Bearer',
        'expiresIn': 300,
      }),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    expect(client.accessToken, isNull);
    expect(client.refreshToken, isNull);
    expect(vault.pair, isNull);
  });

  test('pending logout is flushed once connectivity returns', () async {
    final seen = <String>[];
    final vault = MemoryVault(pendingRevocation: 'refresh-old');
    final client = await buildClient(
      vault,
      MockClient((request) async {
        if (request.url.path.endsWith('/v1/auth/logout')) {
          seen.add(request.body);
          return jsonResponse(200, {'ok': true});
        }
        return jsonResponse(500, {'error': {'code': 'ERROR', 'message': 'Unexpected'}});
      }),
    );

    await client.flushPendingLogout();

    expect(seen.length, 1);
    expect(seen.single, contains('refresh-old'));
    expect(vault.pendingRevocation, isNull);
  });

  test('pending logout stays queued when the server is unreachable', () async {
    final vault = MemoryVault(pendingRevocation: 'refresh-old');
    final client = await buildClient(
      vault,
      MockClient((request) async => throw http.ClientException('offline')),
    );

    await client.flushPendingLogout();

    expect(vault.pendingRevocation, 'refresh-old');
  });
}
