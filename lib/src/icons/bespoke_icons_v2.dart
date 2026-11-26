import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';
import 'icon_shell.dart';

/// Metadata for the 20 new bespoke multi-part animated icons (v2 expansion).
const List<({String slug, String title, KIconTier tier})> kipluoBespokeV2Icons = [
  (slug: 'home-icon', title: 'Home Icon', tier: KIconTier.free),
  (slug: 'folder-icon', title: 'Folder Icon', tier: KIconTier.free),
  (slug: 'calendar-icon', title: 'Calendar Icon', tier: KIconTier.free),
  (slug: 'clock-icon', title: 'Clock Icon', tier: KIconTier.free),
  (slug: 'eye-icon', title: 'Eye Icon', tier: KIconTier.free),
  (slug: 'thumbs-up-icon', title: 'Thumbs Up Icon', tier: KIconTier.free),
  (slug: 'refresh-icon', title: 'Refresh Icon', tier: KIconTier.free),
  (slug: 'upload-icon', title: 'Upload Icon', tier: KIconTier.free),
  (slug: 'shopping-cart-icon', title: 'Shopping Cart Icon', tier: KIconTier.premium),
  (slug: 'rocket-icon', title: 'Rocket Icon', tier: KIconTier.premium),
  (slug: 'flame-icon', title: 'Flame Icon', tier: KIconTier.premium),
  (slug: 'trophy-icon', title: 'Trophy Icon', tier: KIconTier.premium),
  (slug: 'gift-icon', title: 'Gift Icon', tier: KIconTier.premium),
  (slug: 'ghost-icon', title: 'Ghost Icon', tier: KIconTier.premium),
  (slug: 'coffee-icon', title: 'Coffee Icon', tier: KIconTier.premium),
  (slug: 'key-icon', title: 'Key Icon', tier: KIconTier.premium),
  (slug: 'shield-icon', title: 'Shield Icon', tier: KIconTier.premium),
  (slug: 'compass-icon', title: 'Compass Icon', tier: KIconTier.premium),
  (slug: 'music-icon', title: 'Music Icon', tier: KIconTier.premium),
  (slug: 'shiba-paw-icon', title: 'Shiba Paw Icon', tier: KIconTier.premium),
];

class _BespokeV2Icon extends StatefulWidget {
  const _BespokeV2Icon({
    super.key,
    this.size = 56,
    this.label,
    required this.defaultLabel,
    required this.hoverSound,
    required this.clickSound,
    required this.painterFn,
    this.onPressed,
    this.sound = true,
  });

  final double size;
  final String? label;
  final String defaultLabel;
  final KSound hoverSound;
  final KSound clickSound;
  final void Function(Canvas c, Size s, double rot, double scale, double fx, KipluoTokens t) painterFn;
  final VoidCallback? onPressed;
  final bool sound;

  @override
  State<_BespokeV2Icon> createState() => _BespokeV2IconState();
}

class _BespokeV2IconState extends State<_BespokeV2Icon> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(vsync: this, initial: {'rot': 0, 'scale': 100, 'fx': 0}, config: SpringConfig.bouncy);

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _hover() {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'rot': -100, 'scale': 108});
    KipluoSound.play(widget.hoverSound, at: context, volume: 0.28, componentEnabled: widget.sound);
  }

  void _exit() {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'rot': 0, 'scale': 100});
  }

  void _tap() {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.set({'fx': 100, 'scale': 84, 'rot': 160});
    _s.animateTo({'fx': 0, 'scale': 100, 'rot': 0});
    KipluoSound.play(widget.clickSound, at: context, volume: 0.72, componentEnabled: widget.sound);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return KipluoIconButton(
      label: widget.label ?? widget.defaultLabel,
      size: widget.size,
      onHover: _hover,
      onExit: _exit,
      onActivate: _tap,
      child: SizedBox.square(
        dimension: widget.size * 0.62,
        child: AnimatedBuilder(
          animation: _s,
          builder: (context, _) => CustomPaint(
            painter: _V2Painter(
              rot: _s['rot'] / 10,
              scale: _s['scale'] / 100,
              fx: _s['fx'] / 100,
              t: t,
              painterFn: widget.painterFn,
            ),
          ),
        ),
      ),
    );
  }
}

class _V2Painter extends CustomPainter {
  _V2Painter({required this.rot, required this.scale, required this.fx, required this.t, required this.painterFn});
  final double rot, scale, fx;
  final KipluoTokens t;
  final void Function(Canvas c, Size s, double rot, double scale, double fx, KipluoTokens t) painterFn;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    canvas.rotate(rot * math.pi / 180);
    painterFn(canvas, size, rot, scale, fx, t);
    if (fx > 0.05) {
      for (var i = 0; i < 4; i++) {
        final a = math.pi / 4 + i * math.pi / 2;
        final r0 = size.width * 0.36;
        final r1 = size.width * (0.46 + (1 - fx) * 0.1);
        canvas.drawLine(Offset(math.cos(a) * r0, math.sin(a) * r0), Offset(math.cos(a) * r1, math.sin(a) * r1), Paint()..color = t.accent.withValues(alpha: fx)..strokeWidth = 2..strokeCap = StrokeCap.round);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_V2Painter old) => old.rot != rot || old.scale != scale || old.fx != fx || old.t != t;
}

class KHomeIcon extends _BespokeV2Icon {
  KHomeIcon({super.key, super.size, super.label, super.onPressed, super.sound})
      : super(
          defaultLabel: 'Home Icon',
          hoverSound: KSound.boop,
          clickSound: KSound.pop,
          painterFn: (c, sz, _, _, _, t) {
            final w = sz.width * 0.34;
            c.drawRect(Rect.fromLTWH(-w * 0.65, -w * 0.1, w * 1.3, w * 0.9), Paint()..color = t.surface);
            c.drawRect(Rect.fromLTWH(-w * 0.65, -w * 0.1, w * 1.3, w * 0.9), Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2);
            c.drawRect(Rect.fromLTWH(-w * 0.2, w * 0.25, w * 0.4, w * 0.55), Paint()..color = t.accent);
            c.drawPath(Path()..moveTo(-w, 0)..lineTo(0, -w * 0.85)..lineTo(w, 0), Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeCap = StrokeCap.round);
          },
        );
}

class KFolderIcon extends _BespokeV2Icon {
  KFolderIcon({super.key, super.size, super.label, super.onPressed, super.sound})
      : super(
          defaultLabel: 'Folder Icon',
          hoverSound: KSound.flip,
          clickSound: KSound.pop,
          painterFn: (c, sz, _, _, _, t) {
            final w = sz.width * 0.36;
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w, -w * 0.6, w * 2, w * 1.3), const Radius.circular(4)), Paint()..color = t.accent);
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w, -w * 0.6, w * 2, w * 1.3), const Radius.circular(4)), Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2);
          },
        );
}

