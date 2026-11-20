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
  bool _loading = true;
  bool _add = false;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _relationship = 'parent';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
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

  Future<void> _saveContact() async {
    if (_name.text.trim().isEmpty || _phone.text.replaceAll(RegExp(r'\D'), '').length < 10) {
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
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not save the contact');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeContact(Map<String, dynamic> c) async {
    try {
      await widget.state.api.delete('/v1/emergency-contacts/${asString(c['id'])}');
      await _loadContacts();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not remove the contact');
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: [const Color(0xFFFDE0DD), const Color(0xFFEEF5DB), const Color(0xFFE0EFF3)][i],
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          [LucideIcons.phone, LucideIcons.shield, LucideIcons.navigation][i],
                          size: 19,
                          color: [const Color(0xFFC92526), C.green, const Color(0xFF145B73)][i],
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

          DBox(x: 20, y: 734, w: 372, h: 170, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          const DTxt('EMERGENCY CONTACTS', x: 36, y: 748, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent, ls: 1.2),
          if (_contacts.length < 3 && !_loading)
            DTxt('+ Add', x: 300, y: 750, w: 75, s: 13, wt: FontWeight.w700, lh: 18, c: C.green, align: TextAlign.right,
                onTap: () => setState(() => _add = true)),
          if (_loading)
            const DTxt('Loading…', x: 36, y: 780, s: 12, c: C.muted)
          else if (contacts.isEmpty) ...[
            const DTxt('Add someone we should call if you’re in an accident.', x: 36, y: 780, w: 330, s: 13, lh: 19, c: C.muted),
            Btn(x: 36, y: 826, w: 200, h: 44, fs: 12, icon: LucideIcons.plus, label: 'ADD CONTACT', onTap: () => setState(() => _add = true)),
          ] else
            for (var i = 0; i < contacts.length; i++) ...[
              if (i > 0) DBox(x: 36, y: 822, w: 339, h: 1, bg: C.tint5),
              Positioned(
                left: 36,
                top: 774 + i * 61,
                width: 40,
                height: 40,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: i.isOdd ? C.yellow : C.green, shape: BoxShape.circle),
                  child: Text(
                    initials(asString(contacts[i]['name'], 'C')),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i.isOdd ? C.ink : Colors.white,
                    ),
                  ),
                ),
              ),
              DTxt(
                '${asString(contacts[i]['name'])} · ${asString(contacts[i]['relationship'])}',
                x: 91,
                y: 775 + i * 61,
                w: 190,
                s: 15,
                wt: FontWeight.w700,
                lh: 21,
                maxLines: 1,
              ),
              DTxt(
                _mask(asString(contacts[i]['phone'])),
                x: 91,
                y: 797 + i * 61,
                s: 12,
                lh: 16.8,
                c: C.muted,
                onTap: () => _dial(asString(contacts[i]['phone'])),
              ),
              Positioned(
                left: 268,
                top: 774 + i * 61,
                width: 100,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (asBool(contacts[i]['isPrimary']))
                      Pill(label: 'Primary', bg: pillOk.bg, fg: pillOk.fg, dot: pillOk.fg)
                    else
                      GestureDetector(
                        onTap: () => _removeContact(contacts[i]),
                        child: const Icon(LucideIcons.trash2, size: 17, color: C.muted),
                      ),
                  ],
                ),
              ),
            ],

          if (_add)
            Modal(
              onClose: () => setState(() => _add = false),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Emergency contact',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: C.ink)),
                  const SizedBox(height: 12),
                  Field(w: 324, h: 48, label: 'Name', controller: _name, placeholder: 'Full name'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in _relationships)
                        GestureDetector(
                          onTap: () => setState(() => _relationship = r),
                          child: IntrinsicWidth(
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _relationship == r ? C.green : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: _relationship == r ? null : Border.all(color: C.line),
                              ),
                              child: Text(
                                r[0].toUpperCase() + r.substring(1),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _relationship == r ? Colors.white : C.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Field(w: 324, h: 48, label: 'Mobile number', controller: _phone, keyboard: TextInputType.phone, placeholder: '10-digit number'),
                  const SizedBox(height: 16),
                  Btn(w: 324, h: 48, label: _saving ? 'SAVING…' : 'SAVE CONTACT', onTap: _saving ? null : _saveContact),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
