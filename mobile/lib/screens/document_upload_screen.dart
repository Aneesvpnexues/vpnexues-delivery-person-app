import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/format.dart';
import '../state/app_state.dart';
import '../ui/design.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({
    super.key,
    required this.state,
    required this.type,
    this.existing,
  });

  final AppState state;
  final String type;
  final Map<String, dynamic>? existing;

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _number = TextEditingController();
  final _picker = ImagePicker();
  DateTime? _validUntil;
  bool _consent = true;
  bool _busy = false;
  String? _error;
  Uint8List? _bytes;
  String? _fileName;

  bool get _needsConsent => widget.type == 'aadhaar' || widget.type == 'pan';

  @override
  void initState() {
    super.initState();
    final saved = widget.state.getLocalDocument(widget.type) ?? widget.existing;
    final savedBytes = saved?['bytes'];
    if (savedBytes is Uint8List) _bytes = savedBytes;
    _fileName = asString(saved?['fileName']).isEmpty
        ? null
        : asString(saved?['fileName']);
    _number.text = asString(saved?['numberMasked']);
    final date = saved?['validUntil'];
    if (date != null) _validUntil = DateTime.tryParse(asString(date));
    if (saved?['consent'] is bool) _consent = saved!['consent'] as bool;
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_busy) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: C.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Choose how to add your document',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: C.ink,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 2200,
        imageQuality: 85,
      );
      // Cancelling the picker must not change the current selection or status.
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || !mounted) {
        setState(() => _error = 'The selected image is empty. Please try again.');
        return;
      }
      setState(() {
        _bytes = bytes;
        _fileName = file.name;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the camera or gallery. Please try again.');
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
    if (picked != null && mounted) setState(() => _validUntil = picked);
  }

  void _removePhoto() {
    setState(() {
      _bytes = null;
      _fileName = null;
      _error = null;
    });
  }

  void _save() {
    if (_bytes == null || _bytes!.isEmpty) {
      setState(() => _error = 'Choose a photo of the document first');
      return;
    }
    if (_needsConsent && !_consent) {
      setState(() => _error = 'Consent is required for e-KYC');
      return;
    }

    setState(() => _busy = true);
    widget.state.saveLocalDocument(
      type: widget.type,
      bytes: _bytes!,
      fileName: _fileName ?? 'document.jpg',
      number: _number.text.trim(),
      validUntil: _validUntil,
      consent: _consent,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.state.getLocalDocument(widget.type) ?? widget.existing;
    final hasImage = _bytes != null && _bytes!.isNotEmpty;

    return DesignCanvas(
      child: Stack(
        children: [
          const Backdrop(),
          BackBar(title: docLabel(widget.type)),
          DTxt(
            existing == null
                ? 'Upload a clear photo of the original.'
                : 'Document selected. You can replace it with a new photo.',
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
            bg: hasImage ? const Color(0xFFEEF5DB) : const Color(0xFFF4F6EE),
            border: Border.all(
              color: hasImage ? const Color(0xFFDDEBC3) : const Color(0xFFCFD8CB),
              width: 1.5,
            ),
            onTap: _busy ? null : _pick,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: hasImage
                  ? Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _bytes!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _fileName ?? 'Selected document',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: C.ink,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, size: 30, color: C.muted),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose photo',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: C.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'JPG or PNG · up to 10 MB',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.muted),
                        ),
                      ],
                    ),
            ),
          ),
          Positioned(
            left: 20,
            top: 326,
            width: 372,
            child: Row(

          
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(LucideIcons.image, size: 17),
                    label: Text(hasImage ? 'Replace photo' : 'Take photo / Gallery'),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Remove selected photo',
                    onPressed: _busy ? null : _removePhoto,
                    icon: const Icon(LucideIcons.trash2, color: C.danger),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 20,
            top: 392,
            width: 372,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document number (optional)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: C.ink,
                  ),
                ),
                const SizedBox(height: 9),
                TextField(
                  controller: _number,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: C.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Only the last 4 digits will be shown',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: C.muted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: C.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: C.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const DTxt('Expiry date (optional)', x: 20, y: 477, s: 13, wt: FontWeight.w600, lh: 18.2),
          DBox(
            x: 20,
            y: 502,
            w: 372,
            h: 55,
            r: 16,
            bg: Colors.white,
            border: Border.all(color: C.line),
            onTap: _busy ? null : _pickDate,
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
              y: 572,
              w: 372,
              h: 58,
              r: 18,
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
            DTxt(_error!, x: 20, y: _needsConsent ? 642 : 585, w: 372, s: 12.5, wt: FontWeight.w600, lh: 18, c: C.danger),
          Btn(
            y: 782,
            label: _busy ? 'SAVING…' : 'SAVE DOCUMENT',
            onTap: _busy || !hasImage ? null : _save,
          ),
        ],
      ),
    );
  }
}
