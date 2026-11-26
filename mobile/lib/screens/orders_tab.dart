import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'order_detail_screen.dart';
import 'zone_screen.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key, required this.state, required this.onOpenTab});

  final AppState state;
  final ValueChanged<int> onOpenTab;

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  String _tab = 'active';
  String _range = 'today';
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _searchOpen = false;
  final _search = TextEditingController();

  static const _ranges = [('Today', 'today'), ('This week', 'week'), ('This month', 'month'), ('All time', 'all')];
  static const _progress = {'assigned': 1, 'accepted': 2, 'at_pickup': 2, 'picked_up': 3, 'arrived': 4};

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onAppStateChanged);
    _load();
  }

  void _onAppStateChanged() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    widget.state.removeListener(_onAppStateChanged);
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Demo orders are held in AppState, so the Completed tab can refresh
    // immediately without depending on the backend.
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(
          widget.state.demoOrders.where((order) {
            final status = asString(order['status']);
            if (_tab == 'completed') {
              return status == 'delivered' || status == 'cancelled';
            }
            if (_tab == 'upcoming') {
              return status == 'scheduled';
            }
            return status != 'delivered' && status != 'cancelled' && status != 'scheduled';
          }).map((order) => Map<String, dynamic>.from(order)),
        );
      _loading = false;
    });
  }

  Future<void> _setOnline() async {
    try {
      await widget.state.toggleOnline(true);
      await _load();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not go online');
    }
  }

  Future<void> _demo() async {
    try {
      final res = await widget.state.api.post('/v1/demo-order');
      final map = res is Map ? Map<String, dynamic>.from(res) : null;
      if (!mounted || map == null) return;
      await _load();
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OrderDetailScreen(state: widget.state, orderId: asString(map['orderId'])),
      ));
      await _load();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not create a demo order');
    }
  }

  Future<void> _open(Map<String, dynamic> o) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OrderDetailScreen(state: widget.state, orderId: asString(o['id'])),
    ));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.state.online;
    final offline = _tab == 'active' && !online;
    final filtered = _tab == 'completed' && _search.text.trim().isNotEmpty
        ? _items.where((o) {
            final s = '${asString(o['orderCode'])} ${asString(o['customerName'])}'.toLowerCase();
            return s.contains(_search.text.trim().toLowerCase());
          }).toList()
        : _items;

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const DTxt('Orders', x: 20, y: 49, s: 24, wt: FontWeight.w700, lh: 33.6),
          RoundBtn(
            icon: _tab == 'completed' ? LucideIcons.search : LucideIcons.bell,
            dot: false,
            onTap: () => setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) _search.clear();
            }),
          ),
          _segmented(y: _tab == 'completed' ? 102 : 104),

          if (_tab == 'active' && !offline) ...[
            Positioned(
              left: 20,
              top: 176,
              width: 374,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Let’s keep it ',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 29, fontWeight: FontWeight.w700, height: 40.6 / 29, color: C.ink)),
                  const GradientText(
                    'fresh.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 29, fontWeight: FontWeight.w700, height: 40.6 / 29),
                    gradient: LinearGradient(colors: [Color(0xFF5D8A22), Color(0xFF8C7E0C)]),
                  ),
                ],
              ),
            ),
            DTxt(
              _loading ? 'Loading your orders…' : '${_items.length} active order${_items.length == 1 ? '' : 's'}',
              x: 20,
              y: 215,
              s: 13,
              wt: FontWeight.w500,
              lh: 18.2,
              c: C.muted,
            ),
            if (!_loading && _items.isEmpty)
              _empty(y: 250, title: 'No active orders right now', text: 'Stay online inside your zone. New orders appear here the moment the hub assigns them.', onDemo: _demo)
            else
              Positioned(
                left: 20,
                top: 250,
                width: 372,
                height: 556,
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _OrderCard(order: _items[i], primary: i == 0, onTap: () => _open(_items[i])),
                ),
              ),
          ],

          if (offline) ...[
            DBox(x: 20, y: 178, w: 372, h: 67, r: 22, bg: const Color(0xFFFFF5D9), border: Border.all(color: const Color(0xFFF0DC8C))),
            const Positioned(left: 36, top: 203, child: Icon(LucideIcons.wifiOff, size: 16, color: Color(0xFF795109))),
            Positioned(
              left: 65,
              top: 194,
              width: 255,
              child: Text.rich(
                const TextSpan(children: [
                  TextSpan(text: "You're offline.", style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ' Go online to receive new orders.'),
                ]),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFF795109), height: 20 / 13.5),
              ),
            ),
            ToggleSwitch(x: 328, y: 197, on: false, onChanged: (_) => _setOnline()),
            _empty(
              y: 264,
              title: _items.isNotEmpty ? '${_items.length} order${_items.length == 1 ? '' : 's'} still open' : 'No active orders right now',
              text: _items.isNotEmpty ? 'Go online to keep working on your open orders.' : 'Go online inside your zone. New orders appear here the moment the hub assigns them.',
            ),
            Positioned(left: 20, top: 735, child: Btn(w: 198, label: 'GO ONLINE', onTap: _setOnline)),
            Positioned(
              left: 229,
              top: 735,
              child: Btn(
                w: 163,
                kind: BtnKind.outline,
                label: 'MY ZONE',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ZoneScreen(state: widget.state),
                    ),
                  );
                },
              ),
            ),
          ],

          if (_tab == 'upcoming') ...[
            const DTxt('Next in your queue', x: 20, y: 176, w: 374, s: 29, wt: FontWeight.w700, lh: 40.6),
            const DTxt('Scheduled orders show up here before they start.', x: 20, y: 215, s: 13, wt: FontWeight.w500, lh: 18.2, c: C.muted),
            if (!_loading && _items.isEmpty)
              _empty(y: 250, title: 'Nothing scheduled yet', text: 'Orders booked for later in the day will appear here.')
            else
              Positioned(
                left: 20,
                top: 250,
                width: 372,
                height: 556,
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _OrderCard(order: _items[i], primary: false, onTap: () => _open(_items[i])),
                ),
              ),
          ],

          if (_tab == 'completed') ...[
            for (var i = 0; i < 3; i++)
              DBox(
                x: 20 + i * 128.0,
                y: 175,
                w: 116,
                h: 74,
                r: 18,
                bg: Colors.white,
                border: Border.all(color: C.line),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      [(_items.where((o) => o['status'] == 'delivered').length).toString(), (_items.where((o) => o['status'] == 'cancelled').length).toString(), asDouble(widget.state.partner?['rating']).toStringAsFixed(1)][i],
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: C.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ['Delivered', 'Cancelled', 'Rating'][i],
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: C.muted),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: 20,
              top: 263,
              child: Row(
                children: [
                  for (final r in _ranges)
                    Padding(
                      padding: const EdgeInsets.only(right: 9),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _range = r.$2);
                          _load();
                        },
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: _range == r.$2 ? C.green : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: _range == r.$2 ? null : Border.all(color: C.line),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            r.$1,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: _range == r.$2 ? Colors.white : C.ink),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_searchOpen)
              Positioned(
                left: 110,
                top: 44,
                width: 224,
                height: 40,
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search order or customer',
                    hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.muted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: C.line)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: C.green)),
                  ),
                ),
              ),
            DTxt(
              _ranges.firstWhere((r) => r.$2 == _range).$1.toUpperCase(),
              x: 20,
              y: 321,
              s: 11,
              wt: FontWeight.w700,
              lh: 15.4,
              c: C.accent,
              ls: .3,
            ),
            if (_loading)
              const DTxt('Loading…', x: 20, y: 360, w: 372, s: 13, c: C.muted, align: TextAlign.center)
            else if (filtered.isEmpty)
              DTxt(
                _search.text.trim().isNotEmpty ? 'No orders match your search.' : 'No completed orders in this period yet.',
                x: 20,
                y: 370,
                w: 372,
                s: 13.5,
                wt: FontWeight.w500,
                lh: 20,
                c: C.muted,
                align: TextAlign.center,
              )
            else
              Positioned(
                left: 20,
                top: 349,
                width: 372,
                height: 460,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: C.line),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: C.tint5),
                    itemBuilder: (_, i) {
                      final d = filtered[i];
                      final ok = d['status'] == 'delivered';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tile(
                              s: 44,
                              bg: ok ? const Color(0xFFEEF5DB) : const Color(0xFFFDE0DD),
                              icon: ok ? LucideIcons.check : LucideIcons.x,
                              c: ok ? C.green : const Color(0xFFB3261E),
                              isize: 18,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${asString(d['orderCode'])} · ${asString(d['customerName'])}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    ok ? 'Delivered ${dateTime(d['deliveredAt'])} · ${asDouble(d['distanceKm'])} km' : 'Cancelled',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  ok ? money(asInt(d['earningPaise'])) : '–',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink),
                                ),
                                const SizedBox(height: 3),
                                Pill(
                                  label: ok ? 'Delivered' : 'Cancelled',
                                  bg: ok ? pillOk.bg : pillBad.bg,
                                  fg: ok ? pillOk.fg : pillBad.fg,
                                  dot: ok ? pillOk.fg : pillBad.fg,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],

          BottomNav(
            active: 'orders',
            onTap: (k) => widget.onOpenTab({'home': 0, 'orders': 1, 'earnings': 2, 'profile': 3}[k] ?? 1),
          ),
        ],
      ),
    );
  }

  Widget _segmented({required double y}) {
    const tabs = [('active', 'Active'), ('upcoming', 'Upcoming'), ('completed', 'Completed')];
    final i = tabs.indexWhere((t) => t.$1 == _tab);
    return Stack(
      children: [
        DBox(x: 20, y: y, w: 372, h: 56, r: 28, bg: Colors.white, border: Border.all(color: C.line)),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          left: 24 + i * 121.33,
          top: y + 4,
          width: 121.33,
          height: 48,
          child: Container(
            decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(24), boxShadow: sh(6, 10, .12)),
          ),
        ),
        for (var j = 0; j < 3; j++)
          Positioned(
            left: 24 + j * 121.33,
            top: y + 4,
            width: 121.33,
            height: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _tab = tabs[j].$1);
                _load();
              },
              child: Center(
                child: Text(
                  tabs[j].$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tabs[j].$1 == _tab ? Colors.white : C.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _empty({required double y, required String title, required String text, VoidCallback? onDemo}) {
    return Stack(
      children: [
        DBox(x: 20, y: y, w: 372, h: 293, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
        DImg('assets/art/basket.png', x: 120, y: y + 31, w: 180, h: 130),
        Pill(x: 149, y: y + 163, w: 114, label: 'All caught up', bg: pillOk.bg, fg: pillOk.fg, dot: pillOk.fg),
        DTxt(title, x: 20, y: y + 197, w: 372, s: 20, wt: FontWeight.w700, lh: 28, align: TextAlign.center),
        DTxt(text, x: 40, y: y + 228, w: 332, s: 13.5, wt: FontWeight.w500, lh: 20, c: C.muted, align: TextAlign.center),
        if (onDemo != null)
          Positioned(
            left: 56,
            top: y + 305,
            child: Btn(w: 300, h: 44, fs: 12, kind: BtnKind.yellow, icon: LucideIcons.packagePlus, label: 'CREATE A DEMO ORDER (TRIAL)', onTap: onDemo),
          ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.primary, required this.onTap});

  final Map<String, dynamic> order;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = asString(order['status']);
    final ready = status != 'assigned';
    final steps = _OrdersTabState._progress[status] ?? 0;
    final scheduled = order['scheduledFor'];
    final sub = scheduled != null
        ? 'Scheduled · ${dateTime(scheduled)}'
        : 'Assigned ${dateTime(order['createdAt'])} · ${asInt(order['crateCount'])} crates';

    return Container(
      width: 372,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.line),
        boxShadow: sh(8, 20, .04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${asString(order['orderCode'])}',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: C.ink)),
                    const SizedBox(height: 2),
                    Text(sub, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Pill(
                  label: ready ? statusLabel(status) : 'New · accept it',
                  bg: ready ? C.green : pillWarn.bg,
                  fg: ready ? const Color(0xFFD6EE75) : pillWarn.fg,
                  dot: ready ? const Color(0xFFD6EE75) : pillWarn.fg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 3.7),
                    decoration: BoxDecoration(
                      color: i < steps ? (ready ? C.accent : const Color(0xFFE9B32C)) : const Color(0xFFE2EADC),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          _placeRow(const Color(0xFFEEF5DB), LucideIcons.package, asString(order['hubName']), 'Pickup point'),
          const SizedBox(height: 6),
          _placeRow(const Color(0xFFFFF3BF), LucideIcons.mapPin, asString(order['customerName']), asString(order['dropAddress'])),
          const SizedBox(height: 11),
          Row(
            children: [
              Text(
                '${asDouble(order['distanceKm'])} km${asInt(order['etaMinutes']) > 0 ? ' · ${asInt(order['etaMinutes'])} min' : ''}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: C.muted),
              ),
              const Spacer(),
              Text(money(asInt(order['earningPaise'])),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700, color: C.accent)),
            ],
          ),
          const SizedBox(height: 14),
          Btn(
            w: 340,
            h: primary ? 48 : 40,
            fs: primary ? 14 : 12,
            kind: primary ? BtnKind.primary : BtnKind.muted,
            label: status == 'assigned' ? 'VIEW & ACCEPT' : (primary ? 'CONTINUE ORDER' : 'VIEW ORDER'),
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  Widget _placeRow(Color bg, IconData icon, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tile(bg: bg, icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink)),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted)),
            ],
          ),
        ),
      ],
    );
  }
}
