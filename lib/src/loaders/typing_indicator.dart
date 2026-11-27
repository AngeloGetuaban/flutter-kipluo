import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';
import 'loader_base.dart';

export 'loader_base.dart' show LoaderStatus;

/// Textured chat speech bubble with glossy highlight, cast dot shadows, and three springy hopping
/// dots that emit mini pop-lines at their peaks. Tap to bounce & release anime rays; complete pops
/// a radiant check, error shudders red with alert lines.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.value, this.status = LoaderStatus.running, this.size = 96, this.label = 'Loading', this.sound = true});

  /// 0–100, or null for the classic loop.
  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250));
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TypingIndicator old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      if (widget.status == LoaderStatus.complete) {
        KipluoSound.play(KSound.chime, at: context, volume: 0.6, componentEnabled: widget.sound);
        _triggerPulse();
      }
      if (widget.status == LoaderStatus.error) {
        KipluoSound.play(KSound.bonk, at: context, volume: 0.6, componentEnabled: widget.sound);
        _triggerPulse();
      }
    }
    _sync();
  }

  void _triggerPulse() {
    if (kipluoReducedMotion(context)) return;
    _pulse.forward(from: 0);
  }

  void _sync() {
    final run = widget.status == LoaderStatus.running && !kipluoReducedMotion(context);
    if (run && !_loop.isAnimating) _loop.repeat();
    if (!run) _loop.stop();
  }

  @override
  void dispose() {
    _loop.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final status = switch (widget.status) {
      LoaderStatus.complete => '${widget.label} complete',
      LoaderStatus.error => '${widget.label} failed',
      LoaderStatus.running => widget.label,
    };
    return Semantics(
      label: status,
      value: widget.value == null ? null : '${widget.value!.round()}%',
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: () {
          _triggerPulse();
          KipluoSound.play(widget.status == LoaderStatus.error ? KSound.bonk : KSound.pop, at: context, pitch: 1.08, volume: 0.55, componentEnabled: widget.sound);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox.square(
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: Listenable.merge([_loop, _pulse]),
              builder: (context, _) => CustomPaint(
                painter: _BubblePainter(
                  t: _loop.value,
                  pulse: _pulse.isAnimating ? (1.0 - _pulse.value) : 0.0,
                  value: widget.value,
                  status: widget.status,
                  tokens: t,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.t, required this.pulse, required this.value, required this.status, required this.tokens});
  final double t;
  final double pulse;
  final double? value;
  final LoaderStatus status;
  final KipluoTokens tokens;

  static const _rays = [-155.0, -125.0, -90.0, -55.0, -25.0, 18.0, 162.0];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final isComplete = status == LoaderStatus.complete;
    final isError = status == LoaderStatus.error;
    final w = value == null ? 60.0 : 46 + (value!.clamp(0, 100) / 100) * 24;
    final x = 50 - w / 2;

    // Ground shadow
    canvas.drawOval(Rect.fromCenter(center: const Offset(48, 76), width: 44, height: 6), Paint()..color = tokens.track.withValues(alpha: 0.7));

    // Radial anime line-release burst
    if (pulse > 0.02 || isComplete || isError) {
      final rayColor = isError ? tokens.bad : (isComplete ? tokens.ok : tokens.accent);
      final sc = pulse > 0.02 ? 0.8 + (1 - pulse) * 0.36 : 1.0;
      final op = pulse > 0.02 ? (pulse * 1.35).clamp(0.0, 1.0) : 0.88;
      canvas.save();
      canvas.translate(50, 48);
      canvas.scale(sc);
      for (var i = 0; i < _rays.length; i++) {
        final rad = _rays[i] * math.pi / 180;
        final len = i.isEven ? 7.5 : 4.5;
        canvas.drawLine(
          Offset(math.cos(rad) * 35, math.sin(rad) * 22),
          Offset(math.cos(rad) * (35 + len), math.sin(rad) * (22 + len)),
          Paint()
            ..color = rayColor.withValues(alpha: op)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }

    canvas.save();
    final tilt = isError ? -0.07 + math.sin(pulse * math.pi * 4) * 0.1 * pulse : -math.sin(pulse * math.pi * 2) * 0.08 * pulse;
    final sc = 1.0 + math.sin(pulse * math.pi) * 0.08;
    canvas.translate(50, 50);
    canvas.rotate(tilt);
    canvas.scale(sc, 1 / sc);
    canvas.translate(-50, -50);

    final line = Paint()
      ..color = tokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.stroke * 0.85
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final fillCol = isError ? Color.lerp(tokens.surface, tokens.bad, 0.14)! : tokens.surface;
    final bubble = RRect.fromRectAndRadius(Rect.fromLTWH(x, 34, w, 32), const Radius.circular(16));
    final tail = Path()
      ..moveTo(30, 62)
      ..lineTo(23, 73)
      ..lineTo(39, 64);
    canvas.drawPath(tail, Paint()..color = fillCol);
    canvas.drawPath(tail, line);
    canvas.drawRRect(bubble, Paint()..color = fillCol);
    // Inner lower shading band & glossy top arc
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 3, 56, w - 6, 7), const Radius.circular(3.5)), Paint()..color = tokens.track.withValues(alpha: 0.45));
    canvas.drawLine(Offset(x + 11, 39.5), Offset(x + w - 14, 39.5), Paint()..color = Colors.white.withValues(alpha: 0.75)..strokeWidth = 2.2..strokeCap = StrokeCap.round);
    canvas.drawRRect(bubble, line);
    // Seamless interior tail patch
    canvas.drawPath(Path()..moveTo(29.5, 61.5)..lineTo(25.2, 69.5)..lineTo(38, 63)..close(), Paint()..color = fillCol);

    // Subtle determinate progress bar
    if (value != null && status == LoaderStatus.running) {
      final frac = (value!.clamp(0, 100) / 100);
      if (frac > 0.02) {
        canvas.drawLine(
          Offset(x + 11, 62),
          Offset(x + 11 + (w - 22) * frac, 62),
          Paint()..color = tokens.accent.withValues(alpha: 0.45)..strokeWidth = 2..strokeCap = StrokeCap.round,
        );
      }
    }

    switch (status) {
      case LoaderStatus.running:
        for (var i = 0; i < 3; i++) {
          final cx = 37 + i * 13.0;
          final ph = (t - i * 0.22) % 1.0;
          final hopBase = ph < 0.38 ? math.sin((ph / 0.38) * math.pi) : 0.0;
          final hop = (hopBase + pulse * 0.65).clamp(0.0, 1.3);
          final cy = 50 - hop * 7.5;
          // Floor shadow
          canvas.drawOval(Rect.fromCenter(center: Offset(cx, 57.5), width: (3.6 - hop * 1.4) * 2, height: 2.4), Paint()..color = tokens.line.withValues(alpha: 0.3 - hop * 0.14));
          // Mini hop peak release lines
          if (hop > 0.62) {
            final pk = ((hop - 0.62) / 0.38).clamp(0.0, 1.0);
            final tp = Paint()..color = tokens.accent.withValues(alpha: pk * 0.9)..strokeWidth = 1.3..strokeCap = StrokeCap.round;
            final py = cy - 6.5 - pk * 2.5;
            canvas.drawLine(Offset(cx, py), Offset(cx, py - 3.5), tp);
            canvas.drawLine(Offset(cx - 3.2, py + 1.2), Offset(cx - 5, py - 1.2), tp);
            canvas.drawLine(Offset(cx + 3.2, py + 1.2), Offset(cx + 5, py - 1.2), tp);
          }
          // Glossy textured dot
          canvas.drawCircle(Offset(cx, cy), 4.3, Paint()..color = tokens.accent);
          canvas.drawCircle(Offset(cx, cy), 4.3, line..strokeWidth = 1.5);
          canvas.drawCircle(Offset(cx - 1.3, cy - 1.4), 1.2, Paint()..color = Colors.white.withValues(alpha: 0.85));
        }
      case LoaderStatus.complete:
        canvas.drawCircle(const Offset(50, 50), 10.5, Paint()..color = tokens.ok.withValues(alpha: 0.18));
        canvas.drawPath(Path()..moveTo(40.5, 50.5)..lineTo(47.2, 57)..lineTo(60.5, 43.5), line..color = tokens.ok..strokeWidth = tokens.stroke * 1.35);
      case LoaderStatus.error:
        canvas.drawCircle(const Offset(50, 50), 10.5, Paint()..color = tokens.bad.withValues(alpha: 0.18));
        canvas.drawPath(Path()..moveTo(43, 43.5)..lineTo(57, 56.5)..moveTo(57, 43.5)..lineTo(43, 56.5), line..color = tokens.bad..strokeWidth = tokens.stroke * 1.35);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.t != t || old.pulse != pulse || old.value != value || old.status != status || old.tokens != tokens;
}
