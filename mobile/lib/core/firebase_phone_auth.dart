import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Result of a real Firebase Phone Authentication sign-in.
///
/// The Firebase ID token is intentionally not exposed. It is obtained only to
/// confirm that a usable token exists for future Spring Boot integration.
class FirebasePhoneOtpResult {
  const FirebasePhoneOtpResult({
    required this.currentUserAvailable,
    required this.idTokenAvailable,
  });

  final bool currentUserAvailable;
  final bool idTokenAvailable;

  bool get isComplete => currentUserAvailable && idTokenAvailable;
}

/// Testable boundary around Firebase Phone Authentication.
abstract class PhoneOtpService {
  Future<void> sendCode({
    required String phoneNumber,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
    required void Function(FirebasePhoneOtpResult result) onAutoSignedIn,
    void Function(String verificationId)? onTimeout,
  });

  Future<FirebasePhoneOtpResult> verifyCode(
    String verificationId,
    String smsCode,
  );

  Future<void> signOut();

  bool get isSignedIn;
}

/// Real Firebase Auth implementation for Android phone OTP verification.
class FirebasePhoneOtpService implements PhoneOtpService {
  FirebasePhoneOtpService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _autoSignInStarted = false;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  Future<void> sendCode({
    required String phoneNumber,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
    required void Function(FirebasePhoneOtpResult result) onAutoSignedIn,
    void Function(String verificationId)? onTimeout,
  }) async {
    _autoSignInStarted = false;
    await _auth.verifyPhoneNumber(
      phoneNumber: normalizeFirebasePhoneNumber(phoneNumber),
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) {
        if (_autoSignInStarted) return;
        _autoSignInStarted = true;
        unawaited(() async {
          try {
            final result = await _completeSignIn(credential);
            onAutoSignedIn(result);
          } catch (e) {
            onError(firebasePhoneOtpMessage(e));
          }
        }());
      },
      verificationFailed: (error) => onError(firebasePhoneOtpMessage(error)),
      codeSent: (verificationId, token) => onCodeSent(verificationId, token),
      codeAutoRetrievalTimeout: (verificationId) =>
          onTimeout?.call(verificationId),
    );
  }

  @override
  Future<FirebasePhoneOtpResult> verifyCode(
    String verificationId,
    String smsCode,
  ) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId.trim(),
      smsCode: smsCode.trim(),
    );
    return _completeSignIn(credential);
  }

  Future<FirebasePhoneOtpResult> _completeSignIn(
    PhoneAuthCredential credential,
  ) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = _auth.currentUser ?? userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Firebase sign-in did not return a current user.',
      );
    }

    // Obtain the token without returning, persisting or logging it.
    final idToken = await user.getIdToken(false);
    return FirebasePhoneOtpResult(
      currentUserAvailable: true,
      idTokenAvailable: (idToken ?? '').isNotEmpty,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Converts 10-digit Indian mobile numbers to Firebase E.164 format while
/// leaving already-prefixed numbers unchanged.
String normalizeFirebasePhoneNumber(String input) {
  final raw = input.trim();
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (raw.startsWith('+')) return '+$digits';
  if (digits.startsWith('00')) return '+${digits.substring(2)}';
  if (digits.length == 10) return '+91$digits';
  if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
  return '+$digits';
}

/// Maps Firebase Auth error codes to safe, user-facing messages.
/// Raw Firebase messages and credentials are never logged or displayed.
String firebasePhoneOtpMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid mobile number with country code.';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled in Firebase Console.';
      case 'network-request-failed':
        return 'Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait before trying again.';
      case 'quota-exceeded':
        return 'Firebase SMS quota is exhausted. Please try again later.';
      case 'invalid-verification-code':
      case 'code-expired':
      case 'session-expired':
        return 'That code is invalid or expired. Request a new one.';
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return 'This number is already linked to another sign-in method.';
      case 'user-disabled':
        return 'This Firebase account is disabled. Contact support.';
      case 'app-not-authorized':
      case 'invalid-app-credential':
        return 'This app is not authorized for Firebase Phone Authentication.';
    }
  }
  return 'Firebase phone verification failed. Please try again.';
}
