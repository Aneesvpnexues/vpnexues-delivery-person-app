import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../ui/design.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class RootGate extends StatelessWidget {
  const RootGate({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (state.booting) return const SplashScreen(loading: true);
        if (!state.loggedIn) return SplashScreen(state: state);
        return HomeShell(state: state);
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.state, this.loading = false});

  final AppState? state;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const DSvg('assets/glow-top.svg', x: 190, y: -150, w: 370, h: 370),
            const DSvg('assets/glow-soft.svg', x: -150, y: 250, w: 330, h: 330),
            const DSvg('assets/leaf-deco.svg', x: 358, y: 90, w: 60, h: 90),
            const CornerLeaves(),
            const Logo(x: 48, y: 56, s: 68),
            const DTxt('VP NEXUES', x: 134, y: 57.7, w: 240, s: 30, wt: FontWeight.w700, lh: 40.3, c: C.green),
            Positioned(
              left: 136,
              top: 102,
              width: 132,
              height: 20,
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFFFCD24), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Text(
                  'Delivery partner app',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3A3E34)),
                ),
              ),
            ),
            const DSvg('assets/illustration-scooter.svg', x: 105, y: 234, w: 200, h: 232),
            Positioned(
              left: 47.7,
              top: 540,
              width: 244,
              child: const GradientText(
                'Fresh Deliveries',
                style: TextStyle(fontFamily: 'Inter', fontSize: 50, fontWeight: FontWeight.w700, height: 1, letterSpacing: -1),
                gradient: LinearGradient(colors: [Color(0xFF247947), Color(0xFFE9D231)]),
              ),
            ),
            const DTxt('Delivery Partner App', x: 47.7, y: 653, w: 260, s: 24, wt: FontWeight.w700, lh: 36, c: C.inkSoft),
            if (loading)
              const Positioned(
                left: 186,
                top: 720,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: C.green),
                ),
              )
            else ...[
              PrimaryButton(
                y: 735,
                label: 'GET STARTED',
                bg: C.yellow,
                color: C.green,
                onTap: state == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SignupScreen(state: state!)),
                        ),
              ),
              DTxt(
                'I ALREADY HAVE AN ACCOUNT',
                x: 30,
                y: 821.5,
                w: 352,
                s: 14,
                wt: FontWeight.w700,
                lh: 21,
                c: C.green,
                align: TextAlign.center,
                onTap: state == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => LoginScreen(state: state!)),
                        ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
