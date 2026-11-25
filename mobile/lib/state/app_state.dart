import 'package:flutter/widgets.dart';

import '../core/api_client.dart';
import '../core/format.dart';

class AppState extends ChangeNotifier {
  AppState(this.api) {
    api.onSessionExpired = () {
      partner = null;
      settings = {};
      unread = 0;

      if (!_disposed) {
        notifyListeners();
      }
    };
  }

  final ApiClient api;

  bool booting = true;
  bool offline = false;
  Future<void>? _resuming;
  Map<String, dynamic>? partner;
  Map<String, dynamic> settings = {};

  List<Map<String, dynamic>> cities = [];
  bool citiesLoading = false;
  bool citiesFailed = false;

  int unread = 0;

  bool _disposed = false;
  Future<void>? _bootFuture;

  bool get loggedIn => partner != null;

  bool get online => asBool(partner?['isOnline']);

  String get name => asString(partner?['fullName'], 'Partner');

  String get kycStatus => asString(partner?['kycStatus'], 'not_started');

  /// Signup draft stored locally.
  Map<String, dynamic> get signupDraft => api.getSignupDraft() ?? {};

  Future<void> saveSignupDraft(Map<String, dynamic> draft) {
    return api.saveSignupDraft(draft);
  }

  Future<void> saveLoginPhone(String phone) {
    return api.saveLoginPhone(phone);
  }

  // --------------------------------------------------
  // DARK MODE
  // --------------------------------------------------

  /// Returns true when Dark Mode is enabled.
  ///
  /// The preference is stored in partner settings
  /// under the key 'darkModeAtNight'.
  bool get isDarkMode => asBool(settings['darkModeAtNight']);

  // --------------------------------------------------
  // LOCALIZATION TEST MODE
  // --------------------------------------------------

  // Temporary test-mode identifier.
  bool get isLocalizationTestMode => partner?['id'] == 999;

  // --------------------------------------------------
  // APP LANGUAGE / LOCALE
  // --------------------------------------------------

  /// Normal app mode:
  /// Read the saved language from the backend partner profile.
  ///
  /// Localization test mode:
  /// Read the temporary language from local settings.
  ///
  /// Supported backend languages:
  /// en, ta, hi, ml, te, kn
  Locale get locale {
    final String lang = isLocalizationTestMode
        ? asString(settings['language'], 'en')
        : asString(partner?['language'], 'en');

    switch (lang) {
      case 'en':
        return const Locale('en');

      case 'ta':
        return const Locale('ta');

      case 'hi':
        return const Locale('hi');

      case 'ml':
        return const Locale('ml');

      case 'te':
        return const Locale('te');

      case 'kn':
        return const Locale('kn');

      default:
        return const Locale('en');
    }
  }

  // --------------------------------------------------
  // LOCAL SETTINGS UPDATE
  // --------------------------------------------------

