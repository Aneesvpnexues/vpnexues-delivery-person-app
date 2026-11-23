import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../state/app_state.dart';
import '../ui/design.dart';

class AddPayoutScreen extends StatefulWidget {
  const AddPayoutScreen({super.key, required this.state, required this.mode});

  final AppState state;
  final String mode;

  @override
  State<AddPayoutScreen> createState() => _AddPayoutScreenState();
}

class _AddPayoutScreenState extends State<AddPayoutScreen> {
  final _name = TextEditingController();
  final _acc = TextEditingController();
  final _acc2 = TextEditingController();
  final _ifsc = TextEditingController();
  final _bank = TextEditingController();
  final _upi = TextEditingController();
  String _type = 'savings';
  bool _primary = true;
  bool _backup = true;
  bool _busy = false;

  bool get _isUpi => widget.mode == 'upi';

  @override
  void initState() {
    super.initState();
    _name.text = widget.state.name;
    for (final c in [_acc, _acc2, _ifsc, _upi]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _acc, _acc2, _ifsc, _bank, _upi]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _accMatch => _acc.text.length >= 9 && _acc.text == _acc2.text;
  bool get _ifscOk => RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(_ifsc.text);
  bool get _upiOk => RegExp(r'^[\w.-]{2,}@[a-z]{2,}$', caseSensitive: false).hasMatch(_upi.text.trim());
  String get _handle => '@${_upi.text.split('@').length > 1 ? _upi.text.split('@')[1] : ''}';

  Future<void> _saveBank() async {
    if (_name.text.trim().length < 2) return _fail('Enter the account holder’s name');
    if (_acc.text.length < 9) return _fail('Account number must be 9–18 digits');
    if (_acc.text != _acc2.text) return _fail('The account numbers don’t match');
    if (!_ifscOk) return _fail('Enter a valid 11-character IFSC');
    setState(() {
      _busy = true;
    });
    try {
      await widget.state.api.post('/v1/payout-methods', body: {
        'type': 'bank_account',
        'accountHolderName': _name.text.trim(),
        'accountNumber': _acc.text,
        'confirmAccountNumber': _acc2.text,
        'ifsc': _ifsc.text,
        if (_bank.text.trim().isNotEmpty) 'bankName': _bank.text.trim(),
        'accountType': _type,
        'makePrimary': true,
      });
      if (!mounted) return;
      showToast(context, 'Bank account saved. Verification takes a few minutes.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _fail(e is ApiException ? e.message : 'Could not save the account');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveUpi() async {
    if (!_upiOk) return _fail('Enter a valid UPI ID, like name@okhdfcbank');
    setState(() {
      _busy = true;
    });
    try {
      await widget.state.api.post('/v1/payout-methods', body: {
        'type': 'upi',
        'upiVpa': _upi.text.trim(),
        'makePrimary': _primary,
        'keepBankAsBackup': _backup,
      });
      if (!mounted) return;
      showToast(context, 'UPI ID saved. Verification takes a few minutes.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _fail(e is ApiException ? e.message : 'Could not save the UPI ID');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fail(String message) {
    showToast(context, message);
  }

  void _switch(String mode) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => AddPayoutScreen(state: widget.state, mode: mode),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          BackBar(title: _isUpi ? 'Add payout method' : 'Add bank account'),
          DBox(x: 20, y: 105, w: 372, h: 56, r: 28, bg: Colors.white, border: Border.all(color: C.line)),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: _isUpi ? 206 : 24,
            top: 109,
            width: 182,
            height: 48,
            child: Container(
              decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(24), boxShadow: sh(6, 10, .12)),
            ),
          ),
          for (var i = 0; i < 2; i++)
            Positioned(
              left: 24 + i * 182.0,
              top: 109,
              width: 182,
              height: 48,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _switch(i == 0 ? 'bank' : 'upi'),
                child: Center(
                  child: Text(
                    i == 0 ? 'Bank account' : 'UPI ID',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: (_isUpi ? i == 1 : i == 0) ? Colors.white : C.muted,
                    ),
                  ),
                ),
              ),
            ),

          if (_isUpi) ..._upiBody() else ..._bankBody(),

        ],
      ),
    );
  }

  List<Widget> _bankBody() {
    const top = 262.0;
    return [
      DTxt('Where should we send your\nearnings?', x: 20, y: 176, w: 382, s: 24, wt: FontWeight.w700, lh: 30),
      const DTxt('This becomes your primary payout account.', x: 20, y: 240, s: 13.5, wt: FontWeight.w500, lh: 18.9, c: C.muted),
      Field(y: top, label: 'Account holder name', controller: _name, placeholder: 'As on your bank passbook'),
      const DTxt('Must match the name on your Aadhaar.', x: 20, y: top + 81, s: 12, wt: FontWeight.w500, lh: 16.8, c: C.muted),
      Field(
        y: top + 113,
        label: 'Account number',
        controller: _acc,
        obscure: true,
        keyboard: TextInputType.number,
        placeholder: '9–18 digits',
        suffix: const Icon(LucideIcons.lock, size: 19, color: C.muted),
      ),
      Field(
        y: top + 198,
        label: 'Re-enter account number',
        controller: _acc2,
        keyboard: TextInputType.number,
        ok: _accMatch,
        suffix: _accMatch ? const Icon(LucideIcons.check, size: 19, color: C.green) : null,
      ),
      Field(
        y: top + 283,
        label: 'IFSC code',
        controller: _ifsc,
        placeholder: 'e.g. HDFC0001234',
        ok: _ifscOk,
        suffix: _ifscOk ? Pill(label: 'Valid', bg: pillOk.bg, fg: pillOk.fg, dot: pillOk.fg) : null,
      ),
      DBox(x: 20, y: top + 368, w: 372, h: 73, r: 22, bg: const Color(0xFFEEF5DB), border: Border.all(color: const Color(0xFFDDEBC3))),
      Positioned(
        left: 35,
        top: top + 383,
        width: 44,
        height: 44,
        child: const Center(child: Icon(LucideIcons.landmark, size: 20, color: C.green)),
      ),
      Positioned(
        left: 90,
        top: top + 384,
        width: 280,
        height: 22,
        child: TextField(
          controller: _bank,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink),
          decoration: const InputDecoration(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'Bank name (e.g. HDFC Bank)',
            hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.muted),
          ),
        ),
      ),
      DTxt(
        _ifscOk ? 'Branch code ${_ifsc.text.substring(5)}' : 'Enter the IFSC from your cheque book',
        x: 90,
        y: top + 408,
        s: 12,
        wt: FontWeight.w500,
        lh: 16.8,
        c: C.muted,
      ),
      const DTxt('Account type', x: 20, y: top + 451, s: 13, wt: FontWeight.w600, lh: 18.2),
      for (var i = 0; i < 2; i++)
        Positioned(
          left: 20 + i * 100.0,
          top: top + 476,
          child: GestureDetector(
            onTap: () => setState(() => _type = i == 0 ? 'savings' : 'current'),
            child: IntrinsicWidth(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _type == (i == 0 ? 'savings' : 'current') ? C.green : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: _type == (i == 0 ? 'savings' : 'current') ? null : Border.all(color: C.line),
                ),
                child: Text(
                  i == 0 ? 'Savings' : 'Current',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _type == (i == 0 ? 'savings' : 'current') ? Colors.white : C.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      Btn(y: 792, label: _busy ? 'SAVING…' : 'SAVE BANK ACCOUNT', onTap: _busy ? null : _saveBank),
    ];
  }

  List<Widget> _upiBody() {
    return [
      DBox(x: 20, y: 178, w: 372, h: 90, r: 24, bg: const Color(0xFFEEF5DB), border: Border.all(color: const Color(0xFFDDEBC3))),
      Positioned(
        left: 37,
        top: 197,
        width: 52,
        height: 52,
        child: const Center(child: Icon(LucideIcons.zap, size: 24, color: C.green)),
      ),
      const DTxt('Get paid to UPI', x: 102, y: 195, s: 16, wt: FontWeight.w700, lh: 22.4),
      const DTxt('Instant payouts land in seconds, any day of the week.',
          x: 102, y: 219, w: 280, s: 12, lh: 18, c: Color(0xFF333333)),
      Field(
        y: 286,
        label: 'UPI ID',
        controller: _upi,
        icon: LucideIcons.atSign,
        placeholder: 'yourname@okhdfcbank',
        suffix: _upiOk ? Pill(label: 'Looks right', bg: pillOk.bg, fg: pillOk.fg, dot: pillOk.fg) : null,
      ),
      const DTxt('We check the name on this UPI ID against your Aadhaar after you save.',
          x: 20, y: 381, w: 372, s: 12, lh: 16.8, c: C.muted),
      const DTxt('Common handles', x: 20, y: 414, s: 13, wt: FontWeight.w700, lh: 18.2),
      Positioned(
        left: 20,
        top: 431,
        width: 360,
        child: Wrap(
          spacing: 9,
          runSpacing: 8,
          children: [
            for (final h in ['@okhdfcbank', '@ybl', '@oksbi', '@paytm'])
              GestureDetector(
                onTap: () => _upi.text = '${_upi.text.split('@').first.isEmpty ? 'name' : _upi.text.split('@').first}$h',
                child: IntrinsicWidth(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _handle == h ? C.green : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: _handle == h ? null : Border.all(color: C.line),
                    ),
                    child: Text(
                      h,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _handle == h ? Colors.white : C.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      DBox(x: 20, y: 536, w: 372, h: 139, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
      for (var i = 0; i < 2; i++) ...[
        if (i > 0) DBox(x: 36, y: 605, w: 339, h: 1, bg: C.tint5),
        DTxt(
          i == 0 ? 'Set as primary payout method' : 'Keep my bank account as backup',
          x: 36,
          y: 553 + i * 66,
          w: 280,
          s: 15,
          wt: FontWeight.w700,
          lh: 21,
        ),
        DTxt(
          i == 0 ? 'Weekly and instant payouts go here' : 'Used if a UPI payout fails',
          x: 36,
          y: 576 + i * 66,
          s: 12,
          lh: 16.8,
          c: C.muted,
        ),
        ToggleSwitch(
          x: 326,
          y: 557 + i * 66,
          on: i == 0 ? _primary : _backup,
          onChanged: (v) => setState(() {
            if (i == 0) {
              _primary = v;
            } else {
              _backup = v;
            }
          }),
          onColor: C.green,
        ),
      ],
      DBox(x: 20, y: 692, w: 372, h: 87, r: 22, bg: const Color(0xFFFFF5D9), border: Border.all(color: const Color(0xFFF0DC8C))),
      const Positioned(left: 36, top: 708, child: Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFF795109))),
      const DTxt(
        'For your safety, payouts only go to verified accounts. We’ll notify you when this UPI ID is verified.',
        x: 64,
        y: 704,
        w: 315,
        s: 13.5,
        lh: 20,
        c: Color(0xFF795109),
      ),
      Btn(y: 782, label: _busy ? 'SAVING…' : 'SAVE UPI ID', onTap: _busy ? null : _saveUpi),
    ];
  }
}
