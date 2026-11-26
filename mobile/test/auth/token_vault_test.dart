import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vpnexues_partner/core/token_vault.dart';
import 'fakes.dart';

void main() {
  test('legacy tokens move into secure storage and plaintext is deleted', () async {
    SharedPreferences.setMockInitialValues({
      'vpnexues.accessToken': 'legacy-access',
      'vpnexues.refreshToken': 'legacy-refresh',
    });
    final prefs = await SharedPreferences.getInstance();
    final store = MemorySecureStore();
    final vault = SecureTokenVault(store, prefs);

    await vault.initialize();

    expect(store.values['vpn.accessToken'], 'legacy-access');
    expect(store.values['vpn.refreshToken'], 'legacy-refresh');
    expect(prefs.getString('vpnexues.accessToken'), isNull);
    expect(prefs.getString('vpnexues.refreshToken'), isNull);
    expect(prefs.getBool('vpn.secureTokenMigrationDone'), isTrue);

    final restored = await vault.read();
    expect(restored?.accessToken, 'legacy-access');
    expect(restored?.refreshToken, 'legacy-refresh');
  });

  test('migration is idempotent and does not overwrite secure values', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = MemorySecureStore();
    final vault = SecureTokenVault(store, prefs);

    await vault.write(const TokenPair(
      accessToken: 'secure-access',
      refreshToken: 'secure-refresh',
    ));
    await vault.initialize();
    await vault.initialize();

    final restored = await vault.read();
    expect(restored?.accessToken, 'secure-access');
    expect(restored?.refreshToken, 'secure-refresh');
  });

  test('failed secure write keeps legacy plaintext for a later retry', () async {
    SharedPreferences.setMockInitialValues({
      'vpnexues.accessToken': 'legacy-access',
      'vpnexues.refreshToken': 'legacy-refresh',
    });
    final prefs = await SharedPreferences.getInstance();
    final store = MemorySecureStore()..failWrites = true;
    final vault = SecureTokenVault(store, prefs);

    expect(vault.initialize, throwsA(isA<StateError>()));
    expect(prefs.getString('vpnexues.accessToken'), 'legacy-access');
    expect(prefs.getString('vpnexues.refreshToken'), 'legacy-refresh');
    expect(prefs.getBool('vpn.secureTokenMigrationDone'), isNull);
  });
}
