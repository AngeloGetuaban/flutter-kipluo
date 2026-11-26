import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';
import 'bespoke_icons_v2.dart';
import 'icon_shell.dart';

export 'bespoke_icons_v2.dart'
    show
        KHomeIcon, KFolderIcon, KCalendarIcon, KClockIcon, KEyeIcon, KThumbsUpIcon, KRefreshIcon, KUploadIcon, kipluoBespokeV2Icons;

/// Metadata for all 36 bespoke multi-part animated icons (16 v1 + 20 v2).
const List<({String slug, String title, KIconTier tier})> kipluoBespokeIcons = [
  (slug: 'bell-icon', title: 'Bell Icon', tier: KIconTier.free),
  (slug: 'heart-icon', title: 'Heart Icon', tier: KIconTier.free),
  (slug: 'star-icon', title: 'Star Icon', tier: KIconTier.free),
  (slug: 'trash-icon', title: 'Trash Icon', tier: KIconTier.free),
  (slug: 'search-icon', title: 'Search Icon', tier: KIconTier.free),
  (slug: 'gear-icon', title: 'Gear Icon', tier: KIconTier.free),
  (slug: 'lock-icon', title: 'Lock Icon', tier: KIconTier.premium),
  (slug: 'send-icon', title: 'Send Icon', tier: KIconTier.premium),
  (slug: 'bookmark-icon', title: 'Bookmark Icon', tier: KIconTier.premium),
  (slug: 'mail-icon', title: 'Mail Icon', tier: KIconTier.premium),
  (slug: 'speaker-icon', title: 'Speaker Icon', tier: KIconTier.premium),
  (slug: 'camera-icon', title: 'Camera Icon', tier: KIconTier.premium),
  (slug: 'bolt-icon', title: 'Bolt Icon', tier: KIconTier.premium),
  (slug: 'download-icon', title: 'Download Icon', tier: KIconTier.premium),
  (slug: 'wand-icon', title: 'Wand Icon', tier: KIconTier.premium),
  (slug: 'paw-icon', title: 'Cat Paw Icon', tier: KIconTier.premium),
  ...kipluoBespokeV2Icons,
];

abstract class _BaseBespokeIcon extends StatefulWidget {
  const _BaseBespokeIcon({super.key, this.size = 56, this.label, this.onPressed, this.sound = true});
  final double size;
  final String? label;
  final VoidCallback? onPressed;
  final bool sound;
}

class _BespokeState<_W extends _BaseBespokeIcon> extends State<_W> with SingleTickerProviderStateMixin {
  late final KSprings s = KSprings(
    vsync: this,
    initial: {'rot': 0, 'scale': 100, 'fx': 0, 'x': 0, 'y': 0, 'state': 0},
    config: SpringConfig.bouncy,
  );
  bool toggled = false;

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  void hover(KSound soundName, {double pitch = 1, double volume = 0.3, double rot = 6, double scale = 108, double y = -1.5}) {
    s.reducedMotion = kipluoReducedMotion(context);
    s.animateTo({'rot': rot * 10, 'scale': scale, 'y': y});
    KipluoSound.play(soundName, at: context, pitch: pitch, volume: volume, componentEnabled: widget.sound);
  }

  void exit() {
    s.reducedMotion = kipluoReducedMotion(context);
    s.animateTo({'rot': 0, 'scale': 100, 'x': 0, 'y': 0});
  }

