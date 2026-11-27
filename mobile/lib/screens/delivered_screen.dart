import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'order_detail_screen.dart';
import 'home_shell.dart';

class DeliveredScreen extends StatefulWidget {
  const DeliveredScreen({
    super.key,
    required this.state,
    required this.orderId,
    this.demoOrder,
  });

  final AppState state;
  final String orderId;
  final Map<String, dynamic>? demoOrder;

  bool get isDemo => demoOrder != null;

  @override
  State<DeliveredScreen> createState() => _DeliveredScreenState();
}

class _DeliveredScreenState extends State<DeliveredScreen> {
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _today;
  Map<String, dynamic>? _next;
  bool _loading = true;
  String? _fb;

  @override
  void initState() {
    super.initState();
    if (widget.demoOrder != null) {
      _order = Map<String, dynamic>.from(widget.demoOrder!);
      _today = {
        'deliveries': 2,
        'netPaise': 17000,
        'availableBalancePaise': 17000,
      };
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.isDemo) {
      if (!mounted) return;
      setState(() {
        _order = Map<String, dynamic>.from(widget.demoOrder!);
        _today = {
          'deliveries': 2,
          'netPaise': 17000,
          'availableBalancePaise': 17000,
        };
        _loading = false;
      });
      return;
    }

    try {
      final res = await Future.wait([
        widget.state.api.get('/v1/orders/${widget.orderId}'),
        widget.state.api.get('/v1/earnings/summary', query: {'range': 'today'}),
        widget.state.api.get('/v1/orders', query: {'tab': 'active'}),
      ]);
      if (!mounted) return;
      setState(() {
        _order = res[0] is Map ? Map<String, dynamic>.from(res[0] as Map) : null;
        _today = res[1] is Map ? Map<String, dynamic>.from(res[1] as Map) : null;
        final active = mapList(res[2]);
        _next = active.isNotEmpty ? active.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not wrap up this order');
    }
  }

  Future<void> _feedback(String key) async {
    setState(() => _fb = key);
    if (widget.isDemo) {
      showToast(context, 'Thanks for the demo feedback');
      return;
    }
    try {
      await widget.state.api.post('/v1/orders/${widget.orderId}/feedback', body: {'dropOffEase': key});
      if (mounted) showToast(context, 'Thanks for the feedback');
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not save feedback');
    }
  }

  void _backToOrders() {
    // Return to the Orders tab after completing a delivery.
    widget.state.setHomeTabIndex(1);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeShell(state: widget.state),
      ),
      (route) => false,
    );
  }

