import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../ui/design.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class RootGate extends StatefulWidget {
  const RootGate({
    super.key,
    required this.state,
  });

  final AppState state;

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _initialized = false;
  bool _firstTime = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final api = widget.state.api;

    // Check whether this is the first app launch.
    final firstTime = !api.splashSeen;

    if (!mounted) return;

    setState(() {
      _firstTime = firstTime;
      _initialized = true;
    });

    // Save in the background. Never block the UI.
    unawaited(
      api.markSplashSeen().catchError((Object error) {
        debugPrint('Unable to save splash preference: $error');
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen(loading: true);
    }

    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, child) {
        final state = widget.state;

        // First installation: show the welcome splash
        // while the initial app boot is running.
        if (_firstTime && state.booting) {
          return const SplashScreen(loading: true);
        }

        // Returning users with a saved session:
        // avoid displaying signup/login during session checks.
        if (state.booting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: C.green,
              ),
            ),
          );
        }

        // Authenticated user goes directly to HomeShell.
        if (state.loggedIn) {
          return HomeShell(state: state);
        }

        // Unauthenticated user sees welcome screen.
        return SplashScreen(state: state);
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.state,
    this.loading = false,
  });

  final AppState? state;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Preserved full-bleed background design; immune to aspect-ratio distortion.
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
                      DSvg(
                        'assets/glow-top.svg',
                        x: 190,
                        y: -150,
                        w: 370,
                        h: 370,
                      ),
                      DSvg(
                        'assets/glow-soft.svg',
                        x: -150,
                        y: 250,
                        w: 330,
                        h: 330,
                      ),
                      DSvg(
                        'assets/leaf-deco.svg',
                        x: 358,
                        y: 90,
                        w: 60,
                        h: 90,
                      ),
                      CornerLeaves(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Foreground responsive layout
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              24,
                              24,
                              bottomSafe > 0 ? bottomSafe + 20 : 28,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Brand header
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 68,
                                      height: 68,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Logo(x: 0, y: 0, s: 68),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'VP NEXUES',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 30,
                                              fontWeight: FontWeight.w700,
                                              height: 1.2,
                                              color: C.green,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFCD24),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Delivery partner app',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF3A3E34),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const Spacer(flex: 2),

                                // Hero illustration
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: _SplashDesignAsset(
                                      'assets/illustration-scooter.svg',
                                      width: 200,
                                      height: 232,
                                    ),
                                  ),
                                ),

                                const Spacer(flex: 2),

                                // Headline & subtitle
                                const GradientText(
                                  'Fresh Deliveries',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 46,
                                    fontWeight: FontWeight.w700,
                                    height: 1.04,
                                    letterSpacing: -1,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF247947),
                                      Color(0xFFE9D231),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Delivery Partner App',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                    color: C.inkSoft,
                                  ),
                                ),

                                const SizedBox(height: 36),

                                // Bottom CTA / loading state
                                if (loading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.6,
                                          color: C.green,
                                        ),
                                      ),
                                    ),
                                  )
                                else ...[
                                  _SplashPrimaryButton(
                                    label: 'GET STARTED',
                                    backgroundColor: C.yellow,
                                    foregroundColor: C.green,
                                    onTap: state == null
                                        ? null
                                        : () {
                                            HapticFeedback.lightImpact();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => SignupScreen(
                                                  state: state!,
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                  const SizedBox(height: 12),
                                  Semantics(
                                    button: true,
                                    label: 'I already have an account',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: state == null
                                          ? null
                                          : () {
                                              HapticFeedback.selectionClick();
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => LoginScreen(
                                                    state: state!,
                                                  ),
                                                ),
                                              );
                                            },
                                      child: const SizedBox(
                                        height: 48,
                                        child: Center(
                                          child: Text(
                                            'I ALREADY HAVE AN ACCOUNT',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.4,
                                              color: C.green,
                                            ),
                                          ),
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
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashDesignAsset extends StatelessWidget {
  const _SplashDesignAsset(
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

class _SplashPrimaryButton extends StatelessWidget {
  const _SplashPrimaryButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}