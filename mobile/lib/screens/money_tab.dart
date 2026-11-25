import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'transactions_screen.dart';

class MoneyTab extends StatefulWidget {
  const MoneyTab({super.key, required this.state, required this.onOpenTab});

  final AppState state;
  final ValueChanged<int> onOpenTab;

  @override
  State<MoneyTab> createState() => _MoneyTabState();
}

class _MoneyTabState extends State<MoneyTab> {
  String _range = 'today';
  final Map<String, dynamic>? _summary = null;
  bool _loading = true;
  bool _withdraw = false;

  static const _periods = [('Today', 'today'), ('Weekly', 'week'), ('Monthly', 'month'), ('Yearly', 'year')];
  static const _hours = [7, 9, 11, 13, 15, 17, 19];
  static const _hourLabels = ['7a', '9a', '11a', '1p', '3p', '5p', '7p'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Temporary dev mode: no server calls from splash to home screen.
    setState(() => _loading = false);
  }

  String get _tag {
    final now = DateTime.now();
    return switch (_range) {
      'today' => 'TODAY · ${_wd(now.weekday)} ${now.day} ${_mon(now.month)}'.toUpperCase(),
      'week' => 'THIS WEEK',
      'month' => '${_mon(now.month)} ${now.year}'.toUpperCase(),
      _ => 'YEAR ${now.year}',
    };
  }

