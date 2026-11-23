import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api_client.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'otp_screen.dart';
import 'reset_password_screen.dart';
import 'signup_screen.dart';
import 'support_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.state});

  final AppState state;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  String _tab = 'password';
  bool _show = false;
  bool _keep = true;
  bool _busy = false;

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _mobile.text.replaceAll(RegExp(r'\D'), '');
    if (phone.length < 10) {
      showToast(context, 'Enter your 10-digit mobile number');
      return;
    }
    if (_tab == 'password' && _password.text.isEmpty) {
      showToast(context, 'Enter your password');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_tab == 'password') {
        await widget.state.login(phone, _password.text);
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        final res = await widget.state.loginOtpStart(phone);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OtpScreen(
            state: widget.state,
            phone: phone,
            purpose: 'login',
            devCode: res['devCode']?.toString(),
            onResend: () => widget.state.loginOtpStart(phone),
          ),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      showToast(context, e is ApiException ? e.message : 'Could not log you in');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const Backdrop(outlines: [
              Rect.fromLTWH(89.6, 80, 261.7, 444.2),
              Rect.fromLTWH(128.8, 470.9, 222.5, 53.3),
              Rect.fromLTWH(239.1, 470.9, 112.2, 53.3),
              Rect.fromLTWH(299.9, 51.1, 51.4, 473.1),
            ]),
            BackBar(
              onBack: () => Navigator.of(context).maybePop(),
              right: DTxt(
                'Need help?',
                x: 286,
                y: 57,
                w: 106,
                s: 12,
                wt: FontWeight.w700,
                lh: 16.8,
                c: C.green,
                align: TextAlign.right,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SupportScreen(state: widget.state)),
                ),
              ),
            ),
            const Logo(x: 20, y: 110, s: 56),
            const DTxt('VP NEXUES PARTNER', x: 90, y: 122, w: 280, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: .9),
            const DTxt('Delivery partner app', x: 90, y: 137, w: 280, s: 12, wt: FontWeight.w500, lh: 16.8, c: C.muted),
            const DTxt('Welcome back.', x: 20, y: 181, w: 372, s: 29, wt: FontWeight.w700, lh: 40.6),
            const DTxt("Log in to see today's deliveries and payouts.", x: 20, y: 224, w: 380, s: 15, wt: FontWeight.w500, lh: 21, c: C.muted),

            // segmented control
            DBox(
              x: 20,
              y: 262,
              w: 372,
              h: 56,
              r: 28,
              bg: Colors.white,
              border: Border.all(color: C.line),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: _tab == 'password' ? 24 : 206,
              top: 266,
              width: 182,
              height: 48,
              child: Container(
                decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(24), boxShadow: sh(6, 10, .12)),
              ),
            ),
            Positioned(
              left: 24,
              top: 266,
              width: 182,
              height: 48,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = 'password'),
                child: Center(
                  child: Text('Password',
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: _tab == 'password' ? Colors.white : C.muted)),
                ),
              ),
            ),
            Positioned(
              left: 206,
              top: 266,
              width: 182,
              height: 48,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = 'otp'),
                child: Center(
                  child: Text('One-time code',
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: _tab == 'otp' ? Colors.white : C.muted)),
                ),
              ),
            ),

            const DTxt('Mobile number', x: 20, y: 334, w: 372, wt: FontWeight.w600, lh: 18.2),
            DBox(
              x: 20,
              y: 360,
              w: 372,
              h: 55,
              r: 16,
              bg: Colors.white,
              border: Border.all(color: C.line),
            ),
            const DTxt('+91', x: 37, y: 377, w: 38, s: 16, wt: FontWeight.w600, lh: 22.4),
            const DBox(x: 74.5, y: 377, w: 1, h: 21, bg: C.line),
            Positioned(
              left: 87,
              top: 366,
              width: 280,
              height: 44,
              child: TextField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                cursorColor: C.green,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink),
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
                  hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9AA69E)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            if (_tab == 'password') ...[
              const DTxt('Password', x: 20, y: 432, w: 372, wt: FontWeight.w600, lh: 18.2),
              DTxt(
                'Forgot password?',
                x: 252,
                y: 432,
                w: 140,
                wt: FontWeight.w700,
                lh: 18.2,
                c: C.green,
                align: TextAlign.right,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ResetPasswordScreen(state: widget.state)),
                ),
              ),
              DBox(
                x: 20,
                y: 458,
                w: 372,
                h: 55,
                r: 16,
                bg: Colors.white,
                border: Border.all(color: C.green, width: 1.5),
                shadow: [BoxShadow(color: C.green.withValues(alpha: .08), blurRadius: 0, spreadRadius: 4)],
              ),
              const DSvg('assets/ui/lock.svg', x: 38, y: 476, w: 18, h: 18),
              Positioned(
                left: 67,
                top: 466,
                width: 250,
                height: 42,
                child: TextField(
                  controller: _password,
                  obscureText: !_show,
                  cursorColor: C.green,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: 'Your password',
                    hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9AA69E)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              DBox(
                x: 334,
                y: 465,
                w: 40,
                h: 40,
                onTap: () => setState(() => _show = !_show),
                child: Stack(
                  children: [
                    const DSvg('assets/ui/eye-button.svg', x: 0, y: 0, w: 40, h: 40),
                    if (_show)
                      const DSvg('assets/ui/eye.svg', x: 12, y: 12, w: 16, h: 16)
                    else
                      const DSvg('assets/ui/eye-slash.svg', x: 11, y: 11, w: 18, h: 18),
                  ],
                ),
              ),
            ] else
              const DTxt("We'll text a 6-digit one-time code to this number.", x: 20, y: 432, w: 372, s: 13, wt: FontWeight.w500, lh: 19.5, c: C.muted),

            DBox(
              x: 20,
              y: 529,
              w: 22,
              h: 22,
              r: 4,
              bg: _keep ? C.green : Colors.white,
              border: _keep ? null : Border.all(color: C.line, width: 1.5),
              onTap: () => setState(() => _keep = !_keep),
              child: _keep
                  ? Padding(
                      padding: const EdgeInsets.only(left: 2, top: 1),
                      child: SvgPicture.asset('assets/ui/check2.svg', width: 20, height: 20),
                    )
                  : null,
            ),
            const DTxt('Keep me logged in on this phone', x: 54, y: 530, w: 338, wt: FontWeight.w500, lh: 18.2, c: C.muted),

            PrimaryButton(
              y: 687,
              label: _busy ? 'PLEASE WAIT…' : (_tab == 'password' ? 'LOG IN' : 'SEND CODE'),
              onTap: _busy ? null : _submit,
            ),

            const DSvg('assets/ui/fingerprint.svg', x: 113, y: 769, w: 17, h: 17),
            DTxt(
              'Log in with fingerprint',
              x: 137,
              y: 767,
              w: 240,
              s: 15,
              wt: FontWeight.w700,
              lh: 21,
              c: C.green,
              onTap: () => showToast(context, 'Fingerprint login arrives in a later version. Use your password for now.'),
            ),

            const DBox(x: 20, y: 820, w: 122, h: 1, bg: C.tint5),
            const DBox(x: 270, y: 820, w: 122, h: 1, bg: C.tint5),
            const DTxt('New to VP Nexues?', x: 144, y: 812, w: 125, s: 12, wt: FontWeight.w500, lh: 16.8, c: C.muted, align: TextAlign.center),
            OutlineButton(
              y: 840,
              label: 'CREATE A PARTNER ACCOUNT',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SignupScreen(state: widget.state)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
