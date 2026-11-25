import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'add_payout_screen.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key, required this.state});

  final AppState state;

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  List<Map<String, dynamic>> _methods = [];
  Map<String, dynamic>? _pan;
  bool _loading = true;
  Map<String, dynamic>? _pick;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        widget.state.api.get('/v1/payout-methods'),
        widget.state.api.get('/v1/documents'),
      ]);
      if (!mounted) return;
      final docs = res[1] is Map ? Map<String, dynamic>.from(res[1] as Map) : const <String, dynamic>{};
      setState(() {
        _methods = mapList(res[0]);
        _pan = mapList(docs['documents']).where((d) => asString(d['type']) == 'pan').toList().firstOrNull;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load payout methods');
    }
  }

  static String methodName(Map<String, dynamic> m) => asString(m['type']) == 'upi'
      ? asString(m['upiVpa'])
      : '${asString(m['bankName'], 'Bank')} • • ${asString(m['accountLast4'])}';

  Future<void> _makePrimary(Map<String, dynamic> m) async {
    try {
      await widget.state.api.put('/v1/payout-methods/${asString(m['id'])}/primary');
      if (!mounted) return;
      setState(() => _pick = null);
      showToast(context, '${methodName(m)} is now your primary account');
      _load();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not update the account');
    }
  }

  Future<void> _remove(Map<String, dynamic> m) async {
    try {
      await widget.state.api.delete('/v1/payout-methods/${asString(m['id'])}');
      if (!mounted) return;
      setState(() => _pick = null);
      showToast(context, 'Payout method removed');
      _load();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not remove the account');
    }
  }

  Future<void> _add(String mode) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddPayoutScreen(state: widget.state, mode: mode),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final primary = _methods.where((m) => asBool(m['isPrimary'])).toList();
    final main = primary.isNotEmpty ? primary.first : (_methods.isNotEmpty ? _methods.first : null);
    final others = _methods.where((m) => m != main).toList();
    final ordered = main == null ? <Map<String, dynamic>>[] : [main, ...others];
    final pan = _pan;

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'Bank & UPI'),
          DBox(
            x: 20,
            y: 104,
            w: 372,
            h: 200,
            r: 28,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A4A30), Color(0xFF2F7A3B), Color(0xFF479440)],
            ),
            shadow: sh(18, 28, .2),
          ),
          if (main != null) ...[
            DTxt(
              asString(main['type']) == 'upi' ? 'UPI' : asString(main['bankName'], 'Bank account'),
              x: 40,
              y: 122,
              w: 240,
              s: 17,
              wt: FontWeight.w700,
              lh: 24,
              c: Colors.white,
            ),
            Pill(x: 289, y: 124, w: 83, label: 'Primary', bg: C.yellow, fg: const Color(0xFF3A3E34), dot: C.green),
            DBox(
              x: 40,
              y: 167,
              w: 40,
              h: 30,
              r: 8,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF3D721), Color(0xFFC4A300)],
              ),
            ),
            DTxt(
              asString(main['type']) == 'upi' ? asString(main['upiVpa']) : '••••  ••••  ${asString(main['accountLast4'])}',
              x: 40,
              y: 206,
              w: 330,
              s: asString(main['type']) == 'upi' ? 18 : 22,
              wt: FontWeight.w700,
              lh: 30,
              c: Colors.white,
              ls: asString(main['type']) == 'upi' ? 0 : 5,
            ),
            DTxt(
              asString(main['type']) == 'upi'
                  ? (asString(main['verification']) == 'verified' ? 'VERIFIED' : 'VERIFICATION PENDING')
                  : '${asString(main['accountHolderName']).toUpperCase()} · ${asString(main['accountType']).toUpperCase()}',
              x: 40,
              y: 258,
              w: 200,
              s: 12,
              wt: FontWeight.w500,
              lh: 16.8,
              c: const Color(0xFFDFEEE0),
            ),
            DTxt(asString(main['ifsc']), x: 232, y: 258, w: 140, s: 12, wt: FontWeight.w500, lh: 16.8, c: const Color(0xFFDFEEE0), align: TextAlign.right),
          ] else ...[
            DTxt(_loading ? 'Loading…' : 'No payout account yet',
                x: 40, y: 128, w: 330, s: 20, wt: FontWeight.w700, lh: 28, c: Colors.white),
            const DTxt('Add a bank account or UPI ID to receive your weekly and instant payouts.',
                x: 40, y: 164, w: 330, s: 13, lh: 19, c: Color(0xFFDFEEE0)),
            if (!_loading)
              Positioned(
                left: 40,
                top: 232,
                child: Btn(
                  w: 190,
                  h: 44,
                  fs: 12,
                  kind: BtnKind.yellow,
                  icon: LucideIcons.plus,
                  label: 'ADD ACCOUNT',
                  onTap: () => _add('bank'),
                ),
              ),
          ],

          if (ordered.isNotEmpty)
            Positioned(
              left: 20,
              top: 322,
              width: 372,
              height: 160,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: ordered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final m = ordered[i];
                  final verified = asString(m['verification']) == 'verified';
                  final failed = asString(m['verification']) == 'failed';
                  return GestureDetector(
                    onTap: () => setState(() => _pick = m),
                    child: Container(
                      height: 75,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: C.line),
                        boxShadow: sh(8, 20, .04),
                      ),
                      child: Row(
                        children: [
                          Tile(s: 44, icon: asString(m['type']) == 'upi' ? LucideIcons.zap : LucideIcons.landmark, isize: 19),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(methodName(m),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink)),
                                Text(
                                  '${asString(m['type']) == 'upi' ? 'UPI' : 'Bank'} · added ${dateOnly(m['createdAt'])}${asBool(m['isPrimary']) ? ' · primary' : asBool(m['isBackup']) ? ' · backup' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Pill(
                            label: verified ? 'Verified' : failed ? 'Failed' : 'Pending',
                            bg: verified ? pillOk.bg : failed ? pillBad.bg : pillWarn.bg,
                            fg: verified ? pillOk.fg : failed ? pillBad.fg : pillWarn.fg,
                            dot: verified ? pillOk.fg : failed ? pillBad.fg : pillWarn.fg,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          DBox(x: 20, y: 494, w: 372, h: 216, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          DTxt('Payout schedule', x: 36, y: 509, s: 15, wt: FontWeight.w700, lh: 21),
          const DTxt('Every Monday · automatic', x: 36, y: 532, w: 250, s: 12, lh: 16.8, c: C.muted),
          DTxt('Withdraw', x: 300, y: 522, w: 75, s: 14, wt: FontWeight.w700, lh: 20, c: C.green, align: TextAlign.right),
          DBox(x: 36, y: 566, w: 339, h: 1, bg: C.tint5),
          DTxt('PAN linked for TDS', x: 36, y: 580, s: 15, wt: FontWeight.w700, lh: 21),
          DTxt(
            pan == null ? 'Add your PAN in Documents' : '${asString(pan['numberMasked'], 'PAN')} · ${asString(pan['status']).replaceAll('_', ' ')}',
            x: 36,
            y: 603,
            w: 250,
            s: 12,
            lh: 16.8,
            c: C.muted,
          ),
          if (pan != null)
            Pill(
              x: 290,
              y: 590,
              w: 85,
              label: asString(pan['status']) == 'verified' ? 'Linked' : 'In review',
              bg: asString(pan['status']) == 'verified' ? pillOk.bg : pillWarn.bg,
              fg: asString(pan['status']) == 'verified' ? pillOk.fg : pillWarn.fg,
              dot: asString(pan['status']) == 'verified' ? pillOk.fg : pillWarn.fg,
            ),
          DBox(x: 36, y: 637, w: 339, h: 1, bg: C.tint5),
          const DTxt('Payout history', x: 36, y: 651, s: 15, wt: FontWeight.w700, lh: 21),
          const DTxt('Every payout with its bank reference', x: 36, y: 674, w: 250, s: 12, lh: 16.8, c: C.muted),
          const Positioned(left: 360, top: 664, child: Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF8A988F))),

          Positioned(
            left: 20,
            top: 760,
            child: Btn(w: 372, kind: BtnKind.outline, icon: LucideIcons.plus, label: 'ADD BANK ACCOUNT', onTap: () => _add('bank')),
          ),
          Positioned(
            left: 20,
            top: 830,
            child: Btn(w: 372, kind: BtnKind.outline, icon: LucideIcons.zap, label: 'ADD UPI ID', onTap: () => _add('upi')),
          ),

          if (_pick != null)
            Modal(
              onClose: () => setState(() => _pick = null),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(methodName(_pick!),
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: C.ink)),
                  const SizedBox(height: 6),
                  Text(
                    asBool(_pick!['isPrimary']) ? 'This is your primary payout account.' : 'Make this your primary account, or remove it.',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.muted, height: 19 / 13),
                  ),
                  const SizedBox(height: 18),
                  if (!asBool(_pick!['isPrimary'])) ...[
                    Btn(w: 324, h: 48, icon: LucideIcons.star, label: 'MAKE PRIMARY', onTap: () => _makePrimary(_pick!)),
                    const SizedBox(height: 10),
                  ],
                  Btn(
                    w: 324,
                    h: 48,
                    kind: asBool(_pick!['isPrimary']) ? BtnKind.muted : BtnKind.danger,
                    icon: LucideIcons.trash2,
                    label: asBool(_pick!['isPrimary']) ? 'PRIMARY CAN’T BE REMOVED' : 'REMOVE',
                    onTap: asBool(_pick!['isPrimary'])
                        ? () => showToast(context, 'Choose another primary account first')
                        : () => _remove(_pick!),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
