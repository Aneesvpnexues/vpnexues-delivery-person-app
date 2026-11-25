import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'reset_password_screen.dart';
import 'zone_screen.dart';
import 'about_screen.dart';

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
    // Test mode: read settings locally without calling the backend.
    if (widget.state.isLocalizationTestMode) {
      setState(() {
        _s = Map<String, dynamic>.from(widget.state.settings);
        _loading = false;
      });
      return;
    }

    // Normal mode: load settings from the backend.
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

      showToast(
        context,
        e is ApiException
            ? e.message
            : AppLocalizations.of(context).errLoadSettings,
      );
    }
  }

  bool _b(String key) => asBool(_s?[key]);

  Future<void> _update(String key, dynamic value) async {
    final previous = _s;

    setState(() {
      _s = {
        ...?_s,
        key: value,
      };
    });

    // Test mode: update only local settings.
    if (widget.state.isLocalizationTestMode) {
      widget.state.updateLocalSettings({key: value});
      return;
    }

    // Normal mode: save to backend.
    try {
      await widget.state.api.patch(
        '/v1/me/settings',
        body: {key: value},
      );

      widget.state.updateLocalSettings({key: value});
    } catch (e) {
      if (!mounted) return;

      setState(() => _s = previous);

      showToast(
        context,
        e is ApiException
            ? e.message
            : AppLocalizations.of(context).errSaveSetting,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = widget.state.partner ?? {};

    final city = me['city'] is Map
        ? asString((me['city'] as Map)['name'])
        : '';

    final hub = me['hub'] is Map
        ? asString((me['hub'] as Map)['name'], l.noHub)
        : l.noHub;

    final km = asInt(me['deliveryRadiusKm'], 5);

    final navApp = asString(
      _s?['navigationApp'],
      'google_maps',
    );

    // The backend stores the selected language in the partners table.
    // Therefore, use the partner profile as the source of truth.
    final lang = asString(
  widget.state.settings['language'],
  asString(me['language'], 'en'),
);

    Widget toggle(String key) {
      return ToggleSwitch(
        on: _b(key),
        onColor: C.green,
        onChanged: (v) => _update(key, v),
      );
    }

    return DesignCanvas(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: 412,
          height: 960,
          child: Stack(
            children: [
              const Backdrop(),

          BackBar(title: l.settingsTitle),

          DTxt(
            l.secDeliveries,
            x: 20,
            y: 100,
            s: 11,
            wt: FontWeight.w700,
            lh: 15.4,
            c: C.accent,
            ls: 1.2,
          ),

          DBox(
            x: 20,
            y: 125,
            w: 372,
            h: 180,
            r: 24,
            bg: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            shadow: sh(8, 20, .04),
          ),

          _row(
            0,
            icon: LucideIcons.zap,
            title: l.autoAcceptTitle,
            sub: l.autoAcceptSub,
            right: toggle('autoAcceptNearby'),
          ),

          _row(
            1,
            icon: LucideIcons.mapPin,
            title: l.zoneTitle,
            sub: '$city · $hub · $km km',
            right: const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF8A988F),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ZoneScreen(state: widget.state),
                ),
              );
            },
          ),

          _row(
            2,
            icon: LucideIcons.navigation,
            title: l.navTitle,
            sub: navApp == 'in_app'
                ? l.navInApp
                : l.navGoogleMaps,
            right: ToggleSwitch(
              on: navApp != 'in_app',
              onColor: C.green,
              onChanged: (v) {
                _update(
                  'navigationApp',
                  v ? 'google_maps' : 'in_app',
                );
              },
            ),
          ),

          DTxt(
            l.secAlerts,
            x: 20,
            y: 317,
            s: 11,
            wt: FontWeight.w700,
            lh: 15.4,
            c: C.accent,
            ls: 1.2,
          ),

          DBox(
            x: 20,
            y: 342,
            w: 372,
            h: 169,
            r: 24,
            bg: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            shadow: sh(8, 20, .04),
          ),

          _row(
            0,
            base: 342,
            h: 56.3,
            icon: LucideIcons.volume1,
            title: l.newOrderSoundTitle,
            sub: l.newOrderSoundSub,
            right: toggle('newOrderSound'),
          ),

          _row(
            1,
            base: 342,
            h: 56.3,
            icon: LucideIcons.wallet,
            title: l.payoutAlertsTitle,
            right: toggle('payoutAlerts'),
          ),

          _row(
            2,
            base: 342,
            h: 56.3,
            icon: LucideIcons.star,
            title: l.offersTitle,
            right: toggle('offersCampaigns'),
          ),

          DTxt(
            l.secApp,
            x: 20,
            y: 523,
            s: 11,
            wt: FontWeight.w700,
            lh: 15.4,
            c: C.accent,
            ls: 1.2,
          ),

          DBox(
            x: 20,
            y: 549,
            w: 372,
            h: 168,
            r: 24,
            bg: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            shadow: sh(8, 20, .04),
          ),

          _row(
            0,
            base: 549,
            h: 56,
            icon: LucideIcons.globe,
            title: l.languageTitle,
            right: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  langLabel(lang),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Color(0xFF8A988F),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LanguageScreen(state: widget.state),
                ),
              );
            },
          ),

          _row(
            1,
            base: 549,
            h: 56,
            icon: LucideIcons.moon,
            title: l.darkModeTitle,
            // Dark mode is not available yet. Keep the switch off and
            // show an informational message when the user taps it.
            right: ToggleSwitch(
              on: false,
              onColor: C.green,
              onChanged: (_) {
                showToast(context, 'Dark theme mode will be available soon.');
              },
            ),
          ),

          _row(
            2,
            base: 549,
            h: 56,
            icon: LucideIcons.activity,
            title: l.dataSaverTitle,
            sub: l.dataSaverSub,
            right: toggle('dataSaver'),
          ),

          DTxt(
            l.secSecurity,
            x: 20,
            y: 728,
            s: 11,
            wt: FontWeight.w700,
            lh: 15.4,
            c: C.accent,
            ls: 1.2,
          ),

          DBox(
            x: 20,
            y: 754,
            w: 372,
            h: 126,
            r: 24,
            bg: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            shadow: sh(8, 20, .04),
          ),

          _row(
            0,
            base: 754,
            h: 63,
            icon: LucideIcons.lock,
            title: l.changePasswordTitle,
            right: const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF8A988F),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResetPasswordScreen(
                    state: widget.state,
                  ),
                ),
              );
            },
          ),

          _row(
            1,
            base: 754,
            h: 63,
            icon: LucideIcons.shield,
            title: l.fingerprintTitle,
            right: toggle('fingerprintUnlock'),
          ),

              // About VP Nexues is placed below the Security card.
              DTxt(
                l.aboutApp,
                x: 20,
                y: 890,
                w: 372,
                s: 14,
                wt: FontWeight.w700,
                lh: 20,
                c: C.green,
                align: TextAlign.center,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AboutScreen(state: widget.state),
                    ),
                  );
                },
              ),

              if (_loading)
                DTxt(
                  l.loadingSettings,
                  x: 80,
                  y: 78,
                  s: 11,
                  lh: 15,
                  c: C.muted,
                ),
            ],
          ),
        ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          height: 1.15,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
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
  // Keep this list aligned with the backend app_language enum.
  // Supported languages: en, ta, hi, ml, te, kn.
  static const _langs = [
    ('Aa', 'English', 'Default', 'en', false),
    ('த', 'தமிழ்', 'Tamil', 'ta', false),
    ('हि', 'हिन्दी', 'Hindi', 'hi', false),
    ('മ', 'മലയാളം', 'Malayalam', 'ml', false),
    ('తె', 'తెలుగు', 'Telugu', 'te', false),
    ('ಕ', 'ಕನ್ನಡ', 'Kannada', 'kn', false),
  ];

  String _sel = 'en';
  bool _voice = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    // The selected language is stored on the partner profile.
    _sel = asString(
  widget.state.isLocalizationTestMode
      ? widget.state.settings['language']
      : widget.state.partner?['language'],
  'en',
);

    // Guard against an old/unsupported value being returned by local state.
    if (!_langs.any((language) => language.$4 == _sel)) {
      _sel = 'en';
    }

    _voice = asBool(
      widget.state.settings['voiceNavigation'] ?? true,
    );

    _load();
  }

  Future<void> _load() async {
    // Test mode: do not send API requests.
    if (widget.state.isLocalizationTestMode) {
      if (!mounted) return;

      setState(() {
        _voice = asBool(
          widget.state.settings['voiceNavigation'] ?? true,
        );
      });

      return;
    }

    // Normal mode: get voice navigation preference from backend.
    try {
      final res = await widget.state.api.get('/v1/me/settings');

      if (!mounted) return;

      final m = res is Map
          ? Map<String, dynamic>.from(res)
          : <String, dynamic>{};

      if (m.containsKey('voiceNavigation')) {
        setState(() {
          _voice = asBool(m['voiceNavigation']);
        });
      }
    } catch (_) {}
  }

  Future<void> _apply() async {
    setState(() => _busy = true);

    try {
      if (widget.state.isLocalizationTestMode) {
        // Test mode: update language locally.
        widget.state.updateLocalSettings({
          'language': _sel,
          'voiceNavigation': _voice,
        });
      } else {
        // Language belongs to the partner profile, not partner_settings.
        // PATCH /v1/me updates partners.language.
        await widget.state.api.patch(
          '/v1/me',
          body: {'language': _sel},
        );

        // Voice navigation belongs to partner_settings.
        // PATCH /v1/me/settings updates voiceNavigation.
        await widget.state.api.patch(
          '/v1/me/settings',
          body: {'voiceNavigation': _voice},
        );

        // Reload the backend values so AppState reflects the saved profile
        // language and settings.
        await widget.state.loadMe();
      }

      if (!mounted) return;

      showToast(
        context,
        AppLocalizations.of(context).languageSetTo(
          langLabel(_sel),
        ),
      );

      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is ApiException
              ? e.message
              : AppLocalizations.of(context).errChangeLanguage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),

          BackBar(title: l.appLanguageTitle),

          DTxt(
            l.appLanguageDesc,
            x: 20,
            y: 104,
            w: 350,
            s: 13.5,
            lh: 19,
            c: C.muted,
          ),

        
            
Positioned(
  left: 20,
  top: 154,
  width: 372,
  height: 510,
  child: ListView.separated(
    padding: EdgeInsets.zero,
    physics: const BouncingScrollPhysics(),
    itemCount: _langs.length,
    separatorBuilder: (_, __) =>
        const SizedBox(height: 12),
    itemBuilder: (context, i) {
      final selected = _sel == _langs[i].$4;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _busy
            ? null
            : () {
                setState(() {
                  _sel = _langs[i].$4;
                });
              },
        child: Container(
          height: 73,
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
          ),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _langs[i].$1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _langs[i].$2,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _langs[i].$3,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  LucideIcons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      );
    },
  ),
),

          DBox(
            x: 20,
            y: 680,
            w: 372,
            h: 65,
            r: 22,
            bg: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),

          DTxt(
            l.voiceNavTitle,
            x: 36,
            y: 694,
            s: 14,
            wt: FontWeight.w700,
            lh: 20,
          ),

          DTxt(
            l.voiceNavSub,
            x: 36,
            y: 715,
            s: 12,
            lh: 16.8,
          ),

          ToggleSwitch(
            x: 325,
            y: 698,
            on: _voice,
            onColor: C.green,
            onChanged: (v) {
              setState(() {
                _voice = v;
              });
            },
          ),

          Positioned(
            left: 20,
            right: 20,
            // Keep the button above DesignCanvas's 30px bottom safe area.
            bottom: 40,
            child: Btn(
              label: _busy ? l.saving : l.apply,
              onTap: _busy ? null : _apply,
            ),
          ),
        ],
      ),
    );
  }
}
