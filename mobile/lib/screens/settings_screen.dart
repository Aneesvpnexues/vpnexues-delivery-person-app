import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'reset_password_screen.dart';
import 'zone_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _s;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.state.api.get('/v1/me/settings');
      if (!mounted) return;
      setState(() {
        _s = res is Map ? Map<String, dynamic>.from(res) : {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load settings');
    }
  }

  bool _b(String key) => asBool(_s?[key]);

  Future<void> _update(String key, dynamic value) async {
    final prev = _s;
    setState(() => _s = {...?_s, key: value});
    try {
      await widget.state.api.patch('/v1/me/settings', body: {key: value});
    } catch (e) {
      if (!mounted) return;
      setState(() => _s = prev);
      showToast(context, e is ApiException ? e.message : 'Could not save that setting');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.partner ?? {};
    final city = me['city'] is Map ? asString((me['city'] as Map)['name']) : '';
    final hub = me['hub'] is Map ? asString((me['hub'] as Map)['name'], 'No hub') : 'No hub';
    final km = asInt(me['deliveryRadiusKm'], 5);
    final navApp = asString(_s?['navigationApp'], 'google_maps');
    final lang = asString(me['language'], 'en');

    Widget toggle(String key) => ToggleSwitch(
          on: _b(key),
          onColor: C.green,
          onChanged: (v) => _update(key, v),
        );

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'Settings'),

          const DTxt('DELIVERIES', x: 20, y: 100, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          DBox(x: 20, y: 125, w: 372, h: 180, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          _row(0, icon: LucideIcons.zap, title: 'Auto-accept nearby orders', sub: 'Within 2 km of your location', right: toggle('autoAcceptNearby')),
          _row(1, icon: LucideIcons.mapPin, title: 'City, hub & delivery radius', sub: '$city · $hub · $km km',
              right: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF8A988F)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ZoneScreen(state: widget.state)))),
          _row(2, icon: LucideIcons.navigation, title: 'Navigation',
              sub: navApp == 'in_app' ? 'In-app maps' : 'Google Maps · turn-by-turn',
              right: ToggleSwitch(on: navApp != 'in_app', onColor: C.green, onChanged: (v) => _update('navigationApp', v ? 'google_maps' : 'in_app'))),

          const DTxt('ALERTS', x: 20, y: 317, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          DBox(x: 20, y: 342, w: 372, h: 169, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          _row(0, base: 342, h: 56.3, icon: LucideIcons.volume1, title: 'New order sound', sub: 'Plays even on silent', right: toggle('newOrderSound')),
          _row(1, base: 342, h: 56.3, icon: LucideIcons.wallet, title: 'Payout & bonus alerts', right: toggle('payoutAlerts')),
          _row(2, base: 342, h: 56.3, icon: LucideIcons.star, title: 'Offers & campaigns', right: toggle('offersCampaigns')),

          const DTxt('APP', x: 20, y: 523, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          DBox(x: 20, y: 549, w: 372, h: 168, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          _row(0, base: 549, h: 56, icon: LucideIcons.globe, title: 'Language',
              right: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(langLabel(lang), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: C.muted)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF8A988F)),
              ]),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LanguageScreen(state: widget.state)))),
          _row(1, base: 549, h: 56, icon: LucideIcons.moon, title: 'Dark mode for night shifts', right: toggle('darkModeAtNight')),
          _row(2, base: 549, h: 56, icon: LucideIcons.activity, title: 'Data saver', sub: 'Lighter maps on 3G / weak signal', right: toggle('dataSaver')),

          const DTxt('SECURITY', x: 20, y: 728, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          DBox(x: 20, y: 754, w: 372, h: 126, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          _row(0, base: 754, h: 63, icon: LucideIcons.lock, title: 'Change password',
              right: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF8A988F)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResetPasswordScreen(state: widget.state)))),
          _row(1, base: 754, h: 63, icon: LucideIcons.shield, title: 'Fingerprint unlock', right: toggle('fingerprintUnlock')),

          if (_loading) const DTxt('Loading settings…', x: 80, y: 78, s: 11, lh: 15, c: C.muted),
        ],
      ),
    );
  }

  Widget _row(
    int i, {
    double base = 125,
    required IconData icon,
    required String title,
    String? sub,
    required Widget right,
    double h = 60,
    VoidCallback? onTap,
  }) {
    return Positioned(
      left: 36,
      top: base + i * h,
      width: 340,
      height: h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: const Color(0xFFEEF5DB), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: C.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w700, color: C.ink)),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            right,
          ],
        ),
      ),
    );
  }
}

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, required this.state});

  final AppState state;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _langs = [
    ('Aa', 'English', 'Default', 'en', false),
    ('த', 'தமிழ்', 'Tamil', 'ta', false),
    ('हि', 'हिन्दी', 'Hindi', 'hi', false),
    ('മ', 'മലയാളം', 'Malayalam', 'ml', false),
    ('తె', 'తెలుగు', 'Telugu · coming soon', 'te', true),
    ('ಕ', 'ಕನ್ನಡ', 'Kannada · coming soon', 'kn', true),
  ];

  String _sel = 'en';
  bool _voice = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sel = asString(widget.state.partner?['language'], 'en');
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.state.api.get('/v1/me/settings');
      if (!mounted) return;
      final m = res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
      if (m.containsKey('voiceNavigation')) {
        setState(() => _voice = asBool(m['voiceNavigation']));
      }
    } catch (_) {}
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    try {
      await widget.state.api.patch('/v1/me/settings', body: {'language': _sel, 'voiceNavigation': _voice});
      await widget.state.loadMe();
      if (!mounted) return;
      showToast(context, 'Language set to ${langLabel(_sel)}');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not change the language');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'App language'),
          const DTxt('Choose the language for menus, alerts and voice navigation.',
              x: 20, y: 104, w: 350, s: 13.5, lh: 19, c: C.muted),
          for (var i = 0; i < _langs.length; i++)
            Positioned(
              left: 20,
              top: 154 + i * 85,
              width: 372,
              height: 73,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _langs[i].$5 ? null : () => setState(() => _sel = _langs[i].$4),
                child: Opacity(
                  opacity: _langs[i].$5 ? .5 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: _sel == _langs[i].$4 ? const Color(0xFFE6F2D6) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _sel == _langs[i].$4 ? const Color(0xFFD3E6BD) : C.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _sel == _langs[i].$4 ? C.green : const Color(0xFFEEF5DB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _langs[i].$1,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _sel == _langs[i].$4 ? Colors.white : C.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_langs[i].$2,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700, color: C.ink)),
                              Text(_langs[i].$3,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted)),
                            ],
                          ),
                        ),
                        if (_sel == _langs[i].$4) const Icon(LucideIcons.check, size: 16, color: C.green),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          DBox(x: 20, y: 663, w: 372, h: 65, r: 22, bg: const Color(0xFFEEF5DB), border: Border.all(color: const Color(0xFFDDEBC3))),
          const DTxt('Voice navigation in same language', x: 36, y: 677, s: 14, wt: FontWeight.w700, lh: 20),
          const DTxt('Turn-by-turn directions', x: 36, y: 698, s: 12, lh: 16.8),
          ToggleSwitch(x: 325, y: 681, on: _voice, onColor: C.green, onChanged: (v) => setState(() => _voice = v)),
          Btn(y: 839, label: _busy ? 'SAVING…' : 'APPLY', onTap: _busy ? null : _apply),
        ],
      ),
    );
  }
}
