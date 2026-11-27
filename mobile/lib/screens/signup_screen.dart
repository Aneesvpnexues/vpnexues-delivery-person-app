import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api_client.dart';
import '../core/cities.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _ref = TextEditingController();
  final _cityCtl = TextEditingController();

  final _nameFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _refFocus = FocusNode();

  final _nameKey = GlobalKey();
  final _mobileKey = GlobalKey();
  final _cityKey = GlobalKey();
  final _refKey = GlobalKey();

  final _scrollController = ScrollController();

  /// Name of the city currently shown in the field.
  String? _selectedCity;

  /// Id of the selected city coming from `GET /v1/cities`.
  int? _cityId;

  bool _pickCity = false;

  String _vehicle = 'Motorbike';
  bool _agree = true;
  bool _busy = false;
  bool _submittedOnce = false;

  static const vehicles = [
    ('Motorbike', 'motorbike', 20.0, 88.0),
    ('Scooter', 'scooter', 115.0, 70.0),
    ('Electric scooter', 'electric_scooter', 192.0, 116.0),
    ('Bicycle', 'bicycle', 315.0, 77.0),
  ];

  static const _kDefaultCities = [
    {'id': -1, 'name': 'Visakhapatnam', 'state': 'Andhra Pradesh'},
    {'id': -2, 'name': 'Vijayawada', 'state': 'Andhra Pradesh'},
    {'id': -3, 'name': 'Itanagar', 'state': 'Arunachal Pradesh'},
    {'id': -4, 'name': 'Guwahati', 'state': 'Assam'},
    {'id': -5, 'name': 'Patna', 'state': 'Bihar'},
    {'id': -6, 'name': 'Chandigarh', 'state': 'Chandigarh'},
    {'id': -7, 'name': 'Raipur', 'state': 'Chhattisgarh'},
    {'id': -8, 'name': 'New Delhi', 'state': 'Delhi'},
    {'id': -9, 'name': 'Panaji', 'state': 'Goa'},
    {'id': -10, 'name': 'Ahmedabad', 'state': 'Gujarat'},
    {'id': -11, 'name': 'Surat', 'state': 'Gujarat'},
    {'id': -12, 'name': 'Gurugram', 'state': 'Haryana'},
    {'id': -13, 'name': 'Shimla', 'state': 'Himachal Pradesh'},
    {'id': -14, 'name': 'Ranchi', 'state': 'Jharkhand'},
    {'id': -15, 'name': 'Bengaluru', 'state': 'Karnataka'},
    {'id': -16, 'name': 'Mysuru', 'state': 'Karnataka'},
    {'id': -17, 'name': 'Thiruvananthapuram', 'state': 'Kerala'},
    {'id': -18, 'name': 'Kochi', 'state': 'Kerala'},
    {'id': -19, 'name': 'Bhopal', 'state': 'Madhya Pradesh'},
    {'id': -20, 'name': 'Indore', 'state': 'Madhya Pradesh'},
    {'id': -21, 'name': 'Mumbai', 'state': 'Maharashtra'},
    {'id': -22, 'name': 'Pune', 'state': 'Maharashtra'},
    {'id': -23, 'name': 'Imphal', 'state': 'Manipur'},
    {'id': -24, 'name': 'Shillong', 'state': 'Meghalaya'},
    {'id': -25, 'name': 'Aizawl', 'state': 'Mizoram'},
    {'id': -26, 'name': 'Kohima', 'state': 'Nagaland'},
    {'id': -27, 'name': 'Bhubaneswar', 'state': 'Odisha'},
    {'id': -28, 'name': 'Puducherry', 'state': 'Puducherry'},
    {'id': -29, 'name': 'Amritsar', 'state': 'Punjab'},
    {'id': -30, 'name': 'Jaipur', 'state': 'Rajasthan'},
    {'id': -31, 'name': 'Gangtok', 'state': 'Sikkim'},
    {'id': -32, 'name': 'Chennai', 'state': 'Tamil Nadu'},
    {'id': -33, 'name': 'Coimbatore', 'state': 'Tamil Nadu'},
    {'id': -34, 'name': 'Madurai', 'state': 'Tamil Nadu'},
    {'id': -79, 'name': 'Salem', 'state': 'Tamil Nadu'},
    {'id': -80, 'name': 'Tirupathur', 'state': 'Tamil Nadu'},
    {'id': -81, 'name': 'Tirupattur', 'state': 'Tamil Nadu'},
    {'id': -44, 'name': 'Ariyalur', 'state': 'Tamil Nadu'},
    {'id': -45, 'name': 'Chengalpattu', 'state': 'Tamil Nadu'},
    {'id': -46, 'name': 'Cuddalore', 'state': 'Tamil Nadu'},
    {'id': -47, 'name': 'Dharmapuri', 'state': 'Tamil Nadu'},
    {'id': -48, 'name': 'Dindigul', 'state': 'Tamil Nadu'},
    {'id': -49, 'name': 'Erode', 'state': 'Tamil Nadu'},
    {'id': -50, 'name': 'Hosur', 'state': 'Tamil Nadu'},
    {'id': -51, 'name': 'Kanchipuram', 'state': 'Tamil Nadu'},
    {'id': -52, 'name': 'Kanyakumari', 'state': 'Tamil Nadu'},
    {'id': -53, 'name': 'Karur', 'state': 'Tamil Nadu'},
    {'id': -54, 'name': 'Krishnagiri', 'state': 'Tamil Nadu'},
    {'id': -55, 'name': 'Kumbakonam', 'state': 'Tamil Nadu'},
    {'id': -56, 'name': 'Mayiladuthurai', 'state': 'Tamil Nadu'},
    {'id': -57, 'name': 'Nagapattinam', 'state': 'Tamil Nadu'},
    {'id': -58, 'name': 'Namakkal', 'state': 'Tamil Nadu'},
    {'id': -59, 'name': 'Nagercoil', 'state': 'Tamil Nadu'},
    {'id': -60, 'name': 'Ooty', 'state': 'Tamil Nadu'},
    {'id': -61, 'name': 'Perambalur', 'state': 'Tamil Nadu'},
    {'id': -62, 'name': 'Pudukkottai', 'state': 'Tamil Nadu'},
    {'id': -63, 'name': 'Ramanathapuram', 'state': 'Tamil Nadu'},
    {'id': -64, 'name': 'Ranipet', 'state': 'Tamil Nadu'},
    {'id': -65, 'name': 'Sivakasi', 'state': 'Tamil Nadu'},
    {'id': -66, 'name': 'Sivaganga', 'state': 'Tamil Nadu'},
    {'id': -67, 'name': 'Tenkasi', 'state': 'Tamil Nadu'},
    {'id': -68, 'name': 'Thanjavur', 'state': 'Tamil Nadu'},
    {'id': -69, 'name': 'Theni', 'state': 'Tamil Nadu'},
    {'id': -70, 'name': 'Thoothukudi', 'state': 'Tamil Nadu'},
    {'id': -71, 'name': 'Tirunelveli', 'state': 'Tamil Nadu'},
    {'id': -72, 'name': 'Tiruppur', 'state': 'Tamil Nadu'},
    {'id': -73, 'name': 'Tiruvallur', 'state': 'Tamil Nadu'},
    {'id': -74, 'name': 'Tiruvannamalai', 'state': 'Tamil Nadu'},
    {'id': -75, 'name': 'Tiruvarur', 'state': 'Tamil Nadu'},
    {'id': -76, 'name': 'Vellore', 'state': 'Tamil Nadu'},
    {'id': -77, 'name': 'Viluppuram', 'state': 'Tamil Nadu'},
    {'id': -78, 'name': 'Virudhunagar', 'state': 'Tamil Nadu'},
    {'id': -35, 'name': 'Hyderabad', 'state': 'Telangana'},
    {'id': -36, 'name': 'Agartala', 'state': 'Tripura'},
    {'id': -37, 'name': 'Lucknow', 'state': 'Uttar Pradesh'},
    {'id': -38, 'name': 'Noida', 'state': 'Uttar Pradesh'},
    {'id': -39, 'name': 'Dehradun', 'state': 'Uttarakhand'},
    {'id': -40, 'name': 'Kolkata', 'state': 'West Bengal'},
    {'id': -41, 'name': 'Srinagar', 'state': 'Jammu and Kashmir'},
    {'id': -42, 'name': 'Jammu', 'state': 'Jammu and Kashmir'},
    {'id': -43, 'name': 'Leh', 'state': 'Ladakh'},
  ];

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _nameFocus.addListener(() => _handleFocus(_nameFocus, _nameKey));
    _mobileFocus.addListener(() => _handleFocus(_mobileFocus, _mobileKey));
    _cityFocus.addListener(() {
      if (_cityFocus.hasFocus && !_pickCity) {
        setState(() => _pickCity = true);
      }
      _handleFocus(_cityFocus, _cityKey);
    });
    _refFocus.addListener(() => _handleFocus(_refFocus, _refKey));

    // City list is loaded in the background and never blocks the form.
    widget.state.addListener(_onState);
    if (widget.state.cities.isEmpty) {
      widget.state.loadCities();
    }
  }

  void _onState() {
    if (!mounted) return;

    // The draft restored in [initState] may pre-date the city list, so match
    // it as soon as `GET /v1/cities` answers.
    if (_cityId == null) {
      final name = _selectedCity?.trim().toLowerCase();
      if (name != null && name.isNotEmpty) {
        for (final c in widget.state.cities) {
          if (c['name'].toString().trim().toLowerCase() == name) {
            _cityId = _asCityId(c['id']);
            break;
          }
        }
      }
    }

    setState(() {});
  }

  static int? _asCityId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  /// The backend city currently referenced by [_cityId], if any.
  Map<String, dynamic>? get _cityById {
    for (final c in widget.state.cities) {
      if (_asCityId(c['id']) == _cityId) return c;
    }
    return null;
  }

  void _handleFocus(FocusNode node, GlobalKey fieldKey) {
    if (mounted) setState(() {});
    if (!node.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || !node.hasFocus) return;
        final ctx = fieldKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: 0.25,
          );
        }
      });
    });
  }

  void _restoreDraft() {
    final draft = widget.state.signupDraft;
    if (draft.isEmpty) return;

    _name.text = draft['fullName']?.toString() ?? '';
    _mobile.text = draft['phone']?.toString() ?? '';
    _ref.text = draft['referralCode']?.toString() ?? '';

    if (draft['vehicleType'] != null) {
      final matches =
          vehicles.where((v) => v.$2 == draft['vehicleType']).toList();
      if (matches.isNotEmpty) {
        _vehicle = matches.first.$1;
      }
    }

    final city = draft['cityName']?.toString() ?? '';
    _cityCtl.text = city;
    _selectedCity = city.isEmpty ? null : city;
    _cityId = _asCityId(draft['cityId']);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onState);
    _name.dispose();
    _mobile.dispose();
    _ref.dispose();
    _cityCtl.dispose();
    _nameFocus.dispose();
    _mobileFocus.dispose();
    _cityFocus.dispose();
    _refFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Every known city: the backend list combined with Anees's bundled
  /// [_kDefaultCities], deduplicated by name + state and sorted.
  List<Map<String, dynamic>> get _allCities {
    final byKey = <String, Map<String, dynamic>>{};
    for (final c in [...widget.state.cities, ..._kDefaultCities]) {
      final name = c['name'].toString();
      final state = c['state'].toString();
      byKey['${name.toLowerCase()}|${state.toLowerCase()}'] = c;
    }
    final out = byKey.values.toList()
      ..sort((a, b) {
        final s = a['state'].toString().compareTo(b['state'].toString());
        return s != 0 ? s : a['name'].toString().compareTo(b['name'].toString());
      });
    return out;
  }

  /// Cities offered by the picker.
  ///
  /// Prefers the backend list (`GET /v1/cities`) so the sign-up payload can
  /// carry a real `cityId`. While the API has not answered yet (or is
  /// unreachable), HEAD's [availableCities] and Anees's richer
  /// [_kDefaultCities] are both offered as fallbacks.
  List<Map<String, dynamic>> get _visibleCities {
    final List<Map<String, dynamic>> source;
    if (widget.state.cities.isNotEmpty) {
      source = widget.state.cities;
    } else {
      final byKey = <String, Map<String, dynamic>>{};
      for (final name in availableCities) {
        byKey['${name.toLowerCase()}|'] =
            {'id': null, 'name': name, 'state': ''};
      }
      for (final c in _allCities) {
        // Bundled entries use negative placeholder ids; keep the name/state
        // but leave `cityId` unset so HEAD's dev/OTP fallback still applies.
        byKey["${c['name'].toString().toLowerCase()}|${c['state'].toString().toLowerCase()}"] =
            {'id': null, 'name': c['name'], 'state': c['state']};
      }
      source = byKey.values.toList()
        ..sort((a, b) {
          final byState =
              a['state'].toString().compareTo(b['state'].toString());
          return byState != 0
              ? byState
              : a['name'].toString().compareTo(b['name'].toString());
        });
    }

    final query = _cityCtl.text.trim().toLowerCase();
    final selected = _selectedCity?.trim().toLowerCase();
    if (query.isEmpty || query == selected) return source;
    return source
        .where((c) =>
            c['name'].toString().toLowerCase().contains(query) ||
            c['state'].toString().toLowerCase().contains(query) ||
            'india'.contains(query))
        .toList();
  }

  void _toggleCityPicker() {
    HapticFeedback.selectionClick();
    setState(() => _pickCity = !_pickCity);
    if (_pickCity) {
      _cityFocus.requestFocus();
    } else {
      _cityFocus.unfocus();
    }
  }

  /// Resolves a city name (optionally with a state) to a real service city
  /// returned by `GET /v1/cities`. Kept from origin/anees.
  Map<String, dynamic>? _serverCityByName(String name, [String? state]) {
    final q = name.trim().toLowerCase();
    final st = state?.trim().toLowerCase();
    for (final s in widget.state.cities) {
      if (s['name'].toString().toLowerCase() == q &&
          (st == null ||
              st.isEmpty ||
              s['state'].toString().toLowerCase() == st)) {
        return s;
      }
    }
    return null;
  }

  void _pick(Map<String, dynamic> city) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final name = city['name'].toString();
    final server = _serverCityByName(name, city['state']?.toString());
    setState(() {
      _selectedCity = name;
      _cityId = _asCityId(server?['id']) ?? _asCityId(city['id']);
      _cityCtl.text = name;
      _cityCtl.selection = TextSelection.collapsed(offset: name.length);
      _pickCity = false;
    });
  }

  /// Accepts free text typed by the partner as a custom city. A typed name
  /// that exactly matches a service city is upgraded to that city's real id.
  void _pickQuery(String query) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final server = _serverCityByName(query);
    final name = server?['name'].toString() ?? query;
    setState(() {
      _selectedCity = name;
      _cityId = _asCityId(server?['id']);
      _cityCtl.text = name;
      _cityCtl.selection = TextSelection.collapsed(offset: name.length);
      _pickCity = false;
    });
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }

    final name = _name.text.trim();
    final phone = _mobile.text.replaceAll(RegExp(r'\D'), '');
    final city = _cityCtl.text.trim();

    if (name.length < 2) {
      HapticFeedback.lightImpact();
      showToast(context, 'Enter your full name as on Aadhaar');
      return;
    }

    if (phone.length != 10) {
      HapticFeedback.lightImpact();
      showToast(context, 'Enter your 10-digit mobile number');
      return;
    }

    if (city.isEmpty) {
      HapticFeedback.lightImpact();
      showToast(context, 'Enter or choose your city');
      return;
    }

    // Anees's helper: resolve a typed city to a real service city when it
    // exactly matches one from `GET /v1/cities`.
    final typedCityId = _asCityId(_serverCityByName(city)?['id']);
    final effectiveCityId = _cityId ?? typedCityId;

    if (!_agree) {
      HapticFeedback.lightImpact();
      showToast(context, 'Please accept the partner terms to continue');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _busy = true);

    // Prefer the real sign-up endpoint so the backend owns the OTP. When the
    // server cannot be reached (local / offline builds) fall back to the
    // locally stored draft and the development code.
    var serverCode = AppState.devOtpCode;
    var usedBackend = false;
    if (effectiveCityId != null) {
      try {
        final res = await widget.state.signupStart(
          fullName: name,
          phone: phone,
          cityId: effectiveCityId,
          vehicleType: vehicles.firstWhere((v) => v.$1 == _vehicle).$2,
          referralCode: _ref.text.trim(),
        );
        usedBackend = true;
        final code = res['devCode']?.toString();
        serverCode = (code == null || code.isEmpty)
            ? AppState.devOtpCode
            : code;
      } catch (e) {
        debugPrint('signupStart failed, falling back to local draft: $e');
      }
    }

    try {
      await widget.state.saveSignupDraft({
        'fullName': name,
        'phone': phone,
        'cityId': effectiveCityId,
        'cityName': city,
        'vehicleType': vehicles.firstWhere((v) => v.$1 == _vehicle).$2,
        'referralCode': _ref.text.trim(),
      });

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            state: widget.state,
            phone: phone,
            purpose: 'signup',
            devCode: usedBackend ? serverCode : AppState.devOtpCode,
            onResend: () async {
              if (effectiveCityId == null) {
                return {'devCode': AppState.devOtpCode};
              }
              try {
                return await widget.state.signupStart(
                  fullName: name,
                  phone: phone,
                  cityId: effectiveCityId,
                  vehicleType: vehicles.firstWhere((v) => v.$1 == _vehicle).$2,
                  referralCode: _ref.text.trim(),
                );
              } catch (_) {
                return {'devCode': AppState.devOtpCode};
              }
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showToast(context, 'Could not save signup information');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final bottomSafe = media.padding.bottom;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_pickCity) setState(() => _pickCity = false);
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Preserved full-bleed background design; immune to keyboard resizing.
            const Positioned.fill(
              child: IgnorePointer(
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 412,
                    height: 915,
                    child: Stack(
                      children: [
                        Backdrop(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Foreground responsive layout
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _SignupTopBar(
                    title: 'Create account',
                    stepLabel: 'Step 1 of 5',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: _SignupStepProgressBar(
                      totalSteps: 5,
                      currentIndex: 0,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: AutofillGroup(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 22),
                                _buildNameField(),
                                const SizedBox(height: 18),
                                _buildMobileField(),
                                const SizedBox(height: 18),
                                _buildCityField(),
                                const SizedBox(height: 20),
                                _buildVehicleSection(),
                                const SizedBox(height: 20),
                                _buildReferralField(),
                                const SizedBox(height: 20),
                                _buildTermsRow(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sticky bottom CTA bar that glides smoothly above the keyboard
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      keyboardInset > 0
                          ? keyboardInset + 12
                          : (bottomSafe > 0 ? bottomSafe + 12 : 18),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      border: Border(
                        top: BorderSide(
                          color: C.line.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SignupPrimaryButton(
                              label: _busy ? 'SENDING…' : 'SEND OTP',
                              busy: _busy,
                              onTap: _busy ? null : _sendOtp,
                            ),
                            if (keyboardInset == 0) ...[
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LoginScreen(state: widget.state),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Already a partner? Log in',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JOIN THE HARVEST CREW',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            height: 1.4,
            color: C.accent,
          ),
        ),
        const SizedBox(height: 6),
        const Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Ride with us. ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: C.ink,
              ),
            ),
            GradientText(
              'Earn fresh.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF247947),
                  Color(0xFF8A7600),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Takes about 5 minutes. Keep your Aadhaar, driving licence and bank details ready.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.2,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: C.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    final hasError = _submittedOnce && _name.text.trim().length < 2;
    return Column(
      key: _nameKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Full name (as on Aadhaar)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: C.ink,
          ),
        ),
        const SizedBox(height: 8),
        _SignupInputContainer(
          focused: _nameFocus.hasFocus,
          hasError: hasError,
          leading: SvgPicture.asset(
            'assets/ui/user.svg',
            width: 18,
            height: 18,
          ),
          child: TextField(
            controller: _name,
            focusNode: _nameFocus,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _mobileFocus.requestFocus(),
            onChanged: (_) {
              if (_submittedOnce) setState(() {});
            },
            cursorColor: C.green,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: C.ink,
            ),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'As printed on your Aadhaar',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: Color(0xFF9AA69E),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileField() {
    final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
    final hasError = _submittedOnce && digits.length != 10;

    return Column(
      key: _mobileKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile number',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: C.ink,
          ),
        ),
        const SizedBox(height: 8),
        _SignupInputContainer(
          focused: _mobileFocus.hasFocus,
          hasError: hasError,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '+91',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: C.ink,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 1,
                height: 22,
                color: C.line,
              ),
            ],
          ),
          child: TextField(
            controller: _mobile,
            focusNode: _mobileFocus,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onSubmitted: (_) => _cityFocus.requestFocus(),
            onChanged: (_) {
              if (_submittedOnce) setState(() {});
            },
            cursorColor: C.green,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: C.ink,
            ),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '10-digit number',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: Color(0xFF9AA69E),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'We will send a 6-digit OTP to this number.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: C.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildCityField() {
    final hasError = _submittedOnce && _cityCtl.text.trim().isEmpty;

    return Column(
      key: _cityKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: C.ink,
          ),
        ),
        const SizedBox(height: 8),
        _SignupInputContainer(
          focused: _cityFocus.hasFocus || _pickCity,
          hasError: hasError,
          leading: const _SignupDesignAsset(
            'assets/ui/pin.svg',
            width: 18,
            height: 18,
          ),
          trailing: InkResponse(
            onTap: _busy ? null : _toggleCityPicker,
            radius: 20,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: AnimatedRotation(
                  turns: _pickCity ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: const _SignupDesignAsset(
                    'assets/ui/down.svg',
                    width: 19,
                    height: 19,
                  ),
                ),
              ),
            ),
          ),
          child: TextField(
            controller: _cityCtl,
            focusNode: _cityFocus,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onTap: () {
              if (!_pickCity) setState(() => _pickCity = true);
            },
            onChanged: (value) {
              final typed = value.trim();
              final current = _cityById;
              final stillMatches = current != null &&
                  current['name'].toString().trim().toLowerCase() ==
                      typed.toLowerCase();
              setState(() {
                _pickCity = true;
                _selectedCity = typed.isEmpty ? null : typed;
                if (!stillMatches) _cityId = null;
              });
            },
            onSubmitted: (_) {
              setState(() => _pickCity = false);
              _refFocus.requestFocus();
            },
            cursorColor: C.green,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: C.ink,
            ),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Type or choose your city',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: Color(0xFF9AA69E),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _pickCity ? _buildCityDropdown() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    final st = widget.state;
    final visible = _visibleCities;
    final query = _cityCtl.text.trim();
    final loading = st.citiesLoading && st.cities.isEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
        boxShadow: sh(12, 24, .10),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          if (st.citiesFailed)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              color: const Color(0xFFFFF7E6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Couldn't refresh cities — using the saved list.",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8A6D3B),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => st.loadCities(),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: C.green,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Loading cities…',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: C.muted,
                ),
              ),
            ),
          for (final city in visible)
            InkWell(
              onTap: () => _pick(city),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: _selectedCity != null &&
                          _selectedCity!.trim().toLowerCase() ==
                              city['name'].toString().trim().toLowerCase()
                      ? const Color(0xFFEEF5DB)
                      : Colors.white,
                  border: const Border(
                    bottom: BorderSide(color: C.tint5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        city['name'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: C.ink,
                        ),
                      ),
                    ),
                    if (city['state'] != null &&
                        city['state'].toString().trim().isNotEmpty)
                      Text(
                        city['state'].toString(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: C.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (query.isNotEmpty)
            InkWell(
              onTap: () => _pickQuery(query),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Use custom city: '),
                      TextSpan(
                        text: query,
                        style: const TextStyle(
                          color: C.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: C.ink,
                  ),
                ),
              ),
            ),
          if (visible.isEmpty && query.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Start typing your city name',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: C.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How will you deliver?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: C.ink,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in vehicles)
              _VehicleChip(
                label: v.$1,
                selected: _vehicle == v.$1,
                onTap: _busy
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _vehicle = v.$1);
                      },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReferralField() {
    return Column(
      key: _refKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Referral code (optional)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: C.ink,
          ),
        ),
        const SizedBox(height: 8),
        _SignupInputContainer(
          focused: _refFocus.hasFocus,
          hasError: false,
          leading: SvgPicture.asset(
            'assets/ui/gift.svg',
            width: 18,
            height: 18,
          ),
          child: TextField(
            controller: _ref,
            focusNode: _refFocus,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_busy) _sendOtp();
            },
            cursorColor: C.green,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: C.ink,
            ),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'e.g. VPN-ANNA25',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: Color(0xFF9AA69E),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsRow() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _busy
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() => _agree = !_agree);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: _agree ? C.green : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: _agree ? null : Border.all(color: C.line, width: 1.5),
              ),
              alignment: Alignment.center,
              child: _agree
                  ? SvgPicture.asset(
                      'assets/ui/check.svg',
                      width: 16,
                      height: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Partner terms',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: C.ink,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy policy',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: C.ink,
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: C.muted,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Legacy picker opener from origin/anees (unused by the responsive UI).
  void _openCityPicker() {
    FocusScope.of(context).unfocus();
    setState(() => _pickCity = true);
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
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
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

  /// Original absolute-position design from origin/anees, kept for
  /// reference (not rendered by the responsive [build] above).
  // ignore: unused_element
  Widget _buildLegacySignupDesign() {
    final cities = widget.state.cities;

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
              onTap: _openCityPicker,
            ),
            const DSvg('assets/ui/pin.svg', x: 38, y: 510, w: 18, h: 18),
            Positioned(
              left: 67,
              top: 492,
              width: 280,
              height: 55,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _cityCtl,
                  onTap: () => setState(() => _pickCity = true),
                  onChanged: (_) => setState(() {
                    _pickCity = true;
                    if (_cityCtl.text.trim() != (_selectedCity ?? '')) _cityId = null;
                  }),
                  cursorColor: C.green,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.state.citiesLoading && cities.isEmpty
                        ? 'Loading cities...'
                        : 'Type city, state, or country',
                    hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9AA69E)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const DSvg('assets/ui/down.svg', x: 358, y: 510, w: 19, h: 19),

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
              hint: 'e.g. VPN\u2013ANNA25',
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
              label: _busy ? 'SENDING\u2026' : 'SEND OTP',
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
            if (_pickCity) _cityPanel(),
          ],
        ),
      ),
    );
  }

  Widget _cityPanel() {
    final st = widget.state;
    final visible = _visibleCities;
    final q = _cityCtl.text.trim();
    final items = <Widget>[
      for (var i = 0; i < visible.length; i++)
        InkWell(
          onTap: () => _pick(visible[i]),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: visible[i]['id'] == _cityId ? const Color(0xFFEEF5DB) : Colors.white,
              border: i == 0 ? null : const Border(top: BorderSide(color: C.tint5)),
            ),
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: visible[i]['name'].toString()),
                TextSpan(
                  text: '  \u00B7 ${visible[i]['state']}',
                  style: const TextStyle(color: C.muted, fontWeight: FontWeight.w400, fontSize: 13),
                ),
              ]),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: C.ink),
            ),
          ),
        ),
      if (st.citiesLoading && visible.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Loading cities...',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.muted)),
        ),
      if (visible.isEmpty && !st.citiesLoading)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                st.citiesFailed && st.cities.isEmpty
                    ? "Couldn't load cities. Check your connection."
                    : 'No city/state matches "$q".',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.muted),
              ),
              if (st.citiesFailed || q.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => st.citiesFailed
                      ? st.loadCities()
                      : setState(() {
                          _cityCtl.clear();
                          _cityId = null;
                        }),
                  child: Text(
                    st.citiesFailed ? 'Retry' : 'Clear search',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: C.green,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ],
          ),
        ),
    ];

    final mq = MediaQuery.of(context);
    final s = math.min(mq.size.width / kDesignW, mq.size.height / (kDesignH - kBottomSlack));
    final keyboard = mq.viewInsets.bottom / s;
    final spaceBelow = (kDesignH - keyboard) - 555;
    final openBelow = spaceBelow >= 160;

    final panel = Positioned(
      left: 20,
      width: 372,
      top: openBelow ? 551 : null,
      bottom: openBelow ? null : kDesignH - 487,
      child: Container(
        constraints: BoxConstraints(maxHeight: openBelow ? math.max(120.0, math.min(250.0, spaceBelow)) : 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
          boxShadow: sh(16, 30, .14),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items),
        ),
      ),
    );

    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: kDesignW,
          height: 492,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _pickCity = false),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: 0,
          top: 547,
          width: kDesignW,
          height: kDesignH - 547,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _pickCity = false),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        panel,
      ],
    );
  }

}

