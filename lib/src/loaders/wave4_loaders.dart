import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';
import 'loader_base.dart';

/* ==========================================================================
   21. Bouncing Cube Loader (Free)
   ========================================================================== */
class BouncingCubeLoader extends StatelessWidget {
  const BouncingCubeLoader({super.key, this.value, this.status = LoaderStatus.running, this.size = 96, this.label = 'Loading', this.sound = true});

  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;

  @override
  Widget build(BuildContext context) {
    return KipluoLoaderShell(
      value: value,
      status: status,
      size: size,
      label: label,
      sound: sound,
      duration: const Duration(milliseconds: 1450),
      tapSound: KSound.jump,
      hopSound: KSound.jump,
      completeSound: KSound.giggle,
      errorSound: KSound.aww,
      interactivePainterBuilder: (t, p, pulse, s, tokens) => _CubePainter(t: t, progress: p, pulse: pulse, status: s, tokens: tokens),
    );
  }
}

class _CubePainter extends CustomPainter {
  _CubePainter({required this.t, required this.progress, required this.pulse, required this.status, required this.tokens});
  final double t, progress, pulse;
  final LoaderStatus status;
  final KipluoTokens tokens;

  static const _rays = [-155.0, -120.0, -90.0, -60.0, -25.0, 18.0, 162.0];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final isComplete = status == LoaderStatus.complete;
    final isError = status == LoaderStatus.error;
    final phase = t * math.pi * 2;
    final rawHop = status == LoaderStatus.running ? math.sin(phase).abs() : (isComplete ? 0.55 : 0.0);
    final hop = (rawHop + (isError ? 0 : math.sin(pulse * math.pi) * 0.5)).clamp(0.0, 1.35);
    final landImpact = status == LoaderStatus.running ? (1.0 - rawHop * 4.5).clamp(0.0, 1.0) : 0.0;

