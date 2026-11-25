import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'order_detail_screen.dart';
import 'sos_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _cats = ['All', 'Orders', 'Payouts', 'Account'];

  List<Map<String, dynamic>> _items = [];
  int _unread = 0;
  bool _loading = true;
  String _cat = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.state.api.get('/v1/notifications?limit=50');
      if (!mounted) return;
      final map = res is Map ? Map<String, dynamic>.from(res) : {};
      setState(() {
        _items = mapList(map['items']);
        _unread = asInt(map['unreadCount']);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load notifications');
    }
  }

  Future<void> _readAll() async {
    try {
      await widget.state.api.post('/v1/notifications/read');
      await _load();
      widget.state.refreshUnread();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not mark all as read');
    }
  }

  Future<void> _open(Map<String, dynamic> x) async {
    if (asString(x['readAt']).isEmpty) {
      widget.state.api.post('/v1/notifications/${asString(x['id'])}/read').catchError((_) => <String, dynamic>{});
      widget.state.refreshUnread();
      setState(() => _items = [
            for (final i in _items)
              asString(i['id']) == asString(x['id']) ? {...i, 'readAt': DateTime.now().toIso8601String()} : i,
          ]);
    }
    final match = RegExp(r'^/orders/([0-9a-f-]{36})$').firstMatch(asString(x['actionUrl']));
    if (!mounted) return;
    if (match != null) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OrderDetailScreen(state: widget.state, orderId: match.group(1)!),
      ));
      _load();
      return;
    }
    switch (asString(x['category'])) {
      case 'safety':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SosScreen(state: widget.state)));
      case 'payout':
        Navigator.of(context).maybePop();
      case 'account':
        Navigator.of(context).maybePop();
      default:
        break;
    }
  }

  bool _match(Map<String, dynamic> x) {
    if (_cat == 'All') return true;
    final c = asString(x['category']);
    if (_cat == 'Orders') return c == 'order';
    if (_cat == 'Payouts') return c == 'payout';
    return c == 'account' || c == 'promo' || c == 'safety';
  }

  static (IconData, Color, Color) _icon(String cat) {
    switch (cat) {
      case 'payout':
        return (LucideIcons.landmark, const Color(0xFFFFF3BF), C.ink);
      case 'account':
        return (LucideIcons.shieldCheck, const Color(0xFFE0EFF3), const Color(0xFF145B73));
      case 'promo':
        return (LucideIcons.zap, const Color(0xFFFFF3BF), C.ink);
      case 'safety':
        return (LucideIcons.alertTriangle, const Color(0xFFFDE0DD), const Color(0xFFC92526));
      default:
        return (LucideIcons.package, const Color(0xFFEEF5DB), C.green);
    }
  }

  String _ago(String iso) {
    final d = parseDate(iso);
    if (d == null) return '';
    final m = DateTime.now().difference(d).inMinutes;
    if (m < 1) return 'Just now';
    if (m < 60) return '$m min ago';
    if (m < 24 * 60) return '${(m / 60).round()} h ago';
    return dateOnly(d);
  }

  @override
  Widget build(BuildContext context) {
    final list = _items.where(_match).toList();
    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'Notifications'),
          DTxt(
            'Mark all read',
            x: 262,
            y: 55,
            w: 130,
            s: 13,
            wt: FontWeight.w700,
            lh: 18.2,
            c: _unread > 0 ? C.green : C.muted,
            align: TextAlign.right,
            onTap: _unread > 0 ? _readAll : null,
          ),
          Positioned(
            left: 20,
            top: 100,
            child: Row(
              children: [
                for (final c in _cats)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: GestureDetector(
                      onTap: () => setState(() => _cat = c),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _cat == c ? C.green : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: _cat == c ? null : Border.all(color: C.line),
                        ),
                        child: Text(
                          c == 'All' && _unread > 0 ? 'All · $_unread new' : c,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _cat == c ? Colors.white : C.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const DTxt('NOTIFICATIONS', x: 20, y: 163, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          Positioned(
            left: 20,
            top: 180,
            width: 372,
            height: 725,
            child: _loading && _items.isEmpty
                ? const Center(
                    child: Text('Loading…', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.muted)),
                  )
                : list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Text(
                          'No notifications yet. Order, payout and account updates will show up here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, fontWeight: FontWeight.w500, color: C.muted, height: 20 / 13.5),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 11),
                        itemBuilder: (_, i) => _tile(list[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Map<String, dynamic> x) {
    final fresh = asString(x['readAt']).isEmpty;
    final ic = _icon(asString(x['category']));
    return GestureDetector(
      onTap: () => _open(x),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: fresh ? const Color(0xFFF3F7E9) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: fresh ? const Color(0xFFD6E5BF) : C.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Center(child: Icon(ic.$1, size: 19, color: ic.$3)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asString(x['title']),
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w700, color: C.ink, height: 20 / 14.5)),
                  const SizedBox(height: 3),
                  Text(asString(x['body']),
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: C.muted, height: 18 / 12.5)),
                  const SizedBox(height: 6),
                  Text(_ago(asString(x['createdAt'])),
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7B887F))),
                ],
              ),
            ),
            if (fresh)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(left: 6, top: 3),
                decoration: const BoxDecoration(color: C.accent, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
