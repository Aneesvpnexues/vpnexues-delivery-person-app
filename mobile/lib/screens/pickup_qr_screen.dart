import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'trip_screen.dart';

class PickupQrScreen extends StatefulWidget {
  const PickupQrScreen({
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
  State<PickupQrScreen> createState() => _PickupQrScreenState();
}

class _PickupQrScreenState extends State<PickupQrScreen> {
  static const _qr = ['###.#.##', '#.##.##.', '###..###', '.......#', '.#....##', '###..#.#', '#.##.#.#', '###.#.##'];

  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _busy = false;
  bool _torch = false;
  String? _manual;
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.demoOrder != null) {
      _order = _makeDemoPickupOrder(widget.demoOrder!);
      _loading = false;
    } else {
      _load();
    }
  }

  Map<String, dynamic> _makeDemoPickupOrder(Map<String, dynamic> source) {
    final local = Map<String, dynamic>.from(source);
    local['crates'] = [
      {
        'position': 1,
        'label': 'Vegetables',
        'weightGrams': 4000,
        'scanned': false,
        'trialQr': 'DEMO-VEG-001',
      },
      {
        'position': 2,
        'label': 'Fruits & greens',
        'weightGrams': 2500,
        'scanned': false,
        'trialQr': 'DEMO-FRUITS-002',
      },
    ];
    local['pickup'] = {
      'name': 'Anna Nagar Hub',
      'lat': 0,
      'lng': 0,
    };
    return local;
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.isDemo) {
      if (!mounted) return;
      setState(() {
        _order = _makeDemoPickupOrder(widget.demoOrder!);
        _loading = false;
      });
      return;
    }

