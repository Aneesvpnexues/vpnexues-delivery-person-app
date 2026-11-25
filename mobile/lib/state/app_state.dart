
import 'dart:async';

import 'package:flutter/foundation.dart';

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

  Map<String, dynamic>? partner;
  Map<String, dynamic> settings = {};

  // List<Map<String, dynamic>> cities = [];

  // bool citiesLoading = false;
  // bool citiesFailed = false;

  int unread = 0;

  bool _disposed = false;
  Future<void>? _bootFuture;

  bool get loggedIn => partner != null;

  bool get online => asBool(partner?['isOnline']);

  String get name => asString(partner?['fullName'], 'Partner');

  String get kycStatus =>
      asString(partner?['kycStatus'], 'not_started');

  /// Signup draft stored locally.
  Map<String, dynamic> get signupDraft =>
      api.getSignupDraft() ?? {};

  Future<void> saveSignupDraft(
    Map<String, dynamic> draft,
  ) {
    return api.saveSignupDraft(draft);
  }

  Future<void> saveLoginPhone(String phone) {
    return api.saveLoginPhone(phone);
  }

  // --------------------------------------------------
  // APP INITIALIZATION
  // --------------------------------------------------

  Future<void> boot() {
    return _bootFuture ??= _runBoot();
  }

  Future<void> _runBoot() async {
    booting = true;

    // Cities must never block authentication.
    // unawaited(loadCities());

    try {
      // Temporary dev mode: no server calls during splash → home screen.
      // A stored session counts as logged in without calling /v1/me.
      partner = api.hasSession
          ? {
              'fullName': 'Partner',
              'isOnline': true,
            }
          : null;
    } catch (e, stack) {
      debugPrint('App initialization failed: $e');
      debugPrintStack(stackTrace: stack);
    } finally {
      booting = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // --------------------------------------------------
  // CITIES
  // --------------------------------------------------

  //Future<void> loadCities() async {
  //   if (citiesLoading) return;

  //   citiesLoading = true;
  //   citiesFailed = false;

  //   if (!_disposed) {
  //     notifyListeners();
  //   }

  //   try {
  //     final result = await api.get('/v1/cities');

  //     cities = mapList(result);
  //     citiesFailed = cities.isEmpty;
  //   } catch (e) {
  //     citiesFailed = true;
  //     debugPrint('Cities loading failed: $e');
  //   } finally {
  //     citiesLoading = false;

  //     if (!_disposed) {
  //       notifyListeners();
  //     }
  //   }
  // }

  // --------------------------------------------------
  // PROFILE / AUTHENTICATION
  // --------------------------------------------------

  Future<void> loadMe() async {
    final res = await api.get('/v1/me');

    partner = Map<String, dynamic>.from(res as Map);

    // Notify immediately after authentication succeeds.
    if (!_disposed) {
      notifyListeners();
    }

    // These requests must not block the HomeShell.
    unawaited(_loadSettings());
    unawaited(refreshUnread());
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
    if (code == AppState.devOtpCode) {
      // Temporary dev bypass: accept the code and set a local session
      // without calling the backend.
      await api.setTokens({
        'accessToken': 'dev-$phone',
        'refreshToken': 'dev',
      });
      return;
    }

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

    partner?['isOnline'] =
        res is Map ? res['online'] : value;

    if (!_disposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // SETTINGS
  // --------------------------------------------------

  Future<void> saveSettings(
    Map<String, dynamic> patch,
  ) async {
    final res = await api.patch(
      '/v1/me/settings',
      body: patch,
    );

    settings = res is Map
        ? Map<String, dynamic>.from(res)
        : settings;

    if (!_disposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // PROFILE
  // --------------------------------------------------

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
    try {
      if (api.refreshToken != null) {
        await api.post(
          '/v1/auth/logout',
          body: {
            'refreshToken': api.refreshToken,
          },
        );
      }
    } catch (e) {
      debugPrint('Remote logout failed: $e');
    }

    await api.clear();

    partner = null;
    settings = {};
    unread = 0;

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
