import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/theme.dart';
import 'loader_base.dart';

/* 32. Newton Cradle Loader (Free)
   Five-ball Newton's cradle with true outward pendulum collision physics, crisp anime
   line-release bursts at each impact seam, momentum-transfer ripple across the middle spheres,
   3D metallic sheen, and tap-to-slam interactivity!
*/

class PendulumCradleLoader extends StatefulWidget {
  const PendulumCradleLoader({super.key, this.value, this.status = LoaderStatus.running, this.size = 116, this.label = 'Loading', this.sound = true});
  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;

  @override
  State<PendulumCradleLoader> createState() => _PendulumCradleLoaderState();
}

class _PendulumCradleLoaderState extends State<PendulumCradleLoader> with TickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1450))..addListener(_onCycleTick);
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  int _burst = 0;
  int _lastHalf = -1;

  void _onCycleTick() {
    if (widget.status != LoaderStatus.running || !mounted) return;
    final half = _ctrl.value < 0.5 ? 0 : 1;
    if (_lastHalf == -1) {
      _lastHalf = half;
    } else if (half != _lastHalf) {
      _lastHalf = half;
      KipluoSound.play(KSound.clack, at: context, pitch: half == 0 ? 0.97 : 1.04, volume: 0.45, componentEnabled: widget.sound);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PendulumCradleLoader old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      if (widget.status == LoaderStatus.complete) {
        setState(() => _burst++);
        _triggerPulse();
        KipluoSound.play(KSound.chime, at: context, volume: 0.55, componentEnabled: widget.sound);
      } else if (widget.status == LoaderStatus.error) {
        _triggerPulse();
        KipluoSound.play(KSound.bonk, at: context, volume: 0.55, componentEnabled: widget.sound);
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
    if (run && !_ctrl.isAnimating) _ctrl.repeat();
    if (!run) _ctrl.stop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final isError = widget.status == LoaderStatus.error;
    final isComplete = widget.status == LoaderStatus.complete;
    return Semantics(
      label: widget.label,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: () {
          setState(() => _burst++);
          _triggerPulse();
          KipluoSound.play(isError ? KSound.bonk : KSound.clack, at: context, pitch: 1.12, volume: 0.62, componentEnabled: widget.sound);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: widget.size,
            height: widget.size * 0.74,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                KipluoAuraBurst(burstKey: _burst, size: widget.size * 1.05, rays: 12, color: isError ? t.bad : (isComplete ? t.ok : t.accent)),
                AnimatedBuilder(
                  animation: Listenable.merge([_ctrl, _pulse]),
                  builder: (_, _) => CustomPaint(
                    size: Size(widget.size, widget.size * 0.74),
                    painter: _CradlePainter(
                      cycle: _ctrl.value,
                      boost: _pulse.isAnimating ? (1.0 - _pulse.value) : 0.0,
                      value: widget.value,
                      status: widget.status,
                      tokens: t,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CradlePainter extends CustomPainter {
  const _CradlePainter({required this.cycle, required this.boost, required this.value, required this.status, required this.tokens});
  final double cycle;
  final double boost;
  final double? value;
  final LoaderStatus status;
  final KipluoTokens tokens;

  static const _topY = 14.0;
  static const _rodLen = 44.0;
  static const _ballR = 7.0;
  static const _ballXs = [32.0, 46.0, 60.0, 74.0, 88.0];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120);
    final isComplete = status == LoaderStatus.complete;
    final isError = status == LoaderStatus.error;
    final stroke = Paint()
      ..color = tokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ground shadow & brushed A-frame stand
    canvas.drawOval(Rect.fromCenter(center: const Offset(60, 83.5), width: 96, height: 6.4), Paint()..color = tokens.track.withValues(alpha: 0.75));
    final legPaint = Paint()..color = tokens.line.withValues(alpha: 0.75)..strokeWidth = 2.8..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(21, 15), const Offset(14, 77), legPaint);
    canvas.drawLine(const Offset(99, 15), const Offset(106, 77), legPaint);

    final base = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 75.5, 100, 6), const Radius.circular(3));
    canvas.drawRRect(base, Paint()..color = tokens.surface);
    canvas.drawRRect(base, stroke);
    canvas.drawLine(const Offset(18, 77.8), const Offset(96, 77.8), Paint()..color = Colors.white.withValues(alpha: 0.55)..strokeWidth = 1.2..strokeCap = StrokeCap.round);

    final bar = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 10.5, 92, 6), const Radius.circular(3));
    canvas.drawRRect(bar, Paint()..color = tokens.surface);
    canvas.drawRRect(bar, stroke);
    canvas.drawLine(const Offset(20, 12.6), const Offset(94, 12.6), Paint()..color = Colors.white.withValues(alpha: 0.6)..strokeWidth = 1.2..strokeCap = StrokeCap.round);

    // Phase math: cycle in [0, 1):
    // [0.0, 0.5): RIGHT ball swings outward right (sin >= 0), right after collision at t=0 (left seam hit!)
    // [0.5, 1.0): LEFT ball swings outward left (sin < 0), right after collision at t=0.5 (right seam hit!)
    final phase = cycle * math.pi * 2;
    final s = math.sin(phase);
    final maxRad = (38 + boost * 12) * math.pi / 180;

    var leftOutRad = 0.0;
    var rightOutRad = 0.0;
    if (status == LoaderStatus.running) {
      leftOutRad = s < 0 ? s.abs() * maxRad : 0.0;
      rightOutRad = s > 0 ? s.abs() * maxRad : 0.0;
    } else if (isComplete) {
      final settle = boost * math.sin(boost * math.pi * 2).abs() * 0.25;
      leftOutRad = settle;
      rightOutRad = settle;
    } else if (isError) {
      leftOutRad = 0.26;
      rightOutRad = 0.14;
    }

    // Time since last collision (0 at cycle=0.0 [left seam] and cycle=0.5 [right seam])
    final sinceHit = (cycle % 0.5) * 2.0; // 0..1 within half-cycle
    final impactEnergy = status == LoaderStatus.running ? (1.0 - sinceHit * 3.0).clamp(0.0, 1.0) : boost;
    final leftSeamHit = cycle < 0.5;
    final waveDir = leftSeamHit ? 1.0 : -1.0;
    final waveAge = status == LoaderStatus.running ? (sinceHit * 3.5).clamp(0.0, 1.0) : 1.0;
    final impactColor = isError ? tokens.bad : (isComplete ? tokens.ok : tokens.accent);
    final lit = isComplete ? 5 : (value != null ? ((value! / 100) * 5).round() : 5);

    // Kinetic swing arc trail behind airborne outer sphere
    if (status == LoaderStatus.running) {
      final trailPaint = Paint()..color = impactColor.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;
      if (leftOutRad > 0.22) {
        canvas.drawArc(Rect.fromCircle(center: const Offset(32, _topY), radius: _rodLen + 9), math.pi / 2 + leftOutRad * 0.52, leftOutRad * 0.44, false, trailPaint);
      }
      if (rightOutRad > 0.22) {
        canvas.drawArc(Rect.fromCircle(center: const Offset(88, _topY), radius: _rodLen + 9), math.pi / 2 - rightOutRad * 0.96, rightOutRad * 0.44, false, trailPaint);
      }
    }

    // Draw all 5 spheres with exact outward arcs + middle momentum transfer vibration
    for (var i = 0; i < 5; i++) {
      final px = _ballXs[i];
      var bx = px;
      var by = _topY + _rodLen;

      if (i == 0 && leftOutRad > 0) {
        bx = px - math.sin(leftOutRad) * _rodLen;
        by = _topY + math.cos(leftOutRad) * _rodLen;
      } else if (i == 4 && rightOutRad > 0) {
        bx = px + math.sin(rightOutRad) * _rodLen;
        by = _topY + math.cos(rightOutRad) * _rodLen;
      } else if (i >= 1 && i <= 3 && waveAge < 1.0) {
        final order = waveDir > 0 ? i - 1 : 3 - i;
        final localT = ((waveAge - order * 0.14) / 0.42).clamp(0.0, 1.0);
        final kick = math.sin(localT * math.pi);
        bx = px + waveDir * kick * 1.15;
        by = _topY + _rodLen - kick * 0.55;
      }

      canvas.drawCircle(Offset(px, _topY + 2), 1.4, Paint()..color = tokens.line);
      if (isError && (i == 0 || i == 4)) {
        canvas.drawPath(
          Path()..moveTo(px, _topY + 2)..lineTo((px + bx) / 2 + (i == 0 ? -2.5 : 2.5), (_topY + by) / 2)..lineTo(bx, by - _ballR + 1),
          Paint()..color = tokens.bad..style = PaintingStyle.stroke..strokeWidth = 1.6..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawLine(Offset(px, _topY + 2), Offset(bx, by), Paint()..color = tokens.line..strokeWidth = 1.7..strokeCap = StrokeCap.round);
      }

      final fill = isError ? tokens.bad : (isComplete ? tokens.ok : (i < lit ? tokens.accent : tokens.surface));
      final deep = Color.lerp(fill, tokens.line, 0.28)!;
      canvas.drawCircle(Offset(bx, by), _ballR, Paint()..color = fill);
      // Lower spherical depth shade + bright specular highlight
      canvas.drawArc(Rect.fromCircle(center: Offset(bx, by), radius: _ballR - 1.2), 0.35, math.pi - 0.7, false, Paint()..color = deep.withValues(alpha: 0.45)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(bx, by), _ballR, stroke..strokeWidth = 2.2);
      canvas.drawCircle(Offset(bx - 2.3, by - 2.4), 1.6, Paint()..color = Colors.white.withValues(alpha: 0.78));
    }

    // Crisp anime collision line-release burst right at the impact seam!
    if (impactEnergy > 0.02 && !isError && status == LoaderStatus.running) {
      final ix = leftSeamHit ? 39.0 : 81.0;
      final sc = 0.7 + (1 - impactEnergy) * 0.55;
      final op = (impactEnergy * 1.4).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(ix, 58);
      canvas.scale(sc);
      canvas.drawCircle(Offset.zero, 2.2, Paint()..color = Colors.white.withValues(alpha: op));
      final cp = Paint()..color = impactColor.withValues(alpha: op)..strokeWidth = 2.0..strokeCap = StrokeCap.round;
      final lp = Paint()..color = tokens.line.withValues(alpha: op)..strokeWidth = 1.6..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, -8.5), const Offset(0, -16.5), cp);
      canvas.drawLine(const Offset(-4.5, -7.5), const Offset(-9.5, -13.5), lp);
      canvas.drawLine(const Offset(4.5, -7.5), const Offset(9.5, -13.5), lp);
      canvas.drawLine(const Offset(0, 8.5), const Offset(0, 15.5), cp);
      canvas.drawLine(const Offset(-4.5, 7.5), const Offset(-9.5, 13.0), lp);
      canvas.drawLine(const Offset(4.5, 7.5), const Offset(9.5, 13.0), lp);
      canvas.restore();
    }

    if (isComplete) {
      final op = Paint()..color = tokens.ok..strokeWidth = 1.8..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(39, 45), const Offset(39, 39), op);
      canvas.drawLine(const Offset(35, 46), const Offset(31, 41), op);
      canvas.drawLine(const Offset(81, 45), const Offset(81, 39), op);
      canvas.drawLine(const Offset(85, 46), const Offset(89, 41), op);
    }

    if (isError) {
      final ep = Paint()..color = tokens.bad..strokeWidth = 1.9..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(39, 46), const Offset(35, 39), ep);
      canvas.drawLine(const Offset(42, 45), const Offset(44, 38), ep);
      canvas.drawLine(const Offset(81, 46), const Offset(85, 39), ep);
      canvas.drawLine(const Offset(78, 45), const Offset(76, 38), ep);
    }
  }

  @override
  bool shouldRepaint(_CradlePainter old) =>
      old.cycle != cycle || old.boost != boost || old.value != value || old.status != status || old.tokens != tokens;
}