    try {
      final res = await widget.state.api.get('/v1/orders/${widget.orderId}');
      if (!mounted) return;
      setState(() {
        _order = res is Map ? Map<String, dynamic>.from(res) : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load crates');
    }
  }

  Future<void> _scan(String code) async {
    if (widget.isDemo) {
      final crates = mapList(_order?['crates'])
          .map((crate) => Map<String, dynamic>.from(crate))
          .toList();
      final nextIndex = crates.indexWhere((crate) => !asBool(crate['scanned']));
      if (nextIndex < 0) {
        showToast(context, 'All crates are verified.');
        return;
      }

      final expectedCode = asString(crates[nextIndex]['trialQr']);
      if (code.trim().toUpperCase() != expectedCode.toUpperCase()) {
        showToast(context, 'That crate code does not match the demo crate.');
        return;
      }

      crates[nextIndex]['scanned'] = true;
      if (!mounted) return;
      setState(() {
        _order = {
          ...?_order,
          'crates': crates,
        };
        _manual = null;
      });
      _code.clear();
      showToast(context, 'Crate ${nextIndex + 1} of ${crates.length} verified.');
      return;
    }

    setState(() => _busy = true);
    try {
      final res = await widget.state.api.post('/v1/orders/${widget.orderId}/crates/scan', body: {'qrCode': code.trim()});
      if (!mounted) return;
      final crate = res is Map && res['crate'] is Map ? Map<String, dynamic>.from(res['crate'] as Map) : const <String, dynamic>{};
      showToast(context, 'Crate ${asInt(crate['position'])} of ${asInt(res is Map ? res['total'] : null)} verified · ${asString(crate['label'])}');
      setState(() => _manual = null);
      _code.clear();
      await _load();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not verify this crate');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tapScan() {
    if (widget.isDemo) {
      final crates = mapList(_order?['crates'])
          .map((crate) => Map<String, dynamic>.from(crate))
          .toList();
      final nextIndex = crates.indexWhere((crate) => !asBool(crate['scanned']));
      if (nextIndex < 0) {
        showToast(context, 'All crates are scanned');
        return;
      }
      crates[nextIndex]['scanned'] = true;
      setState(() {
        _order = {
          ...?_order,
          'crates': crates,
        };
      });
      showToast(context, 'Crate ${nextIndex + 1} of ${crates.length} verified.');
      return;
    }

    final crates = mapList(_order?['crates']);
    final next = crates.where((c) => !asBool(c['scanned'])).toList();
    if (next.isEmpty) {
      showToast(context, 'All crates are scanned');
      return;
    }
    final qr = asString(next.first['trialQr']);
    if (qr.isNotEmpty) {
      _scan(qr);
    } else {
      setState(() => _manual = '');
    }
  }

  Future<void> _confirm() async {
    if (widget.isDemo) {
      final demoTripOrder = Map<String, dynamic>.from(_order!);
      demoTripOrder['status'] = 'picked_up';
      final timeline = mapList(demoTripOrder['timeline'])
          .map((event) => Map<String, dynamic>.from(event))
          .toList();
      timeline.add({
        'status': 'picked_up',
        'at': DateTime.now().toIso8601String(),
      });
      demoTripOrder['timeline'] = timeline;

      if (!mounted) return;
      showToast(context, 'Demo pickup confirmed. Trip started.');
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TripScreen(
            state: widget.state,
            orderId: widget.orderId,
            demoOrder: demoTripOrder,
          ),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.state.api.post('/v1/orders/${widget.orderId}/pickup', body: const <String, dynamic>{});
      if (!mounted) return;
      showToast(context, 'Pickup confirmed. Trip started.');
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TripScreen(state: widget.state, orderId: widget.orderId),
      ));
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not confirm pickup');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    if (_loading && o == null) {
      return const DesignCanvas(background: Color(0xFF142A1F), child: Center(child: CircularProgressIndicator(color: Color(0xFFB6DC45))));
    }
    final crates = mapList(o?['crates']);
    final scanned = crates.where((c) => asBool(c['scanned'])).length;
    final all = crates.isNotEmpty && scanned == crates.length;
    final pickup = o?['pickup'] is Map ? Map<String, dynamic>.from(o!['pickup'] as Map) : const <String, dynamic>{};
    final trial = crates.any((c) => asString(c['trialQr']).isNotEmpty);

    return DesignCanvas(
      // Keep the lower page area warm off-white, like the reference design.
      background: const Color(0xFFF7F8F1),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 412,
            height: 470,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.04),
                  radius: .62,
                  colors: [_torch ? const Color(0xFF356F4F) : const Color(0xFF24523A), const Color(0xFF142A1F), const Color(0xFF0F2018)],
                  stops: const [0, .62, 1],
                ),
              ),
            ),
          ),
          DBox(
            x: 20,
            y: 48,
            w: 48,
            h: 48,
            r: 24,
            bg: const Color(0x21FFFFFF),
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(LucideIcons.arrowLeft, size: 20, color: Colors.white),
          ),
          const DTxt('Scan pickup QR', x: 70, y: 57, w: 272, s: 20, wt: FontWeight.w700, lh: 28, c: Colors.white, align: TextAlign.center),
          DBox(
            x: 344,
            y: 48,
            w: 48,
            h: 48,
            r: 24,
            bg: _torch ? const Color(0x59B6DC45) : const Color(0x21FFFFFF),
            onTap: () => setState(() => _torch = !_torch),
            child: const Icon(LucideIcons.flashlight, size: 20, color: Colors.white),
          ),

          Positioned(
            left: 91,
            top: 115,
            width: 230,
            height: 230,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _busy ? null : _tapScan,
              child: Stack(
                children: [
                  for (final c in const [
                    (0.0, 0.0, Alignment.topLeft),
                    (187.0, 0.0, Alignment.topRight),
                    (0.0, 187.0, Alignment.bottomLeft),
                    (187.0, 187.0, Alignment.bottomRight),
                  ])
                    Positioned(
                      left: c.$1,
                      top: c.$2,
                      width: 43,
                      height: 43,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: c.$3 == Alignment.topLeft || c.$3 == Alignment.topRight ? const BorderSide(color: Color(0xFFB6DC45), width: 3) : BorderSide.none,
                            bottom: c.$3 == Alignment.bottomLeft || c.$3 == Alignment.bottomRight ? const BorderSide(color: Color(0xFFB6DC45), width: 3) : BorderSide.none,
                            left: c.$3 == Alignment.topLeft || c.$3 == Alignment.bottomLeft ? const BorderSide(color: Color(0xFFB6DC45), width: 3) : BorderSide.none,
                            right: c.$3 == Alignment.topRight || c.$3 == Alignment.bottomRight ? const BorderSide(color: Color(0xFFB6DC45), width: 3) : BorderSide.none,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: c.$3 == Alignment.topLeft ? const Radius.circular(22) : Radius.zero,
                            topRight: c.$3 == Alignment.topRight ? const Radius.circular(22) : Radius.zero,
                            bottomLeft: c.$3 == Alignment.bottomLeft ? const Radius.circular(22) : Radius.zero,
                            bottomRight: c.$3 == Alignment.bottomRight ? const Radius.circular(22) : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          DBox(x: 125, y: 149, w: 162, h: 162, r: 14, bg: const Color(0xFFF4F6F1)),
          for (var r = 0; r < _qr.length; r++)
            for (var i = 0; i < _qr[r].length; i++)
              if (_qr[r][i] == '#')
                DBox(x: 137 + i * 16, y: 161 + r * 16, w: 13, h: 13, r: 3, bg: const Color(0xFF10251A)),
          DBox(x: 111, y: 233, w: 190, h: 3, r: 2, bg: const Color(0xFFB6DC45), shadow: [BoxShadow(color: const Color(0x8CB6DC45), blurRadius: 16, spreadRadius: 5)]),
          if (all)
            DBox(
              x: 170,
              y: 194,
              w: 72,
              h: 72,
              r: 36,
              bg: const Color(0xFF1F7A45),
              border: Border.all(color: const Color(0xFFF4F6F1), width: 4),
              child: const Icon(LucideIcons.check, size: 28, color: Colors.white),
            ),
          DTxt(
            all ? 'All crates verified' : trial ? 'Trial: tap the frame to scan the next crate' : 'Point at the QR label on each crate',
            x: 20,
            y: 379,
            w: 372,
            s: 14,
            wt: FontWeight.w600,
            lh: 20,
            c: const Color(0xFFB6DC45),
            align: TextAlign.center,
          ),

          DBox(x: 20, y: 412, w: 372, h: 274, r: 28, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .06)),
          Pill(
            x: 39,
            y: 431,
            w: all ? 102 : 120,
            label: all ? 'QR verified' : 'Scanning crates',
            bg: all ? pillOk.bg : pillWarn.bg,
            fg: all ? pillOk.fg : pillWarn.fg,
            dot: all ? pillOk.fg : pillWarn.fg,
          ),
          DTxt('#${asString(o?['orderCode'])}${all ? ' matched' : ''}', x: 39, y: 462, w: 250, s: 20, wt: FontWeight.w700, lh: 28),
          DTxt('$scanned/${crates.length}', x: 300, y: 452, w: 74, s: 22, wt: FontWeight.w700, lh: 30, c: C.accent, align: TextAlign.right),
          DTxt(asString(pickup['name']), x: 39, y: 494, s: 12, lh: 16.8, c: C.muted),
          for (var i = 0; i < (crates.length > 2 ? 2 : crates.length); i++) ...[
            DBox(
              x: 39,
              y: 520 + i * 78,
              w: 334,
              h: 69,
              r: 18,
              bg: asBool(crates[i]['scanned']) ? const Color(0xFFF4F8EA) : const Color(0xFFFBFCF6),
              border: asBool(crates[i]['scanned'])
                  ? Border.all(color: const Color(0xFFDBE7C2))
                  : Border.all(color: const Color(0xFFC9D6C9), width: 1.5),
            ),
            Positioned(
              left: 53,
              top: 537 + i * 78,
              width: 36,
              height: 36,
              child: const Center(child: Icon(LucideIcons.package, size: 18, color: C.green)),
            ),
            DTxt('Crate ${asInt(crates[i]['position'])} of ${crates.length}', x: 101, y: 533 + i * 78, s: 14, wt: FontWeight.w700, lh: 19.6),
            DTxt(
              '${asString(crates[i]['label'])} · ${(asInt(crates[i]['weightGrams']) / 1000).toStringAsFixed(1)} kg · ${asBool(crates[i]['scanned']) ? 'verified' : 'not scanned'}',
              x: 101,
              y: 558 + i * 78,
              s: 12,
              lh: 16.8,
              c: C.muted,
            ),
            if (asBool(crates[i]['scanned']))
              Positioned(
                left: 345,
                top: 546 + i * 78,
                child: const Icon(LucideIcons.check, size: 16, color: C.accent),
              ),
          ],

          DBox(x: 20, y: 704, w: 372, h: 67, r: 22, bg: const Color(0xFFFFF5D9), border: Border.all(color: const Color(0xFFF0DC8C))),
          const Positioned(left: 36, top: 720, child: Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFF795109))),
          const DTxt(
            'Seal broken or crate damaged? Don’t pick it up — report it to the hub first.',
            x: 64,
            y: 716,
            w: 320,
            s: 14,
            lh: 21,
            c: Color(0xFF795109),
          ),

          Btn(
            y: 792,
            label: _busy ? 'PLEASE WAIT…' : all ? 'CONFIRM PICKUP & START TRIP' : 'SCAN ${crates.length - scanned} MORE CRATE${crates.length - scanned == 1 ? '' : 'S'}',
            kind: all ? BtnKind.primary : BtnKind.muted,
            onTap: _busy ? null : (all ? _confirm : _tapScan),
          ),
          DTxt(
            'Enter crate code manually',
            x: 20,
            y: 850,
            w: 372,
            s: 14,
            wt: FontWeight.w600,
            c: C.green,
            align: TextAlign.center,
            onTap: () => setState(() => _manual = ''),
          ),

          if (_manual != null)
            Modal(
              onClose: () => setState(() => _manual = null),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter crate code',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: C.ink)),
                  const SizedBox(height: 6),
                  const Text('Type the code printed under the QR label.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.muted, height: 19 / 13)),
                  const SizedBox(height: 14),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(color: C.green, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.keyboard, size: 18, color: C.muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _code,
                            autofocus: true,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink),
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'VPN-CRATE-�?�',
                              hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.muted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Btn(
                    w: 324,
                    h: 48,
                    label: _busy ? 'CHECKING…' : 'VERIFY CRATE',
                    onTap: _busy ? null : () {
                      if (_code.text.trim().isEmpty) {
                        showToast(context, 'Enter the crate code');
                      } else {
                        _scan(_code.text);
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
