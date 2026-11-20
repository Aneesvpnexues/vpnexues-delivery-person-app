import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'set_password_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.state,
    required this.phone,
    required this.purpose,
    this.devCode,
    this.onResend,
  });

  final AppState state;
  final String phone;
  final String purpose;
  final String? devCode;
  final Future<Map<String, dynamic>> Function()? onResend;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const xs = [20.0, 83.8, 147.6, 211.4, 275.2, 339.0];

  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  bool _busy = false;
  int _wait = 30;
  Timer? _timer;

  bool get _isSignup => widget.purpose == 'signup';

  @override
  void initState() {
    super.initState();
    final dev = widget.devCode ?? '';
    for (var i = 0; i < 6 && i < dev.length; i++) {
      _controllers[i].text = dev[i];
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _wait = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _wait -= 1;
        if (_wait <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code)) {
      showToast(context, 'Enter all 6 digits');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isSignup) {
        await widget.state.signupVerify(widget.phone, _code);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SetPasswordScreen(state: widget.state),
        ));
      } else {
        await widget.state.loginOtpVerify(widget.phone, _code);
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      showToast(context, e is ApiException ? e.message : 'Could not verify the code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_wait > 0 || widget.onResend == null) return;
    try {
      final res = await widget.onResend!();
      if (!mounted) return;
      final dev = res['devCode']?.toString() ?? '';
      for (var i = 0; i < 6; i++) {
        _controllers[i].text = i < dev.length ? dev[i] : '';
      }
      _startTimer();
      showToast(context, 'A new code is on its way');
    } catch (e) {
      if (!mounted) return;
      showToast(context, e is ApiException ? e.message : 'Could not resend the code');
    }
  }

  String get _masked {
    final digits = widget.phone.replaceAll(RegExp(r'\D'), '');
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (last10.length < 10) return '+91 $last10';
    return '+91 ${last10.substring(0, 2)}••• ••${last10.substring(8)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const Backdrop(outlines: [
              Rect.fromLTWH(13.5, 453, 338, 71.1),
              Rect.fromLTWH(193.2, 62.2, 158.1, 462),
              Rect.fromLTWH(325.6, 453, 25.8, 71.1),
            ]),
            BackBar(
              title: 'Verify mobile',
              step: _isSignup ? 2 : null,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            if (_isSignup)
              for (var i = 0; i < 5; i++)
                DBox(x: 20 + i * 76.0, y: 104, w: 70, h: 6, r: 3, bg: i == 0 ? C.green : (i == 1 ? C.lime : C.line)),

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
            const Positioned(left: 188, top: 192, child: Icon(LucideIcons.smartphone, size: 36, color: Colors.white)),
            DBox(
              x: 222,
              y: 164,
              w: 30,
              h: 30,
              r: 15,
              bg: C.yellow,
              border: Border.all(color: C.bg, width: 3),
              shadow: sh(4, 10, .18),
              child: const Icon(LucideIcons.messageSquare, size: 15, color: C.green),
            ),

            const DTxt('Enter the 6-digit code', x: 20, y: 294, w: 372, s: 28, wt: FontWeight.w700, lh: 36.4, align: TextAlign.center),
            Positioned(
              left: 20,
              top: 334,
              width: 372,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'Sent to $_masked · '),
                  TextSpan(
                    text: 'Edit',
                    style: const TextStyle(color: C.green, fontWeight: FontWeight.w700),
                    recognizer: null,
                  ),
                ]),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w500, color: C.muted, height: 20.3 / 14.5),
              ),
            ),

            for (var i = 0; i < 6; i++)
              Positioned(
                left: xs[i],
                top: 381,
                width: 53,
                height: 61,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focus[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  cursorColor: C.green,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: C.ink),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _focus[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _focus[i - 1].requestFocus();
                    setState(() {});
                  },
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

            DBox(
              x: 20,
              y: 459,
              w: 372,
              h: 48,
              r: 16,
              bg: const Color(0xFFE5F4E9),
              border: Border.all(color: const Color(0xFFC4E7CE)),
            ),
            const DSvg('assets/ui/check-green.svg', x: 36, y: 475, w: 16, h: 16),
            DTxt(
              widget.devCode != null
                  ? 'Trial code: ${widget.devCode} · filled in for you'
                  : 'Code sent by SMS · valid for 5 minutes',
              x: 64,
              y: 473,
              w: 314,
              s: 13.5,
              wt: FontWeight.w500,
              lh: 18.9,
              c: C.green,
            ),

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
            const DTxt('Need another code?', x: 64, y: 547, w: 200, s: 13.5, lh: 18.9, c: Color(0xFF222222)),
            DTxt(
              _wait > 0 ? 'Resend in ${_wait}s' : 'Resend',
              x: 267,
              y: 547,
              w: 101,
              s: 13.5,
              wt: FontWeight.w700,
              lh: 18.9,
              c: _wait > 0 ? const Color(0xFF90A496) : C.green,
              align: TextAlign.right,
              onTap: _resend,
            ),

            DTxt(
              "Didn't get it? Get the code on a call",
              x: 20,
              y: 604,
              w: 372,
              s: 13.5,
              wt: FontWeight.w500,
              lh: 18.9,
              c: C.muted,
              align: TextAlign.center,
              onTap: () => showToast(context, 'Call-based codes are coming soon. Use Resend for now.'),
            ),

            PrimaryButton(
              y: 808,
              label: _busy ? 'VERIFYING…' : (_isSignup ? 'VERIFY & CONTINUE' : 'VERIFY & LOG IN'),
              onTap: _busy ? null : _verify,
            ),
          ],
        ),
      ),
    );
  }
}
