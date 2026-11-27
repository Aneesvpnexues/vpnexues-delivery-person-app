import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'docs_screen.dart';
import 'document_upload_screen.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key, required this.state});

  final AppState state;

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  static const _vtypes = [
    ('Motorbike', 'motorbike'),
    ('Scooter', 'scooter'),
    ('Electric scooter', 'electric_scooter'),
    ('Bicycle', 'bicycle'),
  ];
  static const _fuels = [
    ('Petrol', 'petrol'),
    ('Electric', 'electric'),
    ('CNG', 'cng'),
    ('None', 'none'),
  ];

  Map<String, dynamic>? _vehicle;
  Map<String, dynamic>? _docs;
  bool _loading = true;
  bool _edit = false;
  bool _saving = false;
  String _type = 'motorbike';
  String _fuel = 'petrol';
  final _reg = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _colour = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_reg, _model, _year, _colour]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait([
        widget.state.api.get('/v1/vehicle'),
        widget.state.api.get('/v1/documents'),
      ]);
      if (!mounted) return;
      setState(() {
        _vehicle =
            res[0] is Map ? Map<String, dynamic>.from(res[0] as Map) : null;
        _docs =
            res[1] is Map ? Map<String, dynamic>.from(res[1] as Map) : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(
        context,
        e is ApiException ? e.message : 'Could not load your vehicle',
      );
    }
  }

  Map<String, dynamic>? _doc(String type) {
    for (final d in mapList(_docs?['documents'])) {
      if (asString(d['type']) == type) return d;
    }
    return null;
  }

  void _openEdit() {
    final v = _vehicle;
    _type = asString(
      v?['type'],
      asString(widget.state.partner?['vehicleType'], 'motorbike'),
    );
    _fuel = asString(v?['fuel'], 'petrol');
    _reg.text = asString(v?['registrationNumber']);
    _model.text = asString(v?['makeModel']);
    _year.text = asString(v?['year']);
    _colour.text = asString(v?['colour']);
    setState(() => _edit = true);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_reg.text.trim().isEmpty) {
      showToast(context, 'Enter the registration number');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.state.api.put('/v1/vehicle', body: {
        'type': _type,
        'registrationNumber': _reg.text.trim().toUpperCase(),
        if (_model.text.trim().isNotEmpty) 'makeModel': _model.text.trim(),
        if (_year.text.trim().isNotEmpty)
          'year': int.tryParse(_year.text.trim()),
        if (_colour.text.trim().isNotEmpty) 'colour': _colour.text.trim(),
        'fuel': _fuel,
      });
      if (!mounted) return;
      showToast(context, 'Vehicle saved');
      setState(() => _edit = false);
      await _load();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is ApiException ? e.message : 'Could not save the vehicle',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _upload(String type) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentUploadScreen(
          state: widget.state,
          type: type,
          existing: _doc(type),
        ),
      ),
    );
    if (ok == true) _load();
  }

  static String _label(List<(String, String)> list, String? v) {
    for (final e in list) {
      if (e.$2 == v) return e.$1;
    }
    return '–';
  }

  @override
  Widget build(BuildContext context) {
    final v = _vehicle;
    final me = widget.state.partner ?? {};
    final specs = [
      ('MAKE & MODEL', asString(v?['makeModel'], '–')),
      ('YEAR', v?['year'] == null ? '–' : asString(v!['year'])),
      ('COLOUR', asString(v?['colour'], '–')),
      ('FUEL', _label(_fuels, asString(v?['fuel']))),
      ('OWNER', widget.state.name),
      ('TYPE', _label(_vtypes, asString(v?['type']))),
    ];
    final insurance = _doc('vehicle_insurance');
    final docTypes = ['vehicle_rc', 'vehicle_insurance', 'pucc'];
    final docIcons = [
      LucideIcons.fileText,
      LucideIcons.umbrella,
      LucideIcons.leaf,
    ];

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
                      // Hero vehicle card
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF5DB),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFDDEBC3)),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/art/rider.png',
                              height: 132,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 10),

                            // Registration plate
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              child: InkWell(
                                onTap: _openEdit,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 210,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF222222),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 21,
                                        height: double.infinity,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2450A8),
                                          borderRadius:
                                              BorderRadius.horizontal(
                                            left: Radius.circular(4),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            'IND',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 7,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                            child: Text(
                                              v == null
                                                  ? (_loading
                                                      ? '…'
                                                      : 'Tap to add')
                                                  : asString(
                                                      v['registrationNumber'],
                                                    ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: v == null ? 13 : 19,
                                                fontWeight: FontWeight.w700,
                                                color: v == null
                                                    ? C.muted
                                                    : const Color(0xFF111111),
                                                letterSpacing:
                                                    v == null ? 0 : 1.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              v == null
                                  ? 'Add your vehicle to start delivering'
                                  : '${_label(_vtypes, asString(v['type']))} · ${_label(_fuels, asString(v['fuel']))} · ${asString(me['status']) == 'active' ? 'Active for deliveries' : 'Pending approval'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF224A36),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Specs card (2-column grid)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: C.line),
                          boxShadow: sh(8, 20, .04),
                        ),
                        child: Column(
                          children: [
                            for (var row = 0; row < 3; row++) ...[
                              if (row > 0) const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SpecItem(
                                      label: specs[row * 2].$1,
                                      value: specs[row * 2].$2,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _SpecItem(
                                      label: specs[row * 2 + 1].$1,
                                      value: specs[row * 2 + 1].$2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Vehicle documents card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: C.line),
                          boxShadow: sh(8, 20, .04),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                for (var i = 0; i < docTypes.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: C.tint5,
                                    ),
                                  InkWell(
                                    onTap: () => _upload(docTypes[i]),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 13,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: i == 1
                                                  ? const Color(0xFFFFF3BF)
                                                  : const Color(0xFFEEF5DB),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              docIcons[i],
                                              size: 19,
                                              color: i == 1
                                                  ? const Color(0xFF825605)
                                                  : C.green,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  docLabel(docTypes[i]),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: C.ink,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  DocsScreen.subFor(
                                                    _doc(docTypes[i]),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    color: C.muted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _pill(_doc(docTypes[i])),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Primary actions
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => _upload('vehicle_insurance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: C.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            insurance == null
                                ? 'UPLOAD INSURANCE'
                                : 'RENEW INSURANCE',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _openEdit,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: C.green,
                            side: const BorderSide(color: C.line, width: 1.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            v == null
                                ? 'ADD VEHICLE DETAILS'
                                : 'EDIT VEHICLE DETAILS',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
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

          if (_edit)
            Modal(
              onClose: () => setState(() => _edit = false),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Vehicle details',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: C.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in _vtypes)
                          _chip(
                            t.$1,
                            _type == t.$2,
                            () => setState(() => _type = t.$2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ModalField(
                      label: 'Registration number',
                      controller: _reg,
                      placeholder: 'TN 02 AB 4821',
                    ),
                    const SizedBox(height: 10),
                    _ModalField(
                      label: 'Make & model',
                      controller: _model,
                      placeholder: 'e.g. TVS Raider 125',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ModalField(
                            label: 'Year',
                            controller: _year,
                            placeholder: '2022',
                            keyboard: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ModalField(
                            label: 'Colour',
                            controller: _colour,
                            placeholder: 'Green',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final f in _fuels)
                          _chip(
                            f.$1,
                            _fuel == f.$2,
                            () => setState(() => _fuel = f.$2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
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
                          _saving ? 'SAVING…' : 'SAVE VEHICLE',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
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
            colors: [Color(0xFF083F2A), Color(0xFF1F7945)],
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
                    color: const Color(0x3878B43C),
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
                      'My vehicle',
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
                  Material(
                    color: const Color(0x24FFFFFF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openEdit,
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          LucideIcons.pencil,
                          size: 18,
                          color: Colors.white,
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
    );
  }

  Widget _chip(String label, bool on, VoidCallback tap) => GestureDetector(
        onTap: tap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: on ? C.green : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: on ? null : Border.all(color: C.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : C.ink,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _pill(Map<String, dynamic>? d) {
    final p = DocsScreen.pillFor(d);
    return Pill(label: p.$1, bg: p.$2, fg: p.$3, dot: p.$3);
  }
}

class _SpecItem extends StatelessWidget {
  const _SpecItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: C.muted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: C.ink,
          ),
        ),
      ],
    );
  }
}

class _ModalField extends StatelessWidget {
  const _ModalField({
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