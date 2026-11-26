import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpnexues_partner/core/firebase_phone_auth.dart';
import 'package:vpnexues_partner/screens/firebase_phone_auth_screen.dart';

class FakePhoneOtpService implements PhoneOtpService {
  bool signedIn = false;
  bool autoSignIn = false;
  String? sendError;
  String? lastPhone;
  int sendCount = 0;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<void> sendCode({
    required String phoneNumber,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
    required void Function(FirebasePhoneOtpResult result) onAutoSignedIn,
    void Function(String verificationId)? onTimeout,
  }) async {
    sendCount += 1;
    lastPhone = phoneNumber;
    if (sendError != null) {
      onError(sendError!);
      return;
    }
    if (autoSignIn) {
      signedIn = true;
      onAutoSignedIn(
        const FirebasePhoneOtpResult(
          currentUserAvailable: true,
          idTokenAvailable: true,
        ),
      );
      return;
    }
    onCodeSent('synthetic-verification-id', 42);
  }

  @override
  Future<FirebasePhoneOtpResult> verifyCode(
    String verificationId,
    String smsCode,
  ) async {
    signedIn = true;
    return const FirebasePhoneOtpResult(
      currentUserAvailable: true,
      idTokenAvailable: true,
    );
  }

  @override
  Future<void> signOut() async => signedIn = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizes synthetic phone numbers to E.164', () {
    expect(normalizeFirebasePhoneNumber('1234567890'), '+911234567890');
    expect(normalizeFirebasePhoneNumber('+44 7700 900123'), '+447700900123');
    expect(normalizeFirebasePhoneNumber('0091 12345 67890'), '+911234567890');
  });

  test('maps Firebase errors to safe messages', () {
    expect(
      firebasePhoneOtpMessage(
        FirebaseAuthException(code: 'invalid-verification-code'),
      ),
      contains('invalid or expired'),
    );
    expect(
      firebasePhoneOtpMessage(
        FirebaseAuthException(code: 'operation-not-allowed'),
      ),
      contains('not enabled in Firebase Console'),
    );
    expect(firebasePhoneOtpMessage(StateError('nope')), contains('failed'));
  });

  testWidgets('sends code, verifies synthetic OTP, then signs out', (
    tester,
  ) async {
    // Synthetic values only; no project test phone number or OTP is embedded.
    const syntheticPhone = '1234567890';
    const syntheticDigit = '1';
    final service = FakePhoneOtpService();

    await tester.pumpWidget(
      MaterialApp(home: FirebasePhoneAuthScreen(service: service)),
    );

    await tester.enterText(find.byType(TextField).first, syntheticPhone);
    await tester.tap(find.text('SEND FIREBASE CODE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(service.lastPhone, '+91$syntheticPhone');
    expect(find.text('Enter the 6-digit code'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.enterText(find.byType(TextField).at(i), syntheticDigit);
    }
    await tester.tap(find.text('VERIFY & SIGN IN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(service.signedIn, true);
    expect(find.text('Firebase sign-in complete'), findsOneWidget);
    expect(find.textContaining('ID token obtained'), findsOneWidget);

    await tester.tap(find.text('SIGN OUT OF FIREBASE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(service.signedIn, false);
    expect(find.text('Verify with Firebase'), findsOneWidget);
  });

  testWidgets('handles auto verification and send failures', (tester) async {
    final autoService = FakePhoneOtpService()..autoSignIn = true;
    await tester.pumpWidget(
      MaterialApp(home: FirebasePhoneAuthScreen(service: autoService)),
    );
    await tester.enterText(find.byType(TextField).first, '1234567890');
    await tester.tap(find.text('SEND FIREBASE CODE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Firebase sign-in complete'), findsOneWidget);

    await tester.tap(find.text('SIGN OUT OF FIREBASE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final failingService = FakePhoneOtpService()
      ..sendError = 'Phone sign-in is not enabled in Firebase Console.';
    await tester.pumpWidget(
      MaterialApp(home: FirebasePhoneAuthScreen(service: failingService)),
    );
    await tester.enterText(find.byType(TextField).first, '1234567890');
    await tester.tap(find.text('SEND FIREBASE CODE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.textContaining('not enabled in Firebase Console'),
      findsOneWidget,
    );
  });
}