class KCalendarIcon extends _BespokeV2Icon {
  KCalendarIcon({super.key, super.size, super.label, super.onPressed, super.sound})
      : super(
          defaultLabel: 'Calendar Icon',
          hoverSound: KSound.flip,
          clickSound: KSound.click,
          painterFn: (c, sz, _, _, _, t) {
            final w = sz.width * 0.34;
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w, -w * 0.7, w * 2, w * 1.5), const Radius.circular(4)), Paint()..color = t.surface);
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w, -w * 0.7, w * 2, w * 1.5), const Radius.circular(4)), Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2);
            c.drawLine(Offset(-w, -w * 0.25), Offset(w, -w * 0.25), Paint()..color = t.line..strokeWidth = 2);
            c.drawCircle(Offset(0, w * 0.3), w * 0.25, Paint()..color = t.accent);
          },
        );
}

class KClockIcon extends _BespokeV2Icon {
  KClockIcon({super.key, super.size, super.label, super.onPressed, super.sound})
      : super(
          defaultLabel: 'Clock Icon',
          hoverSound: KSound.tick,
          clickSound: KSound.ding,
          painterFn: (c, sz, _, _, _, t) {
            final r = sz.width * 0.36;
            c.drawCircle(Offset.zero, r, Paint()..color = t.accent);
            c.drawCircle(Offset.zero, r, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.1);
            c.drawPath(Path()..moveTo(0, -r * 0.55)..lineTo(0, 0)..lineTo(r * 0.4, 0), Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round);
          },
        );
}

class KEyeIcon extends _BespokeV2Icon {
  KEyeIcon({super.key, super.size, super.label, super.onPressed, super.sound})
      : super(
          defaultLabel: 'Eye Icon',
          hoverSound: KSound.tick,
          clickSound: KSound.click,
          painterFn: (c, sz, _, _, _, t) {
            final w = sz.width * 0.38;
            final p = Path()..moveTo(-w, 0)..quadraticBezierTo(0, -w * 0.7, w, 0)..quadraticBezierTo(0, w * 0.7, -w, 0);
            c.drawPath(p, Paint()..color = t.surface);
            c.drawPath(p, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2);
            c.drawCircle(Offset.zero, w * 0.3, Paint()..color = t.accent);
            c.drawCircle(Offset.zero, w * 0.3, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 1.8);
          },
        );
}

class KThumbsUpIcon extends _BespokeV2Icon {
  KThumbsUpIcon({super.key, super.size, super.label, super.onPressed, super.sound})
      : super(
          defaultLabel: 'Thumbs Up Icon',
          hoverSound: KSound.boop,
          clickSound: KSound.pop,
          painterFn: (c, sz, _, _, _, t) {
            final w = sz.width * 0.32;
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w * 0.9, -w * 0.1, w * 0.45, w * 0.95), const Radius.circular(3)), Paint()..color = t.surface);
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w * 0.35, -w * 0.4, w * 1.1, w * 1.25), const Radius.circular(5)), Paint()..color = t.accent);
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w * 0.35, -w * 0.4, w * 1.1, w * 1.25), const Radius.circular(5)), Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2);
          },
        );
}

class KRefreshIcon extends _BespokeV2Icon {
  KRefreshIcon({super.key, super.size, super.label, super.onPressed, super.sound})
      : super(
          defaultLabel: 'Refresh Icon',
          hoverSound: KSound.tick,
          clickSound: KSound.whoosh,
          painterFn: (c, sz, _, _, _, t) {
            final r = sz.width * 0.32;
            c.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), -0.4, math.pi * 1.55, false, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round);
          },
        );
}

class KUploadIcon extends _BespokeV2Icon {
  KUploadIcon({super.key, super.size, super.label, super.onPressed, super.sound})
      : super(
          defaultLabel: 'Upload Icon',
          hoverSound: KSound.whoosh,
          clickSound: KSound.swish,
          painterFn: (c, sz, _, _, _, t) {
            final w = sz.width * 0.3;
            c.drawLine(Offset(0, w * 0.3), Offset(0, -w * 0.9), Paint()..color = t.line..strokeWidth = 2.5..strokeCap = StrokeCap.round);
            c.drawPath(Path()..moveTo(-w * 0.5, -w * 0.4)..lineTo(0, -w * 0.95)..lineTo(w * 0.5, -w * 0.4), Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
            c.drawPath(Path()..moveTo(-w, w * 0.5)..lineTo(-w, w * 0.85)..lineTo(w, w * 0.85)..lineTo(w, w * 0.5), Paint()..color = t.accent..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round);
          },
        );
}
