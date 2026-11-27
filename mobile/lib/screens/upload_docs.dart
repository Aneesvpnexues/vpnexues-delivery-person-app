import 'dart:ui';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../state/app_state.dart';
import '../ui/design.dart';
import 'home_shell.dart';

/// Shown right after "Save & Continue" in [SetPasswordScreen] during signup.
class UploadDocsScreen extends StatefulWidget {
  const UploadDocsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<UploadDocsScreen> createState() => _UploadDocsScreenState();
}

class _UploadDocsScreenState extends State<UploadDocsScreen> {
  final _scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();

  bool _isUploaded(String type) => widget.state.getLocalDocument(type) != null;

  int get _uploadedCount => _docs.where((d) => _isUploaded(d.id)).length;
  double get _progress => _uploadedCount / _docs.length;

  bool _busy = false;

  static const _docs = [
    _DocItem(
      id: 'aadhaar',
      title: 'Aadhaar card',
      subtitle: 'Number + photo · e-KYC',
      actionLabel: 'UPLOAD',
      icon: Icons.badge_outlined,
      isSelfie: false,
    ),
    _DocItem(
      id: 'pan',
      title: 'PAN card',
      subtitle: 'Needed for payouts (TDS)',
      actionLabel: 'UPLOAD',
      icon: Icons.description_outlined,
      isSelfie: false,
    ),
    _DocItem(
      id: 'dl',
      title: 'Driving licence',
      subtitle: 'Two-wheeler class',
      actionLabel: 'UPLOAD',
      icon: Icons.credit_card_outlined,
      isSelfie: false,
    ),
    _DocItem(
      id: 'rc',
      title: 'Vehicle RC',
      subtitle: 'Registration certificate',
      actionLabel: 'UPLOAD',
      icon: Icons.two_wheeler_outlined,
      isSelfie: false,
    ),
    _DocItem(
      id: 'selfie',
      title: 'Live selfie',
      subtitle: 'Matched with your Aadhaar photo',
      actionLabel: 'TAKE',
      icon: Icons.camera_alt_outlined,
      isSelfie: true,
    ),
  ];


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openUploadSheet(_DocItem doc) {
    HapticFeedback.selectionClick();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: C.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  doc.isSelfie ? 'Take a live selfie' : 'Upload ${doc.title}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: C.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doc.isSelfie
                      ? 'Make sure your face is clearly visible in good lighting.'
                      : 'Ensure all details on the document are sharp and readable.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: C.muted,
                  ),
                ),
                const SizedBox(height: 18),
                _SheetOptionTile(
                  icon: Icons.camera_alt_outlined,
                  label: doc.isSelfie ? 'Open front camera' : 'Take photo',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _pickDocument(doc, ImageSource.camera);
                  },
                ),
                if (!doc.isSelfie) ...[
                  const SizedBox(height: 10),
                  _SheetOptionTile(
                    icon: Icons.photo_library_outlined,
                    label: 'Choose from gallery',
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      _pickDocument(doc, ImageSource.gallery);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDocument(_DocItem doc, ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: doc.isSelfie
            ? CameraDevice.front
            : CameraDevice.rear,
        maxWidth: 2200,
        imageQuality: 85,
      );

      // A cancelled picker must not change the document status.
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || !mounted) return;

      widget.state.saveLocalDocument(
        type: doc.id,
        bytes: bytes,
        fileName: file.name,
      );

      HapticFeedback.mediumImpact();
      setState(() {});
      showToast(
        context,
        doc.isSelfie ? 'Live selfie selected' : '${doc.title} selected',
      );
    } catch (e) {
      if (!mounted) return;
      showToast(context, 'Could not select the image. Please try again.');
    }
  }

  void _continueToNext() {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);

    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(builder: (_) => HomeShell(state: widget.state)),
    );
  }

  void _finishLater() {
    if (_busy) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(builder: (_) => HomeShell(state: widget.state)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Preserved full-bleed background design; immune to screen-size distortion.
          const Positioned.fill(
            child: IgnorePointer(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 412,
                  height: 915,
                  child: Stack(
                    children: [
                      Backdrop(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Foreground responsive layout
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _DocsTopBar(
                  title: 'Verify your documents',
                  stepLabel: 'Step 4 of 5',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: _DocsStepProgressBar(
                    totalSteps: 5,
                    currentIndex: 3,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildKycProgressCard(),
                            const SizedBox(height: 18),
                            for (var i = 0; i < _docs.length; i++) ...[
                              _DocUploadCard(
                                doc: _docs[i],
                                uploaded: _isUploaded(_docs[i].id),
                                onTap: () => _openUploadSheet(_docs[i]),
                              ),
                              if (i < _docs.length - 1)
                                const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 16),
                            _buildInfoBanner(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Sticky bottom CTA bar
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    bottomSafe > 0 ? bottomSafe + 12 : 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    border: Border(
                      top: BorderSide(
                        color: C.line.withValues(alpha: 0.7),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DocsPrimaryButton(
                            label: _busy
                                ? 'CONTINUING…'
                                : 'CONTINUE TO BANK DETAILS',
                            busy: _busy,
                            onTap: _busy ? null : _continueToNext,
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _busy ? null : _finishLater,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Text(
                                "I'll finish this later",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: C.green,
                                ),
                              ),
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
    );
  }

  Widget _buildKycProgressCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: kGrad,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: C.green.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'KYC PROGRESS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: C.lime,
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_uploadedCount',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${_docs.length}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload these to start delivering',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 7,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * _progress,
                      height: 7,
                      decoration: BoxDecoration(
                        color: C.lime,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFE8FA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.access_time_rounded,
              size: 18,
              color: Color(0xFF1A5E8A),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Verification usually takes '),
                  TextSpan(
                    text: '2–24 hours.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: " We'll notify you as each document is approved.",
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: Color(0xFF1A5E8A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocItem {
  const _DocItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.isSelfie,
  });

  final String id;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final bool isSelfie;
}

class _DocUploadCard extends StatelessWidget {
  const _DocUploadCard({
    required this.doc,
    required this.uploaded,
    required this.onTap,
  });

  final _DocItem doc;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: uploaded ? C.green.withValues(alpha: 0.55) : const Color(0xFFCDD5C9),
        radius: 20,
        strokeWidth: uploaded ? 1.4 : 1.1,
      ),
      child: Material(
        color: uploaded
            ? const Color(0xFFF3FAF5)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: uploaded ? const Color(0xFFE2F3E7) : Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: uploaded
                          ? const Color(0xFFB7DFC3)
                          : const Color(0xFFE6EBE2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    doc.icon,
                    size: 21,
                    color: C.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: C.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        uploaded ? 'Uploaded · Tap to replace' : doc.subtitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: uploaded ? C.accent : C.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildActionPill(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill() {
    if (uploaded) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE5F4E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF9ED5AF)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 16, color: C.green),
            SizedBox(width: 5),
            Text(
              'DONE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: C.green,
              ),
            ),
          ],
        ),
      );
    }

    if (doc.isSelfie) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.green, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          doc.actionLabel,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: C.green,
          ),
        ),
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: kGrad,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.upload, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            doc.actionLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.1,
    this.dashWidth = 5.0,
    this.dashGap = 4.0,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _SheetOptionTile extends StatelessWidget {
  const _SheetOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F9F4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 22, color: C.green),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: C.ink,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: C.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocsTopBar extends StatelessWidget {
  const _DocsTopBar({
    required this.title,
    required this.onBack,
    this.stepLabel,
  });

  final String title;
  final String? stepLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkResponse(
              onTap: onBack,
              radius: 24,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: C.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: C.ink,
              ),
            ),
          ),
          if (stepLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5DB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                stepLabel!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: C.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocsStepProgressBar extends StatelessWidget {
  const _DocsStepProgressBar({
    required this.totalSteps,
    required this.currentIndex,
  });

  final int totalSteps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final color = i < currentIndex
            ? C.green
            : (i == currentIndex ? C.lime : C.line);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DocsPrimaryButton extends StatelessWidget {
  const _DocsPrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: busy ? 0.82 : 1.0,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              gradient: kGrad,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: C.green.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}