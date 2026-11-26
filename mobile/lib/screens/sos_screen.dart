import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'support_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with TickerProviderStateMixin {
      // Idle SOS wave animation
late AnimationController _idleWaveController;

// Pressed SOS wave animation
late AnimationController _pressWaveController;

// Hold progress (0 → 1 over 3 seconds). Drives the ring and the countdown,
// so the screen is only rebuilt when the visible second changes instead of
// 20 times a second like the old Timer.periodic loop did.
late AnimationController _holdController;

// How far (logical px) the finger may travel before we call it a swipe and
// give up, and how far it may drift along the scroll axis (which would start
// scrolling the page under us).
static const double _maxHoldTravel = 60;
static const double _scrollSlop = 18;

int? _holdPointer;
Offset? _holdOrigin;
bool _holding = false;
int _remaining = 0;
bool _sending = false;
bool _sent = false;
  static const _incidents = [
    ('Road accident', 'road_accident'),
    ('Vehicle breakdown', 'vehicle_breakdown'),
    ('Harassment', 'harassment'),
    ('Medical', 'medical'),
    ('Unsafe area', 'other'),
  ];
  static const _relationships = [
    'parent',
    'spouse',
    'sibling',
    'friend',
    'relative',
    'other',
  ];

  String _incident = 'road_accident';
  List _contacts = [];
  bool _loading = true;
  bool _add = false;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _relationship = 'parent';
  bool _saving = false;

  @override
void initState() {
  super.initState();

  _idleWaveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  _pressWaveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  _holdController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..addListener(_onHoldTick);

  _loadContacts();
}

  @override
