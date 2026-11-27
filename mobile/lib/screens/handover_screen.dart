import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';
import 'delivered_screen.dart';

class HandOverScreen extends StatefulWidget {
  const HandOverScreen({
    super.key,
    required this.state,
    required this.orderId,
    this.demoOrder,
  });

  final AppState state;
  final String orderId;
  final Map<String, dynamic>? demoOrder;

  bool get isDemo => demoOrder != null;

  @override
  State<HandOverScreen> createState() => _HandOverScreenState();
}

class _HandOverScreenState extends State<HandOverScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _busy = false;
  int _focus = 0;
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _nodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _nodes.length; i++) {
      final idx = i;
      _nodes[i].addListener(() {
        if (_nodes[idx].hasFocus && mounted) setState(() => _focus = idx);
      });
    }
    if (widget.demoOrder != null) {
      _order = Map<String, dynamic>.from(widget.demoOrder!);
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.isDemo) {
      if (!mounted) return;
      setState(() {
        _order = Map<String, dynamic>.from(widget.demoOrder!);
        _loading = false;
      });
      return;
    }

    try {
      final res = await widget.state.api.get('/v1/orders/${widget.orderId}');
      if (!mounted) return;
      setState(() {
        _order = res is Map ? Map<String, dynamic>.from(res) : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e is ApiException ? e.message : 'Could not load this order');
    }
  }

  void _set(int i, String v) {
    final digit = v.replaceAll(RegExp(r'\D'), '');
    _controllers[i].text = digit.isEmpty ? '' : digit.substring(digit.length - 1);
    _controllers[i].selection = TextSelection.collapsed(offset: _controllers[i].text.length);
    if (digit.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
  }

  Future<void> _confirm() async {
    final code = _controllers.map((c) => c.text).join();
    if (!RegExp(r'^\d{4}$').hasMatch(code)) {
      showToast(context, 'Enter the 4-digit code from the customer');
      return;
    }
    if (widget.isDemo) {
      if (code != '7391') {
        showToast(context, 'Demo delivery code is incorrect. Use 7391.');
        for (final controller in _controllers) {
          controller.clear();
        }
        _nodes[0].requestFocus();
        return;
      }
      final deliveredOrder = Map<String, dynamic>.from(_order ?? widget.demoOrder!);
      deliveredOrder['status'] = 'delivered';
      deliveredOrder['deliveredAt'] = DateTime.now().toIso8601String();
      deliveredOrder['payBasePaise'] = asInt(deliveredOrder['payBasePaise']) == 0
          ? 6000
          : asInt(deliveredOrder['payBasePaise']);
      deliveredOrder['payDistancePaise'] = asInt(deliveredOrder['payDistancePaise']) == 0
          ? 2500
          : asInt(deliveredOrder['payDistancePaise']);
      deliveredOrder['tipPaise'] = asInt(deliveredOrder['tipPaise']);
      deliveredOrder['distanceKm'] = asDouble(deliveredOrder['distanceKm']) == 0
          ? 3.2
          : asDouble(deliveredOrder['distanceKm']);

      final updatedTimeline = mapList(deliveredOrder['timeline'])
          .map((event) => Map<String, dynamic>.from(event))
          .toList();
      updatedTimeline.add({
        'status': 'delivered',
        'at': DateTime.now().toIso8601String(),
      });
      deliveredOrder['timeline'] = updatedTimeline;
      deliveredOrder['earningPaise'] =
          asInt(deliveredOrder['payBasePaise']) +
          asInt(deliveredOrder['payDistancePaise']) +
          asInt(deliveredOrder['tipPaise']);

      // Save the completed demo order in shared app state so Orders > Completed
      // can display it after leaving the Delivered screen.
      widget.state.upsertDemoOrder(deliveredOrder);

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DeliveredScreen(
            state: widget.state,
            orderId: widget.orderId,
            demoOrder: deliveredOrder,
          ),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.state.api.post('/v1/orders/${widget.orderId}/deliver', body: {'code': code});
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => DeliveredScreen(state: widget.state, orderId: widget.orderId),
      ));
    } catch (e) {
      if (!mounted) return;
      showToast(context, e is ApiException ? e.message : 'Could not confirm delivery');
      for (final c in _controllers) {
        c.clear();
      }
      _nodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    if (_loading && o == null) {
      return const DesignCanvas(child: Center(child: CircularProgressIndicator(color: C.green)));
    }
    final who = firstName(asString(o?['customerName'], 'Customer'));
    final masked = asString(o?['customerPhoneMasked']);
    final crates = mapList(o?['crates']).length;
    final trial = mapList(o?['crates']).any((c) => asString(c['trialQr']).isNotEmpty);

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          BackBar(title: 'Hand over order', onBack: () => Navigator.of(context).maybePop()),
          DBox(
            x: 283,
            y: 41,
            w: 109,
            h: 55,
            r: 28,
            bg: const Color(0xFFE0EFF3),
            border: Border.all(color: const Color(0xFFCFE3EA)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 7,
                  height: 7,
                  child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF145B73), shape: BoxShape.circle)),
                ),
                SizedBox(width: 7),
                Text('At doorstep',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF145B73))),
              ],
            ),
          ),

          DBox(
            x: 20,
            y: 112,
            w: 372,
            h: 101,
            r: 24,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF073E29), Color(0xFF1B7849)],
            ),
            shadow: sh(15, 25, .2),
          ),
          Positioned(
            left: 38,
            top: 135,
            width: 56,
            height: 56,
            child: const Center(child: Icon(LucideIcons.package, size: 24, color: Color(0xFFB6DC45))),
          ),
          DTxt('#${asString(o?['orderCode'])} · $crates crates',
              x: 108, y: 131, s: 12, wt: FontWeight.w700, lh: 16.8, c: const Color(0xFFCFE3D0)),
          DTxt('Ask $who for their 4-digit delivery code',
              x: 108, y: 150, w: 265, s: 18, wt: FontWeight.w700, lh: 24, c: Colors.white),

          for (var i = 0; i < 4; i++)
            Positioned(
              left: 20 + i * 96.0,
              top: 236,
              width: 83,
              height: 70,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _focus == i ? C.green : C.line,
                    width: _focus == i ? 1.5 : 1,
                  ),
                  boxShadow: _focus == i ? [BoxShadow(color: C.green.withValues(alpha: .08), spreadRadius: 4)] : null,
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _nodes[i],
                  onTap: () => _nodes[i].requestFocus(),
                  onChanged: (v) => _set(i, v),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: C.ink),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          const DTxt('The customer sees this code in their app and by SMS.',
              x: 20, y: 324, w: 372, s: 13.5, wt: FontWeight.w500, lh: 20, c: C.muted, align: TextAlign.center),
          if (trial)
            const DTxt('Trial demo orders use code 7391',
                x: 20, y: 344, w: 372, s: 13.5, wt: FontWeight.w700, lh: 20, c: C.green, align: TextAlign.center),

          DBox(x: 20, y: 381, w: 372, h: 250, r: 24, bg: Colors.white, border: Border.all(color: C.line), shadow: sh(8, 20, .04)),
          const DTxt('CUSTOMER NOT ANSWERING?', x: 37, y: 396, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.accent),
          for (var i = 0; i < 3; i++)
            Positioned(
              left: 36,
              top: 415 + i * 73,
              width: 340,
              height: 73,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (i == 0) {
                    showToast(context, 'Calls connect through a masked number ($masked). Coming soon.');
                  } else {
                    showToast(context, 'Open Help & support from your profile');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: i == 0 ? null : const Border(top: BorderSide(color: C.tint5)),
                  ),
                  child: Row(
                    children: [
                      Tile(
                        s: 44,
                        bg: i == 2 ? const Color(0xFFFFF3BF) : const Color(0xFFEEF5DB),
                        icon: [LucideIcons.phone, LucideIcons.camera, LucideIcons.messageCircle][i],
                        isize: 19,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ['Call $who', 'Leave with security', 'Contact support'][i],
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ['Number is masked for privacy', 'Photo proof · needs support approval', 'Average reply under 2 minutes'][i],
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF8A988F)),
                    ],
                  ),
                ),
              ),
            ),

          Btn(y: 816, label: _busy ? 'CONFIRMING…' : 'CONFIRM DELIVERY', onTap: _busy ? null : _confirm),
        ],
      ),
    );
  }
}
