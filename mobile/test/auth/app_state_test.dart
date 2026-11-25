import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vpnexues_partner/core/api_client.dart';
import 'package:vpnexues_partner/core/token_vault.dart';
import 'package:vpnexues_partner/state/app_state.dart';

import 'fakes.dart';

Future<AppState> buildState(MemoryVault vault, http.Client httpClient) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return AppState(ApiClient(prefs, vault: vault, httpClient: httpClient));
}

void main() {
  test('boot keeps a stored session when the network is unavailable', () async {
    final vault = MemoryVault(
      pair: TokenPair(
        accessToken: 'access-old',
        refreshToken: 'refresh-old',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    );
    final state = await buildState(
      vault,
      MockClient((request) async {
        if (request.url.path.endsWith('/v1/cities')) {
          return http.Response('[]', 200);
        }
        throw http.ClientException('offline');
      }),
    );

    await state.boot();

    expect(state.booting, isFalse);
    expect(state.offline, isTrue);
    expect(state.api.refreshToken, 'refresh-old');
    expect(vault.pair?.refreshToken, 'refresh-old');
  });

  test('boot clears a session only on a definitive auth failure', () async {
    final vault = MemoryVault(
      pair: TokenPair(
        accessToken: 'access-old',
        refreshToken: 'refresh-old',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    );
    final state = await buildState(
      vault,
      MockClient((request) async {
        if (request.url.path.endsWith('/v1/cities')) {
          return http.Response('[]', 200);
        }
        return jsonResponse(401, {
          'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in again'},
        });
      }),
    );

    await state.boot();

    expect(state.booting, isFalse);
    expect(state.api.refreshToken, isNull);
    expect(vault.pair, isNull);
    expect(state.partner, isNull);
  });

  test('offline logout clears locally and queues server revocation', () async {
    final vault = MemoryVault();
    final state = await buildState(
      vault,
      MockClient((request) async => throw http.ClientException('offline')),
    );
    await state.api.setTokens(tokenResponse('access-old', 'refresh-old'));

    await state.logout();

    expect(state.api.refreshToken, isNull);
    expect(state.offline, isTrue);
    expect(vault.pair, isNull);
    expect(vault.pendingRevocation, 'refresh-old');
  });

  test('boot restores a valid secure session and loads partner data', () async {
    final vault = MemoryVault(
      pair: TokenPair(
        accessToken: 'access-old',
        refreshToken: 'refresh-old',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    );
    final paths = <String>[];
    final state = await buildState(
      vault,
      MockClient((request) async {
        final path = request.url.path;
        paths.add(path);
        if (path.endsWith('/v1/cities')) {
          return http.Response('[{"id":1,"name":"Test City"}]', 200);
        }
        if (path.endsWith('/v1/me')) {
          return jsonResponse(200, {
            'fullName': 'Restored Partner',
            'isOnline': true,
            'kycStatus': 'verified',
          });
        }
        if (path.endsWith('/v1/me/settings')) {
          return jsonResponse(200, {'language': 'en'});
        }
        if (path.endsWith('/v1/notifications')) {
          return jsonResponse(200, {'unreadCount': 2});
        }
        return jsonResponse(500, {'error': {'code': 'ERROR', 'message': 'Unexpected'}});
      }),
    );

    await state.boot();

    expect(state.booting, isFalse);
    expect(state.offline, isFalse);
    expect(state.partner, isNotNull);
    expect(state.name, 'Restored Partner');
    expect(state.online, isTrue);
    expect(state.settings['language'], 'en');
    expect(state.unread, 2);
    expect(state.api.accessToken, 'access-old');
    expect(state.api.refreshToken, 'refresh-old');
    expect(vault.pair?.refreshToken, 'refresh-old');
    expect(paths, contains('/v1/me'));
    expect(paths, contains('/v1/me/settings'));
    expect(paths, contains('/v1/notifications'));
  });

  test('concurrent resumes validate once and share a single proactive refresh', () async {
    final vault = MemoryVault(
      pair: TokenPair(
        accessToken: 'access-old',
        refreshToken: 'refresh-old',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    );
    var meCalls = 0;
    var refreshCalls = 0;
    final authHeaders = <String?>[];
    final state = await buildState(
      vault,
      MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/v1/cities')) return http.Response('[]', 200);
        if (path.endsWith('/v1/auth/refresh')) {
          refreshCalls++;
          return jsonResponse(200, backendTokenResponse('access-resumed', 'refresh-resumed'));
        }
        if (path.endsWith('/v1/me')) {
          meCalls++;
          authHeaders.add(request.headers['Authorization']);
          return jsonResponse(200, {'fullName': 'Validated Partner'});
        }
        if (path.endsWith('/v1/me/settings')) return jsonResponse(200, {});
        if (path.endsWith('/v1/notifications')) {
          return jsonResponse(200, {'unreadCount': 0});
        }
        return jsonResponse(500, {'error': {'code': 'ERROR', 'message': 'Unexpected'}});
      }),
    );

    await state.boot();
    final meCallsAfterBoot = meCalls;

    // Simulate an access token that expired while the app was backgrounded.
    state.api.expiresAt = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
    await Future.wait([state.resumeSession(), state.resumeSession()]);

    expect(refreshCalls, 1, reason: 'resume refresh must be single-flight');
    expect(meCalls, meCallsAfterBoot + 1);
    expect(state.name, 'Validated Partner');
    expect(state.offline, isFalse);
    expect(state.api.accessToken, 'access-resumed');
    expect(state.api.refreshToken, 'refresh-resumed');
    expect(vault.pair?.refreshToken, 'refresh-resumed');
    expect(authHeaders.last, 'Bearer access-resumed');
  });
}
