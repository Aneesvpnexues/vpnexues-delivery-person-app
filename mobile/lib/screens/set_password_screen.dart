import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../ui/design.dart';
import 'upload_docs.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({
    super.key,
    required this.state,
    this.fromSettings = false,
  });

  final AppState state;
  final bool fromSettings;

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  final _passwordFieldKey = GlobalKey();
  final _confirmFieldKey = GlobalKey();

  final _scrollController = ScrollController();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _fingerprintEnabled = true;
  bool _busy = false;
  bool _submittedOnce = false;

  bool get _longEnough => _passwordController.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_passwordController.text);
  bool get _hasSymbol =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(_passwordController.text);

  int get _score =>
      [_longEnough, _hasUpper, _hasDigit, _hasSymbol].where((x) => x).length;

  bool get _hasConfirmText => _confirmController.text.isNotEmpty;
  bool get _passwordsMatch =>
      _hasConfirmText && _passwordController.text == _confirmController.text;

  String get _strengthLabel =>
      const ['Weak', 'Weak', 'Fair', 'Good', 'Strong'][_score];

  Color get _strengthColor {
    if (_passwordController.text.isEmpty) return C.muted;
    switch (_score) {
      case 0:
      case 1:
        return const Color(0xFFB3261E);
      case 2:
        return const Color(0xFFD97706);
      case 3:
      case 4:
      default:
        return C.accent;
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onTextChanged);
    _confirmController.addListener(_onTextChanged);
    _passwordFocus.addListener(() => _handleFocus(_passwordFocus, _passwordFieldKey));
    _confirmFocus.addListener(() => _handleFocus(_confirmFocus, _confirmFieldKey));
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
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
    _passwordController.removeListener(_onTextChanged);
    _confirmController.removeListener(_onTextChanged);
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }

    if (_score < 4) {
      HapticFeedback.lightImpact();
      showToast(context, 'Your password needs all four items in the checklist');
      return;
    }
    if (!_passwordsMatch) {
      HapticFeedback.lightImpact();
      showToast(context, "The two passwords don't match");
      return;
    }

    setState(() => _busy = true);
    try {
      // Dev mode: skip the server call and go straight to the next page.
      HapticFeedback.mediumImpact();
      showToast(context, 'Password saved');
      if (widget.fromSettings) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UploadDocsScreen(state: widget.state),
          ),
        );
      }
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
                  _ResponsiveTopBar(
                    title: widget.fromSettings
                        ? 'Change password'
                        : 'Secure your account',
                    stepLabel: widget.fromSettings ? null : 'Step 3 of 5',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  if (!widget.fromSettings)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: _StepProgressBar(totalSteps: 5, currentIndex: 2),
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
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeaderSection(),
                                const SizedBox(height: 24),
                                _buildPasswordSection(),
                                const SizedBox(height: 14),
                                _buildStrengthSection(),
                                const SizedBox(height: 18),
                                _buildChecklistCard(),
                                const SizedBox(height: 22),
                                _buildConfirmSection(),
                                const SizedBox(height: 22),
                                _buildFingerprintCard(),
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
                        child: _StickyPrimaryButton(
                          label: _busy
                              ? 'SAVING…'
                              : (widget.fromSettings
                                  ? 'SAVE PASSWORD'
                                  : 'SAVE & CONTINUE'),
                          busy: _busy,
                          onTap: _busy ? null : _save,
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

  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF5DB),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const _DesignAsset(
            'assets/ui/shield.svg',
            width: 22,
            height: 22,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a password',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: C.ink,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'You’ll use it with your mobile number to log in.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
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

  Widget _buildPasswordSection() {
    final hasError = _submittedOnce && _score < 4;
    return Column(
      key: _passwordFieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New password',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: C.ink,
          ),
        ),
        const SizedBox(height: 8),
        _PasswordInputField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          enabled: !_busy,
          obscureText: !_showPassword,
          hintText: 'Create a password',
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _confirmFocus.requestFocus(),
          borderColor: hasError
              ? const Color(0xFFB3261E)
              : (_passwordFocus.hasFocus ? C.green : C.line),
          showFocusGlow: _passwordFocus.hasFocus && !hasError,
          trailing: _VisibilityToggleButton(
            visible: _showPassword,
            semanticLabel:
                _showPassword ? 'Hide new password' : 'Show new password',
            onTap: _busy
                ? null
                : () => setState(() => _showPassword = !_showPassword),
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final active = index < _score;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 3 ? 6 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: active ? null : C.line,
                    gradient: active ? kGrad : null,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Strength: ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: C.muted,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _strengthLabel,
                key: ValueKey(_strengthLabel),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: _strengthColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9ECE5)),
        boxShadow: sh(10, 18, .04),
      ),
      child: Column(
        children: [
          _ChecklistItem(label: 'At least 8 characters', satisfied: _longEnough),
          const SizedBox(height: 12),
          _ChecklistItem(label: 'One uppercase letter', satisfied: _hasUpper),
          const SizedBox(height: 12),
          _ChecklistItem(label: 'One number', satisfied: _hasDigit),
          const SizedBox(height: 12),
          _ChecklistItem(label: 'One symbol (@ # ! %)', satisfied: _hasSymbol),
        ],
      ),
    );
  }

  Widget _buildConfirmSection() {
    final showMismatch = _hasConfirmText && !_passwordsMatch;
    final borderColor = _passwordsMatch
        ? const Color(0xFF81C895)
        : (showMismatch
            ? const Color(0xFFB3261E)
            : (_confirmFocus.hasFocus ? C.green : C.line));

    return Column(
      key: _confirmFieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm password',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: C.ink,
          ),
        ),
        const SizedBox(height: 8),
        _PasswordInputField(
          controller: _confirmController,
          focusNode: _confirmFocus,
          enabled: !_busy,
          obscureText: !_showConfirm,
          hintText: 'Re-enter password',
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_busy) _save();
          },
          borderColor: borderColor,
          showFocusGlow: _confirmFocus.hasFocus && !showMismatch,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _passwordsMatch
                    ? const Padding(
                        key: ValueKey('match'),
                        padding: EdgeInsets.only(right: 6),
                        child: _DesignAsset(
                          'assets/ui/match-check.svg',
                          width: 19,
                          height: 19,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('nomatch')),
              ),
              _VisibilityToggleButton(
                visible: _showConfirm,
                semanticLabel: _showConfirm
                    ? 'Hide confirm password'
                    : 'Show confirm password',
                onTap: _busy
                    ? null
                    : () => setState(() => _showConfirm = !_showConfirm),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: _hasConfirmText
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    _passwordsMatch
                        ? 'Passwords match'
                        : 'Passwords do not match',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: _passwordsMatch
                          ? C.accent
                          : const Color(0xFFB3261E),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFingerprintCard() {
    return Material(
      color: const Color(0xFFEEF5DB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(23),
        side: const BorderSide(color: Color(0xFFDFEBC3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: _busy
            ? null
            : () {
                HapticFeedback.selectionClick();
                setState(() => _fingerprintEnabled = !_fingerprintEnabled);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock with fingerprint',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: C.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Faster log in on this phone',
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
              const SizedBox(width: 12),
              _BrandSwitch(
                value: _fingerprintEnabled,
                onChanged: _busy
                    ? null
                    : (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _fingerprintEnabled = v);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// Wraps the project's existing [DSvg] safely inside responsive layouts.
class _DesignAsset extends StatelessWidget {
  const _DesignAsset(
    this.asset, {
    super.key,
    required this.width,
    required this.height,
    this.opacity = 1,
  });

  final String asset;
  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DSvg(asset, x: 0, y: 0, w: width, h: height, opacity: opacity),
        ],
      ),
    );
  }
}

class _ResponsiveTopBar extends StatelessWidget {
  const _ResponsiveTopBar({
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

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({
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

class _PasswordInputField extends StatelessWidget {
  const _PasswordInputField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.obscureText,
    required this.hintText,
    required this.borderColor,
    required this.showFocusGlow,
    required this.trailing,
    required this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool obscureText;
  final String hintText;
  final Color borderColor;
  final bool showFocusGlow;
  final Widget trailing;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: showFocusGlow ? 1.5 : 1.0,
        ),
        boxShadow: showFocusGlow
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
          const _DesignAsset('assets/ui/lock.svg', width: 18, height: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              obscureText: obscureText,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: autofillHints,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              cursorColor: C.green,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: C.ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: Color(0xFF9AA69E),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 6),
          trailing,
        ],
      ),
    );
  }
}

class _VisibilityToggleButton extends StatelessWidget {
  const _VisibilityToggleButton({
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
                  const _DesignAsset(
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
                        painter: _AnimatedEyePainter(
                          openProgress: progress,
                          color: const Color(0xFF1B5E20), // Dark green
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

class _AnimatedEyePainter extends CustomPainter {
  const _AnimatedEyePainter({
    required this.openProgress,
    required this.color,
  });

  /// 0.0 = closed with downward lashes, 1.0 = round open eye with upward lashes
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

    // Narrower horizontal span + taller curve = rounder, ball-like eye
    final left = Offset(w * 0.14, cy);
    final right = Offset(w * 0.86, cy);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Lower lid: full round arc when open, gently relaxes when closed
    final lowerControlY = cy + h * (0.28 + 0.24 * openProgress);
    final lowerControl = Offset(w * 0.5, lowerControlY);
    final lowerLid = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(lowerControl.dx, lowerControl.dy, right.dx, right.dy);
    canvas.drawPath(lowerLid, strokePaint);

    // Upper lid: sweeps from round top arc down to meet the lower lid
    final upperOpenY = cy - h * 0.52;
    final upperClosedY = lowerControlY;
    final upperControlY =
        upperClosedY + (upperOpenY - upperClosedY) * openProgress;
    final upperControl = Offset(w * 0.5, upperControlY);

    final upperLid = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(upperControl.dx, upperControl.dy, right.dx, right.dy);
    canvas.drawPath(upperLid, strokePaint);

    // Round eyeball / pupil that scales cleanly inside the open eye
    if (openProgress > 0.18) {
      final pupilT = ((openProgress - 0.18) / 0.82).clamp(0.0, 1.0);
      final center = Offset(w * 0.5, cy);

      final pupilPaint = Paint()
        ..color = color.withValues(alpha: pupilT)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, w * 0.16 * pupilT, pupilPaint);

      // Subtle glossy highlight dot for a rounder "ball" feel
      final glintPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * pupilT)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(center.dx - w * 0.05, center.dy - h * 0.05),
        w * 0.045 * pupilT,
        glintPaint,
      );
    }

    // 3 Eyelashes anchored to the upper lid; sweep up when open, down when closed
    final lashLength = w * 0.15;
    final verticalSign = 1.0 - 2.0 * openProgress; // -1 (up) -> +1 (down)
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
  bool shouldRepaint(covariant _AnimatedEyePainter oldDelegate) {
    return oldDelegate.openProgress != openProgress ||
        oldDelegate.color != color;
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.label,
    required this.satisfied,
  });

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: satisfied ? 1.0 : 0.35,
                child: const _DesignAsset(
                  'assets/ui/req-ok.svg',
                  width: 22,
                  height: 22,
                ),
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                scale: satisfied ? 1.0 : 0.0,
                child: const _DesignAsset(
                  'assets/ui/req-check.svg',
                  width: 12,
                  height: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: satisfied ? C.ink : C.muted,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}

class _BrandSwitch extends StatelessWidget {
  const _BrandSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: 'Unlock with fingerprint',
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: value ? null : C.line,
              gradient: value ? kGrad : null,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
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

class _StickyPrimaryButton extends StatelessWidget {
  const _StickyPrimaryButton({
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