  void triggerFx(KSound clickSound, {double pitch = 1, double rot = 0, double scale = 100, double x = 0, double y = 0, bool flipToggle = false}) {
    s.reducedMotion = kipluoReducedMotion(context);
    if (flipToggle) toggled = !toggled;
    s.set({'fx': 100, 'scale': 86, 'rot': rot * 10, 'x': x, 'y': y});
    s.animateTo({'fx': 0, 'scale': scale, 'rot': 0, 'x': 0, 'y': 0, 'state': toggled ? 100 : 0});
    KipluoSound.play(clickSound, at: context, pitch: pitch, volume: 0.72, componentEnabled: widget.sound);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return KipluoIconButton(
      label: widget.label ?? defaultLabel,
      size: widget.size,
      onHover: onHoverSound,
      onExit: exit,
      onActivate: onClickAction,
      child: SizedBox.square(
        dimension: widget.size * 0.62,
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) => CustomPaint(
            painter: painterBuilder(s, toggled, t),
          ),
        ),
      ),
    );
  }

  String get defaultLabel => '';
  void onHoverSound() {}
  void onClickAction() {}
  CustomPainter painterBuilder(KSprings s, bool toggled, KipluoTokens t) => throw UnimplementedError();
}

/// 1. Bell Icon
class KBellIcon extends _BaseBespokeIcon {
  const KBellIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KBellIcon> createState() => _KBellState();
}

class _KBellState extends _BespokeState<KBellIcon> {
  @override
  String get defaultLabel => 'Bell';
  @override
  void onHoverSound() => hover(KSound.tick, volume: 0.28, rot: 12);
  @override
  void onClickAction() => triggerFx(KSound.bell, rot: -20);
  @override
  CustomPainter painterBuilder(KSprings s, bool toggled, KipluoTokens t) => _BellPainter(rot: s['rot'] / 10, fx: s['fx'] / 100, scale: s['scale'] / 100, t: t);
}

