import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* ==========================================================================
   Wave 11 — Five Lightweight Interactive Backgrounds
   1. AuroraBeamsBackground (Free)
   2. SpotlightGridBackground (Free)
   3. RadialHorizonBackground (Paid)
   4. KineticDotField (Paid)
   5. PaperGrainWash (Paid)
   ========================================================================== */

/* 1. AuroraBeamsBackground (Free) */
class AuroraBeamsBackground extends StatefulWidget {
  const AuroraBeamsBackground({super.key, this.interactive = true, this.sound = true, this.child});
  final bool interactive;
  final bool sound;
  final Widget? child;

  @override
  State<AuroraBeamsBackground> createState() => _AuroraBeamsBackgroundState();
}

class _AuroraBeamsBackgroundState extends State<AuroraBeamsBackground> with TickerProviderStateMixin {
  late final KSprings _springs = KSprings(vsync: this, initial: {'px': 0.0, 'py': 0.0, 'pulse': 0.0}, config: SpringConfig.gentle);

  @override
  void dispose() {
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 280.0;
        final h = c.maxHeight.isFinite ? c.maxHeight : 180.0;
        return GestureDetector(
          onTap: widget.interactive
              ? () {
                  _springs.reducedMotion = kipluoReducedMotion(context);
                  _springs.animateTo({'pulse': 0}, velocity: {'pulse': 5.0});
                  KipluoSound.play(KSound.whoosh, at: context, pitch: 1.3, volume: 0.3, componentEnabled: widget.sound);
                }
              : null,
          onPanUpdate: widget.interactive
              ? (d) {
                  _springs.reducedMotion = kipluoReducedMotion(context);
                  _springs.animateTo({'px': (d.localPosition.dx / math.max(1, w)) - 0.5, 'py': (d.localPosition.dy / math.max(1, h)) - 0.5});
                }
              : null,
          onPanEnd: widget.interactive ? (_) => _springs.animateTo({'px': 0, 'py': 0}) : null,
          child: ClipRect(
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _springs,
                    builder: (context, _) => CustomPaint(
                      painter: _AuroraBeamsPainter(px: _springs['px'], py: _springs['py'], pulse: _springs['pulse'], tokens: tokens),
                    ),
                  ),
                  Center(
                    child: widget.child ??
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Aurora Beams', style: TextStyle(color: tokens.line, fontSize: 16, fontWeight: FontWeight.w900)),
                            Text('Lightweight beams · zero WebGL', style: TextStyle(color: tokens.line.withValues(alpha: 0.72), fontSize: 11)),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuroraBeamsPainter extends CustomPainter {
  const _AuroraBeamsPainter({required this.px, required this.py, required this.pulse, required this.tokens});
  final double px, py, pulse;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surface);
    canvas.save();
    canvas.translate(size.width * 0.5 + px * 24, size.height * 0.5 + py * 16);
    canvas.rotate(-0.3);
    for (var i = -2; i <= 2; i++) {
      final r = Rect.fromCenter(center: Offset(i * 44.0, 0), width: 32 + pulse * 10, height: size.height * 2.2);
      canvas.drawRect(
        r,
        Paint()
          ..color = (i.isEven ? tokens.accent : tokens.line).withValues(alpha: i.isEven ? 0.24 : 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AuroraBeamsPainter old) => true;
}

/* 2. SpotlightGridBackground (Free) */
class SpotlightGridBackground extends StatefulWidget {
  const SpotlightGridBackground({super.key, this.cellSize = 28, this.interactive = true, this.sound = true, this.child});
  final double cellSize;
  final bool interactive;
  final bool sound;
  final Widget? child;

  @override
  State<SpotlightGridBackground> createState() => _SpotlightGridBackgroundState();
}

class _SpotlightGridBackgroundState extends State<SpotlightGridBackground> with TickerProviderStateMixin {
  late final KSprings _springs = KSprings(vsync: this, initial: {'x': 120.0, 'y': 90.0}, config: SpringConfig.snappy);

  /// Idle drift: with no touch for a moment, the spotlight wanders slowly so the grid never reads as empty.
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 60))
    ..addListener(_drift);
  Size _size = const Size(280, 180);
  DateTime _lastTouch = DateTime.fromMillisecondsSinceEpoch(0);

  void _drift() {
    if (DateTime.now().difference(_lastTouch).inMilliseconds < 2500) return;
    final t = _idle.value * 60;
    _springs.animateTo({
      'x': _size.width * (0.5 + 0.34 * math.sin(t * 0.42)),
      'y': _size.height * (0.5 + 0.3 * math.sin(t * 0.67 + 1.2)),
    });
  }

  void _touch(Offset p) {
    _lastTouch = DateTime.now();
    _springs.reducedMotion = kipluoReducedMotion(context);
    _springs.animateTo({'x': p.dx, 'y': p.dy});
  }

  @override
  void dispose() {
    _idle.dispose();
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final reduced = kipluoReducedMotion(context);
    if (reduced && _idle.isAnimating) {
      _idle.stop();
    } else if (!reduced && !_idle.isAnimating) {
      _idle.repeat();
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 280.0;
        final h = c.maxHeight.isFinite ? c.maxHeight : 180.0;
        _size = Size(w, h);
        return GestureDetector(
          onTapDown: widget.interactive
              ? (d) {
                  _touch(d.localPosition);
                  KipluoSound.play(KSound.tick, at: context, pitch: 1.15, volume: 0.35, componentEnabled: widget.sound);
                }
              : null,
          onPanUpdate: widget.interactive ? (d) => _touch(d.localPosition) : null,
          child: ClipRect(
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _springs,
                    builder: (context, _) => CustomPaint(
                      painter: _SpotlightGridPainter(spot: Offset(_springs['x'], _springs['y']), cell: widget.cellSize, tokens: tokens),
                    ),
                  ),
                  Center(
                    child: widget.child ??
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Spotlight Grid', style: TextStyle(color: tokens.line, fontSize: 16, fontWeight: FontWeight.w900)),
                            Text('Spring-tracked radial grid mask', style: TextStyle(color: tokens.line.withValues(alpha: 0.72), fontSize: 11)),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpotlightGridPainter extends CustomPainter {
  const _SpotlightGridPainter({required this.spot, required this.cell, required this.tokens});
  final Offset spot;
  final double cell;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surface);
    final basePaint = Paint()..color = tokens.line.withValues(alpha: 0.12)..strokeWidth = 1;
    final step = cell.clamp(14.0, 64.0);
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), basePaint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), basePaint);
    }
    canvas.drawCircle(
      spot,
      110,
      Paint()
        ..shader = RadialGradient(
          colors: [tokens.accent.withValues(alpha: 0.32), tokens.accent.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: spot, radius: 110)),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightGridPainter old) => old.spot != spot || old.tokens != tokens;
}
