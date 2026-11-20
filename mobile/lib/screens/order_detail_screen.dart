import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'handover_screen.dart';
import 'pickup_qr_screen.dart';
import 'trip_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.state, required this.orderId});

  final AppState state;
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const _steps = [
    ('assigned', 'Order assigned', 'Accept to lock it in'),
    ('accepted', 'Accepted', 'Head to the hub'),
    ('picked_up', 'Picked up', 'Scan every crate’s QR at the hub'),
    ('arrived', 'At doorstep', 'Swipe when you arrive'),
    ('delivered', 'Delivered', 'Customer shares a 4-digit code'),
  ];

  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.state.api.get('/v1/orders/${widget.orderId}');
      if (!mounted) return;
      setState(() {
        _order = res is Map ? Map<String, dynamic>.from(res) : null;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Could not load this order';
      });
    }
  }

  static int _stepIndex(String status) {
    if (status == 'at_pickup') return 1;
    final i = _steps.indexWhere((s) => s.$1 == status);
    return i < 0 ? 0 : i;
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  Future<void> _primary(Map<String, dynamic> o) async {
    final status = asString(o['status']);
    if (status == 'assigned') {
      setState(() => _busy = true);
      try {
        await widget.state.api.post('/v1/orders/${widget.orderId}/accept');
        if (!mounted) return;
        showToast(context, 'Order accepted. Head to the hub.');
        await _load();
      } catch (e) {
        if (mounted) showToast(context, e is ApiException ? e.message : 'Could not accept the order');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } else if (status == 'accepted' || status == 'at_pickup') {
      await _open(PickupQrScreen(state: widget.state, orderId: widget.orderId));
    } else if (status == 'picked_up') {
      await _open(TripScreen(state: widget.state, orderId: widget.orderId));
    } else if (status == 'arrived') {
      await _open(HandOverScreen(state: widget.state, orderId: widget.orderId));
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _navigate(Map<String, dynamic> o, bool toPickup) async {
    final lat = toPickup ? asDouble((o['pickup'] is Map) ? (o['pickup'] as Map)['lat'] : null) : asDouble(o['dropLat']);
    final lng = toPickup ? asDouble((o['pickup'] is Map) ? (o['pickup'] as Map)['lng'] : null) : asDouble(o['dropLng']);
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=two-wheeler');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) showToast(context, 'Could not open Maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    if (_loading && o == null) {
      return const DesignCanvas(child: Center(child: CircularProgressIndicator(color: C.green)));
    }
    if (o == null) {
      return DesignCanvas(
        child: Stack(
          children: [
            const Backdrop(),
            BackBar(title: 'Order'),
            DTxt(_error ?? 'Order unavailable', x: 20, y: 300, w: 372, s: 15, wt: FontWeight.w600, c: C.muted, align: TextAlign.center),
          ],
        ),
      );
    }
    final status = asString(o['status']);
    final current = _stepIndex(status);
    final events = mapList(o['timeline']);
    final crates = mapList(o['crates']);
    final earning = asInt(o['payBasePaise']) + asInt(o['payDistancePaise']) + asInt(o['tipPaise']);
    final delivered = status == 'delivered' || status == 'cancelled';
    final label = switch (status) {
      'assigned' => _busy ? 'ACCEPTING…' : 'ACCEPT ORDER',
      'accepted' || 'at_pickup' => 'SCAN PICKUP QR',
      'picked_up' => 'CONTINUE TRIP',
      'arrived' => 'HAND OVER ORDER',
      _ => 'BACK TO ORDERS',
    };
    String? at(String key) {
      for (final e in events) {
        if (asString(e['status']) == key) return asString(e['at']);
      }
      return null;
    }

    return DesignCanvas(
      child: Stack(
        children: [
          DImg('assets/art/map-details.png', x: 0, y: 0, w: 412, h: 232),
          RoundBtn(icon: LucideIcons.arrowLeft, y: 48, onTap: () => Navigator.of(context).maybePop()),
          Pill(x: 257, y: 60, w: 135, label: statusLabel(status), bg: C.green, fg: const Color(0xFFD6EE75)),
          Pill(
            x: 20,
            y: 190,
            w: 121,
            label: '${asDouble(o['distanceKm'])} km${asInt(o['etaMinutes']) > 0 ? ' · ${asInt(o['etaMinutes'])} min' : ''}',
            bg: Colors.white,
            fg: const Color(0xFF3A4A40),
            dot: const Color(0xFF555555),
          ),
          Positioned(
            left: 259,
            top: 174,
            child: Btn(
              w: 133,
              h: 48,
              fs: 12,
              icon: LucideIcons.navigation,
              label: 'NAVIGATE',
              onTap: () => _navigate(o, current <= 1),
            ),
          ),

          const DTxt('ORDER', x: 20, y: 248, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: .3),
          DTxt('#${asString(o['orderCode'])}', x: 20, y: 261, s: 28, wt: FontWeight.w700, lh: 38),
          const DTxt('You earn', x: 292, y: 247, w: 100, s: 12, lh: 16.8, c: C.muted, align: TextAlign.right),
          DTxt(money(earning), x: 292, y: 266, w: 100, s: 24, wt: FontWeight.w700, lh: 32, c: C.accent, align: TextAlign.right),

          DBox(x: 20, y: 314, w: 372, h: 262, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          DBox(x: 46, y: 346, w: 2, h: (current > 0 ? current : 0) * 48, bg: C.accent),
          DBox(x: 46, y: 346 + current * 48, w: 2, h: (4 - current) * 48 - 10, bg: const Color(0xFFE2EADC)),
          for (var i = 0; i < _steps.length; i++) ...[
            if (i == current && status != 'delivered') ...[
              DBox(x: 36, y: 340 + i * 48 - 11, w: 22, h: 22, r: 11, bg: const Color(0xFFE3ECB5)),
              DBox(
                x: 40,
                y: 340 + i * 48 - 7,
                w: 14,
                h: 14,
                r: 7,
                bg: Colors.white,
                border: Border.all(color: C.green, width: 4),
              ),
            ] else if (i < current || status == 'delivered') ...[
              DBox(x: 40, y: 340 + i * 48 - 7, w: 14, h: 14, r: 7, bg: const Color(0xFFD9ECD9)),
              DBox(x: 43, y: 340 + i * 48 - 4, w: 8, h: 8, r: 4, bg: C.accent),
            ] else
              DBox(
                x: 41,
                y: 340 + i * 48 - 6,
                w: 12,
                h: 12,
                r: 6,
                bg: Colors.white,
                border: Border.all(color: const Color(0xFFC9D6C9), width: 2),
              ),
            DTxt(
              _steps[i].$2,
              x: 69,
              y: 340 + i * 48 - 11,
              s: 14,
              wt: FontWeight.w700,
              lh: 19.6,
              c: (i < current || status == 'delivered' || i == current) ? C.ink : C.muted,
            ),
            DTxt(
              at(_steps[i].$1) != null
                  ? '${_time(at(_steps[i].$1))}${i == 2 ? ' · ${crates.length} crates' : ''}'
                  : _steps[i].$3,
              x: 69,
              y: 340 + i * 48 + 9,
              s: 12,
              lh: 16.8,
              c: C.muted,
            ),
          ],

          DBox(x: 20, y: 592, w: 372, h: 86, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          DBox(
            x: 37,
            y: 611,
            w: 48,
            h: 48,
            r: 24,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9CC42C), Color(0xFF247947)],
            ),
            child: Center(
              child: Text(
                initials(asString(o['customerName'], 'Customer')),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          DTxt(asString(o['customerName'], 'Customer'), x: 97, y: 608, s: 15, wt: FontWeight.w700, lh: 21),
          DTxt(asString(o['dropAddress']), x: 97, y: 628, w: 215, s: 12, lh: 18, c: C.muted, maxLines: 2),
          RoundBtn(
            icon: LucideIcons.phone,
            x: 328,
            y: 611,
            onTap: () => showToast(context, 'Calls connect through a masked number (${asString(o['customerPhoneMasked'])}). Coming soon.'),
          ),

          DBox(x: 20, y: 694, w: 372, h: 67, r: 22, bg: const Color(0xFFFFF5D9), border: Border.all(color: const Color(0xFFF0DC8C))),
          const Positioned(left: 36, top: 709, child: Icon(LucideIcons.messageCircle, size: 16, color: Color(0xFF795109))),
          Positioned(
            left: 65,
            top: 707,
            width: 315,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Customer note: ', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: asString(o['dropInstructions']).isEmpty ? 'No special instructions.' : asString(o['dropInstructions'])),
              ]),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: Color(0xFF795109), height: 20 / 13.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Btn(
            y: 782,
            icon: (status == 'accepted' || status == 'at_pickup') ? LucideIcons.scanLine : null,
            label: label,
            onTap: delivered ? () => Navigator.of(context).maybePop() : (_busy ? null : () => _primary(o)),
          ),
          DTxt(
            'Report a problem with this order',
            x: 20,
            y: 862,
            w: 372,
            s: 14,
            wt: FontWeight.w600,
            c: C.green,
            align: TextAlign.center,
            onTap: () => showToast(context, 'Open Help & support from your profile'),
          ),
        ],
      ),
    );
  }

  static String _time(String? v) {
    final d = parseDate(v);
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'am' : 'pm'}';
  }
}