    final cy = isError ? 68.0 : 63 - hop * 23;
    final sx = isError ? 1.18 : 1 + (1 - hop.clamp(0.0, 1.0)) * 0.16;
    final sy = 1 / sx;
    final color = isError ? tokens.bad : (isComplete ? tokens.ok : tokens.accent);
    final stroke = Paint()
      ..color = tokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ground track + shadow + progress pill
    canvas.drawLine(const Offset(16, 81), const Offset(84, 81), Paint()..color = tokens.line.withValues(alpha: 0.22)..strokeWidth = 1.4..strokeCap = StrokeCap.round);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 80.5), width: (16 - hop * 5.5).clamp(6.0, 19.0) * 2, height: 6.4), Paint()..color = tokens.track.withValues(alpha: 0.85));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(25, 87, 50, 4), const Radius.circular(2)), Paint()..color = tokens.track.withValues(alpha: 0.7));
    if (progress > 0) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(25, 87, math.max(4, (progress / 100) * 50), 4), const Radius.circular(2)), Paint()..color = color);
    }

    // Ground impact release lines & dust puffs on every bounce
    if (landImpact > 0.05) {
      final ip = Paint()..color = tokens.accent.withValues(alpha: landImpact * 0.9)..strokeWidth = 1.7..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(30 - landImpact * 6, 77), Offset(22 - landImpact * 9, 73), ip);
      canvas.drawLine(Offset(70 + landImpact * 6, 77), Offset(78 + landImpact * 9, 73), ip);
      canvas.drawCircle(Offset(31 - landImpact * 7, 78), 1.8 + landImpact * 1.4, Paint()..color = tokens.track.withValues(alpha: landImpact * 0.85));
      canvas.drawCircle(Offset(69 + landImpact * 7, 78), 1.8 + landImpact * 1.4, Paint()..color = tokens.track.withValues(alpha: landImpact * 0.85));
    }

    // Radial anime line release on tap / complete / error
    if (pulse > 0.02 || isComplete || isError) {
      final sc = pulse > 0.02 ? 0.8 + (1 - pulse) * 0.42 : 1.0;
      final op = pulse > 0.02 ? (pulse * 1.35).clamp(0.0, 1.0) : 0.88;
      canvas.save();
      canvas.translate(50, cy - 2);
      canvas.scale(sc);
      for (var i = 0; i < _rays.length; i++) {
        final rad = _rays[i] * math.pi / 180;
        final r1 = 21.0 + (i.isEven ? 7.5 : 4.5);
        canvas.drawLine(
          Offset(math.cos(rad) * 21, math.sin(rad) * 21),
          Offset(math.cos(rad) * r1, math.sin(rad) * r1),
          Paint()..color = color.withValues(alpha: op)..strokeWidth = 1.8..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }

    // Textured beveled cube
    canvas.save();
    canvas.translate(50, cy);
    final tilt = status == LoaderStatus.running ? math.cos(phase) * 0.09 + math.sin(pulse * math.pi * 2) * 0.2 * pulse : (isError ? -0.1 : 0.0);
    canvas.rotate(tilt);
    canvas.scale(sx, sy);
    final cube = RRect.fromRectAndRadius(const Rect.fromLTWH(-15.5, -15.5, 31, 31), const Radius.circular(7.5));
    canvas.drawRRect(cube, Paint()..color = color);
    // Bottom depth shading + top specular highlight
    canvas.save();
    canvas.clipRRect(cube);
    canvas.drawRect(const Rect.fromLTWH(-16, 8.5, 32, 8), Paint()..color = tokens.line.withValues(alpha: 0.18));
    canvas.restore();
    canvas.drawLine(const Offset(-9.5, -10.5), const Offset(6, -10.5), Paint()..color = Colors.white.withValues(alpha: 0.65)..strokeWidth = 2.4..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(10, -10.5), 1.2, Paint()..color = Colors.white.withValues(alpha: 0.65));
    canvas.drawRRect(cube, stroke);

    // Cheeks
    final cheek = Paint()..color = (isError ? tokens.line : tokens.bad).withValues(alpha: 0.28);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-9.2, 3.2), width: 4.8, height: 2.8), cheek);
    canvas.drawOval(Rect.fromCenter(center: const Offset(9.2, 3.2), width: 4.8, height: 2.8), cheek);

    if (isError) {
      canvas.drawPath(Path()..moveTo(-8, -4)..lineTo(-3.5, 0.5)..moveTo(-3.5, -4)..lineTo(-8, 0.5)..moveTo(3.5, -4)..lineTo(8, 0.5)..moveTo(8, -4)..lineTo(3.5, 0.5), stroke..strokeWidth = 2);
      canvas.drawPath(Path()..moveTo(-5.5, 6.5)..quadraticBezierTo(-2.7, 4, 0, 6.5)..quadraticBezierTo(2.7, 9, 5.5, 6.5), stroke..strokeWidth = 1.8);
    } else if (isComplete) {
      canvas.drawPath(Path()..moveTo(-8.5, -1)..quadraticBezierTo(-5.5, -4.5, -2.5, -1), stroke..strokeWidth = 2.1);
      canvas.drawCircle(const Offset(5.5, -1.5), 2.4, Paint()..color = tokens.line);
      canvas.drawCircle(const Offset(4.7, -2.3), 0.85, Paint()..color = Colors.white);
      final smile = Path()..moveTo(-5.5, 4.2)..quadraticBezierTo(0, 10.7, 5.5, 4.2)..close();
      canvas.drawPath(smile, Paint()..color = tokens.surface);
      canvas.drawPath(smile, stroke..strokeWidth = 1.8);
    } else {
      canvas.drawCircle(const Offset(-5.2, -1.5), 2.4, Paint()..color = tokens.line);
      canvas.drawCircle(const Offset(-6.0, -2.4), 0.85, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(5.2, -1.5), 2.4, Paint()..color = tokens.line);
      canvas.drawCircle(const Offset(4.4, -2.4), 0.85, Paint()..color = Colors.white);
      canvas.drawPath(Path()..moveTo(-4, 5)..quadraticBezierTo(0, hop > 0.65 ? 8.5 : 6.5, 4, 5), stroke..strokeWidth = 1.9);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CubePainter old) =>
      old.t != t || old.progress != progress || old.pulse != pulse || old.status != status || old.tokens != tokens;
}

