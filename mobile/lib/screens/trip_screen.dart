import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'handover_screen.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.state, required this.orderId});

  final AppState state;
  final String orderId;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  static const _max = 306.0;

  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _busy = false;
  double _dx = 0;

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load trip');
    }
  }

  Future<void> _arrive() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.state.api.post('/v1/orders/${widget.orderId}/arrive', body: const <String, dynamic>{});
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HandOverScreen(state: widget.state, orderId: widget.orderId),
      ));
    } catch (e) {
      if (!mounted) return;
      showToast(context, e is ApiException ? e.message : 'Could not mark arrival');
      setState(() => _dx = 0);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMaps(Map<String, dynamic> o) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${asDouble(o['dropLat'])},${asDouble(o['dropLng'])}&travelmode=two-wheeler');
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
            const BackBar(title: 'Trip'),
            const DTxt('Trip unavailable', x: 20, y: 300, w: 372, s: 15, wt: FontWeight.w600, c: C.muted, align: TextAlign.center),
          ],
        ),
      );
    }
    final street = asString(o['dropAddress']).split(',').take(2).join(',');
    final earning = asInt(o['payBasePaise']) + asInt(o['payDistancePaise']) + asInt(o['tipPaise']);
    final picked = mapList(o['timeline']).where((e) => asString(e['status']) == 'picked_up').toList();
    final instructions = asString(o['dropInstructions']);

    return DesignCanvas(
      child: Stack(
        children: [
          DImg('assets/art/map-trip.png', x: 0, y: 0, w: 412, h: 500),
          RoundBtn(icon: LucideIcons.arrowLeft, y: 54, onTap: () => Navigator.of(context).maybePop()),
          DBox(
            x: 95,
            y: 48,
            w: 297,
            h: 58,
            r: 24,
            bg: const Color(0xFF073D2A),
            shadow: sh(10, 20, .2),
            onTap: () => _openMaps(o),
            child: Stack(
              children: [
                const Positioned(left: 19, top: 20, child: Icon(LucideIcons.cornerUpRight, size: 18, color: Colors.white)),
                Positioned(
                  left: 46,
                  top: 10,
                  width: 240,
                  child: const Text('Open turn-by-turn in Maps',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                Positioned(
                  left: 46,
                  top: 31,
                  width: 240,
                  child: Text(
                    street,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFCFE3D0)),
                  ),
                ),
              ],
            ),
          ),
          DBox(
            x: 340,
            y: 300,
            w: 52,
            h: 52,
            r: 26,
            bg: const Color(0xFFC92526),
            shadow: sh(10, 20, .2),
            child: const Center(
              child: Text('SOS',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),

          Positioned(
            left: 0,
            top: 484,
            width: 412,
            height: 431,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: C.green.withValues(alpha: .08), blurRadius: 24, offset: const Offset(0, -8))],
              ),
            ),
          ),
          DBox(x: 186, y: 494, w: 40, h: 4, r: 2, bg: C.line),
          DBox(
            x: 20,
            y: 514,
            w: 130,
            h: 54,
            r: 27,
            bg: const Color(0xFFE0EFF3),
            border: Border.all(color: const Color(0xFFCFE3EA)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 7,
                  height: 7,
                  child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF145B73), shape: BoxShape.circle)),
                ),
                SizedBox(width: 7),
                Text('Out for delivery',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF145B73))),
              ],
            ),
          ),
          DTxt('#${asString(o['orderCode'])}', x: 252, y: 533, w: 140, s: 12, wt: FontWeight.w700, lh: 16.8, c: C.muted, align: TextAlign.right),
          DTxt(
            asInt(o['etaMinutes']) > 0 ? '${asInt(o['etaMinutes'])} min' : '${asDouble(o['distanceKm'])} km',
            x: 20,
            y: 577,
            s: 36,
            wt: FontWeight.w700,
            lh: 44,
          ),
          DTxt(
            '${asDouble(o['distanceKm'])} km trip · picked up ${picked.isEmpty ? '' : _time(asString(picked.first['at']))}',
            x: 20,
            y: 619,
            s: 13,
            wt: FontWeight.w500,
            lh: 18.2,
            c: C.muted,
          ),
          DTxt(money(earning), x: 292, y: 610, w: 100, s: 18, wt: FontWeight.w700, lh: 25, c: C.accent, align: TextAlign.right),
          DBox(x: 20, y: 652, w: 372, h: 7, r: 4, bg: const Color(0xFFE2EADC)),
          DBox(
            x: 20,
            y: 652,
            w: 208,
            h: 7,
            r: 4,
            gradient: const LinearGradient(colors: [Color(0xFF247947), Color(0xFF9CC42C)]),
          ),
          DBox(
            x: 20,
            y: 676,
            w: 44,
            h: 44,
            r: 22,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9CC42C), Color(0xFF247947)],
            ),
            child: Center(
              child: Text(
                initials(asString(o['customerName'], 'Customer')),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          DTxt(asString(o['customerName']), x: 76, y: 679, w: 200, s: 15, wt: FontWeight.w700, lh: 21),
          DTxt(asString(o['dropAddress']), x: 76, y: 699, w: 200, s: 12, lh: 16.8, c: C.muted, maxLines: 1),
          RoundBtn(
            icon: LucideIcons.messageCircle,
            x: 284,
            y: 674,
            onTap: () => showToast(context, 'Open Help & support from your profile'),
          ),
          RoundBtn(
            icon: LucideIcons.phone,
            x: 344,
            y: 674,
            onTap: () => showToast(context, 'Calls connect through a masked number (${asString(o['customerPhoneMasked'])}). Coming soon.'),
          ),
          if (instructions.isNotEmpty)
            DTxt('Note: $instructions', x: 20, y: 738, w: 372, s: 12.5, lh: 18, c: const Color(0xFF795109), maxLines: 2),

          DBox(
            x: 20,
            y: 824,
            w: 372,
            h: 63,
            r: 32,
            gradient: const LinearGradient(colors: [Color(0xFFDFEAC2), Color(0xFFEEF5DB)]),
            border: Border.all(color: const Color(0xFFC5D9A4)),
          ),
          DTxt(
            _busy ? 'MARKING ARRIVED…' : 'SWIPE – I’VE ARRIVED',
            x: 84,
            y: 845,
            w: 300,
            s: 14,
            wt: FontWeight.w700,
            lh: 21,
            c: C.green.withValues(alpha: (1 - _dx / _max).clamp(0, 1)),
            align: TextAlign.center,
          ),
          Positioned(
            left: 27 + _dx,
            top: 830,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) => setState(() => _dx = (_dx + d.delta.dx).clamp(0, _max)),
              onHorizontalDragEnd: (_) {
                if (_dx > _max * .7) {
                  _arrive();
                } else {
                  setState(() => _dx = 0);
                }
              },
              onTap: _arrive,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: C.green,
                  shape: BoxShape.circle,
                  boxShadow: sh(8, 16, .25),
                ),
                child: const Icon(LucideIcons.arrowRight, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _time(String v) {
    final d = parseDate(v);
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'am' : 'pm'}';
  }
}