class _BellPainter extends CustomPainter {
  _BellPainter({required this.rot, required this.fx, required this.scale, required this.t});
  final double rot, fx, scale;
  final KipluoTokens t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    canvas.rotate(rot * math.pi / 180);
    final w = size.width;
    final bell = Path()
      ..moveTo(-w * 0.28, w * 0.2)
      ..quadraticBezierTo(-w * 0.24, -w * 0.28, 0, -w * 0.28)
      ..quadraticBezierTo(w * 0.24, -w * 0.28, w * 0.28, w * 0.2)
      ..close();
    canvas.drawPath(bell, Paint()..color = t.accent);
    canvas.drawPath(bell, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.1..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(Offset(rot * 0.14, w * 0.26), w * 0.08, Paint()..color = t.line);
    if (fx > 0.05) {
      for (final sign in [-1.0, 1.0]) {
        canvas.drawArc(Rect.fromCircle(center: Offset(sign * w * 0.28, -w * 0.06), radius: w * (0.14 + (1 - fx) * 0.08)), sign > 0 ? -0.7 : math.pi - 0.7, 1.4, false, Paint()..color = t.accent.withValues(alpha: fx)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BellPainter old) => old.rot != rot || old.fx != fx || old.scale != scale || old.t != t;
}

/// 2. Heart Icon
class KHeartIcon extends _BaseBespokeIcon {
  const KHeartIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KHeartIcon> createState() => _KHeartState();
}

class _KHeartState extends _BespokeState<KHeartIcon> {
  @override
  String get defaultLabel => 'Heart';
  @override
  void onHoverSound() => hover(KSound.boop, pitch: 1.15, volume: 0.28, rot: 0, scale: 112);
  @override
  void onClickAction() => triggerFx(toggled ? KSound.boopLow : KSound.pop, flipToggle: true);
  @override
  CustomPainter painterBuilder(KSprings s, bool toggled, KipluoTokens t) => _KHeartPainter(fill: s['state'] / 100, fx: s['fx'] / 100, scale: s['scale'] / 100, t: t);
}

class _KHeartPainter extends CustomPainter {
  _KHeartPainter({required this.fill, required this.fx, required this.scale, required this.t});
  final double fill, fx, scale;
  final KipluoTokens t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    final w = size.width * 0.42;
    final p = Path()
      ..moveTo(0, w * 0.72)
      ..cubicTo(-w * 0.9, w * 0.15, -w * 0.8, -w * 0.7, -w * 0.35, -w * 0.7)
      ..cubicTo(-w * 0.1, -w * 0.7, 0, -w * 0.45, 0, -w * 0.35)
      ..cubicTo(0, -w * 0.45, w * 0.1, -w * 0.7, w * 0.35, -w * 0.7)
      ..cubicTo(w * 0.8, -w * 0.7, w * 0.9, w * 0.15, 0, w * 0.72)
      ..close();
    if (fill > 0.02) canvas.drawPath(p, Paint()..color = t.bad.withValues(alpha: fill.clamp(0.0, 1.0)));
    canvas.drawPath(p, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeJoin = StrokeJoin.round);
    if (fx > 0.05) {
      for (var i = 0; i < 6; i++) {
        final a = (i / 6) * math.pi * 2;
        canvas.drawCircle(Offset(math.cos(a), math.sin(a)) * (w * (0.95 + (1 - fx) * 0.3)), 2, Paint()..color = t.accent.withValues(alpha: fx));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KHeartPainter old) => old.fill != fill || old.fx != fx || old.scale != scale || old.t != t;
}

/// 3. Star Icon
class KStarIcon extends _BaseBespokeIcon {
  const KStarIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KStarIcon> createState() => _KStarState();
}

class _KStarState extends _BespokeState<KStarIcon> {
  @override
  String get defaultLabel => 'Star';
  @override
  void onHoverSound() => hover(KSound.tick, pitch: 1.2, volume: 0.25, rot: 14, scale: 108);
  @override
  void onClickAction() => triggerFx(KSound.ding, rot: 180, scale: 112);
  @override
  CustomPainter painterBuilder(KSprings s, bool toggled, KipluoTokens t) => _KStarPainter(rot: s['rot'] / 10, fx: s['fx'] / 100, scale: s['scale'] / 100, t: t);
}

class _KStarPainter extends CustomPainter {
  _KStarPainter({required this.rot, required this.fx, required this.scale, required this.t});
  final double rot, fx, scale;
  final KipluoTokens t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    canvas.rotate(rot * math.pi / 180);
    final outer = size.width * 0.36;
    final inner = outer * 0.45;
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      i == 0 ? p.moveTo(math.cos(a) * r, math.sin(a) * r) : p.lineTo(math.cos(a) * r, math.sin(a) * r);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = t.accent);
    canvas.drawPath(p, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.1..strokeJoin = StrokeJoin.round);
    if (fx > 0.05) {
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + i * math.pi * 2 / 5;
        canvas.drawLine(Offset(math.cos(a) * outer * 1.15, math.sin(a) * outer * 1.15), Offset(math.cos(a) * outer * 1.4, math.sin(a) * outer * 1.4), Paint()..color = t.accent.withValues(alpha: fx)..strokeWidth = 2..strokeCap = StrokeCap.round);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KStarPainter old) => old.rot != rot || old.fx != fx || old.scale != scale || old.t != t;
}

/// 4. Trash Icon
class KTrashIcon extends _BaseBespokeIcon {
  const KTrashIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KTrashIcon> createState() => _KTrashState();
}

class _KTrashState extends _BespokeState<KTrashIcon> {
  @override
  String get defaultLabel => 'Trash';
  @override
  void onHoverSound() => hover(KSound.boop, volume: 0.25, rot: -10, scale: 105);
  @override
  void onClickAction() => triggerFx(KSound.pop, rot: -26);
  @override
  CustomPainter painterBuilder(KSprings s, bool toggled, KipluoTokens t) => _SimpleBespokePainter(t: t, rot: s['rot'] / 10, scale: s['scale'] / 100, fx: s['fx'] / 100, drawFn: (c, sz) {
    final w = sz.width;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w * 0.22, -w * 0.14, w * 0.44, w * 0.42), const Radius.circular(4)), Paint()..color = t.surface);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w * 0.22, -w * 0.14, w * 0.44, w * 0.42), const Radius.circular(4)), Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2);
    c.save();
    c.translate(-w * 0.24, -w * 0.18);
    c.rotate(-(s['rot'].abs() / 10) * 0.025);
    c.drawLine(Offset.zero, Offset(w * 0.48, 0), Paint()..color = t.bad..strokeWidth = 3..strokeCap = StrokeCap.round);
    c.restore();
  });
}

