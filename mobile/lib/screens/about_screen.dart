import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Branding/copy variants retained from origin/anees while the localized
  // (HEAD) strings remain the visible ones.
  static const String aneesBrand = 'VPNEXUES';
  static const String aneesDescription =
      'VPNEXUES connects local growers with homes and businesses. Our delivery partners are the last, most important mile.';
  static const String aneesRatingPrompt =
      'How has delivering with VPNEXUES been so far?';

  static const _values = [
    (
      LucideIcons.leaf,
      Color(0xFFEEF5DB),
      C.green,
      'Freshness first',
      'Harvested, packed and delivered within hours.',
    ),
    (
      LucideIcons.wallet,
      Color(0xFFFFF3BF),
      C.ink,
      'Fair, transparent pay',
      'Every rupee you earn is itemised in the app.',
    ),
    (
      LucideIcons.shield,
      Color(0xFFE0EFF3),
      Color(0xFF145B73),
      'Safety on every ride',
      'One-tap SOS and accident cover while on duty.',
    ),
  ];

  static const _links = [
    ('Partner terms of service', null),
    ('Privacy policy', null),
    ('Grievance officer', 'Response within 15 days'),
    ('Open-source licences', null),
  ];

  bool _rate = false;
  int _stars = 5;

  List<Widget> _buildLinks(double y) {
    const heights = [48.0, 48.0, 72.0, 48.0];
    final out = <Widget>[];
    var top = y;

    for (var i = 0; i < _links.length; i++) {
      final h = heights[i];

      if (i > 0) {
        out.add(DBox(x: 36, y: top, w: 340, h: 1, bg: C.tint5));
      }

      out.add(
        Positioned(
          left: 36,
          top: top,
          width: 340,
          height: h,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_links[i].$1 == 'Privacy policy') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                );
                return;
              }
              showToast(
                context,
                "${_links[i].$1} will open here once it’s published. "
                "This content isn't available yet.",
              );
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _links[i].$1,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: C.ink,
                        ),
                      ),
                      if (_links[i].$2 != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _links[i].$2!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: C.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Color(0xFF8A988F),
                ),
              ],
            ),
          ),
        ),
      );

      top += h;
    }

    return out;
  }

  Future<void> _submitRating() async {
    setState(() => _rate = false);

    try {
      await widget.state.api.post(
        '/v1/app-ratings',
        body: {'stars': _stars, 'appVersion': '0.1.0'},
      );

      if (!mounted) return;
      showToast(context, 'Thanks for the $_stars-star rating!');
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not submit the rating',
        );
      }
    }
  }

  Widget _ratingButton() {
    return Btn(
      w: 372,
      h: 56,
      kind: BtnKind.outline,
      label: 'RATE THE PARTNER APP',
      icon: LucideIcons.star,
      onTap: () => setState(() => _rate = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            width: 412,
            height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF1F6E3),
                    Color(0xFFF1F6E3),
                    Color(0xFFE4EED0),
                    Color(0xFFE4EED0),
                  ],
                  stops: [0, 0.62, 0.62, 1],
                ),
              ),
            ),
          ),
          RoundBtn(
            icon: LucideIcons.arrowLeft,
            x: 20,
            y: 52,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const DTxt(
            'About',
            x: 80,
            y: 51,
            s: 20,
            wt: FontWeight.w700,
            lh: 28,
            w: 246,
          ),
          const Logo(x: 168, y: 93, s: 76),
          Semantics(
            label: aneesBrand,
            child: const DTxt(
              'VP NEXUES',
              x: 20,
              y: 176,
              w: 372,
              s: 24,
              wt: FontWeight.w700,
              lh: 34,
              c: Color(0xFF0F5132),
              align: TextAlign.center,
            ),
          ),
          const Positioned(
            left: 10,
            top: 233,
            width: 392,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'From the farm to the doorstep,',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: C.ink,
                    height: 30 / 22,
                  ),
                ),
                GradientText(
                  'the same day.',
                  align: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 30 / 22,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: aneesDescription,
            child: const DTxt(
              'VP Nexues connects local growers with homes and businesses. Our delivery partners are the last, most important mile.',
              x: 30,
              y: 300,
              w: 352,
              s: 13.5,
              lh: 20.5,
              c: C.muted,
              align: TextAlign.center,
            ),
          ),
          DBox(
            x: 20,
            y: 376,
            w: 372,
            h: 210,
            r: 24,
            bg: Colors.white,
            border: Border.all(color: C.line),
            shadow: sh(8, 20, .04),
          ),
          for (var i = 0; i < _values.length; i++) ...[
            if (i > 0) DBox(x: 36, y: 376 + i * 70, w: 340, h: 1, bg: C.tint5),
            Positioned(
              left: 36,
              top: 376 + i * 70,
              width: 340,
              height: 70,
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Icon(
                        _values[i].$1,
                        size: 21,
                        color: _values[i].$3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _values[i].$4,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: C.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _values[i].$5,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: C.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          DBox(
            x: 20,
            y: 593,
            w: 372,
            h: 216,
            r: 24,
            bg: Colors.white,
            border: Border.all(color: C.line),
            shadow: sh(8, 20, .04),
          ),
          ..._buildLinks(593),

          // The visible mobile canvas ends at design Y=885 because
          // DesignCanvas reserves 30 pixels of bottom slack.
          // This fixed position keeps the full 56px button visible.
          Positioned(
            left: 20,
            top: 821,
            width: 372,
            height: 56,
            child: _ratingButton(),
          ),

          if (_rate)
            Modal(
              onClose: () => setState(() => _rate = false),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rate the partner app',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: C.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    label: aneesRatingPrompt,
                    child: const Text(
                      'How has delivering with VP Nexues been so far?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: C.muted,
                        height: 19 / 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var n = 1; n <= 5; n++)
                        GestureDetector(
                          onTap: () => setState(() => _stars = n),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              LucideIcons.star,
                              size: 34,
                              color: n <= _stars
                                  ? const Color(0xFFE0B021)
                                  : const Color(0xFFC9D3CB),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Btn(
                    w: 324,
                    h: 46,
                    label: 'SUBMIT RATING',
                    onTap: _submitRating,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
