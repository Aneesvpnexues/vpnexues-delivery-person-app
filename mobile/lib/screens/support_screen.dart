import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'sos_screen.dart';

/// Temporarily pauses all server/API/database calls in this screen.
/// Set to `false` when you are ready to reconnect the backend.
const bool _pauseBackend = true;

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
    if (_pauseBackend) {
      // Backend paused: skip API call and finish loading immediately.
      if (mounted) setState(() => _loading = false);
      return;
    }

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
      _chat(initialMessage: topic);
      return;
    }

    setState(() => _issue = topic);

    if (_pauseBackend) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SupportChatScreen(
            state: widget.state,
            topic: topic,
            initialMessage: '$topic on order #${asString(order['orderCode'])}.',
          ),
        ),
      );
      return;
    }

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

  void _chat({String? initialMessage}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportChatScreen(
          state: widget.state,
          initialMessage: initialMessage,
        ),
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
  16,
  0,
  16,
  6 + MediaQuery.of(context).padding.bottom,
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
                          subtitle: 'Instant reply',
                          onTap: () => _chat(),
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
                                    onPressed: () => _chat(),
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
    this.initialMessage,
  });

  final AppState state;
  final String? ticketId;
  final String topic;
  final String? initialMessage;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  static const List<(String label, String message)> _quickReplies = [
    ('Payouts', 'I need help with my payout.'),
    ('Verification', 'I need help with document verification.'),
    ('Customer unreachable', 'The customer is not answering calls or messages.'),
    ('Damaged veggies', 'Some vegetables/groceries are damaged or spoiled.'),
    ('Missing items', 'Some items are missing from the hub crate.'),
    ('Wrong address', 'The customer delivery address is incorrect.'),
    ('Delivery OTP', 'Customer does not have the delivery OTP code.'),
    ('Hub delay', 'There is a long waiting delay at the VP Nexues hub.'),
    ('Change zone', 'I want to change my delivery hub or zone.'),
  ];

  static const List<String> _faqShortcuts = [
    'When do I get paid?',
    'Why is my document still in review?',
    'Customer has no delivery code',
    'How do I change my delivery zone?',
    'What does accident cover include?',
    'What if vegetables are damaged?',
  ];

  String? _ticketId;
  List _messages = [];
  final _draft = TextEditingController();
  final _scrollController = ScrollController();
  bool _busy = false;
  Timer? _poll;
  int _localMsgCounter = 1;

  @override
  void initState() {
    super.initState();
    _ticketId = widget.ticketId;

    if (!_pauseBackend) {
      _load();
      _poll =
          Timer.periodic(const Duration(seconds: 10), (_) => _load(quiet: true));
    }

    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(widget.initialMessage);
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _draft.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _generateInstantReply(String input) {
    final text = input.toLowerCase();

    if (text.contains('payout') ||
        text.contains('paid') ||
        text.contains('pay') ||
        text.contains('salary') ||
        text.contains('money') ||
        text.contains('earning') ||
        text.contains('bank') ||
        text.contains('withdraw')) {
      return 'VP Nexues weekly earnings (Mon–Sun) are credited every Monday by 6 PM. If you need funds earlier, use Instant Payout in the Earnings tab. For a failed transfer, share your order/payout date and we will check it.';
    }

    if (text.contains('verif') ||
        text.contains('document') ||
        text.contains('review') ||
        text.contains('kyc') ||
        text.contains('aadhaar') ||
        text.contains('pan') ||
        text.contains('license') ||
        text.contains('rc')) {
      return 'Document verification at VP Nexues usually takes 2–24 hours. Please make sure your uploaded photos are clear and not expired. You will get an in-app notification as soon as each document is approved.';
    }

    if (text.contains('unreachable') ||
        text.contains('not answering') ||
        text.contains('no response') ||
        text.contains('call') ||
        text.contains('phone')) {
      return 'Please try calling the customer 3 times with a 2-minute gap and send an in-app message. If there is still no response after 10 minutes, mark "Customer Unreachable" on the order screen and return the groceries to your VP Nexues hub.';
    }

    if (text.contains('damage') ||
        text.contains('spoil') ||
        text.contains('rotten') ||
        text.contains('leak') ||
        text.contains('broken') ||
        text.contains('veggie') ||
        text.contains('vegetable') ||
        text.contains('fresh')) {
      return 'Sorry about that! Please take a quick photo of the damaged or spoiled produce and inform the customer if they are present. Do not pay out of pocket — return the affected items to the VP Nexues hub so we can log a quality replacement.';
    }

    if (text.contains('missing') ||
        text.contains('short') ||
        text.contains('crate') ||
        text.contains('bag') ||
        text.contains('item')) {
      return 'If an item is missing before pickup, notify the VP Nexues hub supervisor immediately before swiping Picked Up. If you already left the hub, let the customer know and we will issue an instant refund or re-dispatch from our end.';
    }

    if (text.contains('address') ||
        text.contains('location') ||
        text.contains('map') ||
        text.contains('pin') ||
        text.contains('wrong')) {
      return 'Call the customer to confirm the exact landmark or gate. If the new drop point is within 1 km, you can deliver and extra distance pay will be adjusted. If it is farther away, do not travel without support approval.';
    }

    if (text.contains('otp') ||
        text.contains('code') ||
        text.contains('delivery code')) {
      return 'Ask the customer to check the VP Nexues order screen or their SMS for the 4-digit delivery code. If they still cannot find it, use the "Verify without OTP" option on the handover screen after confirming their name.';
    }

    if (text.contains('hub') ||
        text.contains('delay') ||
        text.contains('wait') ||
        text.contains('packing') ||
        text.contains('late')) {
      return 'Thanks for letting us know about the VP Nexues hub delay. Your wait time is tracked automatically once you mark "Arrived at Hub" so your delivery rating will not be affected.';
    }

    if (text.contains('zone') ||
        text.contains('area') ||
        text.contains('city') ||
        text.contains('radius') ||
        text.contains('shift')) {
      return 'To update your delivery area, go to Settings → City, hub & delivery radius. Radius updates apply immediately, while VP Nexues hub or city transfers are reviewed within 24 hours.';
    }

    if (text.contains('accident') ||
        text.contains('insurance') ||
        text.contains('cover') ||
        text.contains('emergency') ||
        text.contains('sos') ||
        text.contains('hurt') ||
        text.contains('police') ||
        text.contains('crash')) {
      return 'Your safety comes first. You are covered under VP Nexues partner accident cover while online and on active orders. For immediate emergencies, tap the red SOS button on the Support screen.';
    }

    if (text.contains('hi') ||
        text.contains('hello') ||
        text.contains('hey') ||
        text.contains('good morning') ||
        text.contains('good evening')) {
      return 'Hello! Welcome to VP Nexues Partner Support. How can I help you with your deliveries, hub pickup, documents, or payouts today?';
    }

    if (text.contains('thank') ||
        text.contains('ok') ||
        text.contains('okay') ||
        text.contains('great') ||
        text.contains('done')) {
      return 'You’re welcome! Ride safe and let us know anytime if you need help with a VP Nexues delivery.';
    }

    return 'Got it! We’ve noted your message: "$input". You can also tap one of the quick options or FAQ shortcuts below for instant VP Nexues partner guidance.';
  }

  Future<void> _load({bool quiet = false}) async {
    if (_pauseBackend) return;

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

    _draft.clear();

    if (_pauseBackend) {
      final now = DateTime.now().toIso8601String();
      final userMsg = <String, dynamic>{
        'id': 'local_${_localMsgCounter++}',
        'sender': 'partner',
        'body': msg,
        'createdAt': now,
      };
      final botReply = <String, dynamic>{
        'id': 'local_${_localMsgCounter++}',
        'sender': 'bot',
        'body': _generateInstantReply(msg),
        'createdAt': now,
      };

      setState(() {
        _messages = [..._messages, userMsg, botReply];
      });
      _scrollToBottom();
      return;
    }

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
      setState(() {});
      _scrollToBottom();
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
    final greeting = <String, dynamic>{
      'id': '0',
      'sender': 'bot',
      'body':
          'Hi ${firstName(asString(me['fullName']))}! Welcome to VP Nexues Partner Support. Ask about a vegetable/grocery delivery, hub delay, OTP, documents, or payouts — we’ll reply right away.',
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
                          'VP Nexues Support',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _pauseBackend
                              ? 'Instant support assistant'
                              : (_ticketId != null
                                  ? 'Agents usually reply within a few minutes'
                                  : 'Start a conversation'),
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
              controller: _scrollController,
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

          // Quick replies + FAQ shortcuts + Composer
          Container(
            decoration: BoxDecoration(
              color: C.bg,
              border: Border(top: BorderSide(color: C.line.withOpacity(0.7))),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              6 + MediaQuery.of(context).padding.bottom,
            ),
            child: Transform.translate(
  offset: const Offset(0, -8),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
                // Quick issue topics
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickReplies.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final item = _quickReplies[i];
                      return OutlinedButton(
                        onPressed: _busy ? null : () => _send(item.$2),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: C.green,
                          side: const BorderSide(color: C.line),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          item.$1,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 0),

                // FAQ question shortcuts
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _faqShortcuts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final question = _faqShortcuts[i];
                      return InkWell(
                        onTap: _busy ? null : () => _send(question),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF5DB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFDDEBC3),
                            ),
                          ),
                          child: Text(
                            question,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: C.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Message composer
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
          )
        ],
      ),
    );
  }
}