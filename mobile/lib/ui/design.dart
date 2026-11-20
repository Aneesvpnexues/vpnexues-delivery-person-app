import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double kDesignW = 412;
const double kDesignH = 915;
const double kBottomSlack = 30;

class C {
  static const bg = Color(0xFFF7F8F1);
  static const ink = Color(0xFF173E30);
  static const green = Color(0xFF095334);
  static const accent = Color(0xFF247947);
  static const muted = Color(0xFF5E6B62);
  static const line = Color(0xFFDFE5DD);
  static const tint5 = Color(0xFFEDF0EA);
  static const surface = Colors.white;
  static const yellow = Color(0xFFF8D92F);
  static const lime = Color(0xFF9CC42C);
  static const danger = Color(0xFFC92526);
  static const inkSoft = Color(0xFF47594F);
}

const pillOk = (bg: Color(0xFFDDF2E4), fg: C.green);
const pillWarn = (bg: Color(0xFFFFF1CB), fg: Color(0xFF825605));
const pillBad = (bg: Color(0xFFFDE0DD), fg: Color(0xFFB3261E));
const pillInfo = (bg: Color(0xFFE5F3F8), fg: Color(0xFF145B73));

const kGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF247947), Color(0xFF9CC42C)],
);

List<BoxShadow> sh(double y, double blur, double opacity, [double x = 0]) => [
      BoxShadow(
        color: C.green.withValues(alpha: opacity),
        offset: Offset(x, y),
        blurRadius: blur,
      ),
    ];

/// 412x915 design canvas, uniformly scaled and centred like the original Phone.tsx.
class DesignCanvas extends StatelessWidget {
  const DesignCanvas({super.key, required this.child, this.background});

  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final desk = c.maxWidth > 600;
      final s = desk
          ? math.min(1.0, math.min(c.maxWidth / kDesignW, c.maxHeight / kDesignH))
          : math.min(c.maxWidth / kDesignW, c.maxHeight / (kDesignH - kBottomSlack));
      final w = kDesignW * s;
      final h = kDesignH * s;
      final left = (c.maxWidth - w) / 2;
      final top = desk
          ? math.max(0.0, (c.maxHeight - h) / 2)
          : math.max(0.0, (c.maxHeight - (kDesignH - kBottomSlack) * s) / 2);
      final bg = background ?? C.bg;
      return ColoredBox(
        color: desk ? const Color(0xFFE9ECE4) : bg,
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: w,
              height: h,
              child: FittedBox(
                fit: BoxFit.fill,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: kDesignW,
                  height: kDesignH,
                  // Every screen sits inside a Scaffold so that toasts
                  // (ScaffoldMessenger), Material-dependent widgets and
                  // keyboard presentation always have a host, while the
                  // canvas keeps its fixed 412x915 design geometry.
                  child: Scaffold(
                    backgroundColor: bg,
                    resizeToAvoidBottomInset: false,
                    body: ColoredBox(color: bg, child: child),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class DBox extends StatelessWidget {
  const DBox({
    super.key,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.r = 0,
    this.bg,
    this.gradient,
    this.border,
    this.shadow,
    this.onTap,
    this.child,
  });

  final double x;
  final double y;
  final double w;
  final double h;
  final double r;
  final Color? bg;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: bg,
        gradient: gradient,
        borderRadius: BorderRadius.circular(r),
        border: border,
        boxShadow: shadow,
      ),
      child: child,
    );
    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: onTap == null
          ? box
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: box,
            ),
    );
  }
}

class DTxt extends StatelessWidget {
  const DTxt(
    this.text, {
    super.key,
    required this.x,
    required this.y,
    this.w = 372,
    this.s = 13,
    this.wt = FontWeight.w400,
    this.c = C.ink,
    this.lh,
    this.align = TextAlign.left,
    this.ls,
    this.onTap,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final double x;
  final double y;
  final double w;
  final double s;
  final FontWeight wt;
  final Color c;
  final double? lh;
  final TextAlign align;
  final double? ls;
  final VoidCallback? onTap;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      width: w,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s,
            fontWeight: wt,
            color: c,
            height: lh == null ? 1.35 : lh! / s,
            letterSpacing: ls,
          ),
        ),
      ),
    );
  }
}

class DImg extends StatelessWidget {
  const DImg(this.asset, {super.key, required this.x, required this.y, required this.w, required this.h, this.fit = BoxFit.fill, this.opacity = 1});

  final String asset;
  final double x;
  final double y;
  final double w;
  final double h;
  final BoxFit fit;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(asset, fit: fit, gaplessPlayback: true),
      ),
    );
  }
}

class DSvg extends StatelessWidget {
  const DSvg(this.asset, {super.key, required this.x, required this.y, required this.w, required this.h, this.opacity = 1, this.fit = BoxFit.fill});

