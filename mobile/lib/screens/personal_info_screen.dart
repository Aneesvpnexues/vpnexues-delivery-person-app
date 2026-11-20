import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'sos_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key, required this.state});

  final AppState state;

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final TextEditingController _email;
  late final TextEditingController _addr;
  DateTime? _dob;
  String _blood = '';
  Map<String, dynamic>? _ec;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final me = widget.state.partner ?? {};
    _email = TextEditingController(text: asString(me['email']));
    _addr = TextEditingController(text: asString(me['address']));
    _dob = parseDate(me['dateOfBirth']);
    _blood = asString(me['bloodGroup']);
    _loadContacts();
  }

  @override
  void dispose() {
    _email.dispose();
    _addr.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final res = await widget.state.api.get('/v1/emergency-contacts');
      final list = mapList(res);
      if (!mounted) return;
      setState(() {
        _ec = list.where((c) => asBool(c['isPrimary'])).toList().firstOrNull ?? (list.isNotEmpty ? list.first : null);
      });
    } catch (_) {}
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 24, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final email = _email.text.trim();
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showToast(context, 'Enter a valid email address');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.state.api.patch('/v1/me', body: {
        'email': email.isEmpty ? null : email,
        'dateOfBirth': _dob == null ? null : _dob!.toIso8601String().substring(0, 10),
        'bloodGroup': _blood.isEmpty ? null : _blood,
        'address': _addr.text.trim().isEmpty ? null : _addr.text.trim(),
      });
      await widget.state.loadMe();
      if (!mounted) return;
      showToast(context, 'Changes saved');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not save changes');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.partner ?? {};
    final phone = asString(me['phone']).replaceFirst('+91', '');
    final masked = phone.length == 10 ? '+91 ${phone.substring(0, 5)} ${phone.substring(5)}' : '+91 $phone';

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'Personal info'),
          DBox(x: 154, y: 98, w: 104, h: 104, r: 52, bg: const Color(0xFFEAF2D6)),
          DBox(
            x: 158,
            y: 102,
            w: 96,
            h: 96,
            r: 48,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9CC42C), Color(0xFF247947)],
            ),
            child: Center(
              child: Text(
                initials(widget.state.name),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          DBox(
            x: 220,
            y: 160,
            w: 38,
            h: 38,
            r: 19,
            bg: C.green,
            border: Border.all(color: Colors.white, width: 3),
            onTap: () => showToast(context, 'Profile photos are taken from your verified selfie'),
            child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
          ),
          const DTxt('Photo must match your verified selfie',
              x: 20, y: 207, w: 372, s: 12, lh: 16.8, c: C.muted, align: TextAlign.center),

          const DTxt('Full name', x: 20, y: 238, s: 13, wt: FontWeight.w600, lh: 18.2),
          DBox(
            x: 20,
            y: 263,
            w: 372,
            h: 55,
            r: 16,
            bg: const Color(0xFFF4F6EE),
            border: Border.all(color: const Color(0xFFCFD8CB)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.state.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink),
                    ),
                  ),
                  Pill(w: 120, label: 'As on Aadhaar', bg: pillOk.bg, fg: pillOk.fg, dot: pillOk.fg),
                ],
              ),
            ),
          ),

          const DTxt('Mobile number', x: 20, y: 332, s: 13, wt: FontWeight.w600, lh: 18.2),
          DBox(
            x: 20,
            y: 358,
            w: 372,
            h: 55,
            r: 16,
            bg: const Color(0xFFF4F6EE),
            border: Border.all(color: const Color(0xFFCFD8CB)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  Expanded(
                    child: Text(masked,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink)),
                  ),
                  const Text('Verified',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: C.accent)),
                ],
              ),
            ),
          ),

          Field(
            y: 427,
            label: 'Email (for payout statements)',
            controller: _email,
            icon: LucideIcons.mail,
            placeholder: 'you@example.com',
            keyboard: TextInputType.emailAddress,
          ),

          const DTxt('Date of birth', x: 20, y: 522, s: 13, wt: FontWeight.w600, lh: 18.2),
          DBox(
            x: 20,
            y: 548,
            w: 240,
            h: 55,
            r: 16,
            bg: Colors.white,
            border: Border.all(color: C.line),
            onTap: _pickDob,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dob == null ? 'Select date' : dateOnly(_dob),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _dob == null ? C.muted : C.ink,
                      ),
                    ),
                  ),
                  const Icon(LucideIcons.calendar, size: 16, color: C.muted),
                ],
              ),
            ),
          ),
          const DTxt('Blood group', x: 272, y: 522, s: 13, wt: FontWeight.w600, lh: 18.2),
          DBox(
            x: 272,
            y: 548,
            w: 120,
            h: 55,
            r: 16,
            bg: Colors.white,
            border: Border.all(color: C.line),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _blood.isEmpty ? '' : _blood,
                  isExpanded: true,
                  icon: const Icon(LucideIcons.chevronDown, size: 15, color: C.muted),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('–')),
                    for (final b in ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'])
                      DropdownMenuItem(value: b, child: Text(b)),
                  ],
                  onChanged: (v) => setState(() => _blood = v ?? ''),
                ),
              ),
            ),
          ),

          const DTxt('Current address', x: 20, y: 617, s: 13, wt: FontWeight.w600, lh: 18.2),
          DBox(x: 20, y: 643, w: 372, h: 75, r: 16, bg: Colors.white, border: Border.all(color: C.line)),
          const Positioned(left: 38, top: 659, child: Icon(LucideIcons.mapPin, size: 16, color: C.muted)),
          Positioned(
            left: 69,
            top: 650,
            width: 312,
            height: 62,
            child: TextField(
              controller: _addr,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: C.ink, height: 22 / 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                hintText: 'House, street, area, city, PIN',
                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: C.muted),
              ),
            ),
          ),

          DBox(
            x: 20,
            y: 733,
            w: 372,
            h: 76,
            r: 22,
            bg: const Color(0xFFEEF5DB),
            border: Border.all(color: const Color(0xFFDDEBC3)),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SosScreen(state: widget.state)));
              _loadContacts();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  Tile(s: 44, bg: Colors.white, icon: LucideIcons.users, r: 14),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Emergency contact',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink)),
                        const SizedBox(height: 2),
                        Text(
                          _ec == null
                              ? 'Not added yet'
                              : '${asString(_ec!['name'])} (${asString(_ec!['relationship'])}) · ${_mask(asString(_ec!['phone']))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF333333)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _ec == null ? 'Add' : 'Edit',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: C.green),
                  ),
                ],
              ),
            ),
          ),

          Btn(y: 840, label: _busy ? 'SAVING…' : 'SAVE CHANGES', onTap: _busy ? null : _save),
        ],
      ),
    );
  }

  static String _mask(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return phone;
    return '+91 ••••• ${digits.substring(digits.length - 5)}';
  }
}
