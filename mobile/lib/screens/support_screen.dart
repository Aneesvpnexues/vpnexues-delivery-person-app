import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'sos_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const _faqs = [
    (LucideIcons.wallet, 'When do I get paid?',
        'Earnings from Monday to Sunday are paid every Monday by 6 PM. Need it sooner? Use Instant payout from the Earnings tab.'),
    (LucideIcons.fileText, 'Why is my document still in review?',
        'Reviews take 2–24 hours. You’ll get a notification as each document is approved.'),
    (LucideIcons.lock, 'Customer has no delivery code',
        'Ask them to open the order in their app or check SMS. If it still fails, tap “Contact support” on the hand-over screen.'),
    (LucideIcons.mapPin, 'Changing my delivery zone',
        'Open Settings → City, hub & delivery radius. Radius changes apply at once; city or hub changes are confirmed by support.'),
    (LucideIcons.shield, 'What does accident cover include?',
        'You are covered while online and on an active order. Use Safety & SOS to reach the safety team.'),
  ];
  static const _issues = ['Customer unreachable', 'Wrong address', 'Items damaged', 'Hub delay'];

  final _search = TextEditingController();
  Map<String, dynamic>? _order;
  String _issue = '';
  int _open = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _loadOrder();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final res = await widget.state.api.get('/v1/orders', query: {'tab': 'active', 'limit': '1'});
      if (!mounted) return;
      final list = mapList(res);
      setState(() {
        _order = list.isEmpty ? null : list.first;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _report(String topic) async {
    final order = _order;
    if (order == null) {
      _chat();
      return;
    }
    setState(() => _issue = topic);
    try {
      final res = await widget.state.api.post('/v1/support/tickets', body: {
        'topic': topic,
        'message': '$topic on order #${asString(order['orderCode'])}.',
        'orderId': asString(order['id']),
      });
      if (!mounted) return;
      showToast(context, 'Reported. Support will reply in the chat.');
      final map = res is Map ? Map<String, dynamic>.from(res) : null;
      final ticket = map?['ticket'] is Map ? Map<String, dynamic>.from(map!['ticket'] as Map) : null;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SupportChatScreen(state: widget.state, ticketId: asString(ticket?['id']).isEmpty ? null : asString(ticket?['id'])),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _issue = '');
        showToast(context, e is ApiException ? e.message : 'Could not report that');
      }
    }
  }

  void _chat() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SupportChatScreen(state: widget.state),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = _faqs.where((f) => q.isEmpty || '${f.$2} ${f.$3}'.toLowerCase().contains(q)).toList();
    final order = _order;
    final me = widget.state.partner ?? {};

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'Help & support'),

          DBox(x: 20, y: 102, w: 372, h: 132, r: 28, gradient: const LinearGradient(colors: [Color(0xFF063A2A), Color(0xFF1F7945)], begin: Alignment.topLeft, end: Alignment.bottomRight), shadow: sh(18, 28, .2)),
          DTxt(
            'Hi ${firstName(asString(me['fullName']))}, how can we help?',
            x: 38,
            y: 121,
            w: 340,
            s: 20,
            wt: FontWeight.w700,
            lh: 28,
            c: Colors.white,
            maxLines: 1,
          ),
          DBox(
            x: 38,
            y: 160,
            w: 336,
            h: 56,
            r: 28,
            bg: Colors.white,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(LucideIcons.search, size: 18, color: C.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _search,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: C.ink),
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
                      hintText: 'Search: payout, OTP, insurance�?�',
                      hintStyle: TextStyle(color: C.muted, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          for (var i = 0; i < 3; i++)
            Positioned(
              left: 20 + i * 127.5,
              top: 248,
              width: 117,
              height: 142,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  switch (i) {
                    case 0:
                      _chat();
                    case 1:
                      showToast(context, 'The partner helpline number will appear here once it’s set up');
                    case 2:
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SosScreen(state: widget.state)));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 15, 12, 12),
                  decoration: BoxDecoration(
                    color: i == 2 ? const Color(0xFFFFF5F3) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: i == 2 ? const Color(0xFFF5C9C4) : C.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            [LucideIcons.messageCircle, LucideIcons.phone, LucideIcons.alertTriangle][i],
                            size: 19,
                            color: i == 2 ? const Color(0xFFC92526) : C.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(['Chat', 'Call', 'SOS'][i],
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: i == 2 ? const Color(0xFFC92526) : C.ink)),
                      const SizedBox(height: 4),
                      Text(['Reply in ~2 min', '24 × 7 partner line', 'Emergency'][i],
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted, height: 17 / 12)),
                    ],
                  ),
                ),
              ),
            ),

          DBox(x: 20, y: 405, w: 372, h: 150, r: 24, bg: const Color(0xFFEEF5DB), border: Border.all(color: const Color(0xFFDDEBC3))),
          if (_loading)
            const DTxt('Checking your orders…', x: 36, y: 422, s: 13, c: C.muted)
          else if (order != null) ...[
            DTxt('Problem with #${asString(order['orderCode'])}?', x: 36, y: 422, s: 15, wt: FontWeight.w700, lh: 21),
            Positioned(
              left: 37,
              top: 451,
              width: 340,
              child: Wrap(
                spacing: 9,
                runSpacing: 8,
                children: [
                  for (final c in _issues)
                    GestureDetector(
                      onTap: () => _report(c),
                      child: IntrinsicWidth(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _issue == c ? C.green : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: _issue == c ? null : Border.all(color: C.line),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _issue == c ? Colors.white : C.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const DTxt('No active order', x: 36, y: 422, s: 15, wt: FontWeight.w700, lh: 21),
            const DTxt('Problems with a delivery can be reported from the order itself. For anything else, start a chat.',
                x: 36, y: 448, w: 330, s: 13, lh: 19, c: C.muted),
            Btn(x: 36, y: 500, w: 160, h: 40, fs: 12, label: 'START A CHAT', onTap: _chat),
          ],

          const DTxt('POPULAR TOPICS', x: 20, y: 570, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          Positioned(
            left: 20,
            top: 596,
            width: 372,
            height: 319,
            child: list.isEmpty
                ? SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'No topics match “${_search.text.trim()}”.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: C.muted,
                          height: 20 / 13,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.vertical,
                    padding: EdgeInsets.zero,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _faq(
                      list[i],
                      _faqs.indexOf(list[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _faq((IconData, String, String) f, int index) {
    final open = _open == index;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.line, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _open = open ? -1 : index),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Icon(f.$1, size: 19, color: C.green),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f.$2,
                        textAlign: TextAlign.left,
                        softWrap: true,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: C.ink,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      height: 40,
                      child: Center(
                        child: Icon(
                          open
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 17,
                          color: const Color(0xFF8A988F),
                        ),
                      ),
                    ),
                  ],
                ),
                if (open) ...[
                  const SizedBox(height: 8),
                  Padding(
                    // Start the answer exactly below the question text.
                    padding: const EdgeInsets.only(left: 50, right: 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        f.$3,
                        textAlign: TextAlign.left,
                        softWrap: true,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: C.muted,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, required this.state, this.ticketId, this.topic = 'General help'});

  final AppState state;
  final String? ticketId;
  final String topic;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  String? _ticketId;
  List<Map<String, dynamic>> _messages = [];
  final _draft = TextEditingController();
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _ticketId = widget.ticketId;
    _load();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _draft.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      if (_ticketId == null) {
        final res = await widget.state.api.get('/v1/support/tickets');
        if (!mounted) return;
        final tickets = mapList(res);
        Map<String, dynamic>? open;
        for (final t in tickets) {
          if (asString(t['status']) != 'closed') {
            open = t;
            break;
          }
        }
        if (open != null) {
          _ticketId = asString(open['id']);
        } else {
          return;
        }
      }
      final res = await widget.state.api.get('/v1/support/tickets/$_ticketId');
      if (!mounted) return;
      final map = res is Map ? Map<String, dynamic>.from(res) : null;
      setState(() => _messages = mapList(map?['messages']));
    } catch (e) {
      if (!quiet && mounted) showToast(context, e is ApiException ? e.message : 'Could not load the conversation');
    }
  }

  Future<void> _send([String? text]) async {
    final msg = (text ?? _draft.text).trim();
    if (msg.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      if (_ticketId == null) {
        final res = await widget.state.api.post('/v1/support/tickets', body: {
          'topic': widget.topic,
          'message': msg,
        });
        final map = res is Map ? Map<String, dynamic>.from(res) : null;
        final ticket = map?['ticket'] is Map ? Map<String, dynamic>.from(map!['ticket'] as Map) : null;
        _ticketId = asString(ticket?['id']);
        _messages = mapList(map?['messages']);
      } else {
        final res = await widget.state.api.post('/v1/support/tickets/$_ticketId/messages', body: {'message': msg});
        if (res is Map) _messages = [..._messages, Map<String, dynamic>.from(res)];
      }
      if (!mounted) return;
      _draft.clear();
      setState(() {});
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not send the message');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.partner ?? {};
    final greeting = {
      'id': '0',
      'sender': 'bot',
      'body': 'Hi ${firstName(asString(me['fullName']))}. Tell us what you need help with — a delivery, a payout or your documents — and a support agent will reply here.',
      'createdAt': '',
    };
    final all = [greeting, ..._messages];

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'Support chat'),
          DTxt(
            _ticketId != null ? 'AGENTS USUALLY REPLY WITHIN A FEW MINUTES' : 'START A CONVERSATION',
            x: 20,
            y: 108,
            s: 10.5,
            wt: FontWeight.w700,
            lh: 14,
            c: C.green,
            ls: 1,
          ),
          Positioned(
            left: 20,
            top: 142,
            width: 372,
            height: 540,
            child: ListView.separated(
              reverse: false,
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = all[i];
                final mine = asString(m['sender']) == 'partner';
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: mine ? C.green : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: mine ? null : Border.all(color: C.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asString(m['body']),
                            style: TextStyle(
                                fontFamily: 'Inter', fontSize: 14.5, color: mine ? Colors.white : C.ink, height: 22 / 14.5)),
                        if (asString(m['createdAt']).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(dateTime(m['createdAt']),
                              style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w600,
                                  color: mine ? const Color(0xCCFFFFFF) : C.muted)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 20,
            top: 696,
            width: 274,
            height: 92,
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.line)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: TextField(
                controller: _draft,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.ink, height: 19 / 13),
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Type your message.',
                  hintStyle: TextStyle(color: C.muted, fontSize: 13),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          Positioned(
            left: 304,
            top: 696,
            width: 88,
            height: 92,
            child: GestureDetector(
              onTap: _busy ? null : () => _send(),
              child: Container(
                decoration: BoxDecoration(color: _busy ? C.tint5 : C.green, borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.center,
                child: Text(
                  _busy ? '…' : 'SEND',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
          for (var i = 0; i < 2; i++)
            Positioned(
              left: 20 + i * 192,
              top: 812,
              width: 180,
              height: 52,
              child: GestureDetector(
                onTap: () => _send('I need help with ${['verification', 'payouts'][i]}.'),
                child: Container(
                  decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(20)),
                  alignment: Alignment.center,
                  child: Text(
                    ['Verification', 'Payouts'][i],
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
