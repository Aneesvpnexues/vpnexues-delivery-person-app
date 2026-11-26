import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal interface so storage can be faked in unit tests.
abstract class SecureKeyValueStore {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
}

/// Platform-backed home for authentication credentials.
abstract class TokenVault {
  Future<void> initialize();
  Future<TokenPair?> read();
  Future<void> write(TokenPair pair);
  Future<void> clear();
  Future<String?> readPendingRevocation();
  Future<void> writePendingRevocation(String refreshToken);
  Future<void> clearPendingRevocation();
}

/// Stores tokens in the Android Keystore / iOS Keychain.
///
/// `SharedPreferences` is used only for a one-time migration flag and legacy
/// cleanup bookkeeping, never for token values.
class SecureTokenVault implements TokenVault {
  SecureTokenVault(this._store, this._prefs);

  final SecureKeyValueStore _store;
  final SharedPreferences _prefs;

  static const _kAccess = 'vpn.accessToken';
  static const _kRefresh = 'vpn.refreshToken';
  static const _kExpiresAt = 'vpn.accessTokenExpiresAt';
  static const _kPendingLogout = 'vpn.pendingLogoutRefreshToken';
  static const _kMigrated = 'vpn.secureTokenMigrationDone';

  static const _legacyAccess = 'vpnexues.accessToken';
  static const _legacyRefresh = 'vpnexues.refreshToken';

  @override
  Future<void> initialize() async {
    if (_prefs.getBool(_kMigrated) ?? false) return;

    final legacyAccess = _prefs.getString(_legacyAccess);
    final legacyRefresh = _prefs.getString(_legacyRefresh);

    if (legacyAccess != null) {
      await _store.write(key: _kAccess, value: legacyAccess);
      if (await _store.read(key: _kAccess) != legacyAccess) {
        throw StateError('Secure token migration could not be verified');
      }
    }
    if (legacyRefresh != null) {
      await _store.write(key: _kRefresh, value: legacyRefresh);
      if (await _store.read(key: _kRefresh) != legacyRefresh) {
        throw StateError('Secure token migration could not be verified');
      }
    }

    // Delete plaintext originals only after the secure copy is verified.
    await _prefs.remove(_legacyAccess);
    await _prefs.remove(_legacyRefresh);
    await _prefs.setBool(_kMigrated, true);
  }

  @override
  Future<TokenPair?> read() async {
    final access = await _store.read(key: _kAccess);
    final refresh = await _store.read(key: _kRefresh);
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      return null;
    }
    final rawExpiry = await _store.read(key: _kExpiresAt);
    final expiry = rawExpiry == null ? null : DateTime.tryParse(rawExpiry)?.toUtc();
    return TokenPair(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: expiry,
    );
  }

  @override
  Future<void> write(TokenPair pair) async {
    await _store.write(key: _kAccess, value: pair.accessToken);
    await _store.write(key: _kRefresh, value: pair.refreshToken);
    if (pair.expiresAt == null) {
      await _store.delete(key: _kExpiresAt);
    } else {
      await _store.write(
        key: _kExpiresAt,
        value: pair.expiresAt!.toUtc().toIso8601String(),
      );
    }
  }

  @override
  Future<void> clear() async {
    await _store.delete(key: _kAccess);
    await _store.delete(key: _kRefresh);
    await _store.delete(key: _kExpiresAt);
  }

  @override
  Future<String?> readPendingRevocation() => _store.read(key: _kPendingLogout);

  @override
  Future<void> writePendingRevocation(String refreshToken) =>
      _store.write(key: _kPendingLogout, value: refreshToken);

  @override
  Future<void> clearPendingRevocation() => _store.delete(key: _kPendingLogout);
}
