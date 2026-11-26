import 'dart:async';
import 'dart:math' as math;

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
    (
      LucideIcons.wallet,
      'When do I get paid?',
      'Earnings from Monday to Sunday are paid every Monday by 6 PM. Need it sooner? Use Instant payout from the Earnings tab.',
    ),
    (
      LucideIcons.fileText,
      'Why is my document still in review?',
      'Reviews take 2–24 hours. You’ll get a notification as each document is approved.',
    ),
    (
      LucideIcons.lock,
      'Customer has no delivery code',
      'Ask them to open the order in their app or check SMS. If it still fails, tap “Contact support” on the hand-over screen.',
    ),
    (
      LucideIcons.mapPin,
      'Changing my delivery zone',
      'Open Settings → City, hub & delivery radius. Radius changes apply at once; city or hub changes are confirmed by support.',
    ),
    (
      LucideIcons.shield,
      'What does accident cover include?',
      'You are covered while online and on an active order. Use Safety & SOS to reach the safety team.',
    ),
  ];

  static const _issues = [
    'Customer unreachable',
    'Wrong address',
    'Items damaged',
    'Hub delay',
  ];

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
      final res = await widget.state.api
          .get('/v1/orders', query: {'tab': 'active', 'limit': '1'});
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
      final ticket = map?['ticket'] is Map
          ? Map<String, dynamic>.from(map!['ticket'] as Map)
          : null;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SupportChatScreen(
            state: widget.state,
            ticketId: asString(ticket?['id']).isEmpty
                ? null
                : asString(ticket?['id']),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _issue = '');
        showToast(
          context,
          e is ApiException ? e.message : 'Could not report that',
        );
      }
    }
  }

  void _chat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportChatScreen(state: widget.state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = _faqs
        .where((f) => q.isEmpty || '${f.$2} ${f.$3}'.toLowerCase().contains(q))
        .toList();
    final order = _order;
    final me = widget.state.partner ?? {};

    return Scaffold(
      backgroundColor: C.bg,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, firstName(asString(me['fullName']))),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                28 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 3 quick-action cards
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: LucideIcons.messageCircle,
                          title: 'Chat',
                          subtitle: 'Reply in ~2 min',
                          onTap: _chat,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionCard(
                          icon: LucideIcons.phone,
                          title: 'Call',
                          subtitle: '24 × 7 line',
                          onTap: () => showToast(
                            context,
                            'The partner helpline number will appear here once it’s set up',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionCard(
                          icon: LucideIcons.alertTriangle,
                          title: 'SOS',
                          subtitle: 'Emergency',
                          danger: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SosScreen(state: widget.state),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Active order / quick report card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5DB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFDDEBC3)),
                    ),
                    child: _loading
                        ? const Text(
                            'Checking your orders…',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: C.muted,
                            ),
                          )
                        : order != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Problem with #${asString(order['orderCode'])}?',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: C.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final c in _issues)
                                        GestureDetector(
                                          onTap: () => _report(c),
                                          child: Container(
                                            height: 38,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _issue == c
                                                  ? C.green
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(19),
                                              border: _issue == c
                                                  ? null
                                                  : Border.all(color: C.line),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  c,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: _issue == c
                                                        ? Colors.white
                                                        : C.ink,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'No active order',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: C.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Problems with a delivery can be reported from the order itself. For anything else, start a chat.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      height: 19 / 13,
                                      color: C.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton(
                                    onPressed: _chat,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: C.green,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 11,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'START A CHAT',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                  const SizedBox(height: 22),

                  // Popular topics
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'POPULAR TOPICS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: C.accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        'No topics match “${_search.text.trim()}”.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: C.muted,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < list.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _faq(list[i], _faqs.indexOf(list[i])),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    final topPad = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF083F2A), Color(0xFF1F7945)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 15,
              top: 20,
              width: 90,
              height: 130,
              child: Transform.rotate(
                angle: 25 * math.pi / 180,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x3878B43C),
                    borderRadius: BorderRadius.circular(65),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Material(
                        color: const Color(0x24FFFFFF),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              LucideIcons.arrowLeft,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Help & support',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Hi $name, how can we help?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.search,
                          size: 18,
                          color: C.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: C.ink,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Search: payout, OTP, insurance…',
                              hintStyle: TextStyle(
                                color: C.muted,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (_search.text.isNotEmpty)
                          GestureDetector(
                            onTap: _search.clear,
                            child: const Icon(
                              LucideIcons.x,
                              size: 16,
                              color: C.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faq((IconData, String, String) f, int index) {
    final open = _open == index;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.line),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _open = open ? -1 : index),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF5DB),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Icon(f.$1, size: 18, color: C.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f.$2,
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
                    Icon(
                      open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 17,
                      color: const Color(0xFF8A988F),
                    ),
                  ],
                ),
                if (open) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 50, right: 24),
                    child: Text(
                      f.$3,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: C.muted,
                        height: 1.45,
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? const Color(0xFFC92526) : C.green;

    return Material(
      color: danger ? const Color(0xFFFFF5F3) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: danger ? const Color(0xFFF5C9C4) : C.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFFFDE0DD)
                      : const Color(0xFFEEF5DB),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: danger ? accent : C.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: C.muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({
    super.key,
    required this.state,
    this.ticketId,
    this.topic = 'General help',
  });

  final AppState state;
  final String? ticketId;
  final String topic;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  String? _ticketId;
  List _messages = [];
  final _draft = TextEditingController();
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _ticketId = widget.ticketId;
    _load();
    _poll =
        Timer.periodic(const Duration(seconds: 10), (_) => _load(quiet: true));
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
      if (!quiet && mounted) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not load the conversation',
        );
      }
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
        final ticket = map?['ticket'] is Map
            ? Map<String, dynamic>.from(map!['ticket'] as Map)
            : null;
        _ticketId = asString(ticket?['id']);
        _messages = mapList(map?['messages']);
      } else {
        final res = await widget.state.api.post(
          '/v1/support/tickets/$_ticketId/messages',
          body: {'message': msg},
        );
        if (res is Map) {
          _messages = [..._messages, Map<String, dynamic>.from(res)];
        }
      }
      if (!mounted) return;
      _draft.clear();
      setState(() {});
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not send the message',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.partner ?? {};
    final topPad = MediaQuery.of(context).padding.top;
    final greeting = {
      'id': '0',
      'sender': 'bot',
      'body':
          'Hi ${firstName(asString(me['fullName']))}. Tell us what you need help with — a delivery, a payout or your documents — and a support agent will reply here.',
      'createdAt': '',
    };
    final all = [greeting, ..._messages];

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          // Header
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF083F2A), Color(0xFF1F7945)],
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 18),
              child: Row(
                children: [
                  Material(
                    color: const Color(0x24FFFFFF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          LucideIcons.arrowLeft,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Support chat',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _ticketId != null
                              ? 'Agents usually reply within a few minutes'
                              : 'Start a conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFFDFEEE0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = all[i];
                final mine = asString(m['sender']) == 'partner';
                return Align(
                  alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: mine ? C.green : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: mine ? null : Border.all(color: C.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asString(m['body']),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            color: mine ? Colors.white : C.ink,
                            height: 21 / 14.5,
                          ),
                        ),
                        if (asString(m['createdAt']).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            dateTime(m['createdAt']),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: mine ? const Color(0xCCFFFFFF) : C.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick replies + Composer
          Container(
            decoration: BoxDecoration(
              color: C.bg,
              border: Border(top: BorderSide(color: C.line.withOpacity(0.7))),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 2; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _send(
                                    'I need help with ${['verification', 'payouts'][i]}.',
                                  ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: C.green,
                            side: const BorderSide(color: C.line),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            ['Verification', 'Payouts'][i],
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          maxHeight: 110,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: C.line),
                        ),
                        child: TextField(
                          controller: _draft,
                          maxLines: null,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: C.ink,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: 'Type your message…',
                            hintStyle: TextStyle(color: C.muted, fontSize: 14),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _busy ? null : () => _send(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.green,
                          disabledBackgroundColor: C.tint5,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _busy ? '…' : 'SEND',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}