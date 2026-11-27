import 'dart:math' as math;

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
    if (status == 'uploaded') return ('Uploaded', pillInfo.bg, pillInfo.fg);

    if (status == 'verified') {
      return asBool(d['expiringSoon'])
          ? ('Expiring', pillWarn.bg, pillWarn.fg)
          : ('Verified', pillOk.bg, pillOk.fg);
    }

    if (status == 'in_review') {
      return ('In review', pillInfo.bg, pillInfo.fg);
    }

    if (status == 'rejected') {
      return ('Re-upload', pillBad.bg, pillBad.fg);
    }

    if (status == 'expired') {
      return ('Expired', pillBad.bg, pillBad.fg);
    }

    return ('Pending', pillWarn.bg, pillWarn.fg);
  }

  static String subFor(Map<String, dynamic>? d) {
    if (d == null) return 'Tap to upload';

    // Frontend-only selections carry the picked file name instead of a
    // backend submission timestamp.
    if (asString(d['fileName']).isNotEmpty) return asString(d['fileName']);

    if (asString(d['rejectionReason']).isNotEmpty) {
      return asString(d['rejectionReason']);
    }

    if (d['validUntil'] != null) {
      final v = parseDate(d['validUntil']);
      return '${asString(d['status']) == 'expired' ? 'Expired' : 'Valid till'} ${v == null ? '' : _mon(v)}';
    }

    if (asString(d['numberMasked']).isNotEmpty) {
      return asString(d['numberMasked']);
    }

    return 'Submitted ${dateOnly(d['submittedAt'])}';
  }

  static String _mon(DateTime d) =>
      const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][d.month - 1] +
      ' ${d.year}';

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
    widget.state.addListener(_onDocumentsChanged);
    _load();
  }

  @override
  void dispose() {
    widget.state.removeListener(_onDocumentsChanged);
    super.dispose();
  }

  void _onDocumentsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    // Offline dev sessions keep their selections in AppState.localDocuments;
    // there is no backend to fetch documents from.
    if (widget.state.api.isLocalSession) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

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
      if (widget.state.localDocuments.isEmpty) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not load documents',
        );
      }
    }
  }

  Future<void> _upload(
    String type,
    Map<String, dynamic>? existing,
  ) async {
    final saved = widget.state.getLocalDocument(type) ?? existing;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentUploadScreen(
          state: widget.state,
          type: type,
          existing: saved,
        ),
      ),
    );

    if (ok == true && mounted) {
      showToast(
        context,
        '${docLabel(type)} saved on this device session and submitted for review',
      );
      await _load();
      await widget.state.loadMe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = mapList(_data?['documents']);
    final byType = <String, Map<String, dynamic>>{
      for (final d in docs) asString(d['type']): d,
    };

    // Frontend-only selections overlay the backend response so the cards
    // immediately reflect what was picked in this session (also offline).
    for (final entry in widget.state.localDocuments.entries) {
      byType[entry.key] = entry.value;
    }

    final attention = byType.values
        .where(
          (d) =>
              asBool(d['expiringSoon']) ||
              ['rejected', 'expired'].contains(asString(d['status'])),
        )
        .toList();

    final apiMissing = stringList(_data?['missing'])
        .where(
          (t) =>
              t != 'selfie' &&
              !widget.state.localDocuments.containsKey(
                AppState.documentTypeKey(t),
              ),
        )
        .toList();
    final sessionMissing = _grid
        .map((item) => item.$1)
        .where((type) => !byType.containsKey(type))
        .toList();
    final missing = <String>[
      ...apiMissing,
      for (final type in sessionMissing)
        if (!apiMissing.contains(type)) type,
    ];

    final nextType = missing.isNotEmpty ? missing.first : 'aadhaar';

    return Scaffold(
      backgroundColor: C.bg,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              context,
              onAdd: () => _upload(nextType, byType[nextType]),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                28 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status / Attention banner
                  _buildStatusBanner(
                    attention: attention,
                    missing: missing,
                    byType: byType,
                  ),
                  const SizedBox(height: 18),

                  // 2-column responsive document grid
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _grid.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (_, i) => _card(i, byType[_grid[i].$1]),
                  ),
                  const SizedBox(height: 18),

                  // Verification Dashboard card
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: () => showToast(
                        context,
                        'Verification dashboard is coming soon',
                      ),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: C.line),
                          boxShadow: sh(8, 20, .04),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF5DB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.layoutGrid,
                                size: 20,
                                color: C.green,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verification dashboard',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: C.ink,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Status, expiry and renewals in one place',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: C.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required VoidCallback onAdd}) {
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
                  const Expanded(
                    child: Text(
                      'My documents',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Material(
                  //   color: const Color(0x24FFFFFF),
                  //   shape: const CircleBorder(),
                  //   child: InkWell(
                  //     customBorder: const CircleBorder(),
                  //     onTap: onAdd,
                  //     child: const SizedBox(
                  //       width: 42,
                  //       height: 42,
                  //       child: Icon(
                  //         LucideIcons.plus,
                  //         size: 19,
                  //         color: Colors.white,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required List attention,
    required List<String> missing,
    required Map<String, Map<String, dynamic>> byType,
  }) {
    if (attention.isNotEmpty || missing.isNotEmpty) {
      final hasAttention = attention.isNotEmpty;
      final targetType =
          hasAttention ? asString(attention.first['type']) : missing.first;
      final message = hasAttention
          ? '${docLabel(targetType)} ${asString(attention.first['status']) == 'rejected' ? 'was not approved' : asString(attention.first['status']) == 'expired' ? 'has expired' : 'expires soon'}. Update it to keep receiving orders.'
          : '${missing.length} document${missing.length == 1 ? '' : 's'} still to upload: ${missing.map(docLabel).join(', ')}.';

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5D9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF0DC8C)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertTriangle,
              size: 18,
              color: Color(0xFF795109),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 19 / 13,
                  color: Color(0xFF795109),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _upload(targetType, byType[targetType]),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.yellow,
                foregroundColor: const Color(0xFF3A3E34),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                hasAttention ? 'UPDATE' : 'UPLOAD',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5DB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDEBC3)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.shieldCheck,
            size: 18,
            color: C.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _loading
                  ? 'Loading your documents…'
                  : 'All your documents are up to date.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: C.green,
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _upload(type, d),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: p.$2 == pillWarn.bg ? const Color(0xFFF0DC8C) : C.line,
            ),
            boxShadow: sh(8, 20, .04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 82,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: tone,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      top: 14,
                      width: 26,
                      height: 26,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xBFFFFFFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    for (final t in [17.0, 27.0, 36.0])
                      Positioned(
                        left: 46,
                        right: 14,
                        top: t,
                        height: 3.5,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFA9C4A2),
                          ),
                        ),
                      ),
                    if (d == null)
                      const Positioned(
                        right: 10,
                        bottom: 10,
                        child: Icon(
                          LucideIcons.upload,
                          size: 18,
                          color: C.green,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                docLabel(type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: C.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DocsScreen.subFor(d),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: C.muted,
                ),
              ),
              const Spacer(),
              Pill(
                label: p.$1,
                bg: p.$2,
                fg: p.$3,
                dot: p.$3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
