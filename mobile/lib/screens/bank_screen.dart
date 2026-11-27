import 'dart:math' as math;

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
  List _methods = [];
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
      final docs = res[1] is Map
          ? Map<String, dynamic>.from(res[1] as Map)
          : const <String, dynamic>{};
      final panList = mapList(docs['documents'])
          .where((d) => asString(d['type']) == 'pan')
          .toList();
      setState(() {
        _methods = mapList(res[0]);
        _pan = panList.isNotEmpty ? panList.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(
        context,
        e is ApiException ? e.message : 'Could not load payout methods',
      );
    }
  }

  static String methodName(Map<String, dynamic> m) =>
      asString(m['type']) == 'upi'
          ? asString(m['upiVpa'])
          : '${asString(m['bankName'], 'Bank')} •• ${asString(m['accountLast4'])}';

  Future<void> _makePrimary(Map<String, dynamic> m) async {
    try {
      await widget.state.api
          .put('/v1/payout-methods/${asString(m['id'])}/primary');
      if (!mounted) return;
      setState(() => _pick = null);
      showToast(context, '${methodName(m)} is now your primary account');
      _load();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not update the account',
        );
      }
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
      if (mounted) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not remove the account',
        );
      }
    }
  }

  Future<void> _add(String mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPayoutScreen(state: widget.state, mode: mode),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final primary = _methods.where((m) => asBool(m['isPrimary'])).toList();
    final main = primary.isNotEmpty
        ? primary.first
        : (_methods.isNotEmpty ? _methods.first : null);
    final others = _methods.where((m) => m != main).toList();
    final ordered = main == null ? [] : [main, ...others];
    final pan = _pan;

    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
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
                      // Primary payout card
                      _buildPrimaryCard(main),
                      const SizedBox(height: 18),

                      // Saved payout methods list
                      if (ordered.isNotEmpty) ...[
                        for (var i = 0; i < ordered.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _buildMethodTile(ordered[i]),
                        ],
                        const SizedBox(height: 18),
                      ],

                      // Payout info & settings card
                      Container(
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
                                InkWell(
                                  onTap: () => showToast(
                                    context,
                                    'Instant withdrawals are available in the Earnings tab',
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 15,
                                    ),
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Payout schedule',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: C.ink,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Every Monday · automatic',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  color: C.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Withdraw',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: C.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: C.tint5,
                                ),
                                InkWell(
                                  onTap: () => showToast(
                                    context,
                                    pan == null
                                        ? 'Upload your PAN in My documents'
                                        : 'PAN ${asString(pan['numberMasked'], '')} is ${asString(pan['status']).replaceAll('_', ' ')}',
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 15,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'PAN linked for TDS',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: C.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                pan == null
                                                    ? 'Add your PAN in Documents'
                                                    : '${asString(pan['numberMasked'], 'PAN')} · ${asString(pan['status']).replaceAll('_', ' ')}',
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
                                        if (pan != null) ...[
                                          const SizedBox(width: 10),
                                          Pill(
                                            label: asString(pan['status']) ==
                                                    'verified'
                                                ? 'Linked'
                                                : 'In review',
                                            bg: asString(pan['status']) ==
                                                    'verified'
                                                ? pillOk.bg
                                                : pillWarn.bg,
                                            fg: asString(pan['status']) ==
                                                    'verified'
                                                ? pillOk.fg
                                                : pillWarn.fg,
                                            dot: asString(pan['status']) ==
                                                    'verified'
                                                ? pillOk.fg
                                                : pillWarn.fg,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: C.tint5,
                                ),
                                InkWell(
                                  onTap: () => showToast(
                                    context,
                                    'View full payout history in the Earnings tab',
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 15,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Payout history',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: C.ink,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Every payout with its bank reference',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  color: C.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          LucideIcons.chevronRight,
                                          size: 16,
                                          color: Color(0xFF8A988F),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons
                      _OutlineActionButton(
                        icon: LucideIcons.plus,
                        label: 'ADD BANK ACCOUNT',
                        onTap: () => _add('bank'),
                      ),
                      const SizedBox(height: 12),
                      _OutlineActionButton(
                        icon: LucideIcons.zap,
                        label: 'ADD UPI ID',
                        onTap: () => _add('upi'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_pick != null)
            Modal(
              onClose: () => setState(() => _pick = null),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    methodName(_pick!),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: C.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    asBool(_pick!['isPrimary'])
                        ? 'This is your primary payout account.'
                        : 'Make this your primary account, or remove it.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: C.muted,
                      height: 19 / 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!asBool(_pick!['isPrimary'])) ...[
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _makePrimary(_pick!),
                        icon: const Icon(LucideIcons.star, size: 17),
                        label: const Text(
                          'MAKE PRIMARY',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: asBool(_pick!['isPrimary'])
                          ? () => showToast(
                                context,
                                'Choose another primary account first',
                              )
                          : () => _remove(_pick!),
                      icon: const Icon(LucideIcons.trash2, size: 17),
                      label: Text(
                        asBool(_pick!['isPrimary'])
                            ? 'PRIMARY CAN’T BE REMOVED'
                            : 'REMOVE',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: asBool(_pick!['isPrimary'])
                            ? const Color(0xFFE7ECE6)
                            : const Color(0xFFC92526),
                        foregroundColor: asBool(_pick!['isPrimary'])
                            ? C.muted
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                      'Bank & UPI',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryCard(Map<String, dynamic>? main) {
    final isUpi = main != null && asString(main['type']) == 'upi';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A4A30), Color(0xFF2F7A3B), Color(0xFF479440)],
        ),
        boxShadow: sh(18, 28, .2),
      ),
      child: main != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isUpi
                            ? 'UPI'
                            : asString(main['bankName'], 'Bank account'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Pill(
                      label: 'Primary',
                      bg: C.yellow,
                      fg: const Color(0xFF3A3E34),
                      dot: C.green,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: 40,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF3D721), Color(0xFFC4A300)],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isUpi
                      ? asString(main['upiVpa'])
                      : '••••  ••••  ${asString(main['accountLast4'])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isUpi ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: isUpi ? 0 : 3.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isUpi
                            ? (asString(main['verification']) == 'verified'
                                ? 'VERIFIED'
                                : 'VERIFICATION PENDING')
                            : '${asString(main['accountHolderName']).toUpperCase()} · ${asString(main['accountType']).toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFDFEEE0),
                        ),
                      ),
                    ),
                    if (!isUpi && asString(main['ifsc']).isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        asString(main['ifsc']),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFDFEEE0),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loading ? 'Loading…' : 'No payout account yet',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add a bank account or UPI ID to receive your weekly and instant payouts.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 19 / 13,
                    color: Color(0xFFDFEEE0),
                  ),
                ),
                if (!_loading) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _add('bank'),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text(
                      'ADD ACCOUNT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.yellow,
                      foregroundColor: const Color(0xFF3A3E34),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildMethodTile(Map<String, dynamic> m) {
    final verified = asString(m['verification']) == 'verified';
    final failed = asString(m['verification']) == 'failed';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => setState(() => _pick = m),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child: Icon(
                  asString(m['type']) == 'upi'
                      ? LucideIcons.zap
                      : LucideIcons.landmark,
                  size: 19,
                  color: C.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      methodName(m),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: C.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${asString(m['type']) == 'upi' ? 'UPI' : 'Bank'} · added ${dateOnly(m['createdAt'])}${asBool(m['isPrimary']) ? ' · primary' : asBool(m['isBackup']) ? ' · backup' : ''}',
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
              const SizedBox(width: 8),
              Pill(
                label: verified ? 'Verified' : failed ? 'Failed' : 'Pending',
                bg: verified
                    ? pillOk.bg
                    : failed
                        ? pillBad.bg
                        : pillWarn.bg,
                fg: verified
                    ? pillOk.fg
                    : failed
                        ? pillBad.fg
                        : pillWarn.fg,
                dot: verified
                    ? pillOk.fg
                    : failed
                        ? pillBad.fg
                        : pillWarn.fg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: C.green),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: C.green,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: C.line, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}