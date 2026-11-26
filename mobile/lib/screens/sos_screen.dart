import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _SosScreenState extends State<SosScreen> {
  static const _incidents = [
    ('Road accident', 'road_accident'),
    ('Vehicle breakdown', 'vehicle_breakdown'),
    ('Harassment', 'harassment'),
    ('Medical', 'medical'),
    ('Unsafe area', 'other'),
  ];
  static const _relationships = ['parent', 'spouse', 'sibling', 'friend', 'relative', 'other'];

  Timer? _holdTimer;
  double _hold = 0;
  String _incident = 'road_accident';
  List<Map<String, dynamic>> _contacts = [];
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _relationship = 'parent';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _holdStart() {
    _resetHold();
    final t0 = DateTime.now();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      final p = DateTime.now().difference(t0).inMilliseconds / 3000;
      if (p >= 1) {
        _resetHold();
        _raise('sos');
      } else {
        setState(() => _hold = p);
      }
    });
  }

  void _resetHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (mounted) setState(() => _hold = 0);
  }

  Future<void> _raise(String kind, [String? details]) async {
    try {
      await widget.state.api.post('/v1/sos', body: {'kind': kind, if (details != null) 'details': details});
      if (!mounted) return;
      showToast(
        context,
        kind == 'sos' ? 'SOS sent to the safety team. Stay where you are if it’s safe.' : 'Incident reported. The safety team will contact you.',
      );
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not send the alert');
    }
  }

  Future<void> _openAddContact() async {
    if (_saving || _contacts.length >= 2) return;

    _name.clear();
    _phone.clear();
    _relationship = 'parent';
    FocusScope.of(context).unfocus();

    await showDialog<void>(
      context: context,
      barrierDismissible: !_saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add emergency contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'Enter contact name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Relationship'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final relationship in _relationships)
                          ChoiceChip(
                            label: Text(
                              relationship[0].toUpperCase() +
                                  relationship.substring(1),
                            ),
                            selected: _relationship == relationship,
                            onSelected: _saving
                                ? null
                                : (_) {
                                    setDialogState(() {
                                      _relationship = relationship;
                                    });
                                  },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        hintText: 'Enter phone number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () => _saveContact(dialogContext, setDialogState),
                  child: Text(_saving ? 'SAVING…' : 'SAVE CONTACT'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveContact(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (name.isEmpty || digits.length < 10) {
      showToast(context, 'Enter a name and a valid phone number');
      return;
    }

    // Local state only: do not call the backend for this temporary flow.
    setState(() {
      _contacts = [
        ..._contacts,
        {
          'id': 'local-emergency-contact-${DateTime.now().microsecondsSinceEpoch}',
          'name': name,
          'relationship': _relationship,
          'phone': phone,
          'isPrimary': false,
        },
      ];
    });

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    _name.clear();
    _phone.clear();
    showToast(context, 'Emergency contact added');
  }

  Future<void> _removeContact(Map<String, dynamic> contact) async {
    setState(() {
      _contacts.removeWhere((item) => item['id'] == contact['id']);
    });
    showToast(context, 'Emergency contact removed');
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
    final contacts = _contacts.take(2).toList();

    return DesignCanvas(
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            width: 412,
            height: 420,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFDE6E4), Color(0x99FDE6E4), Color(0x00FDE6E4)],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
          ),
          BackBar(
            title: 'Safety & SOS',
            right: Pill(x: 281, y: 52, w: 111, label: 'Cover active', bg: pillOk.bg, fg: pillOk.fg, dot: pillOk.fg),
          ),
          Positioned(
            left: 111,
            top: 112,
            width: 190,
            height: 190,
            child: Transform.scale(
              scale: 1 + _hold * 0.12,
              child: const DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0x17E5484D)),
              ),
            ),
          ),
          DBox(x: 126, y: 127, w: 160, h: 160, r: 80, bg: const Color(0x26E5484D)),
          Positioned(
            left: 144,
            top: 140,
            width: 133,
            height: 133,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _holdStart(),
              onTapUp: (_) => _resetHold(),
              onTapCancel: _resetHold,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE7393C), Color(0xFFB1171A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Color(0x59BE1E1E), offset: Offset(0, 16), blurRadius: 30)],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('SOS',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white, height: 38 / 30)),
                    Text(
                      _hold > 0 ? 'Sending in ${(3 - _hold * 3).ceil()}…' : 'Hold 3 seconds',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white, height: 17 / 10.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const DTxt(
            'Holding sends your location to the VP Nexues safety team. For immediate danger, also call 112.',
            x: 62,
            y: 321,
            w: 288,
            s: 13.5,
            lh: 20.5,
            c: Color(0xFF7A1F1F),
            align: TextAlign.center,
          ),

          for (var i = 0; i < 3; i++)
            Positioned(
              left: 20 + i * 127.5,
              top: 401,
              width: 117,
              height: 95,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  switch (i) {
                    case 0:
                      _dial('112');
                    case 1:
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupportScreen(state: widget.state)));
                    case 2:
                      _raise('other', 'Shared live location from SOS screen');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFF3D6D2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            [LucideIcons.phone, LucideIcons.shield, LucideIcons.navigation][i],
                            size: 19,
                            color: [const Color(0xFFC92526), C.green, const Color(0xFF145B73)][i],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['Call 112', 'Safety team', 'Share live\nlocation'][i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: C.ink, height: 15 / 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          DBox(x: 20, y: 510, w: 372, h: 209, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          const DTxt('Report an incident', x: 36, y: 525, s: 15, wt: FontWeight.w700, lh: 21),
          const DTxt('Not an emergency? Tell us what happened.', x: 36, y: 548, s: 12, lh: 16.8, c: C.muted),
          Positioned(
            left: 36,
            top: 571,
            width: 345,
            child: Wrap(
              spacing: 7,
              runSpacing: 10,
              children: [
                for (final item in _incidents)
                  GestureDetector(
                    onTap: () => setState(() => _incident = item.$2),
                    child: IntrinsicWidth(
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _incident == item.$2 ? C.green : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: _incident == item.$2 ? null : Border.all(color: C.line),
                        ),
                        child: Text(
                          item.$1,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _incident == item.$2 ? Colors.white : C.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Btn(
            x: 37,
            y: 659,
            w: 338,
            h: 55,
            kind: BtnKind.outline,
            label: 'SEND REPORT',
            onTap: () => _raise(_incident, _incidents.firstWhere((e) => e.$2 == _incident).$1),
          ),

          // Keep the complete card inside the visible mobile canvas.
          // DesignCanvas reserves the last 30 design pixels as bottom slack,
          // so the usable content area ends at Y=885 (not Y=915).
          // The incident button ends at Y=714; this card starts at Y=724.
          Positioned(
            left: 20,
            top: 724,
            width: 372,
            height: 150,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
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
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: C.accent,
                          ),
                        ),
                      ),
                      if (_contacts.length < 2)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openAddContact(),
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.plus,
                                    size: 15,
                                    color: C.green,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: C.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: contacts.isEmpty
                        ? const SizedBox.expand(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Text(
                                  'Add someone we should call if you’re in an accident.',
                                  maxLines: 2,
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    height: 1.35,
                                    color: C.muted,
                                  ),
                                ),
                              ),
                            ),
                          )
                            : Column(
                                children: [
                                  for (var i = 0; i < contacts.length; i++) ...[
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: C.tint5,
                                      ),
                                    SizedBox(
                                      height: 43,
                                      child: Row(
                                        children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: i.isOdd
                                                        ? C.yellow
                                                        : C.green,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    initials(
                                                      asString(
                                                        contacts[i]['name'],
                                                        'C',
                                                      ),
                                                    ),
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: i.isOdd
                                                          ? C.ink
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${asString(contacts[i]['name'])} · ${asString(contacts[i]['relationship'])}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: C.ink,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _mask(
                                                          asString(
                                                            contacts[i]['phone'],
                                                          ),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontSize: 11,
                                                          color: C.muted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                if (asBool(
                                                  contacts[i]['isPrimary'],
                                                ))
                                                  Pill(
                                                    label: 'Primary',
                                                    bg: pillOk.bg,
                                                    fg: pillOk.fg,
                                                    dot: pillOk.fg,
                                                  )
                                                else
                                                  IconButton(
                                                    tooltip: 'Remove contact',
                                                    onPressed: () =>
                                                        _removeContact(
                                                      contacts[i],
                                                    ),
                                                    icon: const Icon(
                                                      LucideIcons.trash2,
                                                      size: 16,
                                                      color: C.muted,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                              ],
                                      ),
                                    ),
                                  ],
                                ],
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
}