  final String asset;
  final double x;
  final double y;
  final double w;
  final double h;
  final double opacity;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: Opacity(
        opacity: opacity,
        child: SvgPicture.asset(asset, fit: fit),
      ),
    );
  }
}

class DIcon extends StatelessWidget {
  const DIcon(this.icon, {super.key, this.x, this.y, this.s = 20, this.c = C.green, this.sw = 1.7});

  final IconData icon;
  final double? x;
  final double? y;
  final double s;
  final Color c;
  final double sw;

  @override
  Widget build(BuildContext context) {
    final ic = Icon(icon, size: s, color: c);
    if (x == null) return ic;
    return Positioned(left: x, top: y ?? 0, child: ic);
  }
}

class Logo extends StatelessWidget {
  const Logo({super.key, required this.x, required this.y, required this.s});

  final double x;
  final double y;
  final double s;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      width: s,
      height: s,
      child: ClipOval(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -1.1589 * s,
              top: -0.7059 * s,
              width: 3.3113 * s,
              height: 7.3529 * s,
              child: Image.asset('assets/logo.png', fit: BoxFit.fill, gaplessPlayback: true),
            ),
          ],
        ),
      ),
    );
  }
}

class Backdrop extends StatelessWidget {
  const Backdrop({super.key, this.outlines = const []});

  final List<Rect> outlines;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DSvg('assets/glow-top.svg', x: 190, y: -150, w: 370, h: 370),
        const DSvg('assets/glow-soft.svg', x: -150, y: 250, w: 330, h: 330),
        const DImg('assets/art/leaves.png', x: 326, y: 0, w: 86, h: 86),
        for (final o in outlines) DSvg('assets/ui/outline.svg', x: o.left, y: o.top, w: 178, h: 136),
      ],
    );
  }
}

class CornerLeaves extends StatelessWidget {
  const CornerLeaves({super.key});

  @override
  Widget build(BuildContext context) =>
      const DImg('assets/art/leaves.png', x: 326, y: 0, w: 86, h: 86);
}

class BackBar extends StatelessWidget {
  const BackBar({super.key, this.title, this.onBack, this.right, this.step});

  final String? title;
  final VoidCallback? onBack;
  final Widget? right;
  final int? step;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 20,
          top: 41,
          width: 48,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: Stack(
              children: const [
                DSvg('assets/ui/back-button.svg', x: -12, y: -8, w: 72, h: 72),
                DSvg('assets/ui/back-icon.svg', x: 15, y: 14, w: 20, h: 20),
              ],
            ),
          ),
        ),
        if (title != null)
          DTxt(title!, x: 80, y: 51, w: 246, s: 20, wt: FontWeight.w700, lh: 28),
        if (step != null)
          DTxt('Step $step of 5', x: 325, y: 57, w: 68, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.muted, align: TextAlign.right),
        if (right != null) right!,
      ],
    );
  }
}

class RoundBtn extends StatelessWidget {
  const RoundBtn({super.key, required this.icon, this.x = 344, this.y = 40, this.dot = false, this.onTap});

  final IconData icon;
  final double x;
  final double y;
  final bool dot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DBox(
      x: x,
      y: y,
      w: 48,
      h: 48,
      r: 24,
      bg: Colors.white,
      shadow: sh(4, 12, .05),
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(left: 14, top: 14, child: Icon(icon, size: 20, color: C.green)),
          if (dot)
            Positioned(
              left: 29,
              top: 21,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    this.x,
    this.y,
    this.w,
    required this.label,
    this.bg = C.green,
    this.fg = const Color(0xFFD6EE75),
    this.dot,
  });

  final double? x;
  final double? y;
  final double? w;
  final String label;
  final Color bg;
  final Color fg;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: w,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: w == null ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: w == null ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot ?? fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: fg, height: 15.4 / 11),
            ),
          ),
        ],
      ),
    );
    if (x == null) return body;
    return Positioned(left: x, top: y ?? 0, child: body);
  }
}

class Tile extends StatelessWidget {
  const Tile({super.key, this.x, this.y, this.s = 36, this.bg = const Color(0xFFEEF5DB), required this.icon, this.c, this.r = 14, this.isize = 21});

  final double? x;
  final double? y;
  final double s;
  final Color bg;
  final IconData icon;
  final Color? c;
  final double r;
  final double isize;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(r)),
      child: Icon(icon, size: isize, color: c ?? C.green),
    );
    if (x == null) return body;
    return Positioned(left: x, top: y ?? 0, child: body);
  }
}

