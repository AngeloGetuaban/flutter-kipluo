import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'loader_base.dart';

/* 21. Bouncing Cube Loader (Free) */
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
      duration: const Duration(milliseconds: 1600),
      painterBuilder: (t, p, s, tokens) => _CubePainter(t: t, progress: p, status: s, tokens: tokens),
    );
  }
}

class _CubePainter extends CustomPainter {
  _CubePainter({required this.t, required this.progress, required this.status, required this.tokens});
  final double t, progress;
  final LoaderStatus status;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final hop = status == LoaderStatus.running ? math.sin(t * math.pi * 2).abs() : (status == LoaderStatus.complete ? 0.35 : 0.0);
    final cy = 62 - hop * 20;
    final sx = 1 + (1 - hop) * 0.14;
    final sy = 1 / sx;
    final color = status == LoaderStatus.error ? tokens.bad : (status == LoaderStatus.complete ? tokens.ok : tokens.accent);

    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 79), width: 28 - hop * 8, height: 6), Paint()..color = tokens.track);
    canvas.save();
    canvas.translate(50, cy);
    canvas.scale(sx, sy);
    final cube = RRect.fromRectAndRadius(const Rect.fromLTWH(-15, -15, 30, 30), const Radius.circular(7));
    canvas.drawRRect(cube, Paint()..color = color);
    canvas.drawRRect(cube, Paint()..color = tokens.line..style = PaintingStyle.stroke..strokeWidth = 2.4);
    canvas.drawCircle(const Offset(-5, -2), 2, Paint()..color = tokens.line);
    canvas.drawCircle(const Offset(5, -2), 2, Paint()..color = tokens.line);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CubePainter old) => old.t != t || old.progress != progress || old.status != status || old.tokens != tokens;
}

/* 22. Hourglass Sand Loader (Free) */
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
      painterBuilder: (t, p, s, tokens) => _HourglassPainter(t: t, progress: p, status: s, tokens: tokens),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  _HourglassPainter({required this.t, required this.progress, required this.status, required this.tokens});
  final double t, progress;
  final LoaderStatus status;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final glass = Path()..moveTo(34, 22)..lineTo(66, 22)..lineTo(53, 48)..lineTo(66, 78)..lineTo(34, 78)..lineTo(47, 48)..close();
    canvas.drawPath(glass, Paint()..color = tokens.surface);
    final sandH = (progress / 100) * 20;
    final sandColor = status == LoaderStatus.error ? tokens.bad : (status == LoaderStatus.complete ? tokens.ok : tokens.accent);
    canvas.drawPath(Path()..moveTo(36, 77)..lineTo(50, 77 - sandH)..lineTo(64, 77)..close(), Paint()..color = sandColor);
    canvas.drawPath(glass, Paint()..color = tokens.line..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeJoin = StrokeJoin.round);
    canvas.drawLine(const Offset(30, 20), const Offset(70, 20), Paint()..color = tokens.line..strokeWidth = 3..strokeCap = StrokeCap.round);
    canvas.drawLine(const Offset(30, 80), const Offset(70, 80), Paint()..color = tokens.line..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_HourglassPainter old) => old.t != t || old.progress != progress || old.status != status || old.tokens != tokens;
}
