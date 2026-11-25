import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';

class ZoneScreen extends StatefulWidget {
  const ZoneScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends State<ZoneScreen> {
  Map<String, dynamic>? _zone;
  int _km = 5;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.state.api.get('/v1/me/zone');
      if (!mounted) return;
      final z = res is Map ? Map<String, dynamic>.from(res) : null;
      setState(() {
        _zone = z;
        _km = asInt(z?['deliveryRadiusKm'], 5);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load your zone');
    }
  }

  List<int> get _opts {
    final allowed = stringList(_zone?['allowedRadiiKm']).map(asInt).where((e) => e > 0).toList();
    return (allowed.isEmpty ? [3, 5, 7] : allowed).take(3).toList();
  }

  List<String> get _areas {
    final raw = _zone?['areasByRadius'];
    if (raw is Map) {
      final list = raw['$_km'];
      return stringList(list);
    }
    return const [];
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.state.api.put('/v1/me/zone/radius', body: {'radiusKm': _km});
      await widget.state.loadMe();
      if (!mounted) return;
      showToast(context, 'Delivery radius set to $_km km');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not save the radius');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opts = _opts;
    final w = 331 / opts.length;
    final areas = _areas;
    final recommended = asInt(_zone?['recommendedRadiusKm']);
    final hubName = asString(_zone?['hubName']);

    return DesignCanvas(
      child: Stack(
        children: [
          DImg('assets/art/map-zone.png', x: 0, y: 0, w: 412, h: 322),
          RoundBtn(icon: LucideIcons.arrowLeft, y: 48, onTap: () => Navigator.of(context).maybePop()),
          RoundBtn(
            icon: LucideIcons.locateFixed,
            x: 344,
            y: 48,
            onTap: () async {
              await _load();
              if (mounted) showToast(context, 'Zone refreshed');
            },
          ),
          Pill(x: 20, y: 279, w: 155, label: '$_km km service radius', bg: Colors.white, fg: C.ink, dot: const Color(0xFFB6DC45)),

          const DTxt('MY ZONE', x: 20, y: 334, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          DTxt(
            hubName.isNotEmpty ? hubName : (_loading ? 'Loading…' : 'No hub assigned'),
            x: 20,
            y: 349,
            w: 260,
            s: 24,
            wt: FontWeight.w700,
            lh: 33,
            maxLines: 1,
          ),
          if (hubName.isNotEmpty)
            Pill(x: 289, y: 344, w: 103, label: 'Your hub', bg: pillOk.bg, fg: pillOk.fg, dot: pillOk.fg),
          const DTxt(
            'Orders are offered only inside your radius. A bigger radius means more orders but longer trips.',
            x: 20,
            y: 385,
            w: 360,
            s: 13.5,
            lh: 21,
            c: C.muted,
          ),

          DBox(
            x: 20,
            y: 438,
            w: 372,
            h: 64,
            r: 22,
            bg: Colors.white,
            border: Border.all(color: C.line),
            shadow: sh(8, 20, .04),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChangeCityScreen(state: widget.state),
              ));
              _load();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${asString(_zone?['city'], '…')} · Change city / hub',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink),
                ),
              ),
            ),
          ),

          DBox(x: 20, y: 519, w: 372, h: 177, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          const DTxt('Delivery radius', x: 36, y: 538, s: 15, wt: FontWeight.w700, lh: 21),
          DTxt('$_km km', x: 275, y: 534, w: 100, s: 20, wt: FontWeight.w700, lh: 28, c: C.accent, align: TextAlign.right),
          DBox(x: 36, y: 577, w: 339, h: 56, r: 28, bg: Colors.white, border: Border.all(color: C.line)),
          if (opts.contains(_km))
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: 40 + opts.indexOf(_km) * w,
              top: 581,
              width: w,
              height: 48,
              child: Container(
                decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(24)),
              ),
            ),
          for (var i = 0; i < opts.length; i++)
            Positioned(
              left: 40 + i * w,
              top: 581,
              width: w,
              height: 48,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _km = opts[i]),
                child: Center(
                  child: Text(
                    '${opts[i]} km',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: opts[i] == _km ? Colors.white : C.muted,
                    ),
                  ),
                ),
              ),
            ),
          DTxt(
            recommended > 0 ? 'Recommended for this hub: $recommended km.' : 'Pick the distance you’re comfortable riding.',
            x: 36,
            y: 645,
            w: 335,
            s: 12,
            lh: 18,
            c: C.muted,
          ),

          DBox(x: 20, y: 710, w: 372, h: 80, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          const DTxt('Areas covered', x: 36, y: 721, s: 15, wt: FontWeight.w700, lh: 21),
          Positioned(
            left: 36,
            top: 747,
            width: 340,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: areas.isEmpty
                    ? const [
                        Text('Area list not available for this hub yet',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: C.muted)),
                      ]
                    : [
                        for (final a in areas)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 13),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: C.line),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(a,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF405947))),
                            ),
                          ),
                      ],
              ),
            ),
          ),
          Btn(y: 798, label: _busy ? 'SAVING…' : 'SAVE RADIUS', onTap: _busy ? null : _save),
          DTxt(
            'Change city or request a different hub',
            x: 20,
            y: 858,
            w: 372,
            s: 13,
            wt: FontWeight.w600,
            c: C.green,
            align: TextAlign.center,
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChangeCityScreen(state: widget.state),
              ));
              _load();
            },
          ),
        ],
      ),
    );
  }
}