class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({super.key, this.x, this.y, required this.on, required this.onChanged, this.onColor = C.accent});

  final double? x;
  final double? y;
  final bool on;
  final ValueChanged<bool> onChanged;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final body = GestureDetector(
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          color: on ? onColor : const Color(0xFFC9D3CB),
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), offset: const Offset(0, 2), blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
    if (x == null) return body;
    return Positioned(left: x, top: y ?? 0, child: body);
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    this.x = 20,
    required this.y,
    this.w = 372,
    required this.label,
    this.onTap,
    this.bg = C.green,
    this.color = Colors.white,
    this.height = 56,
  });

  final double x;
  final double y;
  final double w;
  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      width: w,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: sh(10, 18, .18),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: color, letterSpacing: .2),
          ),
        ),
      ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  const OutlineButton({super.key, required this.y, required this.label, this.onTap});

  final double y;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      top: y,
      width: 372,
      height: 56,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: C.green, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: C.green),
          ),
        ),
      ),
    );
  }
}

enum BtnKind { primary, outline, yellow, muted, danger }

class Btn extends StatelessWidget {
  const Btn({super.key, this.x = 20, this.y, this.w = 372, this.h = 56, required this.label, this.onTap, this.kind = BtnKind.primary, this.fs = 14, this.icon});

  final double x;
  final double? y;
  final double w;
  final double h;
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  final double fs;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, shadow) = switch (kind) {
      BtnKind.primary => (C.green, Colors.white, null, sh(10, 18, .18)),
      BtnKind.outline => (Colors.white, C.green, Border.all(color: C.green, width: 2), null),
      BtnKind.yellow => (C.yellow, C.green, null, sh(10, 18, .18)),
      BtnKind.muted => (const Color(0xFFE3EBDE), const Color(0xFF405947), null, null),
      BtnKind.danger => (C.danger, Colors.white, null, sh(10, 18, .2)),
    };
    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(h / 2), border: border, boxShadow: shadow),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: fs, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
    if (y == null) return body;
    return Positioned(left: x, top: y!, child: body);
  }
}

class Field extends StatelessWidget {
  const Field({
    super.key,
    this.x = 20,
    this.y,
    this.w = 372,
    this.label,
    this.controller,
    this.icon,
    this.placeholder,
    this.obscure = false,
    this.keyboard,
    this.suffix,
    this.ok = false,
    this.h = 55,
    this.readOnly = false,
    this.onTap,
  });

  final double x;
  final double? y;
  final double w;
  final String? label;
  final TextEditingController? controller;
  final IconData? icon;
  final String? placeholder;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? suffix;
  final bool ok;
  final double h;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: C.ink, height: 18.2 / 13)),
          const SizedBox(height: 8),
        ],
        Container(
          height: h,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ok ? const Color(0xFF81C895) : C.line),
          ),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: C.muted), const SizedBox(width: 11)],
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  onTap: onTap,
                  obscureText: obscure,
                  keyboardType: keyboard,
                  cursorColor: C.green,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: C.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9AA69E)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
      ],
    );
    if (y == null) return field;
    return Positioned(left: x, top: y!, width: w, child: field);
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.active, required this.onTap});

  final String active;
  final ValueChanged<String> onTap;

  static const tabs = [
    ('home', 'Home', LucideIcons.home),
    ('orders', 'Orders', LucideIcons.package),
    ('earnings', 'Earnings', LucideIcons.wallet),
    ('profile', 'Profile', LucideIcons.user),
  ];

  @override
  Widget build(BuildContext context) {
    return DBox(
      x: 20,
      y: 816,
      w: 372,
      h: 68,
      r: 26,
      bg: C.green,
      shadow: sh(12, 24, .2),
      child: Stack(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Positioned(
              left: 17 + i * 90.0,
              top: 7,
              width: 68,
              height: 54,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(tabs[i].$1),
                child: Container(
                  decoration: BoxDecoration(
                    color: tabs[i].$1 == active ? const Color(0xFF246849) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tabs[i].$3, size: 20, color: tabs[i].$1 == active ? C.yellow : const Color(0xFFCEE3D0)),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].$2,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tabs[i].$1 == active ? C.yellow : const Color(0xFFCEE3D0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Steps extends StatelessWidget {
  const Steps({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DTxt('Step $step of 5', x: 325, y: 57, w: 68, s: 11, wt: FontWeight.w700, lh: 15.4, c: C.muted, align: TextAlign.right),
        for (var i = 0; i < 5; i++)
          DBox(
            x: 20 + i * 76.0,
            y: 104,
            w: 70,
            h: 6,
            r: 3,
            bg: i < step - 1 ? C.green : (i == step - 1 ? C.lime : C.line),
          ),
      ],
    );
  }
}

class Modal extends StatelessWidget {
  const Modal({super.key, required this.onClose, required this.child, this.w = 372});

  final VoidCallback onClose;
  final Widget child;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: const Color(0x730A1E16),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: w,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 60, offset: const Offset(0, 24))],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

void showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: C.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
}

class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.style, this.gradient = kGrad});

  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }
}
