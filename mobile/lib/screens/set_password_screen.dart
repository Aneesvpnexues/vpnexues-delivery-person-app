import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../state/app_state.dart';
import '../ui/design.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key, required this.state, this.fromSettings = false});

  final AppState state;
  final bool fromSettings;

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _finger = true;
  bool _busy = false;

  bool get _longEnough => _password.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_password.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_password.text);
  bool get _hasSymbol => RegExp(r'[^A-Za-z0-9]').hasMatch(_password.text);
  int get _score => [_longEnough, _hasUpper, _hasDigit, _hasSymbol].where((x) => x).length;
  bool get _match => _confirm.text.isNotEmpty && _password.text == _confirm.text;
  String get _strength => ['Weak', 'Weak', 'Fair', 'Good', 'Strong'][_score];

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_score < 4) {
      showToast(context, 'Your password needs all four items in the checklist');
      return;
    }
    if (!_match) {
      showToast(context, "The two passwords don't match");
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.state.setPassword(_password.text);
      try {
        await widget.state.saveSettings({'fingerprintUnlock': _finger});
      } catch (_) {}
      if (!mounted) return;
      showToast(context, 'Password saved');
      if (widget.fromSettings) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      showToast(context, e is ApiException ? e.message : 'Could not save your password');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _ruleRow(String label, bool ok, double y) {
    return Stack(
      children: [
        DSvg('assets/ui/req-ok.svg', x: 36, y: y, w: 22, h: 22, opacity: ok ? 1 : .35),
        if (ok) DSvg('assets/ui/req-check.svg', x: 41, y: y + 5, w: 12, h: 12),
        DTxt(label, x: 69, y: y + 2, w: 300, s: 13.5, wt: FontWeight.w500, lh: 18.9),
      ],
    );
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
              title: widget.fromSettings ? 'Change password' : 'Secure your account',
              step: widget.fromSettings ? null : 3,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            if (!widget.fromSettings)
              for (var i = 0; i < 5; i++)
                DBox(x: 20 + i * 76.0, y: 104, w: 70, h: 6, r: 3, bg: i < 2 ? C.green : (i == 2 ? C.lime : C.line)),

            const DBox(x: 20, y: 130, w: 56, h: 56, r: 14, bg: Color(0xFFEEF5DB)),
            const DSvg('assets/ui/shield.svg', x: 37.5, y: 147.5, w: 21, h: 21),
            const DTxt('Create a password', x: 90, y: 135, w: 302, s: 20, wt: FontWeight.w700, lh: 28),
            const DTxt('You’ll use it with your mobile number to log in.', x: 90, y: 162, w: 307, s: 13, wt: FontWeight.w500, lh: 18.2, c: C.muted),

            const DTxt('New password', x: 20, y: 202, w: 372, wt: FontWeight.w600, lh: 18.2),
            DBox(
              x: 20,
              y: 228,
              w: 372,
              h: 55,
              r: 16,
              bg: Colors.white,
              border: Border.all(color: C.green, width: 1.5),
              shadow: [BoxShadow(color: C.green.withValues(alpha: .08), spreadRadius: 4)],
            ),
            const DSvg('assets/ui/lock.svg', x: 38, y: 246, w: 18, h: 18),
            Positioned(
              left: 67,
              top: 236,
              width: 250,
              height: 42,
              child: TextField(
                controller: _password,
                obscureText: !_show,
                cursorColor: C.green,
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
                  hintText: 'Create a password',
                  hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9AA69E)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            DBox(
              x: 334,
              y: 235,
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

            for (var i = 0; i < 4; i++)
              DBox(
                x: 20 + i * 94.5,
                y: 295,
                w: 89,
                h: 8,
                r: 4,
                bg: i < _score ? null : C.line,
                gradient: i < _score ? kGrad : null,
              ),
            Positioned(
              left: 20,
              top: 312,
              width: 372,
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Strength: '),
                  TextSpan(text: _strength, style: const TextStyle(color: C.accent, fontWeight: FontWeight.w700)),
                ]),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: C.muted, height: 16.8 / 12),
              ),
            ),

            DBox(
              x: 20,
              y: 345,
              w: 372,
              h: 151,
              r: 24,
              bg: Colors.white,
              border: Border.all(color: const Color(0xFFE9ECE5)),
              shadow: sh(10, 18, .04),
            ),
            _ruleRow('At least 8 characters', _longEnough, 361),
            _ruleRow('One uppercase letter', _hasUpper, 393),
            _ruleRow('One number', _hasDigit, 425),
            _ruleRow('One symbol (@ # ! %)', _hasSymbol, 457),

            const DTxt('Confirm password', x: 20, y: 512, w: 372, wt: FontWeight.w600, lh: 18.2),
            DBox(
              x: 20,
              y: 538,
              w: 372,
              h: 55,
              r: 16,
              bg: Colors.white,
              border: Border.all(color: _match ? const Color(0xFF81C895) : C.line),
            ),
            const DSvg('assets/ui/lock.svg', x: 38, y: 556, w: 18, h: 18),
            Positioned(
              left: 67,
              top: 546,
              width: 280,
              height: 42,
              child: TextField(
                controller: _confirm,
                obscureText: !_show,
                cursorColor: C.green,
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
                  hintText: 'Re-enter password',
                  hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9AA69E)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_match) const DSvg('assets/ui/match-check.svg', x: 358, y: 555, w: 19, h: 19),
            if (_confirm.text.isNotEmpty)
              DTxt(
                _match ? 'Passwords match' : 'Passwords do not match',
                x: 20,
                y: 602,
                w: 372,
                s: 12,
                wt: FontWeight.w700,
                lh: 16.8,
                c: _match ? C.accent : const Color(0xFFB3261E),
              ),

            const DBox(
              x: 20,
              y: 635,
              w: 372,
              h: 66,
              r: 23,
              bg: Color(0xFFEEF5DB),
              border: Border.fromBorderSide(BorderSide(color: Color(0xFFDFEBC3))),
            ),
            const DTxt('Unlock with fingerprint', x: 36, y: 649, w: 280, s: 15, wt: FontWeight.w700, lh: 21),
            const DTxt('Faster log in on this phone', x: 36, y: 670, w: 280, s: 12, wt: FontWeight.w500, lh: 16.8, c: C.muted),
            ToggleSwitch(x: 325, y: 653, on: _finger, onChanged: (v) => setState(() => _finger = v)),

            PrimaryButton(
              y: 839,
              label: _busy ? 'SAVING…' : (widget.fromSettings ? 'SAVE PASSWORD' : 'SAVE & CONTINUE'),
              onTap: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