/* ==========================================================================
   22. Hourglass Sand Loader (Free)
   ========================================================================== */
class HourglassSandLoader extends StatelessWidget {
  const HourglassSandLoader({super.key, this.value, this.status = LoaderStatus.running, this.size = 96, this.label = 'Loading', this.sound = true});

  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;

  @override
  Widget build(BuildContext context) {
    return KipluoLoaderShell(
      value: value,
      status: status,
      size: size,
      label: label,
      sound: sound,
      duration: const Duration(milliseconds: 2200),
      tapSound: KSound.flip,
      hopSound: KSound.sand,
      hopsPerLoop: 4,
      completeSound: KSound.bell,
      errorSound: KSound.click,
      interactivePainterBuilder: (t, p, pulse, s, tokens) => _HourglassPainter(t: t, progress: p, pulse: pulse, status: s, tokens: tokens),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  _HourglassPainter({required this.t, required this.progress, required this.pulse, required this.status, required this.tokens});
  final double t, progress, pulse;
  final LoaderStatus status;
  final KipluoTokens tokens;

  static const _rays = [
    (deg: -162.0, r0: 36.0, len: 7.5),
    (deg: -132.0, r0: 47.0, len: 6.5),
    (deg: -48.0, r0: 47.0, len: 6.5),
    (deg: -18.0, r0: 36.0, len: 7.5),
    (deg: 18.0, r0: 36.0, len: 7.5),
    (deg: 48.0, r0: 47.0, len: 6.5),
    (deg: 132.0, r0: 47.0, len: 6.5),
    (deg: 162.0, r0: 36.0, len: 7.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final isComplete = status == LoaderStatus.complete;
    final isError = status == LoaderStatus.error;
    final frac = isComplete ? 1.0 : (progress / 100).clamp(0.0, 1.0);
    final sandColor = isError ? tokens.bad : (isComplete ? tokens.ok : tokens.accent);
    final stroke = Paint()
      ..color = tokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 86), width: 46, height: 6), Paint()..color = tokens.track.withValues(alpha: 0.75));

    // Radial anime release rays ONLY on complete, error, or interactive shake — with generous clearance from the hourglass body
    if (pulse > 0.02 || isComplete || isError) {
      final sc = pulse > 0.02 ? 0.98 + (1 - pulse) * 0.16 : 1.02;
      final op = pulse > 0.02 ? (pulse * 1.35).clamp(0.0, 1.0) : 0.88;
      canvas.save();
      canvas.translate(50, 50);
      canvas.scale(sc);
      for (final ray in _rays) {
        final rad = ray.deg * math.pi / 180;
        final r1 = ray.r0 + ray.len;
        canvas.drawLine(
          Offset(math.cos(rad) * ray.r0, math.sin(rad) * ray.r0),
          Offset(math.cos(rad) * r1, math.sin(rad) * r1),
          Paint()..color = sandColor.withValues(alpha: op)..strokeWidth = 1.8..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }

    canvas.save();
    final rot = pulse > 0.02 ? math.sin(pulse * math.pi * 3) * 0.22 * pulse : (isError ? -0.14 : 0.0);
    canvas.translate(50, 50);
    canvas.rotate(rot);
    canvas.translate(-50, -50);

    // Side pillars
    final pillar = Paint()..color = tokens.line.withValues(alpha: 0.65)..strokeWidth = 2.4..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(29.5, 22), const Offset(29.5, 78), pillar);
    canvas.drawLine(const Offset(70.5, 22), const Offset(70.5, 78), pillar);

    final topBulb = Path()..moveTo(32, 23)..lineTo(68, 23)..cubicTo(68, 38, 56, 44, 52, 49)..lineTo(48, 49)..cubicTo(44, 44, 32, 38, 32, 23)..close();
    final botBulb = Path()..moveTo(48, 51)..lineTo(52, 51)..cubicTo(56, 56, 68, 62, 68, 77)..lineTo(32, 77)..cubicTo(32, 62, 44, 56, 48, 51)..close();
    final glass = Path()
      ..moveTo(32, 23)
      ..lineTo(68, 23)
      ..cubicTo(68, 38, 55, 44, 52, 50)
      ..cubicTo(55, 56, 68, 62, 68, 77)
      ..lineTo(32, 77)
      ..cubicTo(32, 62, 45, 56, 48, 50)
      ..cubicTo(45, 44, 32, 38, 32, 23)
      ..close();

    canvas.drawPath(glass, Paint()..color = tokens.surface);

    // Upper draining sand
    final upperY = 26 + frac * 19.5;
    if (frac < 0.98) {
      canvas.save();
      canvas.clipPath(topBulb);
      canvas.drawPath(
        Path()..moveTo(28, upperY)..quadraticBezierTo(50, upperY + 5, 72, upperY)..lineTo(72, 52)..lineTo(28, 52)..close(),
        Paint()..color = sandColor,
      );
      canvas.restore();
    }

    // Lower growing sand mound + falling grain stream + peak splash ticks
    final lowerY = 77 - frac * 21;
    canvas.save();
    canvas.clipPath(botBulb);
    if (frac > 0.02) {
      canvas.drawPath(
        Path()..moveTo(28, 78)..quadraticBezierTo(42, lowerY + 5, 50, lowerY)..quadraticBezierTo(58, lowerY + 5, 72, 78)..close(),
        Paint()..color = sandColor,
      );
      canvas.drawCircle(Offset(44, math.min(75, lowerY + 9)), 1.0, Paint()..color = Colors.white.withValues(alpha: 0.65));
      canvas.drawCircle(Offset(56, math.min(75, lowerY + 11)), 0.85, Paint()..color = Colors.white.withValues(alpha: 0.55));
    }
    if (status == LoaderStatus.running && frac < 0.99) {
      canvas.drawLine(const Offset(50, 49), Offset(50, math.max(52, lowerY)), Paint()..color = sandColor..strokeWidth = 1.8);
      for (var i = 0; i < 3; i++) {
        final k = (t * 2.5 + i * 0.33) % 1.0;
        canvas.drawCircle(Offset(50, 51 + k * math.max(4, lowerY - 51)), 1.2, Paint()..color = tokens.line.withValues(alpha: 0.35));
      }
      final sp = Paint()..color = sandColor.withValues(alpha: 0.75)..strokeWidth = 1.2..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(47.5, lowerY - 1), Offset(45, lowerY - 3.5), sp);
      canvas.drawLine(Offset(52.5, lowerY - 1), Offset(55, lowerY - 3.5), sp);
    }
    canvas.restore();

    // Specular glass reflections & error crack
    final sheen = Paint()..color = Colors.white.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.9..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(36, 27)..cubicTo(36, 35, 42, 40, 46, 45), sheen);
    canvas.drawPath(Path()..moveTo(36, 73)..cubicTo(36, 65, 42, 60, 46, 55), sheen);
    if (isError) {
      canvas.drawPath(Path()..moveTo(62, 28)..lineTo(56, 33)..lineTo(60, 38)..lineTo(53, 44), Paint()..color = tokens.bad..style = PaintingStyle.stroke..strokeWidth = 1.7);
    }

    canvas.drawPath(glass, stroke);

    // Ornate beveled caps
    final capCol = isError ? tokens.bad : tokens.surface;
    final topCap = RRect.fromRectAndRadius(const Rect.fromLTWH(24, 17, 52, 6), const Radius.circular(3));
    final botCap = RRect.fromRectAndRadius(const Rect.fromLTWH(24, 77, 52, 6), const Radius.circular(3));
    canvas.drawRRect(topCap, Paint()..color = capCol);
    canvas.drawRRect(topCap, stroke);
    canvas.drawRRect(botCap, Paint()..color = capCol);
    canvas.drawRRect(botCap, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HourglassPainter old) =>
      old.t != t || old.progress != progress || old.pulse != pulse || old.status != status || old.tokens != tokens;
}