void dispose() {
  _holdController.dispose();
  _idleWaveController.dispose();
  _pressWaveController.dispose();

  _name.dispose();
  _phone.dispose();

  super.dispose();
}

  Future<void> _loadContacts() async {
    try {
      final res = await widget.state.api.get('/v1/emergency-contacts');
      if (!mounted) return;
      setState(() {
        _contacts = mapList(res);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Hold-to-send ─────────────────────────────────────────────────────
  //
  // Raw pointer events are used on purpose: a GestureDetector only wins the
  // gesture arena when the finger lifts, so any movement past the ~18px touch
  // slop — even a sideways jiggle that wouldn't scroll anything — used to
  // reject the tap, fire onTapCancel and silently kill the hold (and with it
  // every haptic). A Listener keeps receiving events for the whole pointer
  // lifetime, so we decide ourselves what should abort the hold.

  void _onPointerDown(PointerDownEvent e) {
    if (_holdPointer != null) return;
    _holdStart(e);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_holding || e.pointer != _holdPointer) return;

    final origin = _holdOrigin;
    if (origin == null) return;

    final delta = e.position - origin;

    // Drifting along the scroll axis starts scrolling the page under us.
    if (delta.dy.abs() > _scrollSlop) {
      _resetHold();
      return;
    }

    // Wandered off the button: that's a swipe, not a hold. Never send an SOS
    // because of it.
    if (delta.distance > _maxHoldTravel) _resetHold();
  }

  void _onPointerUp(PointerUpEvent e) {
    if (e.pointer != _holdPointer) return;
    _resetHold();
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer != _holdPointer) return;
    _resetHold();
  }

  void _holdStart(PointerDownEvent e) {
  if (_sending || _sent) return;

  _holdPointer = e.pointer;
  _holdOrigin = e.position;

  // Immediate feedback so the button never feels dead, plus a tick for the
  // "Sending in 3…" the label is about to show.
  HapticFeedback.lightImpact();

  setState(() {
    _holding = true;
    _remaining = 3;
  });

  _idleWaveController.stop();
  _pressWaveController.repeat();

  _holdController.forward(from: 0);
}

// Fires on every animation frame while holding. The ring is painted straight
// from the controller, so the only setState here is the countdown label —
// which is also what drives the tick haptics (3 → 2 → 1).
void _onHoldTick() {
  if (!_holding) return;

  if (_holdController.value >= 1) {
    _holdComplete();
    return;
  }

  final remaining = (3 - _holdController.value * 3).ceil();
  if (remaining != _remaining) {
    setState(() => _remaining = remaining);
    HapticFeedback.mediumImpact();
  }
}

void _holdComplete() {
  if (!_holding) return;

  _holding = false;
  _holdPointer = null;
  _holdOrigin = null;
  _pressWaveController.stop();

  setState(() {
    _remaining = 0;
    _sending = true;
  });

  // Stronger vibration pattern when SOS is triggered
  _sendHapticPattern();

  _raise('sos');
}

void _resetHold() {
  if (!_holding) return;

  _holding = false;
  _holdPointer = null;
  _holdOrigin = null;

  _holdController.stop();
  _holdController.reset();

  if (mounted) {
    setState(() => _remaining = 0);

    _pressWaveController.stop();
    _pressWaveController.reset();

    _idleWaveController.repeat();
  }
}

// Arms the button again after an alert was sent. Without this, `_sent` stayed
// true forever and the button silently refused every later press.
void _rearm() {
  HapticFeedback.selectionClick();

  setState(() {
    _sent = false;
    _sending = false;
    _holding = false;
    _remaining = 0;
  });

  _holdController.reset();
  _pressWaveController.stop();
  _pressWaveController.reset();
  _idleWaveController.repeat();
}

// SOS sent vibration pattern
Future<void> _sendHapticPattern() async {
  await HapticFeedback.heavyImpact();

  await Future.delayed(const Duration(milliseconds: 120));
  await HapticFeedback.heavyImpact();

  await Future.delayed(const Duration(milliseconds: 120));
  await HapticFeedback.vibrate();
}

  Future<void> _raise(String kind, [String? details]) async {
  try {
    await widget.state.api.post(
      '/v1/sos',
      body: {
        'kind': kind,
        if (details != null) 'details': details,
      },
    );

    if (!mounted) return;

    if (kind == 'sos') {
      setState(() {
        _sending = false;
        _sent = true;
      });

      _pressWaveController.stop();

      // Confirmation that the alert actually reached the safety team.
      HapticFeedback.successNotification();
    }

    showToast(
      context,
      kind == 'sos'
          ? 'SOS sent to the safety team. Stay where you are if it’s safe.'
          : 'Incident reported. The safety team will contact you.',
    );

  } catch (e) {
    if (mounted) {
      setState(() {
        _sending = false;
        _sent = false;
        _holding = false;
        _remaining = 0;
      });

      _holdController.reset();
      _pressWaveController.stop();
      _pressWaveController.reset();
      _idleWaveController.repeat();

      showToast(
        context,
        e is ApiException
            ? e.message
            : 'Could not send the alert',
      );
    }
  }
}

  Future<void> _saveContact() async {
    FocusScope.of(context).unfocus();
    if (_name.text.trim().isEmpty ||
        _phone.text.replaceAll(RegExp(r'\D'), '').length < 10) {
      showToast(context, 'Enter a name and a valid phone number');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.state.api.post('/v1/emergency-contacts', body: {
        'name': _name.text.trim(),
        'relationship': _relationship,
        'phone': _phone.text.trim(),
      });
      if (!mounted) return;
      showToast(context, 'Emergency contact saved');
      setState(() {
        _add = false;
        _name.clear();
        _phone.clear();
      });
      await _loadContacts();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not save the contact',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeContact(Map<String, dynamic> c) async {
    try {
      await widget.state.api
          .delete('/v1/emergency-contacts/${asString(c['id'])}');
      await _loadContacts();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not remove the contact',
        );
      }
    }
  }

  Future<void> _dial(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) showToast(context, 'Could not open the dialler');
    }
  }

  String _mask(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phone;
    return '•••••• ${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
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
                      // SOS Hold Button
                      Center(
                        child: SizedBox(
                          width: 196,
                          height: 196,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // First animated wave
AnimatedBuilder(
  animation: _idleWaveController,
  builder: (context, child) {
    final value = _idleWaveController.value;

    return Opacity(
      opacity: (1 - value) * 0.45,
      child: Transform.scale(
        scale: 0.85 + value * 0.35,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE5484D),
              width: 2,
            ),
          ),
        ),
      ),
    );
  },
),

