import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'document_upload_screen.dart';
import 'docs_screen.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key, required this.state});

  final AppState state;

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  static const _vtypes = [('Motorbike', 'motorbike'), ('Scooter', 'scooter'), ('Electric scooter', 'electric_scooter'), ('Bicycle', 'bicycle')];
  static const _fuels = [('Petrol', 'petrol'), ('Electric', 'electric'), ('CNG', 'cng'), ('None', 'none')];

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
        _vehicle = res[0] is Map ? Map<String, dynamic>.from(res[0] as Map) : null;
        _docs = res[1] is Map ? Map<String, dynamic>.from(res[1] as Map) : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load your vehicle');
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
    _type = asString(v?['type'], asString(widget.state.partner?['vehicleType'], 'motorbike'));
    _fuel = asString(v?['fuel'], 'petrol');
    _reg.text = asString(v?['registrationNumber']);
    _model.text = asString(v?['makeModel']);
    _year.text = asString(v?['year']);
    _colour.text = asString(v?['colour']);
    setState(() => _edit = true);
  }

  Future<void> _save() async {
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
        if (_year.text.trim().isNotEmpty) 'year': int.tryParse(_year.text.trim()),
        if (_colour.text.trim().isNotEmpty) 'colour': _colour.text.trim(),
        'fuel': _fuel,
      });
      if (!mounted) return;
      showToast(context, 'Vehicle saved');
      setState(() => _edit = false);
      await _load();
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not save the vehicle');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _upload(String type) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => DocumentUploadScreen(state: widget.state, type: type, existing: _doc(type)),
    ));
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

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          const BackBar(title: 'My vehicle'),
          RoundBtn(icon: LucideIcons.pencil, x: 344, y: 41, onTap: _openEdit),
          DBox(x: 20, y: 102, w: 372, h: 253, r: 28, bg: const Color(0xFFEEF5DB), border: Border.all(color: const Color(0xFFDDEBC3))),
          DImg('assets/art/rider.png', x: 100, y: 118, w: 215, h: 135),
          DBox(
            x: 104,
            y: 260,
            w: 205,
            h: 42,
            r: 6,
            bg: Colors.white,
            border: Border.all(color: const Color(0xFF222222), width: 2),
            onTap: _openEdit,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 21,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2450A8),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                    ),
                    alignment: Alignment.center,
                    child: const RotatedBox(
                      quarterTurns: 3,
                      child: Text('IND',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
                Positioned(
                  left: 21,
                  right: 0,
                  top: 0,
                  child: SizedBox(
                    height: 38,
                    child: Center(
                      child: Text(
                        v == null ? (_loading ? '…' : 'Tap to add') : asString(v['registrationNumber']),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: v == null ? 13 : 20,
                          fontWeight: FontWeight.w700,
                          color: v == null ? C.muted : const Color(0xFF111111),
                          letterSpacing: v == null ? 0 : 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DTxt(
            v == null
                ? 'Add your vehicle to start delivering'
                : '${_label(_vtypes, asString(v['type']))} · ${_label(_fuels, asString(v['fuel']))} · ${asString(me['status']) == 'active' ? 'Active for deliveries' : 'Pending approval'}',
            x: 20,
            y: 317,
            w: 372,
            s: 13,
            wt: FontWeight.w500,
            lh: 18.2,
            c: const Color(0xFF224A36),
            align: TextAlign.center,
          ),

          DBox(x: 20, y: 370, w: 372, h: 165, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          for (var i = 0; i < specs.length; i++) ...[
            DTxt(specs[i].$1, x: 37 + (i % 2) * 175, y: 384 + (i ~/ 2) * 50, s: 10.5, wt: FontWeight.w700, lh: 14.7, c: C.muted),
            DTxt(specs[i].$2, x: 37 + (i % 2) * 175, y: 400 + (i ~/ 2) * 50, w: 165, s: 15, wt: FontWeight.w700, lh: 21, maxLines: 1),
          ],

          DBox(x: 20, y: 545, w: 372, h: 195, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) DBox(x: 36, y: 545 + i * 65, w: 340, h: 1, bg: C.tint5),
            Positioned(
              left: 36,
              top: 545 + i * 65,
              width: 340,
              height: 65,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _upload(['vehicle_rc', 'vehicle_insurance', 'pucc'][i]),
                child: Row(
                  children: [
                    Tile(
                      s: 44,
                      bg: i == 1 ? const Color(0xFFFFF3BF) : const Color(0xFFEEF5DB),
                      icon: [LucideIcons.fileText, LucideIcons.umbrella, LucideIcons.leaf][i],
                      c: i == 1 ? const Color(0xFF825605) : C.green,
                      isize: 19,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            docLabel(['vehicle_rc', 'vehicle_insurance', 'pucc'][i]),
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DocsScreen.subFor(_doc(['vehicle_rc', 'vehicle_insurance', 'pucc'][i])),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
                          ),
                        ],
                      ),
                    ),
                    _pill(_doc(['vehicle_rc', 'vehicle_insurance', 'pucc'][i])),
                  ],
                ),
              ),
            ),
          ],
          // Bottom actions are kept inside the visible design area so both buttons show fully.
          Btn(
            x: 20,
            y: 755,
            w: 372,
            h: 52,
            label: insurance == null ? 'UPLOAD INSURANCE' : 'RENEW INSURANCE',
            onTap: () => _upload('vehicle_insurance'),
          ),
          Btn(
            x: 20,
            y: 815,
            w: 372,
            h: 52,
            label: v == null ? 'ADD VEHICLE DETAILS' : 'EDIT VEHICLE DETAILS',
            onTap: _openEdit,
          ),

          if (_edit)
            Modal(
              onClose: () => setState(() => _edit = false),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vehicle details',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: C.ink)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in _vtypes) _chip(t.$1, _type == t.$2, () => setState(() => _type = t.$2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Field(w: 324, label: 'Registration number', controller: _reg, placeholder: 'TN 02 AB 4821', h: 48),
                    const SizedBox(height: 10),
                    Field(w: 324, label: 'Make & model', controller: _model, placeholder: 'e.g. TVS Raider 125', h: 48),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Field(w: 157, label: 'Year', controller: _year, keyboard: TextInputType.number, placeholder: '2022', h: 48),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Field(w: 157, label: 'Colour', controller: _colour, placeholder: 'Green', h: 48),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final f in _fuels) _chip(f.$1, _fuel == f.$2, () => setState(() => _fuel = f.$2)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Btn(w: 324, h: 48, label: _saving ? 'SAVING…' : 'SAVE VEHICLE', onTap: _saving ? null : _save),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback tap) => GestureDetector(
        onTap: tap,
        child: IntrinsicWidth(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? C.green : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: on ? null : Border.all(color: C.line),
            ),
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: on ? Colors.white : C.ink),
            ),
          ),
        ),
      );

  Widget _pill(Map<String, dynamic>? d) {
    final p = DocsScreen.pillFor(d);
    return Pill(label: p.$1, bg: p.$2, fg: p.$3, dot: p.$3);
  }
}