class _SignupDesignAsset extends StatelessWidget {
  const _SignupDesignAsset(
    this.asset, {
    required this.width,
    required this.height,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DSvg(asset, x: 0, y: 0, w: width, h: height),
        ],
      ),
    );
  }
}

class _SignupTopBar extends StatelessWidget {
  const _SignupTopBar({
    required this.title,
    required this.onBack,
    this.stepLabel,
  });

  final String title;
  final String? stepLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkResponse(
              onTap: onBack,
              radius: 24,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: C.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: C.ink,
              ),
            ),
          ),
          if (stepLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5DB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                stepLabel!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: C.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignupStepProgressBar extends StatelessWidget {
  const _SignupStepProgressBar({
    required this.totalSteps,
    required this.currentIndex,
  });

  final int totalSteps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final color = i < currentIndex
            ? C.green
            : (i == currentIndex ? C.lime : C.line);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SignupInputContainer extends StatelessWidget {
  const _SignupInputContainer({
    required this.focused,
    required this.hasError,
    required this.child,
    this.leading,
    this.trailing,
  });

  final bool focused;
  final bool hasError;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFB3261E)
        : (focused ? C.green : C.line);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 56),
      padding: EdgeInsets.only(
        left: 16,
        right: trailing != null ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: focused && !hasError ? 1.5 : 1.0,
        ),
        boxShadow: focused && !hasError
            ? [
                BoxShadow(
                  color: C.green.withValues(alpha: 0.08),
                  spreadRadius: 4,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(child: child),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? C.green : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: selected ? null : Border.all(color: C.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : C.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupPrimaryButton extends StatelessWidget {
  const _SignupPrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: busy ? 0.82 : 1.0,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              gradient: kGrad,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: C.green.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}