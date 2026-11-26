import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Success celebration badge: stroke-drawn circle and check mark, expanding ripple ring, and
/// bouncy badge settle. Tapping replays cleanly from start.
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({
    super.key,
    this.label = 'Payment received',
    this.size = 68,
    this.sound = true,
  });

  final String label;
  final double size;
  final bool sound;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'draw': 0, 'ripple': 0, 'scale': 80},
    config: SpringConfig.bouncy,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play(playAudio: false);
    });
  }

  void _play({bool playAudio = true}) {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.set({'draw': 0, 'ripple': 0, 'scale': 80});
    _s.animateTo({'draw': 100, 'ripple': 100, 'scale': 100});
    if (playAudio) {
      KipluoSound.play(KSound.pop, at: context, volume: 0.55, componentEnabled: widget.sound);
      KipluoSound.play(KSound.chime, at: context, volume: 0.7, componentEnabled: widget.sound);
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Semantics(
      button: true,
      liveRegion: true,
      label: widget.label,
      onTap: () => _play(),
      child: GestureDetector(
        onTap: () => _play(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: widget.size,
              child: AnimatedBuilder(
                animation: _s,
                builder: (context, _) => Transform.scale(
                  scale: (_s['scale'] / 100).clamp(0.75, 1.3),
                  child: CustomPaint(
                    painter: _SuccessPainter(
                      draw: (_s['draw'] / 100).clamp(0.0, 1.0),
                      ripple: (_s['ripple'] / 100).clamp(0.0, 1.0),
                      tokens: t,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  _SuccessPainter({required this.draw, required this.ripple, required this.tokens});
  final double draw;
  final double ripple;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.36;
    if (ripple > 0.02 && ripple < 0.99) {
      canvas.drawCircle(
        c,
        r * (1 + ripple * 0.55),
        Paint()
          ..color = tokens.ok.withValues(alpha: (1 - ripple) * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    canvas.drawCircle(c, r, Paint()..color = tokens.ok);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * draw,
      false,
      Paint()
        ..color = tokens.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.stroke * 0.65
        ..strokeCap = StrokeCap.round,
    );
    if (draw > 0.05) {
      final path = Path()
        ..moveTo(c.dx - r * 0.42, c.dy + r * 0.05)
        ..lineTo(c.dx - r * 0.1, c.dy + r * 0.36)
        ..lineTo(c.dx + r * 0.46, c.dy - r * 0.3);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * draw),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = tokens.stroke * 0.95
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter old) => old.draw != draw || old.ripple != ripple || old.tokens != tokens;
}
