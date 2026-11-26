import 'package:dio/dio.dart';
import 'auth_token_provider.dart';

class ApiClient {
  late final Dio _dio;
  final AuthTokenProvider _auth;

  // Use 10.0.2.2 for Android Emulator. Use your PC IP (e.g. 192.168.x.x) for physical phone.
  ApiClient(this._auth, {String baseUrl = 'http://10.0.2.2:8080'}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {'Content-Type': 'application/json'}, // Critical for Spring Boot
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _auth.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<String> login(String phone, String password) async {
    final res = await _dio.post('/v1/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return res.data['accessToken'];
  }

  // Notice we return res.data['value'] because backend wraps it as {value: [], Count: 0}
  Future<List<dynamic>> getOrders() async {
    final res = await _dio.get('/v1/orders');
    return res.data['value'] as List<dynamic>; 
  }

  Future<void> acceptOrder(String orderId) async {
    await _dio.post('/v1/orders/$orderId/accept', data: {});
  }
  
  // You can add the rest of the endpoints (scanCrate, atPickup, etc.) exactly like we discussed.
}