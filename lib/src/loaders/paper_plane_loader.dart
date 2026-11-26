import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'loader_base.dart';

/// Paper plane that flies a loop-the-loop route along a dashed trail, zooms off on complete,
/// and noses down on error.
class PaperPlaneLoader extends StatelessWidget {
  const PaperPlaneLoader({super.key, this.value, this.status = LoaderStatus.running, this.size = 96, this.label = 'Loading', this.sound = true});

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
      painterBuilder: (t, p, s, tokens) => _PlanePainter(t: t, progress: p, status: s, tokens: tokens),
    );
  }
}

class _PlanePainter extends CustomPainter {
  _PlanePainter({required this.t, required this.progress, required this.status, required this.tokens});
  final double t;
  final double progress;
  final LoaderStatus status;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    // Dashed loop guide
    for (var i = 0; i < 16; i++) {
      final a = (i / 16) * math.pi * 2;
      canvas.drawCircle(Offset(50 + math.cos(a) * 24, 50 + math.sin(a) * 18), 1.1, Paint()..color = tokens.track);
    }
    final angle = status == LoaderStatus.error ? math.pi * 0.35 : ((progress / 100) * math.pi * 2 + t * math.pi * 2);
    final pos = status == LoaderStatus.complete
        ? const Offset(76, 28)
        : (status == LoaderStatus.error ? const Offset(54, 68) : Offset(50 + math.cos(angle) * 24, 50 + math.sin(angle) * 18));

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(status == LoaderStatus.error ? 0.75 : (status == LoaderStatus.complete ? -0.45 : angle + math.pi / 2));
    final plane = Path()
      ..moveTo(12, 0)
      ..lineTo(-10, -8)
      ..lineTo(-5, 0)
      ..lineTo(-10, 8)
      ..close();
    canvas.drawPath(plane, Paint()..color = status == LoaderStatus.error ? tokens.bad : (status == LoaderStatus.complete ? tokens.ok : tokens.accent));
    canvas.drawPath(plane, Paint()..color = tokens.line..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlanePainter old) => old.t != t || old.progress != progress || old.status != status || old.tokens != tokens;
}
