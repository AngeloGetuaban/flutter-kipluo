import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/theme.dart';
import 'loader_base.dart';

/* ==========================================================================
   47. Vinyl Spin Loader (Free)
   ========================================================================== */

class VinylSpinLoader extends StatefulWidget {
  const VinylSpinLoader({super.key, this.value, this.status = LoaderStatus.running, this.size = 104, this.label = 'Loading', this.sound = true});
  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;

  @override
  State<VinylSpinLoader> createState() => _VinylSpinLoaderState();
}

class _VinylSpinLoaderState extends State<VinylSpinLoader> with TickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1650))..addListener(_onSpinTick);
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  int _burst = 0;
  int _lastHalf = -1;

  void _onSpinTick() {
    if (widget.status != LoaderStatus.running || !mounted) return;
    final half = _ctrl.value < 0.5 ? 0 : 1;
    if (_lastHalf == -1) {
      _lastHalf = half;
    } else if (half != _lastHalf) {
      _lastHalf = half;
      KipluoSound.play(KSound.vinyl, at: context, pitch: 0.92 + half * 0.06, volume: 0.34, componentEnabled: widget.sound);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(VinylSpinLoader old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      if (widget.status == LoaderStatus.complete) {
        setState(() => _burst++);
        _triggerPulse();
        KipluoSound.play(KSound.bell, at: context, volume: 0.55, componentEnabled: widget.sound);
      } else if (widget.status == LoaderStatus.error) {
        _triggerPulse();
        KipluoSound.play(KSound.swipe, at: context, pitch: 0.82, volume: 0.55, componentEnabled: widget.sound);
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
          KipluoSound.play(isError ? KSound.bonk : KSound.swipe, at: context, pitch: 1.15, volume: 0.52, componentEnabled: widget.sound);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                KipluoAuraBurst(burstKey: _burst, size: widget.size * 1.15, rays: 12, color: isError ? t.bad : (isComplete ? t.ok : t.accent)),
                AnimatedBuilder(
                  animation: Listenable.merge([_ctrl, _pulse]),
                  builder: (_, _) => CustomPaint(
                    size: Size.square(widget.size),
                    painter: _VinylPainter(
                      cycle: _ctrl.value,
                      scratch: _pulse.isAnimating ? (1.0 - _pulse.value) : 0.0,
                      value: widget.status == LoaderStatus.complete ? 100 : (widget.value ?? 50),
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

class _VinylPainter extends CustomPainter {
  const _VinylPainter({required this.cycle, required this.scratch, required this.value, required this.status, required this.tokens});
  final double cycle, scratch, value;
  final LoaderStatus status;
  final KipluoTokens tokens;

  static const _rays = [-145.0, -115.0, -85.0, -45.0, 20.0, 155.0];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final isComplete = status == LoaderStatus.complete;
    final isError = status == LoaderStatus.error;
    final labelCol = isError ? tokens.bad : (isComplete ? tokens.ok : tokens.accent);
    final stroke = Paint()
      ..color = tokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 89), width: 80, height: 7), Paint()..color = tokens.track.withValues(alpha: 0.78));

    if (scratch > 0.02 || isComplete || isError) {
      final sc = scratch > 0.02 ? 0.82 + (1 - scratch) * 0.35 : 1.0;
      final op = scratch > 0.02 ? (scratch * 1.35).clamp(0.0, 1.0) : 0.88;
      canvas.save();
      canvas.translate(46, 53);
      canvas.scale(sc);
      for (var i = 0; i < _rays.length; i++) {
        final rad = _rays[i] * math.pi / 180;
        final r1 = 39.0 + (i.isEven ? 7.5 : 4.5);
        canvas.drawLine(
          Offset(math.cos(rad) * 39, math.sin(rad) * 39),
          Offset(math.cos(rad) * r1, math.sin(rad) * r1),
          Paint()..color = labelCol.withValues(alpha: op)..strokeWidth = 1.8..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }

    // Turntable deck housing + feet + LED + pitch slider
    final deck = RRect.fromRectAndRadius(const Rect.fromLTWH(8, 16, 84, 70), const Radius.circular(11));
    canvas.drawRRect(deck, Paint()..color = tokens.surface);
    canvas.drawRRect(deck, stroke..strokeWidth = 2.4);
    canvas.drawLine(const Offset(16, 20), const Offset(72, 20), Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 1.6..strokeCap = StrokeCap.round);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(15, 86, 10, 3), const Radius.circular(1.5)), Paint()..color = tokens.line);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(75, 86, 10, 3), const Radius.circular(1.5)), Paint()..color = tokens.line);

    canvas.drawCircle(const Offset(16.5, 77.5), 2.4, Paint()..color = labelCol);
    canvas.drawCircle(const Offset(16.5, 77.5), 2.4, stroke..strokeWidth = 1.2);
    canvas.drawLine(const Offset(84, 62), const Offset(84, 79), Paint()..color = tokens.line.withValues(alpha: 0.45)..strokeWidth = 1.8..strokeCap = StrokeCap.round);
    final knobY = 75 - (value.clamp(0, 100) / 100) * 12;
    final knob = RRect.fromRectAndRadius(Rect.fromLTWH(81, knobY, 6, 3.2), const Radius.circular(1.2));
    canvas.drawRRect(knob, Paint()..color = labelCol);
    canvas.drawRRect(knob, stroke..strokeWidth = 1.2);

    // Platter recess + spinning obsidian LP
    canvas.drawCircle(const Offset(44, 52), 30.5, Paint()..color = tokens.track.withValues(alpha: 0.6));
    canvas.save();
    canvas.translate(44, 52);
    canvas.rotate(cycle * math.pi * 2 - scratch * 0.9);
    canvas.drawCircle(Offset.zero, 28.5, Paint()..color = const Color(0xFF1E1E26));
    canvas.drawCircle(Offset.zero, 28.5, stroke..strokeWidth = 2.2);
    // Rotating sheen wedges + concentric groove rings
    final wedge = Path()..moveTo(0, 0)..arcTo(Rect.fromCircle(center: Offset.zero, radius: 28), -2.4, 0.55, false)..close();
    canvas.drawPath(wedge, Paint()..color = Colors.white.withValues(alpha: 0.14));
    for (final gr in [24.0, 19.5, 15.2]) {
      canvas.drawCircle(Offset.zero, gr, Paint()..color = Colors.white.withValues(alpha: 0.16)..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    canvas.drawCircle(Offset.zero, 11.2, Paint()..color = labelCol);
    canvas.drawCircle(Offset.zero, 11.2, stroke..strokeWidth = 1.8);
    canvas.drawCircle(const Offset(0, -7.8), 1.5, Paint()..color = tokens.line);
    canvas.drawCircle(Offset.zero, 3.0, Paint()..color = tokens.surface);
    canvas.drawCircle(Offset.zero, 3.0, stroke..strokeWidth = 1.5);
    if (isError) {
      canvas.drawPath(Path()..moveTo(-18, -12)..lineTo(-10, -8)..lineTo(-14, -2)..lineTo(-5, 1), Paint()..color = tokens.bad..style = PaintingStyle.stroke..strokeWidth = 1.7);
    }
    canvas.restore();

    // Soundwave release ticks near stylus while playing
    if (status == LoaderStatus.running) {
      final op = 0.4 + 0.45 * math.sin(cycle * math.pi * 4).abs();
      canvas.drawArc(const Rect.fromLTWH(68, 50, 9, 12), -0.6, 1.2, false, Paint()..color = labelCol.withValues(alpha: op)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    }

    // Articulated S-curved tonearm
    final armDeg = isError ? -28.0 : -12.0 + (value.clamp(0, 100) / 100) * 24.0;
    canvas.save();
    canvas.translate(81, 27);
    canvas.rotate(armDeg * math.pi / 180);
    final cw = RRect.fromRectAndRadius(const Rect.fromLTWH(-2.5, -8.5, 5, 6), const Radius.circular(1.6));
    canvas.drawRRect(cw, Paint()..color = tokens.track);
    canvas.drawRRect(cw, stroke..strokeWidth = 1.6);
    canvas.drawCircle(Offset.zero, 5.2, Paint()..color = tokens.surface);
    canvas.drawCircle(Offset.zero, 5.2, stroke..strokeWidth = 2.1);
    canvas.drawCircle(Offset.zero, 1.8, Paint()..color = tokens.line);
    canvas.drawPath(Path()..moveTo(0, 4)..quadraticBezierTo(1, 17, -5, 25)..lineTo(-10, 31), stroke..strokeWidth = 2.6);
    canvas.save();
    canvas.translate(-11, 32);
    canvas.rotate(0.56);
    final cart = RRect.fromRectAndRadius(const Rect.fromLTWH(-2.4, -3.5, 4.8, 8), const Radius.circular(1.4));
    canvas.drawRRect(cart, Paint()..color = labelCol);
    canvas.drawRRect(cart, stroke..strokeWidth = 1.6);
    canvas.restore();
    canvas.restore();

    // Floating musical note (♪)
    if (status == LoaderStatus.running || isComplete) {
      final ny = isComplete ? 16.0 : 48 - cycle * 26;
      final nx = isComplete ? 72.0 : 69 + math.sin(cycle * math.pi * 2) * 4.5;
      final op = isComplete ? 1.0 : math.sin(cycle * math.pi) * 0.95;
      canvas.save();
      canvas.translate(nx, ny);
      canvas.drawCircle(Offset.zero, 2.6, Paint()..color = labelCol.withValues(alpha: op));
      canvas.drawPath(Path()..moveTo(2.2, 0)..lineTo(2.2, -9)..lineTo(7.5, -7.2)..lineTo(7.5, -3.5), Paint()..color = tokens.line.withValues(alpha: op)..style = PaintingStyle.stroke..strokeWidth = 1.6..strokeCap = StrokeCap.round);
      canvas.drawCircle(const Offset(5.6, -3.2), 2.2, Paint()..color = labelCol.withValues(alpha: op));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_VinylPainter old) =>
      old.cycle != cycle || old.scratch != scratch || old.value != value || old.status != status || old.tokens != tokens;
}
