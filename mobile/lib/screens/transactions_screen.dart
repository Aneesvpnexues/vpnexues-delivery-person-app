import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _cats = [
    ('All', 'all'),
    ('Earnings', 'earnings'),
    ('Payouts', 'payouts'),
    ('Bonuses', 'bonuses'),
    ('Deductions', 'deductions'),
  ];

  final _q = TextEditingController();
  String _cat = 'all';
  String _search = '';
  List<Map<String, dynamic>> _items = [];
  int _monthNet = 0;
  int _paidOut = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        widget.state.api.get('/v1/transactions', query: {
          'filter': _cat,
          'limit': '100',
          if (_search.isNotEmpty) 'search': _search,
        }),
        widget.state.api.get('/v1/earnings/summary', query: {'range': 'month'}),
        widget.state.api.get('/v1/payouts'),
      ]);
      if (!mounted) return;
      final items = res[0] is Map ? mapList((res[0] as Map)['items']) : mapList(res[0]);
      final month = res[1] is Map ? Map<String, dynamic>.from(res[1] as Map) : const <String, dynamic>{};
      final payouts = mapList(res[2]);
      final now = DateTime.now();
      final paid = payouts
          .where((p) {
            final d = parseDate(p['requestedAt']);
            return d != null &&
                d.year == now.year &&
                d.month == now.month &&
                asString(p['status']) != 'failed';
          })
          .fold<int>(0, (a, p) => a + asInt(p['amountPaise']));
      setState(() {
        _items = items;
        _monthNet = asInt(month['netPaise']);
        _paidOut = paid;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load transactions');
    }
  }

  static const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context) {
    final monthName = _monthNames[DateTime.now().month - 1];
    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'Transactions'),
          RoundBtn(
            icon: LucideIcons.download,
            x: 344,
            y: 41,
            onTap: () => showToast(context, 'Statement downloads are coming soon'),
          ),
          Positioned(
            left: 20,
            top: 103,
            width: 372,
            height: 55,
            child: TextField(
              controller: _q,
              onSubmitted: (v) {
                setState(() => _search = v.trim());
                _load();
              },
              onChanged: (v) {
                if (v.isEmpty && _search.isNotEmpty) {
                  setState(() => _search = '');
                  _load();
                }
              },
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: C.ink),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search order ID or UTR',
                hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: C.muted),
                prefixIcon: const Icon(LucideIcons.search, size: 17, color: C.muted),
                prefixIconConstraints: const BoxConstraints(minWidth: 46),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.green)),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 173,
            child: Row(
              children: [
                for (final c in _cats)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _cat = c.$2);
                        _load();
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12.5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _cat == c.$2 ? C.green : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: _cat == c.$2 ? null : Border.all(color: C.line),
                        ),
                        child: Text(
                          c.$1,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _cat == c.$2 ? Colors.white : C.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < 2; i++)
            DBox(
              x: 20 + i * 191.0,
              y: 227,
              w: 181,
              h: 71,
              r: 22,
              bg: Colors.white,
              border: Border.all(color: C.line),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ['In · $monthName', 'Paid out · $monthName'][i],
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: C.muted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [money(_monthNet), money(_paidOut)][i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: i == 0 ? C.accent : C.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const DTxt('TRANSACTIONS', x: 20, y: 313, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          Positioned(
            left: 20,
            top: 340,
            width: 372,
            height: 470,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _items.length + (_items.isEmpty ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (_items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      _loading
                          ? 'Loading…'
                          : _search.isNotEmpty
                              ? 'No transactions match your search.'
                              : 'No transactions yet. Earnings appear here after each delivery.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.muted, height: 20 / 13),
                    ),
                  );
                }
                return _TxnRow(txn: _items[i]);
              },
            ),
          ),
          Positioned(
            left: 20,
            top: 823,
            child: Btn(
              kind: BtnKind.outline,
              icon: LucideIcons.download,
              label: 'DOWNLOAD STATEMENT (PDF)',
              fs: 13,
              onTap: () => showToast(context, 'Statement downloads are coming soon'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn});

  final Map<String, dynamic> txn;

  @override
  Widget build(BuildContext context) {
    final type = asString(txn['type']);
    final amount = asInt(txn['amountPaise']);
    final neg = amount < 0;
    final (icon, bg, fg) = switch (type) {
      'delivery_base' || 'delivery_distance' => (LucideIcons.package, const Color(0xFFEEF5DB), C.green),
      'tip' || 'bonus' || 'incentive' => (LucideIcons.star, const Color(0xFFFFF3BF), const Color(0xFF825605)),
      'payout' => (LucideIcons.arrowUpRight, const Color(0xFFE0EFF3), const Color(0xFF145B73)),
      _ => (LucideIcons.minus, const Color(0xFFFDE0DD), const Color(0xFFC92526)),
    };
    final utr = asString(txn['utr']);
    final payoutStatus = asString(txn['payoutStatus']);
    final sub = '${dateOnly(txn['createdAt'])} · ${_time(txn['createdAt'])}'
        '${utr.isNotEmpty ? ' · UTR $utr' : ''}'
        '${payoutStatus.isNotEmpty ? ' · $payoutStatus' : ''}';

    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Tile(s: 44, bg: bg, icon: icon, c: fg, isize: 18),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asString(txn['description'], ledgerLabel(type)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: C.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${amount >= 0 ? '+' : '−'}${money(amount.abs())}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: neg ? (type == 'payout' ? C.ink : const Color(0xFFC92526)) : C.accent,
            ),
          ),
        ],
      ),
    );
  }

  String _time(dynamic v) {
    final d = parseDate(v);
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'am' : 'pm'}';
  }
}
