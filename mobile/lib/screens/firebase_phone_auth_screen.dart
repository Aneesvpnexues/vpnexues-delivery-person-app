import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/firebase_phone_auth.dart';
import '../ui/design.dart';

enum _Step { phone, code, signedIn }

/// Standalone Firebase Phone OTP flow. It does not alter the existing password
/// login, backend OTP login, JWT tokens or partner session.
class FirebasePhoneAuthScreen extends StatefulWidget {
  const FirebasePhoneAuthScreen({super.key, this.service});

  final PhoneOtpService? service;

  @override
  State<FirebasePhoneAuthScreen> createState() =>
      _FirebasePhoneAuthScreenState();
}

class _FirebasePhoneAuthScreenState extends State<FirebasePhoneAuthScreen> {
  static const xs = [20.0, 83.8, 147.6, 211.4, 275.2, 339.0];

  final _phone = TextEditingController();
  final _otp = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());

  PhoneOtpService? _defaultService;
  PhoneOtpService get _service =>
      widget.service ?? (_defaultService ??= FirebasePhoneOtpService());

  _Step _step = _Step.phone;
  bool _busy = false;
  String? _error;
  String? _status;
  String? _verificationId;
  int? _resendToken;
  int _wait = 30;
  Timer? _timer;

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');

  String get _maskedPhone {
    final digits = _digits;
    if (digits.length < 10) return '+91 $digits';
    return '+91 ${digits.substring(0, 2)}••• ••${digits.substring(8)}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    for (final c in _otp) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _clearCode() {
    for (final c in _otp) {
      c.clear();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _wait = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        _wait -= 1;
        if (_wait <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (_busy) return;
    final digits = _digits;
    if (digits.length != 10) {
      setState(() => _error = 'Enter your 10-digit mobile number');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      if (!resend) _status = null;
    });

    try {
      await _service.sendCode(
        phoneNumber: '+91$digits',
        resendToken: resend ? _resendToken : null,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _step = _Step.code;
            _error = null;
            _status = resend
                ? 'A new code was sent by Firebase SMS.'
                : 'Code sent by Firebase SMS.';
            _clearCode();
            _startTimer();
          });
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _error = message;
            _status = null;
          });
        },
        onAutoSignedIn: _complete,
        onTimeout: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId ??= verificationId;
            _status = 'Auto-retrieval timed out. Enter the code manually.';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = firebasePhoneOtpMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_busy) return;
    final verificationId = _verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      setState(() => _error = 'Request a Firebase code first');
      return;
    }
    final code = _otp.map((c) => c.text).join();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter all 6 digits');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.verifyCode(verificationId, code);
      _complete(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = firebasePhoneOtpMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _complete(FirebasePhoneOtpResult result) {
    if (!mounted) return;
    _timer?.cancel();
    if (!result.currentUserAvailable) {
      setState(() {
        _error = 'Firebase sign-in did not return a current user.';
        _busy = false;
      });
      return;
    }
    setState(() {
      _step = _Step.signedIn;
      _busy = false;
      _error = null;
      _status = result.idTokenAvailable
          ? 'Current user is available. ID token obtained without storing or logging it.'
          : 'Current user is available.';
    });
  }

  void _backToPhone() {
    _timer?.cancel();
    setState(() {
      _step = _Step.phone;
      _error = null;
      _status = null;
      _wait = 30;
      _clearCode();
    });
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.signOut();
      if (!mounted) return;
      setState(() {
        _timer?.cancel();
        _phone.clear();
        _clearCode();
        _verificationId = null;
        _resendToken = null;
        _wait = 30;
        _error = null;
        _status = null;
        _step = _Step.phone;
      });
      showToast(context, 'Signed out of Firebase');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = firebasePhoneOtpMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepWidgets = switch (_step) {
      _Step.phone => _phoneStep(),
      _Step.code => _codeStep(),
      _Step.signedIn => _signedInStep(),
    };
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const Backdrop(
              outlines: [
                Rect.fromLTWH(89.6, 80, 261.7, 444.2),
                Rect.fromLTWH(239.1, 470.9, 112.2, 53.3),
              ],
            ),
            ...stepWidgets,
          ],
        ),
      ),
    );
  }

  List<Widget> _phoneStep() => [
    BackBar(
      title: 'Firebase OTP',
      onBack: () => Navigator.of(context).maybePop(),
    ),
    const Logo(x: 20, y: 110, s: 56),
    const DTxt(
      'VP NEXUES PARTNER',
      x: 90,
      y: 122,
      w: 280,
      s: 11,
      wt: FontWeight.w700,
      lh: 15.4,
      c: C.accent,
      ls: .9,
    ),
    const DTxt(
      'Delivery partner app',
      x: 90,
      y: 137,
      w: 280,
      s: 12,
      wt: FontWeight.w500,
      lh: 16.8,
      c: C.muted,
    ),
    const DTxt(
      'Verify with Firebase',
      x: 20,
      y: 181,
      w: 372,
      s: 29,
      wt: FontWeight.w700,
      lh: 40.6,
    ),
    const DTxt(
      'Use the number configured in Firebase Console. Existing password and OTP login stay unchanged.',
      x: 20,
      y: 224,
      w: 380,
      s: 14,
      wt: FontWeight.w500,
      lh: 20,
      c: C.muted,
    ),
    const DTxt(
      'Mobile number',
      x: 20,
      y: 334,
      w: 372,
      wt: FontWeight.w600,
      lh: 18.2,
    ),
    DBox(
      x: 20,
      y: 360,
      w: 372,
      h: 55,
      r: 16,
      bg: Colors.white,
      border: Border.all(color: C.line),
    ),
    const DTxt(
      '+91',
      x: 37,
      y: 377,
      w: 38,
      s: 16,
      wt: FontWeight.w600,
      lh: 22.4,
    ),
    const DBox(x: 74.5, y: 377, w: 1, h: 21, bg: C.line),
    Positioned(
      left: 87,
      top: 366,
      width: 280,
      height: 44,
      child: TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        cursorColor: C.green,
        onSubmitted: (_) => _busy ? null : _sendCode(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: C.ink,
        ),
        decoration: const InputDecoration(
          isDense: true,
          counterText: '',
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          hintText: '10-digit number',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9AA69E),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ),
    DBox(
      x: 20,
      y: 432,
      w: 372,
      h: 58,
      r: 16,
      bg: const Color(0xFFE5F4E9),
      border: Border.all(color: const Color(0xFFC4E7CE)),
    ),
    const Positioned(
      left: 38,
      top: 450,
      child: Icon(Icons.verified_user_outlined, size: 20, color: C.green),
    ),
    const DTxt(
      'Real Firebase SMS verification. No OTP is compared or stored in the app.',
      x: 68,
      y: 445,
      w: 306,
      s: 13,
      wt: FontWeight.w500,
      lh: 18.2,
      c: C.green,
    ),
    if (_error != null)
      DTxt(
        _error!,
        x: 20,
        y: 500,
        w: 372,
        s: 13,
        wt: FontWeight.w600,
        lh: 18.2,
        c: C.danger,
        maxLines: 2,
      ),
    PrimaryButton(
      y: 548,
      label: _busy ? 'SENDING…' : 'SEND FIREBASE CODE',
      onTap: _busy ? null : () => _sendCode(),
    ),
    OutlineButton(
      y: 620,
      label: 'BACK TO LOGIN',
      onTap: () => Navigator.of(context).maybePop(),
    ),
    const DTxt(
      'Firebase sign-in is verified separately from the Spring Boot partner session.',
      x: 30,
      y: 700,
      w: 352,
      s: 12,
      wt: FontWeight.w500,
      lh: 17,
      c: C.muted,
      align: TextAlign.center,
    ),
  ];

  List<Widget> _codeStep() => [
    BackBar(
      title: 'Verify with Firebase',
      onBack: () => Navigator.of(context).maybePop(),
    ),
    const Backdrop(
      outlines: [
        Rect.fromLTWH(13.5, 453, 338, 71.1),
        Rect.fromLTWH(193.2, 62.2, 158.1, 462),
        Rect.fromLTWH(325.6, 453, 25.8, 71.1),
      ],
    ),
    const DSvg('assets/ui/halo-outer.svg', x: 126, y: 130, w: 160, h: 160),
    const DSvg('assets/ui/halo-inner.svg', x: 140, y: 144, w: 132, h: 132),
    const DSvg('assets/ui/halo-disc.svg', x: 146, y: 162, w: 120, h: 120),
    DBox(
      x: 170,
      y: 174,
      w: 72,
      h: 72,
      r: 24,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1F7945), Color(0xFF095334)],
      ),
      shadow: sh(12, 20, .22),
    ),
    const Positioned(
      left: 188,
      top: 192,
      child: Icon(Icons.smartphone, size: 36, color: Colors.white),
    ),
    DBox(
      x: 222,
      y: 164,
      w: 30,
      h: 30,
      r: 15,
      bg: C.yellow,
      border: Border.all(color: C.bg, width: 3),
      shadow: sh(4, 10, .18),
      child: const Icon(Icons.message_outlined, size: 15, color: C.green),
    ),
    const DTxt(
      'Enter the 6-digit code',
      x: 20,
      y: 294,
      w: 372,
      s: 28,
      wt: FontWeight.w700,
      lh: 36.4,
      align: TextAlign.center,
    ),
    Positioned(
      left: 20,
      top: 334,
      width: 372,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Sent to $_maskedPhone · '),
            const TextSpan(
              text: 'Edit',
              style: TextStyle(color: C.green, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: C.muted,
          height: 20.3 / 14.5,
        ),
      ),
    ),
    DTxt(
      'Edit',
      x: 216,
      y: 332,
      w: 50,
      s: 14.5,
      wt: FontWeight.w700,
      lh: 20.3,
      c: C.green,
      align: TextAlign.right,
      onTap: _busy ? null : _backToPhone,
    ),
    for (var i = 0; i < 6; i++)
      Positioned(
        left: xs[i],
        top: 381,
        width: 53,
        height: 61,
        child: TextField(
          controller: _otp[i],
          focusNode: _focus[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          cursorColor: C.green,
          onChanged: (v) {
            if (v.isNotEmpty && i < 5) _focus[i + 1].requestFocus();
            if (v.isEmpty && i > 0) _focus[i - 1].requestFocus();
            setState(() {});
          },
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: C.ink,
          ),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: C.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: C.green, width: 1.4),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
    _infoBanner(),
    DBox(
      x: 20,
      y: 524,
      w: 372,
      h: 64,
      r: 23,
      bg: Colors.white,
      border: Border.all(color: const Color(0xFFE9ECE5)),
      shadow: sh(8, 15, .04),
    ),
    const DSvg('assets/ui/clock.svg', x: 37, y: 548, w: 16, h: 16),
    const DTxt(
      'Need another code?',
      x: 64,
      y: 547,
      w: 200,
      s: 13.5,
      lh: 18.9,
      c: Color(0xFF222222),
    ),
    DTxt(
      _wait > 0 ? 'Resend in ${_wait}s' : 'Resend',
      x: 267,
      y: 547,
      w: 101,
      s: 13.5,
      wt: FontWeight.w700,
      lh: 18.9,
      c: _wait > 0 || _busy ? const Color(0xFF90A496) : C.green,
      align: TextAlign.right,
      onTap: _wait > 0 || _busy ? null : () => _sendCode(resend: true),
    ),
    DTxt(
      'Sign out of Firebase',
      x: 20,
      y: 706,
      w: 372,
      s: 13,
      wt: FontWeight.w600,
      lh: 18.2,
      c: C.muted,
      align: TextAlign.center,
      onTap: _busy ? null : _signOut,
    ),
    PrimaryButton(
      y: 808,
      label: _busy ? 'VERIFYING…' : 'VERIFY & SIGN IN',
      onTap: _busy ? null : _verifyCode,
    ),
  ];

  Widget _infoBanner() {
    final isError = _error != null;
    final message =
        _error ?? _status ?? 'Code sent by Firebase SMS · valid for 5 minutes';
    return DBox(
      x: 20,
      y: 459,
      w: 372,
      h: 48,
      r: 16,
      bg: isError ? const Color(0xFFFFECEC) : const Color(0xFFE5F4E9),
      border: Border.all(
        color: isError ? const Color(0xFFF3C2C2) : const Color(0xFFC4E7CE),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 14,
            child: Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 18,
              color: isError ? C.danger : C.green,
            ),
          ),
          Positioned(
            left: 44,
            top: 9,
            width: 312,
            height: 30,
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isError ? C.danger : C.green,
                height: 17.5 / 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _signedInStep() => [
    BackBar(
      title: 'Firebase verified',
      onBack: () => Navigator.of(context).maybePop(),
    ),
    const Backdrop(outlines: [Rect.fromLTWH(89.6, 80, 261.7, 444.2)]),
    const DSvg('assets/ui/halo-outer.svg', x: 126, y: 130, w: 160, h: 160),
    const DSvg('assets/ui/halo-inner.svg', x: 140, y: 144, w: 132, h: 132),
    const DSvg('assets/ui/halo-disc.svg', x: 146, y: 162, w: 120, h: 120),
    DBox(
      x: 170,
      y: 174,
      w: 72,
      h: 72,
      r: 24,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1F7945), Color(0xFF095334)],
      ),
      shadow: sh(12, 20, .22),
    ),
    const Positioned(
      left: 188,
      top: 192,
      child: Icon(Icons.check_circle_outline, size: 36, color: Colors.white),
    ),
    const DTxt(
      'Firebase sign-in complete',
      x: 20,
      y: 294,
      w: 372,
      s: 27,
      wt: FontWeight.w700,
      lh: 35.1,
      align: TextAlign.center,
    ),
    const DTxt(
      'Current user is available.',
      x: 20,
      y: 334,
      w: 372,
      s: 14.5,
      wt: FontWeight.w500,
      lh: 20.3,
      c: C.muted,
      align: TextAlign.center,
    ),
    DBox(
      x: 20,
      y: 420,
      w: 372,
      h: 70,
      r: 18,
      bg: const Color(0xFFE5F4E9),
      border: Border.all(color: const Color(0xFFC4E7CE)),
    ),
    const Positioned(
      left: 38,
      top: 442,
      child: Icon(Icons.lock_outline, size: 20, color: C.green),
    ),
    DTxt(
      _status ?? 'Firebase verification succeeded.',
      x: 68,
      y: 434,
      w: 306,
      s: 13,
      wt: FontWeight.w500,
      lh: 18.2,
      c: C.green,
      maxLines: 3,
    ),
    PrimaryButton(
      y: 548,
      label: _busy ? 'SIGNING OUT…' : 'SIGN OUT OF FIREBASE',
      onTap: _busy ? null : _signOut,
    ),
    OutlineButton(
      y: 620,
      label: 'DONE',
      onTap: () => Navigator.of(context).maybePop(),
    ),
    const DTxt(
      'Spring Boot JWT and partner session are unchanged.',
      x: 30,
      y: 700,
      w: 352,
      s: 12,
      wt: FontWeight.w500,
      lh: 17,
      c: C.muted,
      align: TextAlign.center,
    ),
  ];
}