/// 5. Search Icon
class KSearchIcon extends _BaseBespokeIcon {
  const KSearchIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KSearchIcon> createState() => _KSearchState();
}

class _KSearchState extends _BespokeState<KSearchIcon> {
  @override
  String get defaultLabel => 'Search';
  @override
  void onHoverSound() => hover(KSound.whoosh, volume: 0.25, rot: -8, scale: 108);
  @override
  void onClickAction() => triggerFx(KSound.click, rot: 14, scale: 112);
  @override
  CustomPainter painterBuilder(KSprings s, bool toggled, KipluoTokens t) => _SimpleBespokePainter(t: t, rot: s['rot'] / 10, scale: s['scale'] / 100, fx: s['fx'] / 100, drawFn: (c, sz) {
    final r = sz.width * 0.22;
    c.drawCircle(Offset(-r * 0.25, -r * 0.25), r, Paint()..color = t.accent.withValues(alpha: 0.25));
    c.drawCircle(Offset(-r * 0.25, -r * 0.25), r, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.4);
    c.drawLine(Offset(r * 0.42, r * 0.42), Offset(r * 1.15, r * 1.15), Paint()..color = t.line..strokeWidth = 3..strokeCap = StrokeCap.round);
  });
}

/// 6. Gear Icon
class KGearIcon extends _BaseBespokeIcon {
  const KGearIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KGearIcon> createState() => _KGearState();
}

class _KGearState extends _BespokeState<KGearIcon> {
  @override
  String get defaultLabel => 'Settings';
  @override
  void onHoverSound() => hover(KSound.tick, volume: 0.25, rot: 45, scale: 105);
  @override
  void onClickAction() => triggerFx(KSound.tick, pitch: 1.25, rot: 180);
  @override
  CustomPainter painterBuilder(KSprings s, bool toggled, KipluoTokens t) => _SimpleBespokePainter(t: t, rot: s['rot'] / 10, scale: s['scale'] / 100, fx: s['fx'] / 100, drawFn: (c, sz) {
    final r = sz.width * 0.26;
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2;
      c.drawLine(Offset(math.cos(a) * r * 0.8, math.sin(a) * r * 0.8), Offset(math.cos(a) * r * 1.25, math.sin(a) * r * 1.25), Paint()..color = t.line..strokeWidth = 3.2..strokeCap = StrokeCap.round);
    }
    c.drawCircle(Offset.zero, r * 0.9, Paint()..color = t.accent);
    c.drawCircle(Offset.zero, r * 0.9, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 2.2);
    c.drawCircle(Offset.zero, r * 0.35, Paint()..color = t.surface);
    c.drawCircle(Offset.zero, r * 0.35, Paint()..color = t.line..style = PaintingStyle.stroke..strokeWidth = 1.8);
  });
}

class _SimpleBespokePainter extends CustomPainter {
  _SimpleBespokePainter({required this.t, required this.rot, required this.scale, required this.fx, this.offset = Offset.zero, required this.drawFn});
  final KipluoTokens t;
  final double rot, scale, fx;
  final Offset offset;
  final void Function(Canvas canvas, Size size) drawFn;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx + offset.dx, c.dy + offset.dy);
    canvas.scale(scale);
    canvas.rotate(rot * math.pi / 180);
    drawFn(canvas, size);
    if (fx > 0.05) {
      for (var i = 0; i < 4; i++) {
        final a = math.pi / 4 + i * math.pi / 2;
        final r0 = size.width * 0.38;
        final r1 = size.width * (0.48 + (1 - fx) * 0.1);
        canvas.drawLine(Offset(math.cos(a) * r0, math.sin(a) * r0), Offset(math.cos(a) * r1, math.sin(a) * r1), Paint()..color = t.accent.withValues(alpha: fx)..strokeWidth = 2..strokeCap = StrokeCap.round);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SimpleBespokePainter old) => true;
}
