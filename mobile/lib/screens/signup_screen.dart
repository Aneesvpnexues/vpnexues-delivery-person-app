import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:country_code_picker/country_code_picker.dart';

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
  String _selectedCountryCode = '+91';
  String _selectedCountryIso = 'IN';
  bool _agree = true;
  bool _busy = false;
  bool _submittedOnce = false;

  static const vehicles = [
    ('Motorbike', 'motorbike'),
    ('Scooter', 'scooter'),
    ('Electric scooter', 'electric_scooter'),
    ('Bicycle', 'bicycle'),
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
    _selectedCountryCode = draft['countryCode']?.toString() ?? '+91';
    _selectedCountryIso = draft['countryIso']?.toString() ?? 'IN';
    final savedPhone = draft['phone']?.toString() ?? '';
    _mobile.text = savedPhone.startsWith(_selectedCountryCode)
        ? savedPhone.substring(_selectedCountryCode.length).replaceAll(RegExp(r'\D'), '')
        : savedPhone.replaceAll(RegExp(r'\D'), '');
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

  /// Cities offered by the picker.
  ///
  /// Prefers the backend list (`GET /v1/cities`) so the sign-up payload can
  /// carry a real `cityId`, and falls back to the bundled list while the API
  /// has not answered yet or is unreachable.
  List<Map<String, dynamic>> get _visibleCities {
    final List<Map<String, dynamic>> source = widget.state.cities.isNotEmpty
        ? widget.state.cities
        : <Map<String, dynamic>>[
            for (final name in availableCities)
              {'id': null, 'name': name, 'state': ''},
          ];

    final query = _cityCtl.text.trim().toLowerCase();
    final selected = _selectedCity?.trim().toLowerCase();
    if (query.isEmpty || query == selected) return source;
    return source
        .where((c) =>
            c['name'].toString().toLowerCase().contains(query) ||
            c['state'].toString().toLowerCase().contains(query))
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

  void _pick(Map<String, dynamic> city) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final name = city['name'].toString();
    setState(() {
      _selectedCity = name;
      _cityId = _asCityId(city['id']);
      _cityCtl.text = name;
      _cityCtl.selection = TextSelection.collapsed(offset: name.length);
      _pickCity = false;
    });
  }

  /// Accepts free text typed by the partner as a custom city.
  void _pickQuery(String query) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedCity = query;
      _cityId = null;
      _cityCtl.text = query;
      _cityCtl.selection = TextSelection.collapsed(offset: query.length);
      _pickCity = false;
    });
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }

    final name = _name.text.trim();
    final phoneNumber = _mobile.text.replaceAll(RegExp(r'\D'), '');
    final phone = '$_selectedCountryCode$phoneNumber';
    final city = _cityCtl.text.trim();

    if (name.length < 2) {
      HapticFeedback.lightImpact();
      showToast(context, 'Enter your full name as on Aadhaar');
      return;
    }

    final internationalDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (internationalDigits.length < 8 || internationalDigits.length > 15) {
      HapticFeedback.lightImpact();
      showToast(context, 'Enter a valid international mobile number');
      return;
    }

    if (city.isEmpty) {
      HapticFeedback.lightImpact();
      showToast(context, 'Enter or choose your city');
      return;
    }

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
    if (_cityId != null) {
      try {
        final res = await widget.state.signupStart(
          fullName: name,
          phone: phone,
          cityId: _cityId!,
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
        'phone': phoneNumber,
        'countryCode': _selectedCountryCode,
        'countryIso': _selectedCountryIso,
        'cityId': _cityId,
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
              if (_cityId == null) {
                return {'devCode': AppState.devOtpCode};
              }
              try {
                return await widget.state.signupStart(
                  fullName: name,
                  phone: phone,
                  cityId: _cityId!,
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

  /// Maximum national-number digits allowed by the E.164 limit (15 digits,
  /// including the selected country calling code).
  int get _maxNationalNumberDigits {
    final callingCodeDigits =
        _selectedCountryCode.replaceAll(RegExp(r'\\D'), '').length;
    return (15 - callingCodeDigits).clamp(1, 15).toInt();
  }

  Widget _buildMobileField() {
    final digits = _mobile.text.replaceAll(RegExp(r'\\D'), '');
    final fullDigits =
        '$_selectedCountryCode$digits'.replaceAll(RegExp(r'\\D'), '');
    final hasError = _submittedOnce &&
        (fullDigits.length < 8 || fullDigits.length > 15);

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
          leadingGap: 8,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 82,
                child: CountryCodePicker(
                  initialSelection: _selectedCountryIso,
                  favorite: const ['+91', '+94', '+1', '+44'],
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  showFlag: true,
                  showDropDownButton: false,
                  flagWidth: 20,
                  alignLeft: true,
                  padding: EdgeInsets.zero,
                  builder: (countryCode) {
                    final flagUri = countryCode?.flagUri;
                    final dialCode =
                        countryCode?.dialCode ?? _selectedCountryCode;

                    return SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (flagUri != null && flagUri.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.asset(
                                flagUri,
                                package: 'country_code_picker',
                                width: 20,
                                height: 15,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              dialCode,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: C.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onChanged: (country) {
                    final newCode = country.dialCode ?? '+91';
                    final newIso = country.code ?? 'IN';
                    setState(() {
                      _selectedCountryCode = newCode;
                      _selectedCountryIso = newIso;

                      // Keep the entered number when changing countries, but
                      // trim excess digits if the new calling code leaves
                      // fewer digits available under the international limit.
                      final currentDigits =
                          _mobile.text.replaceAll(RegExp(r'\\D'), '');
                      final maxDigits = (15 -
                              newCode.replaceAll(RegExp(r'\\D'), '').length)
                          .clamp(1, 15)
                          .toInt();
                      if (currentDigits.length > maxDigits) {
                        _mobile.text = currentDigits.substring(0, maxDigits);
                        _mobile.selection = TextSelection.collapsed(
                          offset: _mobile.text.length,
                        );
                      }
                      if (_submittedOnce) _submittedOnce = false;
                    });
                    HapticFeedback.selectionClick();
                  },
                  dialogSize: Size(
                    MediaQuery.sizeOf(context).width * 0.9,
                    MediaQuery.sizeOf(context).height * 0.72,
                  ),
                  searchDecoration: InputDecoration(
                    hintText: 'Search country or calling code',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8A978F),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFF718078),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 46,
                      minHeight: 48,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F9F5),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFDCE4D9),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF247947),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: C.muted,
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 24,
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
              LengthLimitingTextInputFormatter(_maxNationalNumberDigits),
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
              hintText: 'Mobile number',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
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
          'Include your number without the country code.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: C.muted,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          const Text(
            'Enter a valid mobile number with 8–15 digits including the country code.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFFB3261E),
            ),
          ),
        ],
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
    this.leadingGap = 12,
  });

  final bool focused;
  final bool hasError;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final double leadingGap;

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
            SizedBox(width: leadingGap),
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