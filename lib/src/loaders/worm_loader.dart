import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'loader_base.dart';

/// Crawling inchworm loader with segmented body ridges, antennae, ground track, curled happy
/// spiral on complete, and kinked error pose.
class WormLoader extends StatelessWidget {
  const WormLoader({super.key, this.value, this.status = LoaderStatus.running, this.size = 96, this.label = 'Loading', this.sound = true});

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
      painterBuilder: (t, p, s, tokens) => _WormPainter(t: t, progress: p, status: s, tokens: tokens),
    );
  }
}

class _WormPainter extends CustomPainter {
  _WormPainter({required this.t, required this.progress, required this.status, required this.tokens});
  final double t;
  final double progress;
  final LoaderStatus status;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    // Ground dotted path
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(Offset(14 + i * 10.2, 74), 1.3, Paint()..color = tokens.track);
    }

    if (status == LoaderStatus.complete) {
      // Curled happy worm + anime pop lines
      canvas.drawArc(const Rect.fromLTWH(28, 34, 44, 34), 0, math.pi * 1.4, false, Paint()..color = tokens.ok..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round);
      canvas.drawCircle(const Offset(50, 44), 2.2, Paint()..color = Colors.white);
      for (var i = 0; i < 4; i++) {
        final a = -math.pi * 0.8 + i * 0.55;
        canvas.drawLine(Offset(50 + math.cos(a) * 28, 48 + math.sin(a) * 24), Offset(50 + math.cos(a) * 35, 48 + math.sin(a) * 30), Paint()..color = tokens.ok..strokeWidth = 2..strokeCap = StrokeCap.round);
      }
      return;
    }

    final inch = status == LoaderStatus.error ? 0.2 : (math.sin(t * math.pi * 2) * 0.5 + 0.5);
    final travel = (progress / 100) * 34;
    final startX = 18.0 + travel * 0.65;
    final endX = startX + 28 - inch * 9;
    final midX = (startX + endX) / 2;
    final humpY = 66.0 - (status == LoaderStatus.error ? 4.0 : 10.0 + inch * 12.0);

    final bodyColor = status == LoaderStatus.error ? tokens.bad : tokens.accent;
    final worm = Path()
      ..moveTo(startX, 66)
      ..quadraticBezierTo(midX, humpY, endX, 66);

    canvas.drawPath(
      worm,
      Paint()
        ..color = tokens.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      worm,
      Paint()
        ..color = bodyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Body segment ridges
    for (var i = 1; i <= 4; i++) {
      final u = i / 5.0;
      final sx = ((1 - u) * (1 - u) * startX + 2 * (1 - u) * u * midX + u * u * endX).toDouble();
      final sy = ((1 - u) * (1 - u) * 66 + 2 * (1 - u) * u * humpY + u * u * 66).toDouble();
      canvas.drawCircle(Offset(sx, sy - 1.5), 1.4, Paint()..color = tokens.line.withValues(alpha: 0.35));
    }
    // Head eye + antennae
    canvas.drawCircle(Offset(endX + 1, 63), 1.6, Paint()..color = tokens.line);
    canvas.drawLine(Offset(endX, 60), Offset(endX + 3, 54), Paint()..color = tokens.line..strokeWidth = 1.6..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_WormPainter old) => old.t != t || old.progress != progress || old.status != status || old.tokens != tokens;
}