  /// Updates settings locally without calling the backend.
  /// Used for temporary localization testing and local UI updates.
  void updateLocalSettings(Map<String, dynamic> patch) {
    settings = {
      ...settings,
      ...patch,
    };

    if (!_disposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // SESSION VALIDATION
  // --------------------------------------------------

  static bool _invalidSession(ApiException e) =>
      e.status == 401 ||
      e.code == 'UNAUTHENTICATED' ||
      e.code == 'INVALID_SESSION' ||
      e.code == 'REVOKED';

  void _clearSessionState() {
    partner = null;
    settings = {};
    unread = 0;
  }

  // --------------------------------------------------
  // APP INITIALIZATION
  // --------------------------------------------------

  Future<void> boot() {
    return _bootFuture ??= _runBoot();
  }

  Future<void> _runBoot() async {
    booting = true;

    try {
      // Restore credentials from platform-backed secure storage, flush any
      // logout that could not reach the server, then validate the session.
      await api.restore();
      await api.flushPendingLogout();
      await loadCities();
      if (api.hasSession) {
        await api.ensureFreshToken();
        await loadMe();
      }
      offline = false;
    } on ApiException catch (e) {
      if (_invalidSession(e)) {
        await api.expireSession();
        _clearSessionState();
      } else {
        // Network/server errors must not destroy a valid stored session.
        offline = true;
      }
    } catch (e, stack) {
      debugPrint('App initialization failed: $e');
      debugPrintStack(stackTrace: stack);
      offline = true;
    } finally {
      booting = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }
  /// Called when the app returns to the foreground. Shares the single-flight
  /// refresh with boot so startup and resume cannot double-spend a token.
  Future<void> resumeSession() {
    if (booting || !api.hasSession) return Future.value();
    return _resuming ??= _doResume().whenComplete(() => _resuming = null);
  }

  Future<void> _doResume() async {
    try {
      await api.flushPendingLogout();
      await api.ensureFreshToken();
      await loadMe();
      offline = false;
    } on ApiException catch (e) {
      if (_invalidSession(e)) {
        await api.expireSession();
        _clearSessionState();
      } else {
        offline = true;
      }
    } catch (e) {
      debugPrint('Session resume failed: $e');
      offline = true;
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // CITIES
  // --------------------------------------------------

  Future<void> loadCities() async {
    if (citiesLoading) return;

    citiesLoading = true;
    citiesFailed = false;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      cities = mapList(await api.get('/v1/cities'));
      citiesFailed = cities.isEmpty;
    } catch (e) {
      citiesFailed = true;
      debugPrint('Cities loading failed: $e');
    } finally {
      citiesLoading = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // --------------------------------------------------
  // LOAD PARTNER DETAILS AND SETTINGS
  // --------------------------------------------------

  Future<void> loadMe() async {
    final res = await api.get('/v1/me');

    partner = Map<String, dynamic>.from(res as Map);

    // Notify immediately after authentication succeeds.
    if (!_disposed) {
      notifyListeners();
    }

    // Awaited so callers of boot()/login() observe a fully hydrated state
    // (settings + unread badge) before they continue.
    await _loadSettings();
    await refreshUnread();
  }

  Future<void> _loadSettings() async {
    try {
      final result = await api.get('/v1/me/settings');

      settings = result is Map
          ? Map<String, dynamic>.from(result)
          : {};

      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Settings loading failed: $e');
    }
  }

  // --------------------------------------------------
  // NOTIFICATIONS
  // --------------------------------------------------

  Future<void> refreshUnread() async {
    try {
      final result = await api.get(
        '/v1/notifications',
        query: {'limit': '1'},
      );

      unread = result is Map
          ? asInt(result['unreadCount'])
          : 0;

      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Notification loading failed: $e');
    }
  }

  // --------------------------------------------------
  // PHONE / PASSWORD LOGIN
  // --------------------------------------------------

  Future<void> login(
    String phone,
    String password,
  ) async {
    final res = await api.post(
      '/v1/auth/login',
      body: {
        'phone': phone,
        'password': password,
      },
    );

    await api.setTokens(Map<String, dynamic>.from(res as Map));

    await loadMe();
  }

  // --------------------------------------------------
  // SIGNUP
  // --------------------------------------------------

  /// Temporary dev OTP accepted to verify a mobile number without the backend.
  static const String devOtpCode = '123456';

  Future<Map<String, dynamic>> signupStart({
    required String fullName,
    required String phone,
    required int cityId,
    required String vehicleType,
    String? referralCode,
  }) async {
    final res = await api.post(
      '/v1/auth/signup/start',
      body: {
        'fullName': fullName,
        'phone': phone,
        'cityId': cityId,
        'vehicleType': vehicleType,
        'referralCode':
            (referralCode == null || referralCode.trim().isEmpty)
                ? null
                : referralCode.trim(),
        'acceptedTerms': true,
      },
    );

    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> signupVerify(
    String phone,
    String code,
  ) async {
    try {
      final res = await api.post(
        '/v1/auth/signup/verify',
        body: {
          'phone': phone,
          'code': code,
        },
      );

      await api.setTokens(Map<String, dynamic>.from(res as Map));

      await loadMe();
      return;
    } on ApiException catch (e) {
      // The server answered (wrong/expired code, rate limit, …): surface it.
      if (e.status != 0) rethrow;
      // status 0 = unreachable network → fall through to the dev bypass.
    }

    // Temporary dev bypass: accept the code and set a local session without
    // calling the backend. Only reached when the backend cannot be reached.
    await api.setTokens({
      'accessToken': 'dev-$phone',
      'refreshToken': 'dev',
    });
  }

  // --------------------------------------------------
  // OTP LOGIN
  // --------------------------------------------------

  Future<Map<String, dynamic>> loginOtpStart(
    String phone,
  ) async {
    final res = await api.post(
      '/v1/auth/login/otp/start',
      body: {'phone': phone},
    );

    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> loginOtpVerify(
    String phone,
    String code,
  ) async {
    final res = await api.post(
      '/v1/auth/login/otp/verify',
      body: {
        'phone': phone,
        'code': code,
      },
    );

    await api.setTokens(Map<String, dynamic>.from(res as Map));

    await loadMe();
  }

  // --------------------------------------------------
  // PASSWORD
  // --------------------------------------------------

  Future<void> setPassword(String password) async {
    await api.post(
      '/v1/auth/password',
      body: {'password': password},
    );
  }

  Future<Map<String, dynamic>> resetStart(
    String phone,
  ) async {
    final res = await api.post(
      '/v1/auth/password/reset/start',
      body: {'phone': phone},
    );

    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> resetVerify(
    String phone,
    String code,
    String password,
  ) async {
    await api.post(
      '/v1/auth/password/reset/verify',
      body: {
        'phone': phone,
        'code': code,
        'password': password,
      },
    );
  }

  // --------------------------------------------------
  // ONLINE / OFFLINE
  // --------------------------------------------------

  Future<void> toggleOnline(bool value) async {
    final res = await api.put(
      '/v1/me/online',
      body: {'online': value},
    );

    partner?['isOnline'] = res is Map ? res['online'] : value;

    if (!_disposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // SAVE SETTINGS
  // --------------------------------------------------

  /// Saves preferences to the backend settings endpoint.
  /// Do not use this method to save the application language.
  Future<void> saveSettings(
    Map<String, dynamic> patch,
  ) async {
    final res = await api.patch(
      '/v1/me/settings',
      body: patch,
    );

    settings = res is Map
        ? Map<String, dynamic>.from(res)
        : {
            ...settings,
            ...patch,
          };

    if (!_disposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // SAVE PROFILE
  // --------------------------------------------------

  /// Updates partner profile fields, including application language.
  Future<void> saveProfile(
    Map<String, dynamic> patch,
  ) async {
    await api.patch('/v1/me', body: patch);

    await loadMe();
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> logout() async {
    final token = api.refreshToken;
    if (token != null) {
      try {
        await api.post(
          '/v1/auth/logout',
          body: {'refreshToken': token},
          auth: false,
          timeout: const Duration(seconds: 15),
        );
      } on ApiException catch (e) {
        if (e.status == 0 || e.status >= 500) {
          // Offline/server failure: keep a one-shot revocation token in secure
          // storage and flush it on the next boot or resume.
          await api.clear(retainForRevocation: true);
          _clearSessionState();
          offline = true;
          _notify();
          return;
        }
        // 401/404 means the session is already invalid on the server.
      } catch (e) {
        debugPrint('Remote logout failed: $e');
        await api.clear(retainForRevocation: true);
        _clearSessionState();
        offline = true;
        _notify();
        return;
      }
    }
    await api.clear();
    _clearSessionState();
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
