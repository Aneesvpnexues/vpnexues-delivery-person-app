import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key, required this.state, required this.type, this.existing});

  final AppState state;
  final String type;
  final Map<String, dynamic>? existing;

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _number = TextEditingController();
  DateTime? _validUntil;
  bool _consent = true;
  bool _busy = false;
  String? _error;
  Uint8List? _bytes;
  String? _contentType;
  String? _fileName;

  bool get _needsConsent => widget.type == 'aadhaar' || widget.type == 'pan';

  @override
  void initState() {
    super.initState();
    _number.text = asString(widget.existing?['numberMasked']);
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final file = await ImagePicker().pickImage(
        source: widget.type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 2200,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _fileName = file.name;
        _contentType = name.endsWith('.png') ? 'image/png' : 'image/jpeg';
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the image picker');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => _validUntil = picked);
  }

  Future<void> _submit() async {
    if (_bytes == null) return setState(() => _error = 'Choose a photo of the document first');
    if (_needsConsent && !_consent) return setState(() => _error = 'Consent is required for e-KYC');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final presign = await widget.state.api.post(
        '/v1/documents/${widget.type}/upload-url',
        body: {'contentType': _contentType, 'side': 'single'},
      );
      final map = presign is Map ? Map<String, dynamic>.from(presign) : null;
      if (map == null) throw ApiException(500, 'UPLOAD', 'Upload failed');
      await widget.state.api.upload(asString(map['url']), _bytes!, _contentType!);
      await widget.state.api.post(
        '/v1/documents/${widget.type}/submit',
        body: {
          's3Keys': [asString(map['key'])],
          'number': _number.text.trim().isEmpty ? null : _number.text.trim(),
          'validUntil': _validUntil == null ? null : _validUntil!.toIso8601String().substring(0, 10),
          'consent': _consent,
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Could not submit this document');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          BackBar(title: docLabel(widget.type)),
          DTxt(
            existing == null
                ? 'Upload a clear photo of the original.'
                : 'Status: ${statusLabel(asString(existing['status']))}. Upload again to replace it.',
            x: 20,
            y: 104,
            w: 372,
            s: 13,
            wt: FontWeight.w500,
            lh: 19,
            c: C.muted,
          ),
          DBox(
            x: 20,
            y: 148,
            w: 372,
            h: 172,
            r: 22,
            bg: _bytes == null ? const Color(0xFFF4F6EE) : const Color(0xFFEEF5DB),
            border: Border.all(color: _bytes == null ? const Color(0xFFCFD8CB) : const Color(0xFFDDEBC3), width: 1.5),
            onTap: _busy ? null : _pick,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_bytes == null ? LucideIcons.camera : LucideIcons.checkCircle2, size: 30, color: _bytes == null ? C.muted : C.green),
                const SizedBox(height: 8),
                Text(
                  _fileName ?? 'Choose photo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: C.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  _bytes == null ? 'JPG or PNG · up to 10 MB' : 'Tap to change the photo',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
                ),
              ],
            ),
          ),
          Field(
            y: 348,
            label: 'Document number (optional)',
            controller: _number,
            placeholder: 'Only the last 4 digits will be shown',
          ),
          const DTxt('Expiry date (optional)', x: 20, y: 443, s: 13, wt: FontWeight.w600, lh: 18.2),
          DBox(
            x: 20,
            y: 468,
            w: 372,
            h: 55,
            r: 16,
            bg: Colors.white,
            border: Border.all(color: C.line),
            onTap: _pickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _validUntil == null ? 'Select date' : dateOnly(_validUntil),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _validUntil == null ? C.muted : C.ink,
                      ),
                    ),
                  ),
                  const Icon(LucideIcons.calendar, size: 16, color: C.muted),
                ],
              ),
            ),
          ),
          if (_needsConsent)
            DBox(
              x: 20,
              y: 542,
              w: 372,
              h: 76,
              r: 20,
              bg: Colors.white,
              border: Border.all(color: C.line),
              onTap: () => setState(() => _consent = !_consent),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _consent ? C.green : Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: _consent ? null : Border.all(color: C.line, width: 1.5),
                      ),
                      child: _consent ? const Icon(LucideIcons.check, size: 15, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I consent to e-KYC verification of this document',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w500, color: C.muted, height: 18 / 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null)
            DTxt(_error!, x: 20, y: 636, w: 372, s: 12.5, wt: FontWeight.w600, lh: 18, c: C.danger),
          Btn(y: 782, label: _busy ? 'SUBMITTING…' : 'SUBMIT FOR REVIEW', onTap: _busy ? null : _submit),
        ],
      ),
    );
  }
}