// Second animated wave
AnimatedBuilder(
  animation: _idleWaveController,
  builder: (context, child) {
    final value =
        (_idleWaveController.value + 0.5) % 1.0;

    return Opacity(
      opacity: (1 - value) * 0.35,
      child: Transform.scale(
        scale: 0.85 + value * 0.35,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE5484D),
              width: 2,
            ),
          ),
        ),
      ),
    );
  },
),
                              // Hold progress ring — driven straight off the
                              // animation controller so it stays smooth
                              // without rebuilding this whole screen.
                              AnimatedBuilder(
                                animation: _holdController,
                                builder: (context, child) =>
                                    Transform.scale(
                                  scale: 1 + _holdController.value * 0.12,
                                  child: child,
                                ),
                                child: Container(
                                  width: 190,
                                  height: 190,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0x17E5484D),
                                  ),
                                ),
                              ),
                              Container(
                                width: 160,
                                height: 160,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0x26E5484D),
                                ),
                              ),
                              Listener(
  behavior: HitTestBehavior.opaque,
  onPointerDown: _onPointerDown,
  onPointerMove: _onPointerMove,
  onPointerUp: _onPointerUp,
  onPointerCancel: _onPointerCancel,
  child: Semantics(
    button: true,
    label: 'Hold for three seconds to send an SOS',
    child: AnimatedBuilder(
    animation: _pressWaveController,
    builder: (context, child) {
      final wave = _pressWaveController.value;

      return Transform.scale(
        scale: _sending || _sent
            ? 1.0
            : 1.0 + wave * 0.06,
        child: child,
      );
    },
    child: Container(
                                  width: 134,
                                  height: 134,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFE7393C),
                                        Color(0xFFB1171A),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x59BE1E1E),
                                        offset: Offset(0, 14),
                                        blurRadius: 28,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'SOS',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
  _sent
      ? 'SOS SENT!'
      : _sending
          ? 'Sending alert...'
          : _holding
              ? 'Sending in $_remaining…'
              : 'Hold 3 seconds',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
  ),
                              ),
  ),
                            ],
                          ),
                        ),
                      ),
                      
                      // After an alert has gone out, the button used to stay
                      // stuck forever with no way to send another one.
                      if (_sent) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: _rearm,
                            style: TextButton.styleFrom(
                              foregroundColor: C.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                            ),
                            child: const Text(
                              'START A NEW ALERT',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'Press and hold to send your location to the VP Nexues safety team. If you are in immediate danger, call 112 as well.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            height: 20 / 13,
                            color: Color(0xFF7A1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3 quick emergency actions
                      Row(
                        children: [
                          Expanded(
                            child: _SosActionCard(
                              icon: LucideIcons.phone,
                              color: const Color(0xFFC92526),
                              label: 'Call 112',
                              onTap: () => _dial('112'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SosActionCard(
                              icon: LucideIcons.shield,
                              color: C.green,
                              label: 'Safety team',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SupportScreen(state: widget.state),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SosActionCard(
                              icon: LucideIcons.navigation,
                              color: const Color(0xFF145B73),
                              label: 'Share live\nlocation',
                              onTap: () => _raise(
                                'other',
                                'Shared live location from SOS screen',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Report an incident card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: C.line),
                          boxShadow: sh(8, 20, .04),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Report an incident',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: C.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Not an emergency? Tell us what happened.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: C.muted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final item in _incidents)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _incident = item.$2);
                                    },
                                    child: Container(
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _incident == item.$2
                                            ? C.green
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: _incident == item.$2
                                            ? null
                                            : Border.all(color: C.line),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.$1,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: _incident == item.$2
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
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _raise(
                                    _incident,
                                    _incidents
                                        .firstWhere((e) => e.$2 == _incident)
                                        .$1,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: C.green,
                                  side: const BorderSide(
                                    color: C.line,
                                    width: 1.3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'SEND REPORT',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Emergency contacts card
                      Container(
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
                              children: [
                                const Expanded(
                                  child: Text(
                                    'EMERGENCY CONTACTS',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: C.accent,
                                    ),
                                  ),
                                ),
                                if (_contacts.length < 3 && !_loading)
                                  TextButton(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _add = true);
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 32),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: C.green,
                                    ),
                                    child: const Text(
                                      '+ Add',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_loading)
                              const Text(
                                'Loading…',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: C.muted,
                                ),
                              )
                            else if (_contacts.isEmpty)
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Add someone we should call if you’re in an accident.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: C.muted,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _add = true);
                                    },
                                    icon: const Icon(LucideIcons.plus, size: 15),
                                    label: const Text(
                                      'ADD',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: C.green,
                                      side: const BorderSide(color: C.green),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  for (var i = 0; i < _contacts.length; i++) ...[
                                    if (i > 0)
                                      const Divider(
                                        height: 16,
                                        thickness: 1,
                                        color: C.tint5,
                                      ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: i.isOdd ? C.yellow : C.green,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            initials(
                                              asString(
                                                _contacts[i]['name'],
                                                'C',
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: i.isOdd
                                                  ? C.ink
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${asString(_contacts[i]['name'])} · ${asString(_contacts[i]['relationship'])}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: C.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _mask(
                                                  asString(
                                                    _contacts[i]['phone'],
                                                  ),
                                                ),
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 11.5,
                                                  color: C.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (asBool(_contacts[i]['isPrimary']))
                                          Pill(
                                            label: 'Primary',
                                            bg: pillOk.bg,
                                            fg: pillOk.fg,
                                            dot: pillOk.fg,
                                          )
                                        else
                                          IconButton(
                                            tooltip: 'Remove contact',
                                            onPressed: () {
                                              HapticFeedback.selectionClick();
                                              _removeContact(_contacts[i]);
                                            },
                                            icon: const Icon(
                                              LucideIcons.trash2,
                                              size: 16,
                                              color: C.muted,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
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

          if (_add)
            Modal(
              onClose: () => setState(() => _add = false),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Emergency contact',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: C.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SosModalField(
                      label: 'Name',
                      controller: _name,
                      placeholder: 'Full name',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final r in _relationships)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _relationship = r);
                            },
                            child: Container(
                              height: 36,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color:
                                    _relationship == r ? C.green : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: _relationship == r
                                    ? null
                                    : Border.all(color: C.line),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    r[0].toUpperCase() + r.substring(1),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _relationship == r
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
                    const SizedBox(height: 12),
                    _SosModalField(
                      label: 'Mobile number',
                      controller: _phone,
                      placeholder: '10-digit number',
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _saveContact();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.green,
                          disabledBackgroundColor: C.green.withOpacity(0.6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _saving ? 'SAVING…' : 'SAVE CONTACT',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF991B1B), Color(0xFFD92D20)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 15,
              top: 18,
              width: 90,
              height: 120,
              child: Transform.rotate(
                angle: 25 * math.pi / 180,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x28FFFFFF),
                    borderRadius: BorderRadius.circular(65),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 22),
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
                  const Expanded(
                    child: Text(
                      'Safety & SOS',
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
                  Pill(
                    label: 'Cover active',
                    bg: pillOk.bg,
                    fg: pillOk.fg,
                    dot: pillOk.fg,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosActionCard extends StatelessWidget {
  const _SosActionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 98,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF3D6D2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: C.ink,
                  height: 15 / 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosModalField extends StatelessWidget {
  const _SosModalField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.keyboard,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: C.ink,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.line),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: C.ink,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: C.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}