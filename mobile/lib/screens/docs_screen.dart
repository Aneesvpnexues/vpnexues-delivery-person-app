import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'document_upload_screen.dart';

class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key, required this.state});

  final AppState state;

  static (String, Color, Color) pillFor(Map<String, dynamic>? d) {
    if (d == null) return ('Not added', pillBad.bg, pillBad.fg);
    final status = asString(d['status']);
    if (status == 'verified') {
      return asBool(d['expiringSoon'])
          ? ('Expiring', pillWarn.bg, pillWarn.fg)
          : ('Verified', pillOk.bg, pillOk.fg);
    }
    if (status == 'in_review') return ('In review', pillInfo.bg, pillInfo.fg);
    if (status == 'rejected') return ('Re-upload', pillBad.bg, pillBad.fg);
    if (status == 'expired') return ('Expired', pillBad.bg, pillBad.fg);
    return ('Pending', pillWarn.bg, pillWarn.fg);
  }

  static String subFor(Map<String, dynamic>? d) {
    if (d == null) return 'Tap to upload';
    if (asString(d['rejectionReason']).isNotEmpty) return asString(d['rejectionReason']);
    if (d['validUntil'] != null) {
      final v = parseDate(d['validUntil']);
      return '${asString(d['status']) == 'expired' ? 'Expired' : 'Valid till'} ${v == null ? '' : _mon(v)}';
    }
    if (asString(d['numberMasked']).isNotEmpty) return asString(d['numberMasked']);
    return 'Submitted ${dateOnly(d['submittedAt'])}';
  }

  static String _mon(DateTime d) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1] + ' ${d.year}';

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  static const _grid = [
    ('aadhaar', 0),
    ('pan', 0),
    ('driving_licence', 1),
    ('vehicle_rc', 1),
    ('vehicle_insurance', 2),
    ('police_verification', 0),
  ];

  static const _thumbs = [
    [Color(0xFFE6F1CF), Color(0xFFD5E6B4)],
    [Color(0xFFE0EFF5), Color(0xFFC2E1EC)],
    [Color(0xFFFFF2BB), Color(0xFFFDE492)],
  ];

  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.state.api.get('/v1/documents');
      if (!mounted) return;
      setState(() {
        _data = res is Map ? Map<String, dynamic>.from(res) : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load documents');
    }
  }

  Future<void> _upload(String type, Map<String, dynamic>? existing) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => DocumentUploadScreen(state: widget.state, type: type, existing: existing),
    ));
    if (ok == true && mounted) {
      showToast(context, '${docLabel(type)} submitted for review');
      await _load();
      await widget.state.loadMe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = mapList(_data?['documents']);
    final byType = {for (final d in docs) asString(d['type']): d};
    final attention = docs.where((d) => asBool(d['expiringSoon']) || ['rejected', 'expired'].contains(asString(d['status']))).toList();
    final missing = stringList(_data?['missing']).where((t) => t != 'selfie').toList();

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'My documents'),
          RoundBtn(
            icon: LucideIcons.plus,
            x: 344,
            y: 41,
            onTap: () => _upload(missing.isNotEmpty ? missing.first : 'aadhaar', byType[missing.isNotEmpty ? missing.first : 'aadhaar']),
          ),
          if (attention.isNotEmpty || missing.isNotEmpty) ...[
            DBox(x: 20, y: 102, w: 372, h: 88, r: 22, bg: const Color(0xFFFFF5D9), border: Border.all(color: const Color(0xFFF0DC8C))),
            const Positioned(left: 36, top: 139, child: Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFF795109))),
            DTxt(
              attention.isNotEmpty
                  ? '${docLabel(asString(attention.first['type']))} ${asString(attention.first['status']) == 'rejected' ? 'was not approved' : asString(attention.first['status']) == 'expired' ? 'has expired' : 'expires soon'}. Update it to keep receiving orders.'
                  : '${missing.length} document${missing.length == 1 ? '' : 's'} still to upload: ${missing.map(docLabel).join(', ')}.',
              x: 64,
              y: 117,
              w: 215,
              s: 13.5,
              lh: 19.5,
              c: const Color(0xFF795109),
              maxLines: 3,
            ),
            Positioned(
              left: 287,
              top: 126,
              child: Btn(
                w: 90,
                h: 40,
                fs: 13,
                kind: BtnKind.yellow,
                label: attention.isNotEmpty ? 'UPDATE' : 'UPLOAD',
                onTap: () => _upload(attention.isNotEmpty ? asString(attention.first['type']) : missing.first,
                    byType[attention.isNotEmpty ? asString(attention.first['type']) : missing.first]),
              ),
            ),
          ] else ...[
            DBox(x: 20, y: 102, w: 372, h: 88, r: 22, bg: const Color(0xFFEEF5DB), border: Border.all(color: const Color(0xFFDDEBC3))),
            const Positioned(left: 36, top: 139, child: Icon(LucideIcons.shieldCheck, size: 16, color: C.green)),
            DTxt(
              _loading ? 'Loading your documents…' : 'All your documents are up to date.',
              x: 64,
              y: 125,
              w: 300,
              s: 13.5,
              lh: 19.5,
              c: C.green,
            ),
          ],

          for (var i = 0; i < _grid.length; i++) _card(i, byType[_grid[i].$1]),

          DBox(
            x: 20,
            y: 822,
            w: 372,
            h: 76,
            r: 24,
            bg: Colors.white,
            border: Border.all(color: C.line),
            shadow: sh(8, 20, .04),
            onTap: () => showToast(context, 'Verification dashboard is coming soon'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  const Tile(s: 44, icon: LucideIcons.layoutGrid, isize: 20),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verification dashboard',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink)),
                        Text('Status, expiry and renewals in one place',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF8A988F)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(int i, Map<String, dynamic>? d) {
    final type = _grid[i].$1;
    final tone = _thumbs[_grid[i].$2];
    final p = DocsScreen.pillFor(d);
    final x = 20 + (i % 2) * 192.0;
    final y = 204 + (i ~/ 2) * 201.0;
    return Positioned(
      left: x,
      top: y,
      width: 180,
      height: 188,
      child: GestureDetector(
        onTap: () => _upload(type, d),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.$2 == pillWarn.bg ? const Color(0xFFF0DC8C) : C.line),
            boxShadow: sh(8, 20, .04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tone),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      top: 14,
                      width: 26,
                      height: 26,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: const Color(0xBFFFFFFF), borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    for (final t in [17.0, 27.0, 36.0])
                      Positioned(
                        left: 46,
                        top: t,
                        width: 101,
                        height: 3.5,
                        child: const DecoratedBox(decoration: BoxDecoration(color: Color(0xFFA9C4A2))),
                      ),
                    if (d == null)
                      const Positioned(
                        right: 10,
                        bottom: 10,
                        child: Icon(LucideIcons.upload, size: 18, color: C.green),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                docLabel(type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink),
              ),
              const SizedBox(height: 5),
              Text(
                DocsScreen.subFor(d),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
              ),
              const Spacer(),
              Pill(label: p.$1, bg: p.$2, fg: p.$3, dot: p.$3),
            ],
          ),
        ),
      ),
    );
  }
}
