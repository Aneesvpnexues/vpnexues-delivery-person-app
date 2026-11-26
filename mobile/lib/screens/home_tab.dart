import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'notifications_screen.dart';
import 'order_detail_screen.dart';
import 'sos_screen.dart';
import 'zone_screen.dart';
import 'bank_payout_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.state, required this.onOpenTab});

  final AppState state;
  final ValueChanged<int> onOpenTab;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final Map<String, dynamic>? _earnings = null;
  final List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onAppStateChanged);
    _load();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onAppStateChanged);
      widget.state.addListener(_onAppStateChanged);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onAppStateChanged);
    super.dispose();
  }

  Future<void> _load() async {
    // Temporary dev mode: no server calls from splash to home screen.
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _openBankPayout() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BankPayoutScreen(
          state: widget.state,
          availableBalancePaise: widget.state.demoAvailableEarnings,
        ),
      ),
    );
  }

  Future<void> _toggleOnline(bool value) async {
    // Going online is not available yet. Keep the partner offline and
    // show an informational message instead of calling the API.
    if (value == true) {
      showToast(context, 'Going online is under development.');
      return;
    }

    try {
      await widget.state.toggleOnline(value);
      if (value == false && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ZoneScreen(state: widget.state)));
      }
    } catch (e) {
      if (mounted) {
        showToast(context,
            e is ApiException ? e.message : AppLocalizations.of(context).errStatus);
      }
    }
  }

  Future<void> _createDemo() async {
    if (_creating) return;

    setState(() => _creating = true);

    // Local preview order: this does not require a backend request.
    final demoOrder = <String, dynamic>{
      'id': 'DEMO-VPN-2025',
      'orderCode': 'VPN-2025',
      'status': 'assigned',
      'distanceKm': 3.2,
      'etaMinutes': 18,
      'payBasePaise': 8500,
      'payDistancePaise': 0,
      'tipPaise': 0,
      'customerName': 'Priya Sharma',
      'customerPhoneMasked': 'XXXXXX',
      'dropAddress': '24, 2nd Avenue, Anna Nagar East, Chennai 600102',
      'dropInstructions': 'Ring the bell twice. Leave with security if not home.',
      'dropLat': 0,
      'dropLng': 0,
      'pickup': <String, dynamic>{'lat': 0, 'lng': 0},
      'crates': <Map<String, dynamic>>[],
      'timeline': <Map<String, dynamic>>[
        <String, dynamic>{
          'status': 'assigned',
          'at': DateTime.now().toIso8601String(),
        },
      ],
    };

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            state: widget.state,
            orderId: 'DEMO-VPN-2025',
            demoOrder: demoOrder,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  String _greeting(AppLocalizations l) {
    final h = DateTime.now().hour;
    if (h < 12) return l.greetingMorning;
    if (h < 17) return l.greetingAfternoon;
    return l.greetingEvening;
  }

  String _today(AppLocalizations l) {
    // Registers CLDR date symbols for every locale up front (the work is
    // synchronous; the returned future is already completed).
    initializeDateFormatting(l.localeName);
    final d = DateTime.now();
    return DateFormat.EEEE(l.localeName).add_d().add_MMMM().format(d);
  }

  /// Status label localized for the Home screen (other screens still use
  /// the English `statusLabel` from core/format.dart).
  String _status(AppLocalizations l, String status) {
    switch (status) {
      case 'assigned':
        return l.statusAssigned;
      case 'accepted':
        return l.statusAccepted;
      case 'at_pickup':
        return l.statusAtPickup;
      case 'picked_up':
        return l.statusPickedUp;
      case 'arrived':
        return l.statusArrived;
      case 'delivered':
        return l.statusDelivered;
      case 'cancelled':
        return l.statusCancelled;
      default:
        return statusLabel(status);
    }
  }

  Future<void> _openOrder(Map<String, dynamic> order) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OrderDetailScreen(state: widget.state, orderId: asString(order['id'])),
    ));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = widget.state;
    final partner = state.partner ?? {};
    final hub = partner['hub'] is Map ? Map<String, dynamic>.from(partner['hub'] as Map) : const <String, dynamic>{};
    final online = state.online;
    final next = _orders.isNotEmpty ? _orders.first : null;
    final queued = _orders.length - 1;
    // Include locally completed demo deliveries in the Home summary.
    // Real backend earnings can be connected here when API loading is enabled.
    final net = state.demoEarningsToday;
    final available = state.demoAvailableEarnings;
    final deliveries = state.demoDeliveriesToday;

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          Positioned(
            left: 20,
            top: 40,
            width: 372,
            height: 66,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Logo(s: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _today(l),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 16.8 / 12,
                            color: C.muted),
                      ),
                      Text(
                        '${_greeting(l)},\n${firstName(state.name)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 22.5 / 18,
                            color: C.ink),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SosScreen(state: state))),
                  child: Container(
                    width: 81,
                    height: 48,
                    decoration: BoxDecoration(color: C.danger, borderRadius: BorderRadius.circular(24), boxShadow: sh(10, 20, .2)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('SOS',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen(state: state)));
                    state.refreshUnread();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: sh(4, 12, .05)),
                    child: Stack(
                      children: [
                        const Positioned(left: 14, top: 14, child: Icon(LucideIcons.bell, size: 20, color: C.green)),
                        if (state.unread > 0)
                          const Positioned(
                            left: 29,
                            top: 21,
                            child: SizedBox(
                              width: 5,
                              height: 5,
                              child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // online bar
          const DBox(x: 20, y: 121, w: 372, h: 50, r: 25, bg: Colors.white),
          Positioned(
            left: 20,
            top: 121,
            width: 372,
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 11),
                Container(
                  width: 23,
                  height: 23,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: online ? const Color(0xFFD9F0DF) : const Color(0xFFE6E9E4),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: online ? const Color(0xFF2FB463) : const Color(0xFF9AA69E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  online ? l.online : l.offline,
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, height: 19.6 / 14, color: C.ink),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ZoneScreen(state: state))),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '· ${asString(hub['name'], l.noHub).replaceAll(RegExp(r' Hub$'), '')} · ${asInt(partner['deliveryRadiusKm'], 5)} km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, height: 19.6 / 12, color: C.muted),
                          ),
                        ),
                        Text(
                          ' · ${l.change}',
                          maxLines: 1,
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, height: 19.6 / 12, color: C.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ToggleSwitch(on: online, onChanged: _toggleOnline),
                const SizedBox(width: 10),
              ],
            ),
          ),

          // hero card
          DBox(
            x: 20,
            y: 188,
            w: 372,
            h: 352,
            r: 32,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF063A2A), Color(0xFF1F7945)],
            ),
            shadow: sh(18, 28, .2),
          ),
          if (next != null) ...[
            Pill(
              x: 117,
              y: 210,
              w: 168,
              label: next['status'] == 'assigned'
                  ? l.newOrderPill
                  : 'Next · ${_status(l, asString(next['status'])).toLowerCase()}',
              bg: const Color(0xFF356D35),
              fg: const Color(0xFFDFEE91),
            ),
            DTxt(
              (next['status'] == 'picked_up' || next['status'] == 'arrived')
                  ? l.orderOnWay(asString(next['orderCode']))
                  : l.orderAtHub(asString(next['orderCode'])),
              x: 33,
              y: 246,
              w: 346,
              s: 20,
              wt: FontWeight.w700,
              lh: 26,
              c: Colors.white,
              align: TextAlign.center,
              maxLines: 1,
            ),
            const DBox(x: 110, y: 292, w: 184, h: 184, r: 92, border: null),
            Positioned(
              left: 110,
              top: 292,
              width: 184,
              height: 184,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFB9C74A), style: BorderStyle.solid),
                ),
              ),
            ),
            DBox(x: 119, y: 301, w: 166, h: 166, r: 83, bg: const Color(0xE6286034)),
            DBox(x: 128, y: 310, w: 148, h: 148, r: 74, bg: const Color(0xFF41652F)),
            DBox(
              x: 136,
              y: 318,
              w: 132,
              h: 132,
              r: 66,
              gradient: const RadialGradient(
                center: Alignment(0, -.24),
                radius: .9,
                colors: [Color(0xFFFFF27A), Color(0xFFF8DC36), Color(0xFFEFC81F)],
              ),
              onTap: () => _openOrder(next),
              child: Stack(
                children: [
                  const Positioned(left: 45, top: 23, child: Icon(LucideIcons.scan, size: 42, color: C.ink)),
                  Positioned(
                    left: 0,
                    top: 66,
                    width: 132,
                    child: Text(
                      next['status'] == 'assigned' ? l.viewOrder : l.continueBtn,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: C.green),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 94,
                    width: 132,
                    child: Text(
                      _status(l, asString(next['status'])),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF49622D)),
                    ),
                  ),
                ],
              ),
            ),
            Pill(x: 44, y: 500.5, w: 175, label: asString(next['hubName']), bg: const Color(0xFF34825A), fg: Colors.white),
            Pill(
              x: 235.75,
              y: 500.5,
              w: 132,
              label: l.crates(asInt(next['crateCount'])),
              bg: const Color(0xFF34825A),
              fg: Colors.white,
            ),
          ] else ...[
            Pill(
              x: 131,
              y: 210,
              w: 150,
              label: _loading ? l.checkingOrders : l.allCaughtUp,
              bg: const Color(0xFF356D35),
              fg: const Color(0xFFDFEE91),
            ),
            DTxt(
              _loading ? l.loadingOrders : l.noOrders,
              x: 43,
              y: 244,
              w: 326,
              s: 22,
              wt: FontWeight.w700,
              lh: 28.2,
              c: Colors.white,
              align: TextAlign.center,
            ),
            DTxt(
              online ? l.stayOnline : l.goOnline,
              x: 53,
              y: 280,
              w: 306,
              s: 13,
              wt: FontWeight.w500,
              lh: 19,
              c: const Color(0xFFCFE3D0),
              align: TextAlign.center,
            ),
            Positioned(
              left: 136,
              top: 340,
              width: 140,
              height: 140,
              child: const Center(child: Icon(LucideIcons.packagePlus, size: 50, color: Color(0xFFDFEE91))),
            ),
            if (!_loading)
              Positioned(
                left: 56,
                top: 490,
                width: 300,
                child: Btn(
                  w: 300,
                  h: 40,
                  fs: 12,
                  kind: BtnKind.yellow,
                  label: _creating ? l.creating : l.createDemo,
                  onTap: _creating ? null : _createDemo,
                ),
              ),
          ],

          // secondary card
          DBox(x: 20, y: 556, w: 372, h: 157, r: 24, bg: Colors.white, shadow: sh(8, 22, .05)),
          if (next != null) ...[
            DTxt(l.thenDeliverTo, x: 37, y: 574, s: 16, wt: FontWeight.w700, lh: 22.4),
            Pill(x: 240, y: 572, w: 135, label: _status(l, asString(next['status']))),
            const Tile(x: 37, y: 609, bg: Color(0xFFFFF3BF), icon: LucideIcons.mapPin),
            DTxt(asString(next['customerName']), x: 85, y: 608, w: 210, s: 15, wt: FontWeight.w700, lh: 21),
            DTxt(asString(next['dropAddress']), x: 85, y: 629, w: 215, s: 12, lh: 16.8, c: C.muted, maxLines: 1),
            DTxt(money(asInt(next['earningPaise'])), x: 300, y: 609, w: 75, s: 17, wt: FontWeight.w700, lh: 23.8, c: C.accent, align: TextAlign.right),
            const DBox(x: 37, y: 658, w: 338, h: 1, bg: C.tint5),
            DTxt(
              '${asDouble(next['distanceKm'])} km${asInt(next['etaMinutes']) > 0 ? ' · ${asInt(next['etaMinutes'])} min' : ''} · ${l.crates(asInt(next['crateCount']))}${queued > 0 ? ' · ${l.moreQueued(queued)}' : ''}',
              x: 37,
              y: 668,
              w: 338,
              s: 13,
              wt: FontWeight.w500,
              lh: 18.2,
              c: C.muted,
            ),
          ] else ...[
            DTxt(l.yourDaySoFar, x: 37, y: 574, s: 16, wt: FontWeight.w700, lh: 22.4),
            Pill(
              x: 265,
              y: 572,
              w: 110,
              label: online ? l.online : l.offline,
              bg: online ? pillOk.bg : pillWarn.bg,
              fg: online ? pillOk.fg : pillWarn.fg,
              dot: online ? pillOk.fg : pillWarn.fg,
            ),
            const Tile(x: 37, y: 609, icon: LucideIcons.wallet),
            DTxt(l.deliveriesToday(deliveries), x: 85, y: 608, s: 15, wt: FontWeight.w700, lh: 21),
            DTxt(l.earningsCreditNote, x: 85, y: 629, s: 12, lh: 16.8, c: C.muted),
            DTxt(money(net), x: 260, y: 609, w: 115, s: 17, wt: FontWeight.w700, lh: 23.8, c: C.accent, align: TextAlign.right),
            const DBox(x: 37, y: 658, w: 338, h: 1, bg: C.tint5),
            DTxt(l.viewEarnings, x: 37, y: 668, s: 13, wt: FontWeight.w500, lh: 18.2, c: C.green, onTap: () => widget.onOpenTab(2)),
          ],

          // Entire Today Earned / Available to withdraw card opens Bank payout.
          DBox(
            x: 20,
            y: 724,
            w: 372,
            h: 70,
            r: 22,
            bg: const Color(0xFFEEF5DB),
            onTap: _openBankPayout,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 12, 48, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.todayEarned(money(net)),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 22.4 / 14,
                      color: C.ink,
                    ),
                  ),
                  Text(
                    l.availableToWithdraw(money(available)),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      height: 18.2 / 11,
                      color: C.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 350,
            top: 749,
            child: Icon(LucideIcons.chevronRight, size: 20, color: C.green),
          ),

          BottomNav(active: 'home', onTap: (k) => widget.onOpenTab({'home': 0, 'orders': 1, 'earnings': 2, 'profile': 3}[k] ?? 0)),
        ],
      ),
    );
  }
}
