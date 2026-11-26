import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthTokenProvider {
  Future<String?> getToken();
}

class JwtTokenProvider implements AuthTokenProvider {
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }
}

// The Firebase Implementation
class FirebaseTokenProvider implements AuthTokenProvider {
  @override
  Future<String?> getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    // Gets the JWT token from Firebase
    return await user.getIdToken(); 
  }
}