  void _done() {
    // Return to the Home tab.
    widget.state.setHomeTabIndex(0);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeShell(state: widget.state),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    if (_loading && o == null) {
      return const DesignCanvas(child: Center(child: CircularProgressIndicator(color: C.green)));
    }

    final deliveredAt = mapList(o?['timeline']).where((e) => asString(e['status']) == 'delivered').toList();
    final pickedAt = mapList(o?['timeline']).where((e) => asString(e['status']) == 'picked_up').toList();
    final dAt = deliveredAt.isEmpty ? null : parseDate(deliveredAt.first['at']);
    final pAt = pickedAt.isEmpty ? null : parseDate(pickedAt.first['at']);
    final tripMin = (dAt != null && pAt != null)
        ? dAt.difference(pAt).inMinutes.clamp(1, 100000)
        : (widget.isDemo ? 2 : null);
    final earning = asInt(o?['payBasePaise']) + asInt(o?['payDistancePaise']) + asInt(o?['tipPaise']);
    final today = _today;
    final tip = asInt(o?['tipPaise']);

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          DImg('assets/art/delivered.png', x: 96, y: 46, w: 228, h: 190),
          Pill(
            x: 121,
            y: 250,
            w: 170,
            label: 'Delivered · ${deliveredAt.isEmpty ? (widget.isDemo ? _time(DateTime.now().toIso8601String()) : '') : _time(deliveredAt.first['at'])}',
            bg: pillOk.bg,
            fg: pillOk.fg,
            dot: pillOk.fg,
          ),
          Positioned(
            left: 10,
            top: 280,
            width: 392,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Fresh, and '),
                TextSpan(
                  text: 'right on time',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF4F8A25), Color(0xFF8C7E0C)],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                  ),
                ),
                const TextSpan(text: '.'),
              ]),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 29,
                fontWeight: FontWeight.w700,
                height: 40.6 / 29,
                color: C.ink,
              ),
            ),
          ),
          DTxt(
            '#${asString(o?['orderCode'])} handed to ${asString(o?['customerName'])}${tripMin != null ? ' · $tripMin min trip' : ''}',
            x: 20,
            y: 331,
            w: 372,
            s: 13.5,
            wt: FontWeight.w500,
            lh: 20,
            c: C.muted,
            align: TextAlign.center,
          ),
          DBox(x: 20, y: 372, w: 372, h: 187, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          DBox(
            x: 39,
            y: 371,
            w: 334,
            h: 4,
            r: 2,
            gradient: const LinearGradient(colors: [Color(0xFF247947), Color(0xFF9CC42C), Color(0xFFF8D92F)]),
          ),
          const DTxt('You earned', x: 37, y: 405, s: 13, wt: FontWeight.w500, lh: 18.2, c: C.muted),
          DTxt('+${money(earning)}', x: 175, y: 393, w: 200, s: 26, wt: FontWeight.w700, lh: 36, c: C.accent, align: TextAlign.right),
          const DTxt('Base pay', x: 37, y: 448, s: 13, wt: FontWeight.w500, lh: 18.2, c: C.muted),
          DTxt(money(asInt(o?['payBasePaise'])), x: 175, y: 447, w: 200, s: 14, wt: FontWeight.w700, lh: 20, c: const Color(0xFF222222), align: TextAlign.right),
          DTxt(
            'Distance pay · ${asDouble(o?['distanceKm'])} km${tip > 0 ? ' · tip ${money(tip)}' : ''}',
            x: 37,
            y: 481,
            w: 130,
            s: 13,
            wt: FontWeight.w500,
            lh: 18.2,
            c: C.muted,
          ),
          DTxt(money(asInt(o?['payDistancePaise']) + tip), x: 175, y: 480, w: 200, s: 14, wt: FontWeight.w700, lh: 20, c: const Color(0xFF222222), align: TextAlign.right),
          DBox(x: 37, y: 511, w: 338, h: 1, bg: C.tint5),
          const DTxt('Today so far', x: 37, y: 525, s: 13, wt: FontWeight.w500, lh: 18.2, c: C.muted),
          DTxt(
            today == null
                ? '…'
                : '${asInt(today['deliveries'])} ${asInt(today['deliveries']) == 1 ? 'delivery' : 'deliveries'} · ${money(asInt(today['netPaise']))}',
            x: 175,
            y: 524,
            w: 200,
            s: 14,
            wt: FontWeight.w700,
            lh: 20,
            c: const Color(0xFF222222),
            align: TextAlign.right,
          ),
          DBox(x: 20, y: 578, w: 372, h: 69, r: 22, bg: const Color(0xFFEEF5DB), border: Border.all(color: const Color(0xFFDFEBC3))),
          const DTxt('Available to withdraw', x: 37, y: 594, s: 14, wt: FontWeight.w700, lh: 20),
          DTxt(money(asInt(today?['availableBalancePaise'])), x: 235, y: 593, w: 140, s: 14, wt: FontWeight.w700, lh: 20, c: C.accent, align: TextAlign.right),
          const DTxt('Weekly payout every Monday, or withdraw instantly.', x: 37, y: 617, w: 338, s: 12, lh: 17, c: C.muted),
          const DTxt('How was the drop-off?', x: 20, y: 663, s: 13, wt: FontWeight.w700, lh: 18.2),
          for (var i = 0; i < 3; i++)
            Positioned(
              left: [20, 132, 240][i].toDouble(),
              top: 689,
              child: GestureDetector(
                onTap: () => _feedback(['smooth', 'hard_to_find', 'long_wait'][i]),
                child: IntrinsicWidth(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _fb == ['smooth', 'hard_to_find', 'long_wait'][i] ? C.green : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: _fb == ['smooth', 'hard_to_find', 'long_wait'][i] ? null : Border.all(color: C.line),
                    ),
                    child: Text(
                      ['Smooth', 'Hard to find', 'Long wait'][i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _fb == ['smooth', 'hard_to_find', 'long_wait'][i] ? Colors.white : C.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Btn(y: 781, label: 'BACK TO ORDERS', onTap: _backToOrders),
          DTxt('Back to home', x: 20, y: 842, w: 372, s: 14, wt: FontWeight.w600, c: C.green, align: TextAlign.center, onTap: _done),
        ],
      ),
    );
  }

  static String _time(dynamic v) {
    final d = parseDate(v);
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'am' : 'pm'}';
  }
}

