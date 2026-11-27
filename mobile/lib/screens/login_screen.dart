import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api_client.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'firebase_phone_auth_screen.dart';
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

  final _mobileFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _mobileKey = GlobalKey();
  final _passwordKey = GlobalKey();

  final _scrollController = ScrollController();

  String _tab = 'password';
  bool _show = false;
  bool _keep = true;
  bool _busy = false;
  bool _submittedOnce = false;

  @override
  void initState() {
    super.initState();
    _mobileFocus.addListener(() => _handleFocus(_mobileFocus, _mobileKey));
    _passwordFocus.addListener(() => _handleFocus(_passwordFocus, _passwordKey));
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
            alignment: 0.28,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    _mobileFocus.dispose();
    _passwordFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }

    final phone = _mobile.text.replaceAll(RegExp(r'\D'), '');
    if (phone.length < 10) {
      HapticFeedback.lightImpact();
      showToast(context, 'Enter your 10-digit mobile number');
      return;
    }
    if (_tab == 'password' && _password.text.isEmpty) {
      HapticFeedback.lightImpact();
      showToast(context, 'Enter your password');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      if (_tab == 'password') {
        // Dev mode: log in locally without calling the server.
        await widget.state.loginLocally(phone);
        await widget.state.saveLoginPhone(phone);
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        // Dev mode: go straight to the OTP screen without calling the server.
        await widget.state.saveLoginPhone(phone);
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              state: widget.state,
              phone: phone,
              purpose: 'login',
              devCode: AppState.devOtpCode,
            ),
          ),
        );
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
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final bottomSafe = media.padding.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
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
                        Backdrop(
                          outlines: [
                            Rect.fromLTWH(89.6, 80, 261.7, 444.2),
                            Rect.fromLTWH(128.8, 470.9, 222.5, 53.3),
                            Rect.fromLTWH(239.1, 470.9, 112.2, 53.3),
                            Rect.fromLTWH(299.9, 51.1, 51.4, 473.1),
                          ],
                        ),
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
                  _LoginTopBar(
                    onBack: () => Navigator.of(context).maybePop(),
                    onHelp: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SupportScreen(state: widget.state),
                      ),
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
                                _buildBrandHeader(),
                                const SizedBox(height: 22),
                                const Text(
                                  'Welcome back.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 29,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                    color: C.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Log in to see today's deliveries and payouts.",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    color: C.muted,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _buildSegmentedTabs(),
                                const SizedBox(height: 22),
                                _buildMobileField(),
                                const SizedBox(height: 18),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: _tab == 'password'
                                      ? _buildPasswordField()
                                      : _buildOtpNotice(),
                                ),
                                const SizedBox(height: 18),
                                _buildKeepLoggedInRow(),
                                const SizedBox(height: 12),
                                _buildFirebaseOtpLink(),
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
                          : (bottomSafe > 0 ? bottomSafe + 12 : 20),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LoginPrimaryButton(
                              label: _busy
                                  ? 'PLEASE WAIT…'
                                  : (_tab == 'password'
                                      ? 'LOG IN'
                                      : 'SEND CODE'),
                              busy: _busy,
                              onTap: _busy ? null : _submit,
                            ),
                            if (keyboardInset == 0) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    showToast(
                                      context,
                                      'Fingerprint login arrives in a later version. Use your password for now.',
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _LoginDesignAsset(
                                          'assets/ui/fingerprint.svg',
                                          width: 17,
                                          height: 17,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Log in with fingerprint',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            height: 1.4,
                                            color: C.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: C.tint5,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'New to VP Nexues?',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: C.muted,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: C.tint5,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _LoginOutlineButton(
                                label: 'CREATE A PARTNER ACCOUNT',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SignupScreen(state: widget.state),
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

  Widget _buildBrandHeader() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Logo(x: 0, y: 0, s: 56),
            ],
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VP NEXUES PARTNER',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  height: 1.4,
                  color: C.accent,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Delivery partner app',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: C.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: C.line),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: _tab == 'password'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: C.green,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: sh(6, 10, .12),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _busy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _tab = 'password');
                        },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _tab == 'password' ? Colors.white : C.muted,
                      ),
                      child: const Text('Password'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _busy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _tab = 'otp');
                        },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _tab == 'otp' ? Colors.white : C.muted,
                      ),
                      child: const Text('One-time code'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileField() {
    final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
    final hasError = _submittedOnce && digits.length < 10;

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
        _LoginInputContainer(
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
            textInputAction:
                _tab == 'password' ? TextInputAction.next : TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onSubmitted: (_) {
              if (_tab == 'password') {
                _passwordFocus.requestFocus();
              } else if (!_busy) {
                _submit();
              }
            },
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
      ],
    );
  }

  Widget _buildPasswordField() {
    final hasError = _submittedOnce && _password.text.isEmpty;

    return Column(
      key: _passwordKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: C.ink,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResetPasswordScreen(state: widget.state),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: C.green,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _LoginInputContainer(
          focused: _passwordFocus.hasFocus,
          hasError: hasError,
          leading: const _LoginDesignAsset(
            'assets/ui/lock.svg',
            width: 18,
            height: 18,
          ),
          trailing: _LoginVisibilityToggleButton(
            visible: _show,
            semanticLabel: _show ? 'Hide password' : 'Show password',
            onTap: _busy ? null : () => setState(() => _show = !_show),
          ),
          child: TextField(
            controller: _password,
            focusNode: _passwordFocus,
            enabled: !_busy,
            obscureText: !_show,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_busy) _submit();
            },
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
              hintText: 'Your password',
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

  Widget _buildOtpNotice() {
    return Container(
      key: const ValueKey('otp-notice'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5DB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFEBC3)),
      ),
      child: const Text(
        "We'll text a 6-digit one-time code to this number.",
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: C.ink,
        ),
      ),
    );
  }

  Widget _buildKeepLoggedInRow() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _busy
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() => _keep = !_keep);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _keep ? C.green : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: _keep ? null : Border.all(color: C.line, width: 1.5),
              ),
              alignment: Alignment.center,
              child: _keep
                  ? SvgPicture.asset(
                      'assets/ui/check2.svg',
                      width: 18,
                      height: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Keep me logged in on this phone',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: C.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Firebase phone OTP entry point added on origin/rashi. It is kept alongside
  /// the password and backend OTP flows so none of the sign-in options is lost.
  Widget _buildFirebaseOtpLink() {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const FirebasePhoneAuthScreen(),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            'VERIFY WITH FIREBASE OTP',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: C.green,
            ),
          ),
        ),
      ),
    );
  }

  /// Absolute-position design preserved from origin/anees.
  ///
  /// This is kept as an alternative layout (e.g. for a design preview or a
  /// future switch back to the fixed 412x915 canvas) and is not wired into
  /// [build] by default. It deliberately keeps Anees's original strings,
  /// fixed coordinates and design widgets intact.
  // ignore: unused_element
  Widget _buildLegacyDesign(BuildContext context) {
    return DesignCanvas(
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
                MaterialPageRoute(
                  builder: (_) => SupportScreen(state: widget.state),
                ),
              ),
            ),
          ),
          const Logo(x: 20, y: 102, s: 56),
          const DTxt('VPNEXUES PARTNER',
              x: 90,
              y: 114,
              w: 280,
              s: 11,
              wt: FontWeight.w700,
              lh: 15.4,
              c: C.accent,
              ls: .9),
          const DTxt('Delivery partner app',
              x: 90,
              y: 129,
              w: 280,
              s: 12,
              wt: FontWeight.w500,
              lh: 16.8,
              c: C.muted),
          const DTxt('Welcome back.',
              x: 20,
              y: 164,
              w: 372,
              s: 29,
              wt: FontWeight.w700,
              lh: 40.6),
          const DTxt("Log in to see today's deliveries and payouts.",
              x: 20,
              y: 202,
              w: 380,
              s: 15,
              wt: FontWeight.w500,
              lh: 21,
              c: C.muted),

          // segmented control
          DBox(
            x: 20,
            y: 236,
            w: 372,
            h: 56,
            r: 28,
            bg: Colors.white,
            border: Border.all(color: C.line),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: _tab == 'password' ? 24 : 206,
            top: 240,
            width: 182,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                color: C.green,
                borderRadius: BorderRadius.circular(24),
                boxShadow: sh(6, 10, .12),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 240,
            width: 182,
            height: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _tab = 'password'),
              child: Center(
                child: Text('Password',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _tab == 'password' ? Colors.white : C.muted)),
              ),
            ),
          ),
          Positioned(
            left: 206,
            top: 240,
            width: 182,
            height: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _tab = 'otp'),
              child: Center(
                child: Text('One-time code',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _tab == 'otp' ? Colors.white : C.muted)),
              ),
            ),
          ),

          const DTxt('Mobile number',
              x: 20, y: 308, w: 372, wt: FontWeight.w600, lh: 18.2),
          DBox(
            x: 20,
            y: 332,
            w: 372,
            h: 55,
            r: 16,
            bg: Colors.white,
            border: Border.all(color: C.line),
          ),
          const DTxt('+91',
              x: 37, y: 349, w: 38, s: 16, wt: FontWeight.w600, lh: 22.4),
          const DBox(x: 74.5, y: 349, w: 1, h: 21, bg: C.line),
          Positioned(
            left: 87,
            top: 332,
            width: 280,
            height: 55,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                cursorColor: C.green,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: C.ink),
                decoration: const InputDecoration(
                  isDense: true,
                  isCollapsed: true,
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
                      color: Color(0xFF9AA69E)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          if (_tab == 'password') ...[
            const DTxt('Password',
                x: 20, y: 399, w: 372, wt: FontWeight.w600, lh: 18.2),
            DTxt(
              'Forgot password?',
              x: 252,
              y: 399,
              w: 140,
              wt: FontWeight.w700,
              lh: 18.2,
              c: C.green,
              align: TextAlign.right,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResetPasswordScreen(state: widget.state),
                ),
              ),
            ),
            DBox(
              x: 20,
              y: 423,
              w: 372,
              h: 55,
              r: 16,
              bg: Colors.white,
              border: Border.all(color: C.green, width: 1.5),
              shadow: [
                BoxShadow(
                  color: C.green.withValues(alpha: .08),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ],
            ),
            const DSvg('assets/ui/lock.svg', x: 38, y: 441, w: 18, h: 18),
            Positioned(
              left: 67,
              top: 423,
              width: 250,
              height: 55,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _password,
                  obscureText: !_show,
                  cursorColor: C.green,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: C.ink),
                  decoration: const InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: 'Your password',
                    hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9AA69E)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            DBox(
              x: 334,
              y: 430,
              w: 40,
              h: 40,
              onTap: () => setState(() => _show = !_show),
              child: Stack(
                children: [
                  const DSvg('assets/ui/eye-button.svg',
                      x: 0, y: 0, w: 40, h: 40),
                  if (_show)
                    const DSvg('assets/ui/eye.svg',
                        x: 12, y: 12, w: 16, h: 16)
                  else
                    const DSvg('assets/ui/eye-slash.svg',
                        x: 11, y: 11, w: 18, h: 18),
                ],
              ),
            ),
          ] else
            const DTxt("We'll text a 6-digit one-time code to this number.",
                x: 20,
                y: 399,
                w: 372,
                s: 13,
                wt: FontWeight.w500,
                lh: 19.5,
                c: C.muted),

          DBox(
            x: 20,
            y: 496,
            w: 22,
            h: 22,
            r: 4,
            bg: _keep ? C.green : Colors.white,
            border: _keep ? null : Border.all(color: C.line, width: 1.5),
            onTap: () => setState(() => _keep = !_keep),
            child: _keep
                ? Padding(
                    padding: const EdgeInsets.only(left: 2, top: 1),
                    child: SvgPicture.asset(
                      'assets/ui/check2.svg',
                      width: 20,
                      height: 20,
                    ),
                  )
                : null,
          ),
          const DTxt('Keep me logged in on this phone',
              x: 54, y: 497, w: 338, wt: FontWeight.w500, lh: 18.2, c: C.muted),

          PrimaryButton(
            y: 560,
            label: _busy
                ? 'PLEASE WAIT...'
                : (_tab == 'password' ? 'LOG IN' : 'SEND CODE'),
            onTap: _busy ? null : _submit,
          ),

          const DSvg('assets/ui/fingerprint.svg',
              x: 113, y: 636, w: 17, h: 17),
          DTxt(
            'Log in with fingerprint',
            x: 137,
            y: 634,
            w: 240,
            s: 15,
            wt: FontWeight.w700,
            lh: 21,
            c: C.green,
            onTap: () => showToast(
              context,
              'Fingerprint login arrives in a later version. Use your password for now.',
            ),
          ),

          // Firebase OTP link from origin/rashi, positioned to fit this
          // alternative fixed-canvas layout between the fingerprint row and
          // the sign-up divider.
          DTxt(
            'VERIFY WITH FIREBASE OTP',
            x: 20,
            y: 668,
            w: 372,
            s: 13,
            wt: FontWeight.w700,
            lh: 18.2,
            c: C.green,
            align: TextAlign.center,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FirebasePhoneAuthScreen(),
              ),
            ),
          ),

          const DBox(x: 20, y: 705, w: 122, h: 1, bg: C.tint5),
          const DBox(x: 270, y: 705, w: 122, h: 1, bg: C.tint5),
          const DTxt('New to VPNEXUES?',
              x: 144,
              y: 697,
              w: 125,
              s: 12,
              wt: FontWeight.w500,
              lh: 16.8,
              c: C.muted,
              align: TextAlign.center),
          OutlineButton(
            y: 728,
            label: 'CREATE A PARTNER ACCOUNT',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SignupScreen(state: widget.state),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginDesignAsset extends StatelessWidget {
  const _LoginDesignAsset(
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

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar({
    required this.onBack,
    required this.onHelp,
  });

  final VoidCallback onBack;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onHelp,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                'Need help?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: C.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginInputContainer extends StatelessWidget {
  const _LoginInputContainer({
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

class _LoginVisibilityToggleButton extends StatelessWidget {
  const _LoginVisibilityToggleButton({
    required this.visible,
    required this.semanticLabel,
    required this.onTap,
  });

  final bool visible;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        radius: 22,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _LoginDesignAsset(
                    'assets/ui/eye-button.svg',
                    width: 40,
                    height: 40,
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: visible ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOutCubic,
                    builder: (context, progress, _) {
                      return CustomPaint(
                        size: const Size(20, 20),
                        painter: _LoginAnimatedEyePainter(
                          openProgress: progress,
                          color: const Color(0xFF1B5E20),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginAnimatedEyePainter extends CustomPainter {
  const _LoginAnimatedEyePainter({
    required this.openProgress,
    required this.color,
  });

  final double openProgress;
  final Color color;

  Offset _quadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1.0 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h * 0.52;
    final left = Offset(w * 0.14, cy);
    final right = Offset(w * 0.86, cy);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final lowerControlY = cy + h * (0.28 + 0.24 * openProgress);
    final lowerControl = Offset(w * 0.5, lowerControlY);
    final lowerLid = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(lowerControl.dx, lowerControl.dy, right.dx, right.dy);
    canvas.drawPath(lowerLid, strokePaint);

    final upperOpenY = cy - h * 0.52;
    final upperClosedY = lowerControlY;
    final upperControlY =
        upperClosedY + (upperOpenY - upperClosedY) * openProgress;
    final upperControl = Offset(w * 0.5, upperControlY);

    final upperLid = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(upperControl.dx, upperControl.dy, right.dx, right.dy);
    canvas.drawPath(upperLid, strokePaint);

    if (openProgress > 0.18) {
      final pupilT = ((openProgress - 0.18) / 0.82).clamp(0.0, 1.0);
      final center = Offset(w * 0.5, cy);

      final pupilPaint = Paint()
        ..color = color.withValues(alpha: pupilT)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, w * 0.16 * pupilT, pupilPaint);

      final glintPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * pupilT)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(center.dx - w * 0.05, center.dy - h * 0.05),
        w * 0.045 * pupilT,
        glintPaint,
      );
    }

    final lashLength = w * 0.15;
    final verticalSign = 1.0 - 2.0 * openProgress;
    final lashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const lashSpecs = [
      (t: 0.26, dx: -0.55, dy: 0.83),
      (t: 0.50, dx: 0.0, dy: 1.0),
      (t: 0.74, dx: 0.55, dy: 0.83),
    ];

    for (final lash in lashSpecs) {
      final base = _quadBezier(left, upperControl, right, lash.t);
      final tip = Offset(
        base.dx + lash.dx * lashLength,
        base.dy + lash.dy * verticalSign * lashLength,
      );
      canvas.drawLine(base, tip, lashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoginAnimatedEyePainter oldDelegate) {
    return oldDelegate.openProgress != openProgress ||
        oldDelegate.color != color;
  }
}

class _LoginPrimaryButton extends StatelessWidget {
  const _LoginPrimaryButton({
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
              gradient: const LinearGradient(
  colors: [
    Color(0xFF064E32), // Dark green
    Color(0xFF0B6B43), // Slightly lighter green
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
),
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

class _LoginOutlineButton extends StatelessWidget {
  const _LoginOutlineButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: C.green, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 54,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: C.green,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}