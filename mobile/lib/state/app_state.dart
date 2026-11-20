import 'package:flutter/foundation.dart';

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
  int unread = 0;

  bool get loggedIn => partner != null;
  bool get online => asBool(partner?['isOnline']);
  String get name => asString(partner?['fullName'], 'Partner');
  String get kycStatus => asString(partner?['kycStatus'], 'not_started');

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

  Future<void> loadCities() async {
    try {
      cities = mapList(await api.get('/v1/cities'));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMe() async {
    final res = await api.get('/v1/me');
    partner = Map<String, dynamic>.from(res as Map);
    try {
      final s = await api.get('/v1/me/settings');
      settings = s is Map ? Map<String, dynamic>.from(s) : {};
    } catch (_) {}
    await refreshUnread();
    notifyListeners();
  }

  Future<void> refreshUnread() async {
    try {
      final n = await api.get('/v1/notifications', query: {'limit': '1'});
      unread = n is Map ? asInt(n['unreadCount']) : 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> login(String phone, String password) async {
    final res = await api.post('/v1/auth/login',
        body: {'phone': phone, 'password': password});
    await api.setTokens(Map<String, dynamic>.from(res as Map));
    await loadMe();
  }

  Future<Map<String, dynamic>> signupStart({
    required String fullName,
    required String phone,
    required int cityId,
    required String vehicleType,
    String? referralCode,
  }) async {
    final res = await api.post('/v1/auth/signup/start', body: {
      'fullName': fullName,
      'phone': phone,
      'cityId': cityId,
      'vehicleType': vehicleType,
      'referralCode':
          (referralCode == null || referralCode.trim().isEmpty)
              ? null
              : referralCode.trim(),
      'acceptedTerms': true,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> signupVerify(String phone, String code) async {
    final res = await api.post('/v1/auth/signup/verify',
        body: {'phone': phone, 'code': code});
    await api.setTokens(Map<String, dynamic>.from(res as Map));
    await loadMe();
  }

  Future<Map<String, dynamic>> loginOtpStart(String phone) async {
    final res =
        await api.post('/v1/auth/login/otp/start', body: {'phone': phone});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> loginOtpVerify(String phone, String code) async {
    final res = await api.post('/v1/auth/login/otp/verify',
        body: {'phone': phone, 'code': code});
    await api.setTokens(Map<String, dynamic>.from(res as Map));
    await loadMe();
  }

  Future<void> setPassword(String password) async {
    await api.post('/v1/auth/password', body: {'password': password});
  }

  Future<Map<String, dynamic>> resetStart(String phone) async {
    final res =
        await api.post('/v1/auth/password/reset/start', body: {'phone': phone});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> resetVerify(
      String phone, String code, String password) async {
    await api.post('/v1/auth/password/reset/verify',
        body: {'phone': phone, 'code': code, 'password': password});
  }

  Future<void> toggleOnline(bool value) async {
    final res = await api.put('/v1/me/online', body: {'online': value});
    partner?['isOnline'] = res is Map ? res['online'] : value;
    notifyListeners();
  }

  Future<void> saveSettings(Map<String, dynamic> patch) async {
    final res = await api.patch('/v1/me/settings', body: patch);
    settings = res is Map ? Map<String, dynamic>.from(res) : settings;
    notifyListeners();
  }

  Future<void> saveProfile(Map<String, dynamic> patch) async {
    await api.patch('/v1/me', body: patch);
    await loadMe();
  }

  Future<void> logout() async {
    try {
      if (api.refreshToken != null) {
        await api.post('/v1/auth/logout',
            body: {'refreshToken': api.refreshToken});
      }
    } catch (_) {}
    await api.clear();
    partner = null;
    settings = {};
    unread = 0;
    notifyListeners();
  }
}