  static String _wd(int d) => const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d - 1];
  static String _mon(int m) => const ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][m - 1];

  @override
  Widget build(BuildContext context) {
    final d = _summary;
    final base = asInt(d?['basePaise']);
    final dist = asInt(d?['distancePaise']);
    final extras = asInt(d?['extrasPaise']);
    final total = base + dist + extras;
    final widths = [base, dist, extras]
        .map<double>((v) => total == 0 || v == 0 ? 0 : (v / total * 326).clamp(6, 326).toDouble())
        .toList();
    final rawHours = mapList(d?['byHour']);
    final buckets = _hours.map((h) {
      var sum = 0;
      for (final x in rawHours) {
        final hr = asInt(x['hour']);
        if (hr >= h && hr < h + 2) sum += asInt(x['paise']);
      }
      return sum;
    }).toList();
    final peak = buckets.fold<int>(1, (a, b) => b > a ? b : a);
    final hot = buckets.indexOf(buckets.reduce((a, b) => b > a ? b : a));
    final deliveries = asInt(d?['deliveries']);
    final avg = deliveries == 0 ? 0 : ((base + dist) / deliveries).round();
    final withdrawable = asInt(d?['availableBalancePaise']);

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const DTxt('Earnings', x: 20, y: 49, s: 24, wt: FontWeight.w700, lh: 33.6),
          RoundBtn(
            icon: LucideIcons.receipt,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TransactionsScreen(state: widget.state),
            )),
          ),
          DBox(x: 20, y: 102, w: 372, h: 56, r: 28, bg: Colors.white, border: Border.all(color: C.line)),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: 24 + _periods.indexWhere((p) => p.$2 == _range) * 91,
            top: 106,
            width: 91,
            height: 48,
            child: Container(
              decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(24), boxShadow: sh(6, 10, .12)),
            ),
          ),
          for (var i = 0; i < _periods.length; i++)
            Positioned(
              left: 24 + i * 91,
              top: 106,
              width: 91,
              height: 48,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _range = _periods[i].$2);
                  _load();
                },
                child: Center(
                  child: Text(
                    _periods[i].$1,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _periods[i].$2 == _range ? Colors.white : C.muted,
                    ),
                  ),
                ),
              ),
            ),

          DBox(
            x: 20,
            y: 174,
            w: 372,
            h: 202,
            r: 32,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF063A2A), Color(0xFF1F7945)],
            ),
            shadow: sh(18, 28, .2),
          ),
          DTxt(_tag, x: 40, y: 199, s: 11, wt: FontWeight.w700, lh: 15.4, c: const Color(0xFFB6DC45)),
          if (_loading)
            const Pill(x: 278, y: 193, w: 94, label: 'Updating…', bg: Color(0xFF39773F), fg: Color(0xFFDFEE91)),
          DTxt(money(asInt(d?['netPaise'])), x: 40, y: 222, s: 34, wt: FontWeight.w700, lh: 46, c: Colors.white),
          DTxt('$deliveries ${deliveries == 1 ? 'delivery' : 'deliveries'} · after deductions',
              x: 40, y: 273, s: 13, wt: FontWeight.w500, lh: 18.2, c: const Color(0xFFCFE3D0)),
          for (var i = 0; i < 3; i++)
            DBox(
              x: 40 + i * 113.5,
              y: 294,
              w: 105,
              h: 60,
              r: 18,
              bg: const Color(0x1AFFFFFF),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    [deliveries.toString(), money(avg), money(withdrawable)][i],
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ['Deliveries', 'Avg. / delivery', 'Withdrawable'][i],
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDFEEE0)),
                  ),
                ],
              ),
            ),

          DBox(x: 20, y: 391, w: 372, h: 167, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          const DTxt('Today by hour', x: 37, y: 408, s: 16, wt: FontWeight.w700, lh: 22.4),
          const DTxt('7 AM – 9 PM', x: 255, y: 410, w: 120, s: 12, wt: FontWeight.w600, lh: 17, c: C.muted, align: TextAlign.right),
          for (var i = 0; i < buckets.length; i++) ...[
            Positioned(
              left: 37 + i * 49.5,
              top: (518 - (buckets[i] == 0 ? 3 : (buckets[i] / peak * 82).round().clamp(8, 82))).toDouble(),
              width: 42,
              height: buckets[i] == 0 ? 3 : (buckets[i] / peak * 82).round().clamp(8, 82).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: buckets[i] > 0 && i == hot
                      ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9CC42C), Color(0xFF0B5A36)])
                      : null,
                  color: buckets[i] > 0 && i == hot ? null : const Color(0xFFDDE8CF),
                  borderRadius: BorderRadius.circular(((buckets[i] == 0 ? 3 : (buckets[i] / peak * 82).round().clamp(8, 82)) > 10 ? 10 : 2).toDouble()),
                ),
              ),
            ),
            Positioned(
              left: 37 + i * 49.5,
              top: 532,
              width: 42,
              child: Text(
                _hourLabels[i],
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: C.muted),
              ),
            ),
          ],

          DBox(x: 20, y: 572, w: 372, h: 174, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          const DTxt('Every rupee, explained', x: 37, y: 590, s: 16, wt: FontWeight.w700, lh: 22.4),
          if (total == 0)
            DBox(x: 37, y: 619, w: 338, h: 12, r: 6, bg: const Color(0xFFE2EADC))
          else ...[
            DBox(x: 37, y: 619, w: widths[0], h: 12, r: 6, bg: C.green),
            DBox(x: 37 + widths[0] + 3, y: 619, w: widths[1], h: 12, r: 6, bg: const Color(0xFF9CC42C)),
            DBox(x: 37 + widths[0] + widths[1] + 6, y: 619, w: widths[2], h: 12, r: 6, bg: const Color(0xFFE0B021)),
          ],
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) DBox(x: 37, y: 639 + i * 26, w: 338, h: 1, bg: C.tint5),
            DBox(x: 37, y: 647 + i * 26, w: 10, h: 10, r: 3, bg: [C.green, const Color(0xFF9CC42C), const Color(0xFFE0B021)][i]),
            DTxt(['Delivery pay', 'Distance pay', 'Tips & bonuses'][i], x: 59, y: 643 + i * 26, s: 13, lh: 18.2, c: const Color(0xFF333333)),
            DTxt(money([base, dist, extras][i]), x: 235, y: 642 + i * 26, w: 140, s: 14, wt: FontWeight.w700, lh: 20, c: const Color(0xFF222222), align: TextAlign.right),
          ],

          DBox(
            x: 20,
            y: 758,
            w: 372,
            h: 42,
            r: 21,
            bg: const Color(0xFFEEF5DB),
            onTap: () => setState(() => _withdraw = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Next weekly payout · ${d?['nextWeeklyPayoutAt'] == null ? 'Monday' : dateOnly(d!['nextWeeklyPayoutAt'])} · Withdraw now',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3A4A40)),
                ),
              ),
            ),
          ),

          BottomNav(
            active: 'earnings',
            onTap: (k) => widget.onOpenTab({'home': 0, 'orders': 1, 'earnings': 2, 'profile': 3}[k] ?? 2),
          ),

          if (_withdraw)
            Modal(
              onClose: () => setState(() => _withdraw = false),
              child: _PayoutForm(
                state: widget.state,
                balance: withdrawable,
                onDone: () {
                  setState(() => _withdraw = false);
                  showToast(context, 'Instant payout requested');
                  _load();
                },
                onCancel: () => setState(() => _withdraw = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayoutForm extends StatefulWidget {
  const _PayoutForm({required this.state, required this.balance, required this.onDone, required this.onCancel});

  final AppState state;
  final int balance;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  State<_PayoutForm> createState() => _PayoutFormState();
}

class _PayoutFormState extends State<_PayoutForm> {
  late final TextEditingController _amount = TextEditingController(text: rupeesInput(widget.balance));
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rupees = int.tryParse(_amount.text.trim());
    if (rupees == null || rupees < 100) {
      setState(() => _error = 'Minimum withdrawal is ₹100');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.state.api.post(
        '/v1/payouts/instant',
        body: {'amountPaise': rupees * 100},
        headers: {'Idempotency-Key': DateTime.now().microsecondsSinceEpoch.toString()},
      );
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : 'Could not start the payout');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Instant payout',
            style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: C.ink)),
        const SizedBox(height: 6),
        const Text('Money reaches your verified account in minutes.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.muted, height: 19 / 13)),
        const SizedBox(height: 18),
        Field(
          label: 'Amount (₹)',
          controller: _amount,
          keyboard: TextInputType.number,
          h: 52,
        ),
        const SizedBox(height: 10),
        Text('Available: ${money(widget.balance)} · ₹10 instant fee · minimum ₹100',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: C.muted)),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: C.danger)),
        ],
        const SizedBox(height: 16),
        Btn(w: 324, label: _busy ? 'WITHDRAWING…' : 'WITHDRAW', onTap: _busy ? null : _submit),
        const SizedBox(height: 8),
        Btn(w: 324, kind: BtnKind.outline, h: 48, label: 'CANCEL', onTap: _busy ? null : widget.onCancel),
      ],
    );
  }
}
