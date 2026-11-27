import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'about_screen.dart';
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
    if (widget.state.isLocalizationTestMode) {
      setState(() {
        _s = Map<String, dynamic>.from(widget.state.settings);
        _loading = false;
      });
      return;
    }

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

    if (widget.state.isLocalizationTestMode) {
      widget.state.updateLocalSettings({key: value});
      return;
    }

    try {
      await widget.state.api.patch('/v1/me/settings', body: {key: value});
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

  Future<void> _pushAndRefresh(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) {
      setState(() {});
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = widget.state.partner ?? {};

    final city =
        me['city'] is Map ? asString((me['city'] as Map)['name']) : '';
    final hub = me['hub'] is Map
        ? asString((me['hub'] as Map)['name'], l.noHub)
        : l.noHub;
    final km = asInt(me['deliveryRadiusKm'], 5);
    final navApp = asString(_s?['navigationApp'], 'google_maps');
    final lang = asString(
      widget.state.settings['language'],
      asString(me['language'], 'en'),
    );

    Widget toggle(String key) => ToggleSwitch(
          on: _b(key),
          onColor: C.green,
          onChanged: (v) => _update(key, v),
        );

    return Scaffold(
      backgroundColor: C.bg,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingsHeader(
              title: l.settingsTitle,
              subtitle: _loading ? l.loadingSettings : null,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                22,
                20,
                28 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Deliveries
                  _SectionLabel(l.secDeliveries),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    rows: [
                      _SettingRow(
                        icon: LucideIcons.zap,
                        title: l.autoAcceptTitle,
                        sub: l.autoAcceptSub,
                        right: toggle('autoAcceptNearby'),
                      ),
                      _SettingRow(
                        icon: LucideIcons.mapPin,
                        title: l.zoneTitle,
                        sub: city.isEmpty
                            ? '$hub · $km km'
                            : '$city · $hub · $km km',
                        right: const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: Color(0xFF8A988F),
                        ),
                        onTap: () =>
                            _pushAndRefresh(ZoneScreen(state: widget.state)),
                      ),
                      _SettingRow(
                        icon: LucideIcons.navigation,
                        title: l.navTitle,
                        sub: navApp == 'in_app'
                            ? l.navInApp
                            : l.navGoogleMaps,
                        right: ToggleSwitch(
                          on: navApp != 'in_app',
                          onColor: C.green,
                          onChanged: (v) => _update(
                            'navigationApp',
                            v ? 'google_maps' : 'in_app',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Alerts
                  _SectionLabel(l.secAlerts),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    rows: [
                      _SettingRow(
                        icon: LucideIcons.volume1,
                        title: l.newOrderSoundTitle,
                        sub: l.newOrderSoundSub,
                        right: toggle('newOrderSound'),
                      ),
                      _SettingRow(
                        icon: LucideIcons.wallet,
                        title: l.payoutAlertsTitle,
                        right: toggle('payoutAlerts'),
                      ),
                      _SettingRow(
                        icon: LucideIcons.star,
                        title: l.offersTitle,
                        right: toggle('offersCampaigns'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // App
                  _SectionLabel(l.secApp),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    rows: [
                      _SettingRow(
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
                        onTap: () => _pushAndRefresh(
                          LanguageScreen(state: widget.state),
                        ),
                      ),
                      _SettingRow(
                        icon: LucideIcons.moon,
                        title: l.darkModeTitle,
                        right: ToggleSwitch(
                          on: false,
                          onColor: C.green,
                          onChanged: (_) => showToast(
                            context,
                            'Dark theme mode will be available soon.',
                          ),
                        ),
                      ),
                      _SettingRow(
                        icon: LucideIcons.activity,
                        title: l.dataSaverTitle,
                        sub: l.dataSaverSub,
                        right: toggle('dataSaver'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Security
                  _SectionLabel(l.secSecurity),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    rows: [
                      _SettingRow(
                        icon: LucideIcons.lock,
                        title: l.changePasswordTitle,
                        right: const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: Color(0xFF8A988F),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ResetPasswordScreen(state: widget.state),
                          ),
                        ),
                      ),
                      _SettingRow(
                        icon: LucideIcons.shield,
                        title: l.fingerprintTitle,
                        right: toggle('fingerprintUnlock'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // About link
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AboutScreen(state: widget.state),
                        ),
                      ),
                      child: Text(
                        l.aboutApp,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: C.green,
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
}

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, required this.state});

  final AppState state;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _langs = [
    ('Aa', 'English', 'Default', 'en'),
    ('த', 'தமிழ்', 'Tamil', 'ta'),
    ('हि', 'हिन्दी', 'Hindi', 'hi'),
    ('മ', 'മലയാളം', 'Malayalam', 'ml'),
    ('తె', 'తెలుగు', 'Telugu', 'te'),
    ('ಕ', 'ಕನ್ನಡ', 'Kannada', 'kn'),
  ];

  String _sel = 'en';
  bool _voice = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sel = asString(
      widget.state.isLocalizationTestMode
          ? widget.state.settings['language']
          : widget.state.partner?['language'],
      'en',
    );
    if (!_langs.any((language) => language.$4 == _sel)) {
      _sel = 'en';
    }
    _voice = asBool(widget.state.settings['voiceNavigation'] ?? true);
    _load();
  }

  Future<void> _load() async {
    if (widget.state.isLocalizationTestMode) {
      if (!mounted) return;
      setState(() {
        _voice = asBool(widget.state.settings['voiceNavigation'] ?? true);
      });
      return;
    }

    try {
      final res = await widget.state.api.get('/v1/me/settings');
      if (!mounted) return;
      final m = res is Map
          ? Map<String, dynamic>.from(res)
          : <String, dynamic>{};
      if (m.containsKey('voiceNavigation')) {
        setState(() => _voice = asBool(m['voiceNavigation']));
      }
    } catch (_) {}
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    try {
      if (widget.state.isLocalizationTestMode) {
        widget.state.updateLocalSettings({
          'language': _sel,
          'voiceNavigation': _voice,
        });
      } else {
        await widget.state.api.patch('/v1/me', body: {'language': _sel});
        await widget.state.api.patch(
          '/v1/me/settings',
          body: {'voiceNavigation': _voice},
        );
        await widget.state.loadMe();
      }

      if (!mounted) return;
      showToast(
        context,
        AppLocalizations.of(context).languageSetTo(langLabel(_sel)),
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsHeader(title: l.appLanguageTitle),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.appLanguageDesc,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            height: 19 / 13.5,
                            color: C.muted,
                          ),
                        ),
                        const SizedBox(height: 16),

                        for (var i = 0; i < _langs.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _buildLangTile(_langs[i], cs),
                        ],
                        const SizedBox(height: 18),

                        // Voice navigation card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.voiceNavTitle,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: C.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l.voiceNavSub,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: C.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ToggleSwitch(
                                on: _voice,
                                onColor: C.green,
                                onChanged: (v) => setState(() => _voice = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pinned Apply button
          Container(
            decoration: BoxDecoration(
              color: C.bg,
              border: Border(top: BorderSide(color: C.line.withOpacity(0.7))),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              14 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _busy ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.green,
                  disabledBackgroundColor: C.green.withOpacity(0.6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l.apply,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangTile((String, String, String, String) lang, ColorScheme cs) {
    final selected = _sel == lang.$4;

    return Material(
      color: selected ? cs.secondaryContainer : cs.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: _busy ? null : () => setState(() => _sel = lang.$4),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.35)
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
                  color: selected ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  lang.$1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: selected ? cs.onPrimary : cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.$2,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      lang.$3,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  LucideIcons.check,
                  size: 18,
                  color: cs.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF083F2A), Color(0xFF1F7945)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 15,
              top: 18,
              width: 90,
              height: 120,
              child: Transform.rotate(
                angle: 25 * math.pi / 180,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x3878B43C),
                    borderRadius: BorderRadius.circular(65),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 22),
              child: Row(
                children: [
                  Material(
                    color: const Color(0x24FFFFFF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          LucideIcons.arrowLeft,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFFDFEEE0),
                            ),
                          ),
                        ],
                      ],
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: C.accent,
          letterSpacing: 1.2,
          height: 15.4 / 11,
        ),
      ),
    );
  }
}

class _SettingRow {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.sub,
    required this.right,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final Widget right;
  final VoidCallback? onTap;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.rows});

  final List<_SettingRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: sh(8, 20, .04),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: C.tint5,
                  ),
                InkWell(
                  onTap: rows[i].onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF5DB),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            rows[i].icon,
                            size: 17,
                            color: C.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rows[i].title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              if (rows[i].sub != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  rows[i].sub!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        rows[i].right,
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}