
import 'package:flutter/widgets.dart';

import '../core/api_client.dart';
import '../core/format.dart';

class AppState extends ChangeNotifier {
  AppState(this.api) {
    api.onSessionExpired = () {
      partner = null;
      settings = {};
      unread = 0;
      notifyListeners();
    };
  }

  final ApiClient api;

  bool booting = true;
  Map<String, dynamic>? partner;
  Map<String, dynamic> settings = {};
  List<Map<String, dynamic>> cities = [];
  bool citiesLoading = false;
  bool citiesFailed = false;
  int unread = 0;

  // --------------------------------------------------
  // BASIC APP STATE
  // --------------------------------------------------

  bool get loggedIn => partner != null;

  bool get online => asBool(partner?['isOnline']);

  String get name => asString(partner?['fullName'], 'Partner');

  String get kycStatus => asString(partner?['kycStatus'], 'not_started');

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

    notifyListeners();
  }

  // --------------------------------------------------
  // APP INITIALIZATION
  // --------------------------------------------------

  Future<void> boot() async {
    try {
      await loadCities();

      if (api.hasSession) {
        await loadMe();
      }
    } catch (_) {
      await api.clear();
      partner = null;
    } finally {
      booting = false;
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
    notifyListeners();

    try {
      cities = mapList(await api.get('/v1/cities'));
      citiesFailed = cities.isEmpty;
    } catch (_) {
      citiesFailed = true;
    } finally {
      citiesLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // LOAD PARTNER DETAILS AND SETTINGS
  // --------------------------------------------------

  Future<void> loadMe() async {
    final res = await api.get('/v1/me');

    // Partner profile contains the saved language.
    partner = Map<String, dynamic>.from(res as Map);

    // Partner settings contain preferences such as dark mode
    // and voice navigation.
    try {
      final s = await api.get('/v1/me/settings');

      settings = s is Map
          ? Map<String, dynamic>.from(s)
          : {};
    } catch (_) {}

    await refreshUnread();

    notifyListeners();
  }

  // --------------------------------------------------
  // NOTIFICATIONS
  // --------------------------------------------------

  Future<void> refreshUnread() async {
    try {
      final n = await api.get(
        '/v1/notifications',
        query: {'limit': '1'},
      );

      unread = n is Map ? asInt(n['unreadCount']) : 0;

      notifyListeners();
    } catch (_) {}
  }

  // --------------------------------------------------
  // LOGIN
  // --------------------------------------------------

  Future<void> login(String phone, String password) async {
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

  Future<void> signupVerify(String phone, String code) async {
    final res = await api.post(
      '/v1/auth/signup/verify',
      body: {
        'phone': phone,
        'code': code,
      },
    );

    await api.setTokens(Map<String, dynamic>.from(res as Map));
    await loadMe();
  }

  // --------------------------------------------------
  // OTP LOGIN
  // --------------------------------------------------

  Future<Map<String, dynamic>> loginOtpStart(String phone) async {
    final res = await api.post(
      '/v1/auth/login/otp/start',
      body: {'phone': phone},
    );

    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> loginOtpVerify(String phone, String code) async {
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

  Future<Map<String, dynamic>> resetStart(String phone) async {
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

    notifyListeners();
  }

  // --------------------------------------------------
  // SAVE SETTINGS
  // --------------------------------------------------

  /// Saves preferences to the backend settings endpoint.
  /// Do not use this method to save the application language.
  Future<void> saveSettings(Map<String, dynamic> patch) async {
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

    notifyListeners();
  }

  // --------------------------------------------------
  // SAVE PROFILE
  // --------------------------------------------------

  /// Updates partner profile fields, including application language.
  Future<void> saveProfile(Map<String, dynamic> patch) async {
    await api.patch('/v1/me', body: patch);
    await loadMe();
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> logout() async {
    try {
      if (api.refreshToken != null) {
        await api.post(
          '/v1/auth/logout',
          body: {'refreshToken': api.refreshToken},
        );
      }
    } catch (_) {}

    await api.clear();

    partner = null;
    settings = {};
    unread = 0;

    notifyListeners();
  }
}
