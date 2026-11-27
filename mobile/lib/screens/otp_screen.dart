import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  final Future Function()? onResend;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  final _otpRowKey = GlobalKey();
  final _scrollController = ScrollController();

  late final TapGestureRecognizer _editTapRecognizer;

  bool _busy = false;
  int _wait = 30;
  Timer? _timer;

  bool get _isSignup => widget.purpose == 'signup';

  @override
  void initState() {
    super.initState();
    _editTapRecognizer = TapGestureRecognizer()
      ..onTap = () => Navigator.of(context).maybePop();

    final dev = widget.devCode ?? '';
    for (var i = 0; i < 6 && i < dev.length; i++) {
      _controllers[i].text = dev[i];
    }

    for (final node in _focus) {
      node.addListener(() => _handleFocus(node));
    }

    _startTimer();
  }

  void _handleFocus(FocusNode node) {
    if (mounted) setState(() {});
    if (!node.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || !node.hasFocus) return;
        final ctx = _otpRowKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: 0.3,
          );
        }
      });
    });
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
    _editTapRecognizer.dispose();
    _scrollController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    // Handle paste of multiple digits
    if (digits.length > 1) {
      for (var i = 0; i < 6; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final nextIndex = digits.length.clamp(0, 5);
      _focus[nextIndex].requestFocus();
      setState(() {});
      return;
    }

    if (digits.isNotEmpty) {
      _controllers[index].text = digits;
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
      if (index < 5) {
        _focus[index + 1].requestFocus();
      } else {
        _focus[index].unfocus();
      }
    } else if (index > 0) {
      _focus[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();

    if (!RegExp(r'^\d{6}$').hasMatch(_code)) {
      HapticFeedback.lightImpact();
      showToast(context, 'Enter all 6 digits');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _busy = true);

    try {
      // Temporary local OTP verification.
      if (_code != '123456') {
        HapticFeedback.lightImpact();
        showToast(context, 'Invalid OTP. Use 123456');
        return;
      }

      if (!mounted) return;

      if (_isSignup) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SetPasswordScreen(
              state: widget.state,
            ),
          ),
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_wait > 0) return;

    HapticFeedback.selectionClick();
    // Local resend — no backend request.
    for (var i = 0; i < 6; i++) {
      _controllers[i].text = '123456'[i];
    }

    setState(() {});
    _startTimer();
    showToast(context, 'Your demo OTP is 123456');
  }

  String get _masked {
    final digits = widget.phone.replaceAll(RegExp(r'\D'), '');
    final last10 =
        digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (last10.length < 10) return '+91 $last10';
    return '+91 ${last10.substring(0, 2)}••• ••${last10.substring(8)}';
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
                            Rect.fromLTWH(13.5, 453, 338, 71.1),
                            Rect.fromLTWH(193.2, 62.2, 158.1, 462),
                            Rect.fromLTWH(325.6, 453, 25.8, 71.1),
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
                  _OtpTopBar(
                    title: 'Verify mobile',
                    stepLabel: _isSignup ? 'Step 2 of 5' : null,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  if (_isSignup)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: _OtpStepProgressBar(
                        totalSteps: 5,
                        currentIndex: 1,
                      ),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeroBadge(),
                              const SizedBox(height: 16),
                              const Text(
                                'Enter the 6-digit code',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  color: C.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: 'Sent to $_masked · '),
                                    TextSpan(
                                      text: 'Edit',
                                      style: const TextStyle(
                                        color: C.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      recognizer: _editTapRecognizer,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: C.muted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _buildOtpRow(),
                              const SizedBox(height: 18),
                              _buildDemoBanner(),
                              const SizedBox(height: 16),
                              _buildResendCard(),
                              const SizedBox(height: 14),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => showToast(
                                  context,
                                  'Call-based codes are coming soon. Use Resend for now.',
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    "Didn't get it? Get the code on a call",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                      color: C.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                        child: _OtpPrimaryButton(
                          label: _busy
                              ? 'VERIFYING…'
                              : (_isSignup
                                  ? 'VERIFY & CONTINUE'
                                  : 'VERIFY & LOG IN'),
                          busy: _busy,
                          onTap: _busy ? null : _verify,
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

  Widget _buildHeroBadge() {
    return Center(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const _OtpDesignAsset(
              'assets/ui/halo-outer.svg',
              width: 160,
              height: 160,
            ),
            const _OtpDesignAsset(
              'assets/ui/halo-inner.svg',
              width: 132,
              height: 132,
            ),
            const Positioned(
              top: 32,
              child: _OtpDesignAsset(
                'assets/ui/halo-disc.svg',
                width: 120,
                height: 120,
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1F7945), Color(0xFF095334)],
                ),
                boxShadow: sh(12, 20, .22),
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.smartphone,
                size: 36,
                color: Colors.white,
              ),
            ),
            Positioned(
              right: 34,
              top: 34,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: C.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: C.bg, width: 3),
                  boxShadow: sh(4, 10, .18),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.messageSquare,
                  size: 14,
                  color: C.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpRow() {
    return Row(
      key: _otpRowKey,
      children: List.generate(6, (i) {
        final isFocused = _focus[i].hasFocus;
        final hasValue = _controllers[i].text.isNotEmpty;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isFocused
                      ? C.green
                      : (hasValue ? C.green.withValues(alpha: 0.45) : C.line),
                  width: isFocused ? 1.6 : 1.0,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: C.green.withValues(alpha: 0.09),
                          spreadRadius: 3.5,
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _controllers[i],
                focusNode: _focus[i],
                enabled: !_busy,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                textInputAction:
                    i < 5 ? TextInputAction.next : TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                cursorColor: C.green,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: C.ink,
                ),
                onChanged: (v) => _onDigitChanged(i, v),
                onSubmitted: (_) {
                  if (i == 5 && !_busy) _verify();
                },
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDemoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F4E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4E7CE)),
      ),
      child: const Row(
        children: [
          _OtpDesignAsset(
            'assets/ui/check-green.svg',
            width: 16,
            height: 16,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Demo OTP: 123456 · filled in for you',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: C.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendCard() {
    final canResend = _wait <= 0 && !_busy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE9ECE5)),
        boxShadow: sh(8, 15, .04),
      ),
      child: Row(
        children: [
          const _OtpDesignAsset(
            'assets/ui/clock.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Need another code?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF222222),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: canResend ? _resend : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                _wait > 0 ? 'Resend in ${_wait}s' : 'Resend',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _wait > 0 ? const Color(0xFF90A496) : C.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpDesignAsset extends StatelessWidget {
  const _OtpDesignAsset(
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

class _OtpTopBar extends StatelessWidget {
  const _OtpTopBar({
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

class _OtpStepProgressBar extends StatelessWidget {
  const _OtpStepProgressBar({
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

class _OtpPrimaryButton extends StatelessWidget {
  const _OtpPrimaryButton({
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
              // HEAD's dark-green styling kept; Shizan's kGrad direction hook
              // is reused so theme-level gradient direction stays shared.
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF064E32), // Dark green
                  Color(0xFF0B6B43), // Slightly lighter green
                ],
                begin: kGrad.begin,
                end: kGrad.end,
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