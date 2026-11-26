import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/format.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'about_screen.dart';
import 'bank_screen.dart';
import 'docs_screen.dart';
import 'personal_info_screen.dart';
import 'settings_screen.dart';
import 'sos_screen.dart';
import 'support_screen.dart';
import 'vehicle_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.state, required this.onOpenTab});

  final AppState state;
  final ValueChanged<int> onOpenTab;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  List _methods = [];
  Map<String, dynamic>? _vehicle;
  int _missing = 0;
  int _expiring = 0;
  bool _out = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait([
        widget.state.api.get('/v1/payout-methods'),
        widget.state.api.get('/v1/vehicle'),
        widget.state.api.get('/v1/documents'),
      ]);
      if (!mounted) return;
      setState(() {
        _methods = mapList(res[0]);
        _vehicle = res[1] is Map
            ? Map<String, dynamic>.from(res[1] as Map)
            : null;
        final docs = res[2] is Map
            ? Map<String, dynamic>.from(res[2] as Map)
            : const <String, dynamic>{};
        _missing = mapList(docs['missing']).length;
        _expiring = mapList(docs['documents'])
            .where((d) => asBool(d['expiringSoon']))
            .length;
      });
    } catch (_) {}
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  static const _kycColors = {
    'verified': Color(0xFFDFEE91),
    'in_review': Color(0xFFFFE08A),
    'not_started': Color(0xFFFFD0C8),
    'rejected': Color(0xFFFFD0C8),
  };

  static String _kycLabel(AppLocalizations l, String status) {
    switch (status) {
      case 'verified':
        return l.kycVerified;
      case 'in_review':
        return l.kycInReview;
      case 'rejected':
        return l.kycNeedsAttention;
      default:
        return l.kycNotStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = widget.state.partner ?? {};
    final kycStatus = asString(me['kycStatus'], 'not_started');
    final kycColor = _kycColors[kycStatus] ?? _kycColors['not_started']!;
    final primary = _methods.where((m) => asBool(m['isPrimary'])).toList();
    final method = primary.isNotEmpty
        ? primary.first
        : (_methods.isNotEmpty ? _methods.first : null);
    final methodText = method == null
        ? l.notAdded
        : asString(method['type']) == 'upi'
            ? asString(method['upiVpa'])
            : '${asString(method['bankName'], 'Bank')} ••${asString(method['accountLast4'])}';
    final hub = me['hub'] is Map ? asString((me['hub'] as Map)['name']) : '';
    final city = me['city'] is Map ? asString((me['city'] as Map)['name']) : '';
    final since = parseDate(me['partnerSince']);

    final stats = [
      (asDouble(me['rating']).toStringAsFixed(1), l.statRating),
      (asInt(me['deliveries']).toString(), l.statDeliveries),
      (
        since == null ? '–' : '${_mon(since.month)} ’${since.year % 100}',
        l.statPartnerSince,
      ),
    ];

    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(
        children: [
          Positioned.fill(
  child: SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(
                    l: l,
                    me: me,
                    kycStatus: kycStatus,
                    kycColor: kycColor,
                    location: hub.isNotEmpty ? hub : city,
                    stats: stats,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(l.secAccount),
                        const SizedBox(height: 10),
                        _MenuCard(
                          rows: [
                            _MenuRow(
                              icon: LucideIcons.user,
                              title: l.personalInfoTitle,
                              onTap: () => _push(
                                PersonalInfoScreen(state: widget.state),
                              ),
                            ),
                            _MenuRow(
                              icon: LucideIcons.fileText,
                              title: l.documentsTitle,
                              right: _missing > 0
                                  ? _pill(l.docsToUpload(_missing))
                                  : _expiring > 0
                                      ? _pill(l.docsExpiring(_expiring))
                                      : null,
                              onTap: () => _push(DocsScreen(state: widget.state)),
                            ),
                            _MenuRow(
                              icon: LucideIcons.landmark,
                              title: l.bankTitle,
                              value: methodText,
                              onTap: () => _push(BankScreen(state: widget.state)),
                            ),
                            _MenuRow(
                              icon: LucideIcons.bike,
                              title: l.vehicleTitle,
                              value: _vehicle == null
                                  ? l.notAdded
                                  : asString(
                                      _vehicle!['registrationNumber'],
                                      l.notAdded,
                                    ),
                              onTap: () =>
                                  _push(VehicleScreen(state: widget.state)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(l.secAppSupport),
                        const SizedBox(height: 10),
                        _MenuCard(
                          rows: [
                            _MenuRow(
                              icon: LucideIcons.globe,
                              title: l.languageTitle,
                              value: () {
  final lang = asString(me['language'], 'en').trim();
  if (lang.isEmpty) return 'Eng';

  final short = lang.length > 3 ? lang.substring(0, 3) : lang;
  final formatted =
      short[0].toUpperCase() + short.substring(1).toLowerCase();

  return formatted == 'En' ? 'Eng' : formatted;
}(),
                              onTap: () =>
                                  _push(LanguageScreen(state: widget.state)),
                            ),
                            _MenuRow(
                              icon: LucideIcons.messageCircle,
                              title: l.helpSupport,
                              onTap: () =>
                                  _push(SupportScreen(state: widget.state)),
                            ),
                            _MenuRow(
                              icon: LucideIcons.alertTriangle,
                              tileBg: const Color(0xFFFDE0DD),
                              iconColor: const Color(0xFFC92526),
                              title: l.sosContacts,
                              onTap: () => _push(SosScreen(state: widget.state)),
                            ),
                            _MenuRow(
                              icon: LucideIcons.info,
                              title: l.aboutApp,
                              onTap: () => _push(AboutScreen(state: widget.state)),
                            ),
                            _MenuRow(
                              icon: LucideIcons.logOut,
                              tileBg: const Color(0xFFFDE0DD),
                              iconColor: const Color(0xFFC92526),
                              title: l.logoutRow,
                              onTap: () => setState(() => _out = true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: C.green,
                borderRadius: BorderRadius.circular(26),
                boxShadow: sh(12, 24, .2),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < BottomNav.tabs.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onOpenTab(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: BottomNav.tabs[i].$1 == 'profile'
                                ? const Color(0xFF246849)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                BottomNav.tabs[i].$3,
                                size: 20,
                                color: BottomNav.tabs[i].$1 == 'profile'
                                    ? C.yellow
                                    : const Color(0xFFCEE3D0),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  l.navHome,
                                  l.navOrders,
                                  l.navEarnings,
                                  l.navProfile,
                                ][i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: BottomNav.tabs[i].$1 == 'profile'
                                      ? C.yellow
                                      : const Color(0xFFCEE3D0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_out)
            Modal(
              onClose: () => setState(() => _out = false),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.logoutTitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: C.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.logoutBody,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: C.muted,
                      height: 19 / 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Btn(
                    w: 324,
                    h: 48,
                    kind: BtnKind.danger,
                    icon: LucideIcons.logOut,
                    label: l.logoutBtn,
                    onTap: () async {
                      setState(() => _out = false);
                      await widget.state.logout();
                    },
                  ),
                  const SizedBox(height: 10),
                  Btn(
                    w: 324,
                    h: 48,
                    kind: BtnKind.outline,
                    label: l.cancelBtn,
                    onTap: () => setState(() => _out = false),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required AppLocalizations l,
    required Map<String, dynamic> me,
    required String kycStatus,
    required Color kycColor,
    required String location,
    required List<(String, String)> stats,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
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
              top: 30,
              width: 90,
              height: 130,
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
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.profileTitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 28 / 20,
                        ),
                      ),
                      Material(
                        color: const Color(0x24FFFFFF),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () =>
                              _push(SettingsScreen(state: widget.state)),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              LucideIcons.settings,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 74,
                        height: 74,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF9CC42C),
                                    Color(0xFF247947),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF9CC42C),
                                  width: 3,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials(widget.state.name),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (kycStatus == 'verified')
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9CC42C),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF1A6A3F),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.state.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 28 / 21,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l.partnerId(
                                asString(me['partnerCode']),
                                location,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                color: Color(0xFFDFEEE0),
                                height: 17 / 12.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Pill(
                              label: _kycLabel(l, kycStatus),
                              bg: const Color(0x21FFFFFF),
                              fg: kycColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 68,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0x1FFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0x18FFFFFF),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  stats[i].$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  stats[i].$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFDFEEE0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _pill(String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Pill(
          label: label,
          bg: pillWarn.bg,
          fg: pillWarn.fg,
          dot: pillWarn.fg,
        ),
      );

  static String _mon(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[(m - 1).clamp(0, 11)];
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

class _MenuRow {
  const _MenuRow({
    required this.icon,
    required this.title,
    this.value,
    this.right,
    this.onTap,
    this.tileBg,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? right;
  final VoidCallback? onTap;
  final Color? tileBg;
  final Color? iconColor;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.rows});

  final List<_MenuRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.line),
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
                  child: SizedBox(
                    height: 58,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: rows[i].tileBg ?? const Color(0xFFEEF5DB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              rows[i].icon,
                              size: 18,
                              color: rows[i].iconColor ?? C.green,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              rows[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: C.ink,
                              ),
                            ),
                          ),
                          if (rows[i].right != null) rows[i].right!,
                          if (rows[i].value != null) ...[
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 135),
                              child: Text(
                                rows[i].value!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: C.muted,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: Color(0xFF8A988F),
                          ),
                        ],
                      ),
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