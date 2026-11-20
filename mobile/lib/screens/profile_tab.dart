import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/format.dart';
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
  List<Map<String, dynamic>> _methods = [];
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
        _vehicle = res[1] is Map ? Map<String, dynamic>.from(res[1] as Map) : null;
        final docs = res[2] is Map ? Map<String, dynamic>.from(res[2] as Map) : const <String, dynamic>{};
        _missing = mapList(docs['missing']).length;
        _expiring = mapList(docs['documents']).where((d) => asBool(d['expiringSoon'])).length;
      });
    } catch (_) {}
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  static const _kyc = {
    'verified': ('KYC verified', Color(0xFFDFEE91)),
    'in_review': ('KYC in review', Color(0xFFFFE08A)),
    'not_started': ('KYC not started', Color(0xFFFFD0C8)),
    'rejected': ('KYC needs attention', Color(0xFFFFD0C8)),
  };

  @override
  Widget build(BuildContext context) {
    final me = widget.state.partner ?? {};
    final kyc = _kyc[asString(me['kycStatus'], 'not_started')] ?? _kyc['not_started']!;
    final primary = _methods.where((m) => asBool(m['isPrimary'])).toList();
    final method = primary.isNotEmpty ? primary.first : (_methods.isNotEmpty ? _methods.first : null);
    final methodText = method == null
        ? 'Not added'
        : asString(method['type']) == 'upi'
            ? asString(method['upiVpa'])
            : '${asString(method['bankName'], 'Bank')} ••${asString(method['accountLast4'])}';
    final hub = me['hub'] is Map ? asString((me['hub'] as Map)['name']) : '';
    final city = me['city'] is Map ? asString((me['city'] as Map)['name']) : '';
    final since = parseDate(me['partnerSince']);

    return DesignCanvas(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 412,
            height: 289,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF083F2A), Color(0xFF1F7945)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
            ),
          ),
          Positioned(
            left: 300,
            top: 40,
            width: 90,
            height: 130,
            child: Transform.rotate(
              angle: 25 * 3.1415926 / 180,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x3878B43C),
                  borderRadius: BorderRadius.circular(65),
                ),
              ),
            ),
          ),
          const DTxt('Profile', x: 20, y: 63, s: 20, wt: FontWeight.w700, lh: 28, c: Colors.white),
          DBox(
            x: 344,
            y: 52,
            w: 48,
            h: 48,
            r: 24,
            bg: const Color(0x24FFFFFF),
            onTap: () => _push(SettingsScreen(state: widget.state)),
            child: const Icon(LucideIcons.slidersHorizontal, size: 17, color: Colors.white),
          ),
          DBox(
            x: 20,
            y: 115,
            w: 72,
            h: 72,
            r: 36,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9CC42C), Color(0xFF247947)],
            ),
            border: Border.all(color: const Color(0xFF9CC42C), width: 3),
            child: Center(
              child: Text(
                initials(widget.state.name),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          if (asString(me['kycStatus']) == 'verified')
            DBox(
              x: 71,
              y: 163,
              w: 22,
              h: 22,
              r: 11,
              bg: const Color(0xFF9CC42C),
              border: Border.all(color: const Color(0xFF1A6A3F), width: 2),
              child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
            ),
          DTxt(
            widget.state.name,
            x: 106,
            y: 112,
            w: 290,
            s: 22,
            wt: FontWeight.w700,
            lh: 30,
            c: Colors.white,
            maxLines: 1,
          ),
          DTxt(
            'Partner ID ${asString(me['partnerCode'])} · ${hub.isNotEmpty ? hub : city}',
            x: 106,
            y: 141,
            w: 290,
            s: 12,
            lh: 16.8,
            c: const Color(0xFFDFEEE0),
            maxLines: 1,
          ),
          Pill(x: 106, y: 164, label: kyc.$1, bg: const Color(0x21FFFFFF), fg: kyc.$2),
          for (var i = 0; i < 3; i++)
            DBox(
              x: 20 + i * 127.0,
              y: 204,
              w: 118,
              h: 65,
              r: 20,
              bg: const Color(0x1FFFFFFF),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    [
                      asDouble(me['rating']).toStringAsFixed(1),
                      asInt(me['deliveries']).toString(),
                      since == null ? '–' : '${_mon(since.month)} ’${since.year % 100}',
                    ][i],
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ['Rating', 'Deliveries', 'Partner since'][i],
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFDFEEE0)),
                  ),
                ],
              ),
            ),

          const DTxt('ACCOUNT', x: 20, y: 299, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          _Rows(
            y: 324,
            h: 54,
            rows: [
              _Row(
                icon: LucideIcons.user,
                title: 'Personal info',
                onTap: () => _push(PersonalInfoScreen(state: widget.state)),
              ),
              _Row(
                icon: LucideIcons.fileText,
                title: 'Documents',
                right: _missing > 0
                    ? _pill('$_missing to upload')
                    : _expiring > 0
                        ? _pill('$_expiring expiring')
                        : null,
                onTap: () => _push(DocsScreen(state: widget.state)),
              ),
              _Row(
                icon: LucideIcons.landmark,
                title: 'Bank & UPI',
                value: methodText,
                onTap: () => _push(BankScreen(state: widget.state)),
              ),
              _Row(
                icon: LucideIcons.bike,
                title: 'Vehicle',
                value: _vehicle == null ? 'Not added' : asString(_vehicle!['registrationNumber'], 'Not added'),
                onTap: () => _push(VehicleScreen(state: widget.state)),
              ),
            ],
          ),
          const DTxt('APP & SUPPORT', x: 20, y: 556, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          _Rows(
            y: 581,
            h: 46,
            rows: [
              _Row(
                icon: LucideIcons.globe,
                title: 'Language',
                value: asString(me['language'], 'en'),
                onTap: () => _push(SettingsScreen(state: widget.state)),
              ),
              _Row(
                icon: LucideIcons.messageCircle,
                title: 'Help & support',
                onTap: () => _push(SupportScreen(state: widget.state)),
              ),
              _Row(
                icon: LucideIcons.alertTriangle,
                tile: const Color(0xFFFDE0DD),
                ic: const Color(0xFFC92526),
                title: 'SOS & emergency contacts',
                onTap: () => _push(SosScreen(state: widget.state)),
              ),
              _Row(
                icon: LucideIcons.info,
                title: 'About VP Nexues',
                onTap: () => _push(AboutScreen(state: widget.state)),
              ),
              _Row(
                icon: LucideIcons.logOut,
                tile: const Color(0xFFFDE0DD),
                ic: const Color(0xFFC92526),
                title: 'Log out',
                onTap: () => setState(() => _out = true),
              ),
            ],
          ),

          BottomNav(
            active: 'profile',
            onTap: (k) => widget.onOpenTab({'home': 0, 'orders': 1, 'earnings': 2, 'profile': 3}[k] ?? 3),
          ),

          if (_out)
            Modal(
              onClose: () => setState(() => _out = false),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Log out?',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: C.ink)),
                  const SizedBox(height: 6),
                  const Text('You’ll stop receiving new orders until you log in again.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.muted, height: 19 / 13)),
                  const SizedBox(height: 20),
                  Btn(
                    w: 324,
                    h: 48,
                    kind: BtnKind.danger,
                    icon: LucideIcons.logOut,
                    label: 'LOG OUT',
                    onTap: () async {
                      setState(() => _out = false);
                      await widget.state.logout();
                    },
                  ),
                  const SizedBox(height: 10),
                  Btn(w: 324, h: 48, kind: BtnKind.outline, label: 'CANCEL', onTap: () => setState(() => _out = false)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _pill(String label) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Pill(label: label, bg: pillWarn.bg, fg: pillWarn.fg, dot: pillWarn.fg),
      );

  static String _mon(int m) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}

class _Row {
  _Row({
    required this.icon,
    required this.title,
    this.value,
    this.right,
    this.onTap,
    this.tile,
    this.ic,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? right;
  final VoidCallback? onTap;
  final Color? tile;
  final Color? ic;
}

class _Rows extends StatelessWidget {
  const _Rows({required this.y, required this.h, required this.rows});

  final double y;
  final double h;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      top: y,
      width: 372,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: C.line),
          boxShadow: sh(8, 20, .04),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: rows[i].onTap,
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    border: i == 0 ? null : const Border(top: BorderSide(color: C.tint5)),
                  ),
                  child: Row(
                    children: [
                      Tile(s: 36, bg: rows[i].tile ?? const Color(0xFFEEF5DB), icon: rows[i].icon, c: rows[i].ic, isize: 17, r: 12),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          rows[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink),
                        ),
                      ),
                      if (rows[i].right != null) rows[i].right!,
                      if (rows[i].value != null)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            rows[i].value!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF8A988F)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
