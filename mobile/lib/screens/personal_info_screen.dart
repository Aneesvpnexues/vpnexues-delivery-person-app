import 'dart:math' as math;

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
  static const _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

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

    final rawBlood = asString(me['bloodGroup']).trim().toUpperCase();
    _blood = _bloodGroups.contains(rawBlood) ? rawBlood : '';

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

      final primary = list.where((c) => asBool(c['isPrimary'])).toList();
      setState(() {
        _ec = primary.isNotEmpty
            ? primary.first
            : (list.isNotEmpty ? list.first : null);
      });
    } catch (_) {}
  }

  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final lastDate = DateTime(now.year - 18, now.month, now.day);
    final initial = _dob != null && !_dob!.isAfter(lastDate)
        ? _dob!
        : DateTime(now.year - 24, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: lastDate,
    );

    if (picked != null && mounted) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _openSos() async {
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SosScreen(state: widget.state)),
    );
    _loadContacts();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();

    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showToast(context, 'Enter a valid email address');
      return;
    }

    setState(() => _busy = true);

    try {
      await widget.state.api.patch('/v1/me', body: {
        'email': email.isEmpty ? null : email,
        'dateOfBirth':
            _dob == null ? null : _dob!.toIso8601String().substring(0, 10),
        'bloodGroup': _blood.isEmpty ? null : _blood,
        'address': _addr.text.trim().isEmpty ? null : _addr.text.trim(),
      });

      await widget.state.loadMe();
      if (!mounted) return;

      showToast(context, 'Changes saved');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not save changes',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.partner ?? {};
    final phone = asString(me['phone']).replaceFirst('+91', '').trim();
    final maskedPhone = phone.length == 10
        ? '+91 ${phone.substring(0, 5)} ${phone.substring(5)}'
        : (phone.isEmpty ? 'Not added' : '+91 $phone');

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full name (read-only)
                        const _FieldLabel('Full name'),
                        const SizedBox(height: 8),
                        _ReadOnlyField(
                          value: widget.state.name,
                          trailing: Pill(
                            label: 'As on Aadhaar',
                            bg: pillOk.bg,
                            fg: pillOk.fg,
                            dot: pillOk.fg,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Mobile number (read-only)
                        const _FieldLabel('Mobile number'),
                        const SizedBox(height: 8),
                        _ReadOnlyField(
                          value: maskedPhone,
                          trailing: const Text(
                            'Verified',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: C.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        const _FieldLabel('Email (for payout statements)'),
                        const SizedBox(height: 8),
                        Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: C.line),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.mail,
                                size: 17,
                                color: C.muted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    color: C.ink,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintText: 'you@example.com',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w500,
                                      color: C.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date of birth & Blood group
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Date of birth'),
                                  const SizedBox(height: 8),
                                  Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap: _pickDob,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        height: 55,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(color: C.line),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _dob == null
                                                    ? 'Select date'
                                                    : dateOnly(_dob),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: _dob == null
                                                      ? C.muted
                                                      : C.ink,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              LucideIcons.calendar,
                                              size: 16,
                                              color: C.muted,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Blood group'),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 55,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: C.line),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _blood,
                                        isExpanded: true,
                                        dropdownColor: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        icon: const Icon(
                                          LucideIcons.chevronDown,
                                          size: 16,
                                          color: C.muted,
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                          color: C.ink,
                                        ),
                                        items: [
                                          const DropdownMenuItem(
                                            value: '',
                                            child: Text('–'),
                                          ),
                                          for (final b in _bloodGroups)
                                            DropdownMenuItem(
                                              value: b,
                                              child: Text(b),
                                            ),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _blood = v ?? ''),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Current address
                        const _FieldLabel('Current address'),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: C.line),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  LucideIcons.mapPin,
                                  size: 17,
                                  color: C.muted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _addr,
                                  minLines: 2,
                                  maxLines: 3,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: C.ink,
                                    height: 22 / 15,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'House, street, area, city, PIN',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: C.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Emergency contact card
                        Material(
                          color: const Color(0xFFEEF5DB),
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            onTap: _openSos,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFDDEBC3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      LucideIcons.users,
                                      size: 20,
                                      color: C.green,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Emergency contact',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: C.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _ec == null
                                              ? 'Not added yet'
                                              : '${asString(_ec!['name'])} (${asString(_ec!['relationship'])}) · ${_mask(asString(_ec!['phone']))}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12.5,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _ec == null ? 'Add' : 'Edit',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
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
                  ),
                ],
              ),
            ),
          ),

          // Pinned Save button bar
          Container(
            decoration: BoxDecoration(
              color: C.bg,
              border: Border(top: BorderSide(color: C.line.withOpacity(0.7))),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              14 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _busy ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.green,
                  disabledBackgroundColor: C.green.withOpacity(0.6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
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
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
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
              top: 24,
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
              padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
              child: Column(
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
                          'Personal info',
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

                  // Avatar + camera badge
                  SizedBox(
                    width: 102,
                    height: 102,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF9CC42C), Color(0xFF247947)],
                            ),
                            border: Border.all(
                              color: const Color(0xFF9CC42C),
                              width: 3,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials(widget.state.name),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: C.green,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => showToast(
                                context,
                                'Profile photos are taken from your verified selfie',
                              ),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.camera,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Photo must match your verified selfie',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
    );
  }

  static String _mask(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return phone;
    return '+91 ••••• ${digits.substring(digits.length - 5)}';
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: C.ink,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value, required this.trailing});

  final String value;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFD8CB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: C.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }
}