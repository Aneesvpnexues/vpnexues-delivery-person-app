import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api_client.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _ref = TextEditingController();
  int? _cityId;
  bool _pickCity = false;
  String _vehicle = 'Motorbike';
  bool _agree = true;
  bool _busy = false;

  static const vehicles = [
    ('Motorbike', 'motorbike', 20.0, 89.0),
    ('Scooter', 'scooter', 116.8, 70.3),
    ('Electric scooter', 'electric_scooter', 194.9, 119.3),
    ('Bicycle', 'bicycle', 326.1, 65.9),
  ];

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _ref.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final name = _name.text.trim();
    final phone = _mobile.text.replaceAll(RegExp(r'\D'), '');
    if (name.length < 2) {
      showToast(context, 'Enter your full name as on Aadhaar');
      return;
    }
    if (phone.length < 10) {
      showToast(context, 'Enter your 10-digit mobile number');
      return;
    }
    if (_cityId == null) {
      showToast(context, 'Choose your city');
      return;
    }
    if (!_agree) {
      showToast(context, 'Please accept the partner terms to continue');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await widget.state.signupStart(
        fullName: name,
        phone: phone,
        cityId: _cityId!,
        vehicleType: vehicles.firstWhere((v) => v.$1 == _vehicle).$2,
        referralCode: _ref.text,
      );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpScreen(
          state: widget.state,
          phone: phone,
          purpose: 'signup',
          devCode: res['devCode']?.toString(),
          onResend: () => widget.state.signupStart(
            fullName: name,
            phone: phone,
            cityId: _cityId!,
            vehicleType: vehicles.firstWhere((v) => v.$1 == _vehicle).$2,
            referralCode: _ref.text,
          ),
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      showToast(context, e is ApiException ? e.message : 'Could not send the code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _input({
    required double left,
    required double top,
    required double width,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    int? maxLength,
    String? iconAsset,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: 44,
      child: Row(
        children: [
          if (iconAsset != null) ...[SvgPicture.asset(iconAsset, width: 18, height: 18), const SizedBox(width: 11)],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              maxLength: maxLength,
              cursorColor: C.green,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9AA69E)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cities = widget.state.cities;
    Map<String, dynamic>? city;
    for (final c in cities) {
      if (c['id'] == _cityId) city = c;
    }

    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const Backdrop(),
            BackBar(title: 'Create account', step: 1, onBack: () => Navigator.of(context).maybePop()),
            for (var i = 0; i < 5; i++)
              DBox(x: 20 + i * 76.0, y: 104, w: 70, h: 6, r: 3, bg: i == 0 ? C.lime : C.line),
            const DTxt('JOIN THE HARVEST CREW', x: 20, y: 129, w: 372, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
            Positioned(
              left: 20,
              top: 149,
              width: 380,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Ride with us. ',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 29, fontWeight: FontWeight.w700, height: 34.8 / 29, color: C.ink)),
                  const GradientText(
                    'Earn fresh.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 29, fontWeight: FontWeight.w700, height: 34.8 / 29),
                    gradient: LinearGradient(colors: [Color(0xFF247947), Color(0xFF8A7600)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                ],
              ),
            ),
            const DTxt('Takes about 5 minutes. Keep your Aadhaar, driving licence\nand bank details ready.',
                x: 20, y: 191, w: 385, s: 13.2, wt: FontWeight.w500, lh: 19.8, c: C.muted),

            const DTxt('Full name (as on Aadhaar)', x: 20, y: 246, w: 372, wt: FontWeight.w600, lh: 18.2),
            DBox(x: 20, y: 272, w: 372, h: 55, r: 16, bg: Colors.white, border: Border.all(color: C.line)),
            _input(
              left: 67,
              top: 278,
              width: 320,
              controller: _name,
              hint: 'As printed on your Aadhaar',
              iconAsset: 'assets/ui/user.svg',
            ),

            const DTxt('Mobile number', x: 20, y: 343, w: 372, wt: FontWeight.w600, lh: 18.2),
            DBox(x: 20, y: 369, w: 372, h: 55, r: 16, bg: Colors.white, border: Border.all(color: C.green, width: 1.5)),
            const DTxt('+91', x: 37, y: 386, w: 38, s: 16, wt: FontWeight.w600, lh: 22.4),
            const DBox(x: 74.5, y: 386, w: 1, h: 21, bg: C.line),
            _input(left: 87, top: 375, width: 260, controller: _mobile, hint: '10-digit number', keyboard: TextInputType.phone, maxLength: 11),
            const DTxt('We will send a 6-digit OTP to this number.', x: 20, y: 433, w: 372, s: 12, wt: FontWeight.w500, lh: 16.8, c: C.muted),

            const DTxt('City', x: 20, y: 466, w: 372, wt: FontWeight.w600, lh: 18.2),
            DBox(
              x: 20,
              y: 492,
              w: 372,
              h: 55,
              r: 16,
              bg: Colors.white,
              border: Border.all(color: C.line),
              onTap: () => setState(() => _pickCity = !_pickCity),
            ),
            const DSvg('assets/ui/pin.svg', x: 38, y: 510, w: 18, h: 18),
            DTxt(
              city == null ? (cities.isEmpty ? 'Loading cities…' : 'Choose your city') : city['name'].toString(),
              x: 67,
              y: 510,
              w: 300,
              s: 16,
              wt: FontWeight.w600,
              lh: 22,
              c: city == null ? const Color(0xFF9AA69E) : C.ink,
              onTap: () => setState(() => _pickCity = !_pickCity),
            ),
            const DSvg('assets/ui/down.svg', x: 358, y: 509, w: 19, h: 19),
            if (_pickCity)
              Positioned(
                left: 20,
                top: 551,
                width: 372,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.line),
                    boxShadow: sh(16, 30, .14),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < cities.length; i++)
                        InkWell(
                          onTap: () => setState(() {
                            _cityId = cities[i]['id'] as int;
                            _pickCity = false;
                          }),
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: cities[i]['id'] == _cityId ? const Color(0xFFEEF5DB) : Colors.white,
                              border: i == 0 ? null : const Border(top: BorderSide(color: C.tint5)),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: cities[i]['name'].toString()),
                                TextSpan(
                                  text: '  · ${cities[i]['state']}',
                                  style: const TextStyle(color: C.muted, fontWeight: FontWeight.w400, fontSize: 13),
                                ),
                              ]),
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: C.ink),
                            ),
                          ),
                        ),
                      if (cities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("Couldn't load cities. Check your connection.",
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.muted)),
                        ),
                    ],
                  ),
                ),
              ),

            const DTxt('How will you deliver?', x: 20, y: 562, w: 372, wt: FontWeight.w600, lh: 18.2),
            for (final v in vehicles)
              DBox(
                x: v.$3,
                y: 587,
                w: v.$4,
                h: 40,
                r: 20,
                bg: _vehicle == v.$1 ? C.green : Colors.white,
                border: _vehicle == v.$1 ? null : Border.all(color: C.line),
                onTap: () => setState(() => _vehicle = v.$1),
                child: Center(
                  child: Text(
                    v.$1,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _vehicle == v.$1 ? Colors.white : C.ink,
                    ),
                  ),
                ),
              ),

            const DTxt('Referral code (optional)', x: 20, y: 658, w: 372, wt: FontWeight.w600, lh: 18.2),
            DBox(x: 20, y: 683, w: 372, h: 55, r: 16, bg: Colors.white, border: Border.all(color: C.line)),
            _input(
              left: 67,
              top: 689,
              width: 300,
              controller: _ref,
              hint: 'e.g. VPN–ANNA25',
              iconAsset: 'assets/ui/gift.svg',
            ),

            DBox(
              x: 20,
              y: 761.75,
              w: 22,
              h: 22,
              r: 4,
              bg: _agree ? C.green : Colors.white,
              border: _agree ? null : Border.all(color: C.line, width: 1.5),
              onTap: () => setState(() => _agree = !_agree),
              child: _agree
                  ? Padding(
                      padding: const EdgeInsets.only(left: 2, top: 2),
                      child: SvgPicture.asset('assets/ui/check.svg', width: 18, height: 18),
                    )
                  : null,
            ),
            Positioned(
              left: 54,
              top: 762.75,
              width: 340,
              child: Text.rich(
                const TextSpan(children: [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(text: 'Partner terms', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ' and '),
                  TextSpan(text: 'Privacy policy', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ', and'),
                ]),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: C.muted, height: 17.5 / 12.5),
              ),
            ),
            PrimaryButton(
              y: 803.88,
              label: _busy ? 'SENDING…' : 'SEND OTP',
              onTap: _busy ? null : _sendOtp,
            ),
            DTxt(
              'Already a partner? Log in',
              x: 20,
              y: 880,
              w: 372,
              lh: 18.2,
              align: TextAlign.center,
              c: const Color(0xFF222222),
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen(state: widget.state)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
