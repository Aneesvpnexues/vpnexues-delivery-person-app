import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../state/app_state.dart';
import '../ui/design.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _devCode;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final phone = _phone.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length != 10) {
      showToast(context, 'Enter your 10-digit mobile number');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await widget.state.resetStart(phone);
      if (!mounted) return;
      final dev = res['devCode']?.toString();
      setState(() {
        _sent = true;
        _devCode = dev;
        if (dev != null) _code.text = dev;
      });
    } catch (e) {
      if (!mounted) return;
      showToast(context, e is ApiException ? e.message : 'Could not send the code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    final phone = _phone.text.trim();
    final code = _code.text.trim();
    if (code.length != 6) {
      showToast(context, 'Enter the 6-digit code');
      return;
    }
    final pw = _password.text;
    if (pw.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(pw) ||
        !RegExp(r'\d').hasMatch(pw) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) {
      showToast(context, 'Use 8+ characters with an uppercase letter, a number and a symbol');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.state.resetVerify(phone, code, pw);
      if (!mounted) return;
      showToast(context, 'Password updated. Sign in with your new password.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showToast(context, e is ApiException ? e.message : 'Could not reset the password');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const Backdrop(),
            BackBar(title: 'Reset password', onBack: () => Navigator.of(context).maybePop()),
            const DBox(x: 20, y: 130, w: 56, h: 56, r: 14, bg: Color(0xFFEEF5DB)),
            const Positioned(left: 37, top: 147, child: Icon(LucideIcons.shieldCheck, size: 22, color: C.green)),
            const DTxt('Forgot your password?', x: 90, y: 135, w: 302, s: 20, wt: FontWeight.w700, lh: 28),
            DTxt(
              _sent ? 'Enter the code we sent and choose a new password.' : 'We will text you a 6-digit code to reset it.',
              x: 90,
              y: 162,
              w: 307,
              s: 13,
              wt: FontWeight.w500,
              lh: 18.2,
              c: C.muted,
            ),

            Field(
              y: 210,
              label: 'Mobile number',
              controller: _phone,
              icon: LucideIcons.smartphone,
              placeholder: '10-digit number',
              keyboard: TextInputType.phone,
              readOnly: _sent,
            ),

            if (_sent) ...[
              Field(
                y: 306,
                label: 'Verification code',
                controller: _code,
                icon: LucideIcons.keyRound,
                placeholder: '6-digit code',
                keyboard: TextInputType.number,
              ),
              Field(
                y: 402,
                label: 'New password',
                controller: _password,
                icon: LucideIcons.lock,
                placeholder: 'New password',
                obscure: true,
              ),
              if (_devCode != null) ...[
                DBox(
                  x: 20,
                  y: 492,
                  w: 372,
                  h: 48,
                  r: 16,
                  bg: const Color(0xFFE5F4E9),
                  border: Border.all(color: const Color(0xFFC4E7CE)),
                ),
                const DSvg('assets/ui/check-green.svg', x: 36, y: 508, w: 16, h: 16),
                DTxt('Trial code: $_devCode', x: 64, y: 506, w: 314, s: 13.5, wt: FontWeight.w500, lh: 18.9, c: C.green),
              ],
            ],

            PrimaryButton(
              y: 839,
              label: _loading ? 'PLEASE WAIT…' : (_sent ? 'UPDATE PASSWORD' : 'SEND CODE'),
              onTap: _loading ? null : (_sent ? _reset : _send),
            ),
            if (_sent)
              DTxt(
                'Use a different number',
                x: 20,
                y: 795,
                w: 372,
                s: 13,
                wt: FontWeight.w700,
                c: C.green,
                align: TextAlign.center,
                onTap: _loading
                    ? null
                    : () => setState(() {
                          _sent = false;
                          _devCode = null;
                          _code.clear();
                        }),
              ),
          ],
        ),
      ),
    );
  }
}