class ChangeCityScreen extends StatefulWidget {
  const ChangeCityScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ChangeCityScreen> createState() => _ChangeCityScreenState();
}

class _ChangeCityScreenState extends State<ChangeCityScreen> {
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _hubs = [];
  int? _cityId;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final city = widget.state.partner?['city'];
    _cityId = city is Map ? asInt(city['id']) : null;
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.state.api.get('/v1/cities');
      if (!mounted) return;
      setState(() {
        _cities = mapList(res);
        _loading = false;
      });
      if (_cityId != null) _loadHubs(_cityId!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load cities');
    }
  }

  Future<void> _loadHubs(int cityId) async {
    try {
      final res = await widget.state.api.get('/v1/cities/$cityId/hubs');
      if (!mounted) return;
      setState(() => _hubs = mapList(res));
    } catch (_) {}
  }

  Future<void> _request() async {
    if (_cityId == null) {
      showToast(context, 'Choose a city');
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.state.api.post('/v1/me/zone/change-request', body: {
        'cityId': _cityId,
        if (_hubs.isNotEmpty) 'hubId': asString(_hubs.first['id']),
      });
      if (!mounted) return;
      showToast(context, 'Request sent. Support will confirm the change.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not send the request');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.partner ?? {};
    final city = me['city'] is Map ? asString((me['city'] as Map)['name']) : '';
    final selected = _cities.where((c) => asInt(c['id']) == _cityId).toList();
    final hub = _hubs.isNotEmpty ? asString(_hubs.first['name']) : '';

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'Change city or hub'),
          const DTxt('Choose your delivery city', x: 20, y: 122, s: 22, wt: FontWeight.w700, lh: 30),
          DTxt('Current city: $city', x: 20, y: 164, s: 13, lh: 18.2, c: C.muted),
          if (_loading)
            const DTxt('Loading cities…', x: 20, y: 201, s: 13, c: C.muted)
          else
            for (var i = 0; i < (_cities.length > 3 ? 3 : _cities.length); i++)
              DBox(
                x: 20,
                y: 201 + i * 58,
                w: 372,
                h: 48,
                r: 16,
                bg: asInt(_cities[i]['id']) == _cityId ? C.green : Colors.white,
                border: asInt(_cities[i]['id']) == _cityId ? null : Border.all(color: C.line),
                onTap: () {
                  setState(() => _cityId = asInt(_cities[i]['id']));
                  _loadHubs(asInt(_cities[i]['id']));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      asString(_cities[i]['name']),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: asInt(_cities[i]['id']) == _cityId ? Colors.white : C.ink,
                      ),
                    ),
                  ),
                ),
              ),

          DBox(x: 20, y: 400, w: 372, h: 172, r: 22, bg: Colors.white, border: Border.all(color: C.line)),
          const DTxt('Delivery hub', x: 38, y: 421, s: 15, wt: FontWeight.w700, lh: 21),
          DTxt(
            hub.isNotEmpty ? hub : '${selected.isNotEmpty ? asString(selected.first['name']) : 'This city'} · hub to be confirmed',
            x: 38,
            y: 456,
            w: 340,
            s: 20,
            wt: FontWeight.w700,
            lh: 28,
            maxLines: 1,
          ),
          const DTxt(
            'Changing your hub or city? Support will confirm coverage before the change takes effect.',
            x: 38,
            y: 495,
            w: 300,
            s: 13.5,
            lh: 19,
            c: C.muted,
          ),

          DBox(x: 20, y: 596, w: 372, h: 148, r: 22, bg: const Color(0xFFEAF2D9)),
          const DTxt('Keep your current zone active', x: 38, y: 617, s: 15, wt: FontWeight.w700, lh: 21),
          DTxt(
            'Your current $city zone stays unchanged until support confirms the move.',
            x: 38,
            y: 650,
            w: 330,
            s: 13.5,
            lh: 19,
            c: const Color(0xFF333333),
          ),

          Btn(y: 784, label: _sending ? 'SENDING…' : 'SEND REQUEST TO SUPPORT', onTap: _sending ? null : _request),
          DTxt(
            'Keep my current location',
            x: 20,
            y: 860,
            w: 372,
            s: 14,
            wt: FontWeight.w700,
            lh: 20,
            align: TextAlign.center,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
