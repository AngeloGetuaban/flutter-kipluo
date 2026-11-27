import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/iso3d.dart';
import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';
import 'loader_base.dart';

/* ==========================================================================
   Wave 9 — Zero-dependency 3D Loaders
   1. IsometricCubeGridLoader (Free)
   2. BrickBar3DLoader (Free, optional drag scrubbing)
   3. KineticSpheres3DLoader (Free, volumetric shaded spheres)
   4. WireframePrismLoader (Paid, outer wireframe + growing inner prism)
   ========================================================================== */

class IsometricCubeGridLoader extends StatefulWidget {
  const IsometricCubeGridLoader({
    super.key,
    this.value,
    this.status = LoaderStatus.running,
    this.size = 104,
    this.label = 'Loading',
    this.sound = true,
    this.interactive = true,
  });

  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;
  final bool interactive;

  @override
  State<IsometricCubeGridLoader> createState() => _IsometricCubeGridLoaderState();
}

class _IsometricCubeGridLoaderState extends State<IsometricCubeGridLoader> with TickerProviderStateMixin {
  static const _baseRx = 0.62;
  static const _baseRy = -0.78;
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  late final AnimationController _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final KSprings _springs = KSprings(
    vsync: this,
    initial: {'p': widget.value?.clamp(0.0, 100.0) ?? 0.0, 'rx': _baseRx, 'ry': _baseRy},
    config: SpringConfig.snappy,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(IsometricCubeGridLoader old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      if (widget.status == LoaderStatus.complete) {
        KipluoSound.play(KSound.chime, at: context, volume: 0.62, componentEnabled: widget.sound);
      } else if (widget.status == LoaderStatus.error) {
        KipluoSound.play(KSound.bonk, at: context, volume: 0.62, componentEnabled: widget.sound);
      }
      if (!kipluoReducedMotion(context)) _ripple.forward(from: 0);
    }
    if (widget.value != null && widget.value != old.value) {
      _springs.reducedMotion = kipluoReducedMotion(context);
      _springs.animateTo({'p': widget.value!.clamp(0.0, 100.0)});
    }
    _syncLoop();
  }

  void _syncLoop() {
    final run = widget.status == LoaderStatus.running && !kipluoReducedMotion(context);
    if (run && !_loop.isAnimating) _loop.repeat();
    if (!run) _loop.stop();
  }

  @override
  void dispose() {
    _loop.dispose();
    _ripple.dispose();
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final showShadow = KipluoTheme.shadowOf(context).isNotEmpty;
    final reduced = kipluoReducedMotion(context);
    final det = widget.value != null;
    final semLabel = widget.status == LoaderStatus.error
        ? '${widget.label} failed'
        : widget.status == LoaderStatus.complete
            ? '${widget.label} complete'
            : widget.label;

    return Semantics(
      label: semLabel,
      value: det ? '${widget.value!.clamp(0, 100).round()}%' : null,
      child: GestureDetector(
        onTap: widget.interactive
            ? () {
                if (!reduced) _ripple.forward(from: 0);
                KipluoSound.play(
                  widget.status == LoaderStatus.error ? KSound.bonk : (widget.status == LoaderStatus.complete ? KSound.sparkle : KSound.pop),
                  at: context,
                  volume: 0.5,
                  componentEnabled: widget.sound,
                );
              }
            : null,
        onPanUpdate: widget.interactive && !reduced
            ? (d) {
                final rx = (_springs['rx'] + d.delta.dy * 0.012).clamp(_baseRx - 0.52, _baseRx + 0.52);
                final ry = (_springs['ry'] + d.delta.dx * 0.014).clamp(_baseRy - 0.52, _baseRy + 0.52);
                _springs.set({'rx': rx, 'ry': ry});
              }
            : null,
        onPanEnd: widget.interactive && !reduced
            ? (_) {
                _springs.animateTo({'rx': _baseRx, 'ry': _baseRy});
                KipluoSound.play(KSound.whoosh, at: context, pitch: 1.25, volume: 0.28, componentEnabled: widget.sound);
              }
            : null,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_loop, _ripple, _springs]),
            builder: (context, _) => CustomPaint(
              painter: _IsoCubeGridPainter(
                t: reduced ? 0 : _loop.value * math.pi * 2,
                pct: widget.status == LoaderStatus.complete ? 100 : (det ? _springs['p'] : 0),
                determinate: det,
                ripple: reduced ? 0 : (1 - _ripple.value) * (_ripple.isAnimating ? 1 : 0),
                rx: reduced ? _baseRx : _springs['rx'],
                ry: reduced ? _baseRy : _springs['ry'],
                status: widget.status,
                tokens: tokens,
                showShadow: showShadow,
                reduced: reduced,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IsoCubeGridPainter extends CustomPainter {
  const _IsoCubeGridPainter({
    required this.t,
    required this.pct,
    required this.determinate,
    required this.ripple,
    required this.rx,
    required this.ry,
    required this.status,
    required this.tokens,
    required this.showShadow,
    required this.reduced,
  });

  final double t, pct, ripple, rx, ry;
  final bool determinate, showShadow, reduced;
  final LoaderStatus status;
  final KipluoTokens tokens;

  static const _grid = <(double, double)>[
    (-1, -1), (0, -1), (1, -1),
    (-1, 0),  (0, 0),  (1, 0),
    (-1, 1),  (0, 1),  (1, 1),
  ];
  static const _fillOrder = [6, 3, 7, 0, 4, 8, 1, 5, 2];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final isComplete = status == LoaderStatus.complete;
    final isError = status == LoaderStatus.error;

    if (showShadow) {
      final sc = 1 - (isComplete ? 0.12 : 0.0) - ripple * 0.08;
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 83), width: 58 * sc, height: 17 * sc),
        Paint()..color = tokens.track.withValues(alpha: 0.52),
      );
    }

    final gap = isComplete ? 1.02 : (isError ? 1.56 : 1.24);
    final filledCount = (pct / 100) * 9;
    final drawList = <({KProjectedFace face, Color fill})>[];

    for (var i = 0; i < 9; i++) {
      final (gx, gz) = _grid[i];
      final orderIdx = _fillOrder.indexOf(i);
      final dist = math.sqrt(gx * gx + gz * gz);
      final wave = reduced ? 0.0 : math.sin(t * 1.5 - dist * 1.15);
      final rJump = ripple > 0 ? math.sin((ripple - dist * 0.18).clamp(0.0, 1.0) * math.pi) * 0.55 : 0.0;

      final activeAmt = isComplete || isError
          ? 1.0
          : (determinate ? (filledCount - orderIdx).clamp(0.0, 1.0) : 0.45 + 0.55 * (0.5 + 0.5 * wave));

      final h = determinate && status == LoaderStatus.running ? 0.55 + activeAmt * 0.62 : 0.92;
      final cy = isError
          ? -0.35 - (i.isEven ? 0.12 : 0.0)
          : isComplete
              ? 0.32
              : (determinate ? activeAmt * 0.25 + wave * 0.14 * activeAmt : wave * 0.48) + rJump;

      final baseColor = isError
          ? tokens.bad
          : isComplete
              ? tokens.ok
              : determinate
                  ? (activeAmt > 0.35 ? tokens.accent : tokens.track)
                  : (i == 4 || wave > 0.1 ? tokens.accent : tokens.surface);

      final errTilt = isError ? (i.isEven ? 0.28 : -0.28) : 0.0;
      final faces = kProjectBoxFaces(
        KVec3(gx * gap, cy, gz * gap),
        KVec3(0.94, h, 0.94),
        rx,
        ry,
        cx: 50,
        cy: 52,
        scale: 12.2,
        perspective: 28,
        localRx: errTilt,
        localRz: errTilt * 0.7,
      );
      for (final f in faces) {
        drawList.add((face: f, fill: kShadeColor(baseColor, tokens.line, f.light)));
      }
    }

    drawList.sort((a, b) => a.face.depth.compareTo(b.face.depth));
    final strokePaint = Paint()
      ..color = tokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.stroke * 0.72
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (final item in drawList) {
      final path = item.face.toPath();
      canvas.drawPath(path, Paint()..color = item.fill);
      canvas.drawPath(path, strokePaint);
    }

    if (isComplete) {
      final sp = Paint()
        ..color = tokens.ok
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(24, 26), const Offset(18, 20), sp);
      canvas.drawLine(const Offset(76, 26), const Offset(82, 20), sp);
      canvas.drawLine(const Offset(50, 17), const Offset(50, 10), sp);
    }
  }

  @override
  bool shouldRepaint(covariant _IsoCubeGridPainter old) => true;
}

/* ==========================================================================
   2. BrickBar3DLoader (Free)
   ========================================================================== */

class BrickBar3DLoader extends StatefulWidget {
  const BrickBar3DLoader({
    super.key,
    this.value,
    this.status = LoaderStatus.running,
    this.size = 112,
    this.label = 'Loading',
    this.sound = true,
    this.segments = 10,
    this.onValueChange,
    this.interactive = true,
  });

  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;
  final int segments;
  final ValueChanged<double>? onValueChange;
  final bool interactive;

  @override
  State<BrickBar3DLoader> createState() => _BrickBar3DLoaderState();
}

class _BrickBar3DLoaderState extends State<BrickBar3DLoader> with TickerProviderStateMixin {
  static const _baseRx = 0.54;
  static const _baseRy = -0.44;
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late final KSprings _springs = KSprings(
    vsync: this,
    initial: {'p': widget.value?.clamp(0.0, 100.0) ?? 0.0, 'rx': _baseRx, 'ry': _baseRy},
    config: SpringConfig.snappy,
  );
  int _lastBrickSound = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(BrickBar3DLoader old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      if (widget.status == LoaderStatus.complete) {
        KipluoSound.play(KSound.chime, at: context, volume: 0.62, componentEnabled: widget.sound);
      } else if (widget.status == LoaderStatus.error) {
        KipluoSound.play(KSound.bonk, at: context, volume: 0.62, componentEnabled: widget.sound);
      }
    }
    if (widget.value != null && widget.value != old.value) {
      _springs.reducedMotion = kipluoReducedMotion(context);
      _springs.animateTo({'p': widget.value!.clamp(0.0, 100.0)});
    }
    _syncLoop();
  }

  void _syncLoop() {
    final run = widget.status == LoaderStatus.running && !kipluoReducedMotion(context);
    if (run && !_loop.isAnimating) _loop.repeat();
    if (!run) _loop.stop();
  }

  void _scrubAt(double localX) {
    final cb = widget.onValueChange;
    if (cb == null) return;
    final count = widget.segments.clamp(6, 16);
    final frac = ((localX - widget.size * 0.1) / (widget.size * 0.8)).clamp(0.0, 1.0);
    final nextVal = (frac * 100).roundToDouble();
    final brick = (frac * count).floor();
    if (brick != _lastBrickSound) {
      _lastBrickSound = brick;
      KipluoSound.play(KSound.tick, at: context, pitch: 0.85 + frac * 0.5, volume: 0.4, componentEnabled: widget.sound);
    }
    cb(nextVal);
  }

  @override
  void dispose() {
    _loop.dispose();
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final showShadow = KipluoTheme.shadowOf(context).isNotEmpty;
    final reduced = kipluoReducedMotion(context);
    final det = widget.value != null;
    final scrubbable = widget.interactive && widget.onValueChange != null;
    final count = widget.segments.clamp(6, 16);

    return Semantics(
      label: widget.status == LoaderStatus.error
          ? '${widget.label} failed'
          : widget.status == LoaderStatus.complete
              ? '${widget.label} complete'
              : widget.label,
      slider: scrubbable,
      value: det ? '${widget.value!.clamp(0, 100).round()}%' : null,
      child: GestureDetector(
        onTapDown: scrubbable ? (d) => _scrubAt(d.localPosition.dx) : null,
        onHorizontalDragUpdate: scrubbable ? (d) => _scrubAt(d.localPosition.dx) : null,
        onPanUpdate: widget.interactive && !scrubbable && !reduced
            ? (d) {
                final rx = (_springs['rx'] + d.delta.dy * 0.01).clamp(_baseRx - 0.42, _baseRx + 0.42);
                final ry = (_springs['ry'] + d.delta.dx * 0.012).clamp(_baseRy - 0.42, _baseRy + 0.42);
                _springs.set({'rx': rx, 'ry': ry});
              }
            : null,
        onPanEnd: widget.interactive && !scrubbable && !reduced
            ? (_) => _springs.animateTo({'rx': _baseRx, 'ry': _baseRy})
            : null,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_loop, _springs]),
            builder: (context, _) => CustomPaint(
              painter: _BrickBar3DPainter(
                t: reduced ? 0 : _loop.value,
                pct: widget.status == LoaderStatus.complete ? 100 : (det ? _springs['p'] : 0),
                determinate: det,
                count: count,
                rx: reduced ? _baseRx : _springs['rx'],
                ry: reduced ? _baseRy : _springs['ry'],
                status: widget.status,
                tokens: tokens,
                showShadow: showShadow,
                reduced: reduced,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrickBar3DPainter extends CustomPainter {
  const _BrickBar3DPainter({
    required this.t,
    required this.pct,
    required this.determinate,
    required this.count,
    required this.rx,
    required this.ry,
    required this.status,
    required this.tokens,
    required this.showShadow,
    required this.reduced,
  });

  final double t, pct, rx, ry;
  final bool determinate, showShadow, reduced;
  final int count;
  final LoaderStatus status;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final isComplete = status == LoaderStatus.complete;
    final isError = status == LoaderStatus.error;

    const totalW = 6.6;
    final step = totalW / count;
    final brickW = step * 0.78;
    const brickD = 1.05;
    final filledBricks = (pct / 100) * count;

    if (showShadow) {
      final floorFaces = kProjectBoxFaces(
        const KVec3(0.15, -0.62, 0.12),
        const KVec3(totalW + 0.55, 0.02, brickD + 0.55),
        rx,
        ry,
        cx: 50,
        cy: 55,
        scale: 11.4,
        perspective: 30,
      );
      if (floorFaces.isNotEmpty) {
        canvas.drawPath(floorFaces.first.toPath(), Paint()..color = tokens.track.withValues(alpha: 0.48));
      }
    }

    final drawList = <({KProjectedFace face, Color fill})>[];
    final railFaces = kProjectBoxFaces(
      const KVec3(0, -0.32, 0),
      const KVec3(totalW + 0.45, 0.34, brickD + 0.42),
      rx,
      ry,
      cx: 50,
      cy: 55,
      scale: 11.4,
      perspective: 30,
    );
    for (final f in railFaces) {
      drawList.add((face: f, fill: kShadeColor(tokens.surface, tokens.line, f.light)));
    }

    for (var i = 0; i < count; i++) {
      final bx = -totalW / 2 + step * (i + 0.5);
      double h;
      bool filled;
      if (isComplete) {
        h = 1.48;
        filled = true;
      } else if (isError) {
        h = 0.24 + (i.isEven ? 0.12 : 0.0);
        filled = true;
      } else if (determinate) {
        final f = (filledBricks - i).clamp(0.0, 1.0);
        filled = f > 0.25;
        h = 0.26 + f * 1.18;
      } else {
        final wavePos = t * (count + 3) - 1.5;
        final bump = (1 - (i - wavePos).abs() / 2.2).clamp(0.0, 1.0);
        filled = bump > 0.28;
        h = 0.3 + bump * bump * 1.25;
      }

      final baseColor = isError ? tokens.bad : (isComplete ? tokens.ok : (filled ? tokens.accent : tokens.track));
      final faces = kProjectBoxFaces(
        KVec3(bx, -0.15 + h * 0.5, 0),
        KVec3(brickW, h, brickD),
        rx,
        ry,
        cx: 50,
        cy: 55,
        scale: 11.4,
        perspective: 30,
      );
      for (final f in faces) {
        drawList.add((face: f, fill: kShadeColor(baseColor, tokens.line, f.light)));
      }
    }

    drawList.sort((a, b) => a.face.depth.compareTo(b.face.depth));
    final strokePaint = Paint()
      ..color = tokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.stroke * 0.65
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (final item in drawList) {
      final path = item.face.toPath();
      canvas.drawPath(path, Paint()..color = item.fill);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrickBar3DPainter old) => true;
}

/* ==========================================================================
   3. KineticSpheres3DLoader (Free)
   ========================================================================== */

class KineticSpheres3DLoader extends StatefulWidget {
  const KineticSpheres3DLoader({
    super.key,
    this.value,
    this.status = LoaderStatus.running,
    this.size = 104,
    this.label = 'Loading',
    this.sound = true,
    this.interactive = true,
  });

  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;
  final bool interactive;

  @override
  State<KineticSpheres3DLoader> createState() => _KineticSpheres3DLoaderState();
}

class _KineticSpheres3DLoaderState extends State<KineticSpheres3DLoader> with TickerProviderStateMixin {
  static const _baseRx = 0.42;
  static const _baseRy = -0.35;
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  late final KSprings _springs = KSprings(
    vsync: this,
    initial: {'p': widget.value?.clamp(0.0, 100.0) ?? 0.0, 'rx': _baseRx, 'ry': _baseRy, 'fling': 0.0},
    config: SpringConfig.snappy,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(KineticSpheres3DLoader old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      if (widget.status == LoaderStatus.complete) {
        KipluoSound.play(KSound.chime, at: context, volume: 0.62, componentEnabled: widget.sound);
      } else if (widget.status == LoaderStatus.error) {
        KipluoSound.play(KSound.bonk, at: context, volume: 0.62, componentEnabled: widget.sound);
      }
    }
    if (widget.value != null && widget.value != old.value) {
      _springs.reducedMotion = kipluoReducedMotion(context);
      _springs.animateTo({'p': widget.value!.clamp(0.0, 100.0)});
    }
    _syncLoop();
  }

  void _syncLoop() {
    final run = widget.status == LoaderStatus.running && !kipluoReducedMotion(context);
    if (run && !_loop.isAnimating) _loop.repeat();
    if (!run) _loop.stop();
  }

  @override
  void dispose() {
    _loop.dispose();
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final showShadow = KipluoTheme.shadowOf(context).isNotEmpty;
    final reduced = kipluoReducedMotion(context);
    final det = widget.value != null;

    return Semantics(
      label: widget.status == LoaderStatus.error
          ? '${widget.label} failed'
          : widget.status == LoaderStatus.complete
              ? '${widget.label} complete'
              : widget.label,
      value: det ? '${widget.value!.clamp(0, 100).round()}%' : null,
      child: GestureDetector(
        onTap: widget.interactive
            ? () {
                if (!reduced) _springs.animateTo({'fling': 0}, velocity: {'fling': 6.0});
                KipluoSound.play(KSound.boop, at: context, pitch: 1.15, volume: 0.5, componentEnabled: widget.sound);
              }
            : null,
        onPanUpdate: widget.interactive && !reduced
            ? (d) {
                final rx = (_springs['rx'] + d.delta.dy * 0.012).clamp(_baseRx - 0.65, _baseRx + 0.65);
                final ry = _springs['ry'] + d.delta.dx * 0.014;
                _springs.set({'rx': rx, 'ry': ry});
              }
            : null,
        onPanEnd: widget.interactive && !reduced
            ? (_) => _springs.animateTo({'rx': _baseRx})
            : null,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_loop, _springs]),
            builder: (context, _) => CustomPaint(
              painter: _KineticSpheres3DPainter(
                t: reduced ? 0 : _loop.value * math.pi * 2,
                pct: widget.status == LoaderStatus.complete ? 100 : (det ? _springs['p'] : 0),
                determinate: det,
                rx: reduced ? _baseRx : _springs['rx'],
                ry: reduced ? _baseRy : _springs['ry'],
                fling: reduced ? 0 : _springs['fling'],
                status: widget.status,
                tokens: tokens,
                showShadow: showShadow,
                reduced: reduced,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KineticSpheres3DPainter extends CustomPainter {
  const _KineticSpheres3DPainter({
    required this.t,
    required this.pct,
    required this.determinate,
    required this.rx,
    required this.ry,
    required this.fling,
    required this.status,
    required this.tokens,
    required this.showShadow,
    required this.reduced,
  });

  final double t, pct, rx, ry, fling;
  final bool determinate, showShadow, reduced;
  final LoaderStatus status;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final isComplete = status == LoaderStatus.complete;
    final isError = status == LoaderStatus.error;
    const floorY = -1.25;

    final ringR = isComplete ? 1.43 : 1.85;
    const ringSteps = 32;
    final ringPts = List<Offset>.generate(ringSteps + 1, (i) {
      final a = (i / ringSteps) * math.pi * 2;
      final rp = kProjectPoint(kRotate3D(KVec3(math.cos(a) * ringR, floorY, math.sin(a) * ringR), rx, ry), cx: 50, cy: 52, scale: 14.2, perspective: 18);
      return rp.offset;
    });

    final ringPath = Path()..addPolygon(ringPts, false);
    canvas.drawPath(
      ringPath,
      Paint()
        ..color = tokens.track.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, tokens.stroke * 0.7),
    );

    if (determinate || isComplete) {
      final arcCount = ((pct / 100) * ringSteps).round().clamp(1, ringSteps);
      final arcPath = Path()..moveTo(ringPts[0].dx, ringPts[0].dy);
      for (var i = 1; i <= arcCount; i++) {
        arcPath.lineTo(ringPts[i].dx, ringPts[i].dy);
      }
      canvas.drawPath(
        arcPath,
        Paint()
          ..color = isError ? tokens.bad : (isComplete ? tokens.ok : tokens.accent)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.8, tokens.stroke * 0.9),
      );
    }

    final orbs = <({double sx, double sy, double sz, double r, double gx, double gy, double h, Color color})>[];
    final energized = (pct / 100) * 4;
    for (var i = 0; i < 4; i++) {
      final phase = (i / 4) * math.pi * 2;
      final angle = phase + (reduced ? 0 : t);
      final radius = isError ? 1.75 : (isComplete ? 1.13 : 1.58);
      final bounce = reduced ? 0.35 : math.sin(t * 1.5 + i * 0.78).abs();
      final active = isComplete || isError || !determinate || energized > i + 0.15;
      final yWorld = isError
          ? floorY + 0.36
          : isComplete
              ? 0.28
              : floorY + 0.42 + (active ? bounce * 1.42 : 0.08) + fling * 0.45;

      final wx = math.cos(angle) * radius;
      final wz = math.sin(angle) * radius;
      final rot = kRotate3D(KVec3(wx, yWorld, wz), rx, ry);
      final p2 = kProjectPoint(rot, cx: 50, cy: 52, scale: 14.2, perspective: 18);
      final perspK = 18 / math.max(2.0, 18 - rot.z);
      final g2 = kProjectPoint(kRotate3D(KVec3(wx, floorY, wz), rx, ry), cx: 50, cy: 52, scale: 14.2, perspective: 18);
      final color = isError ? tokens.bad : (isComplete ? tokens.ok : (active ? tokens.accent : tokens.surface));

      orbs.add((sx: p2.x, sy: p2.y, sz: rot.z, r: 8.6 * perspK, gx: g2.x, gy: g2.y, h: math.max(0.0, yWorld - floorY), color: color));
    }

    if (showShadow) {
      for (final o in orbs) {
        final shrink = (1 - o.h * 0.24).clamp(0.38, 1.0);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(o.gx, o.gy), width: o.r * 1.84 * shrink, height: o.r * 0.64 * shrink),
          Paint()..color = tokens.line.withValues(alpha: 0.22 * shrink),
        );
      }
    }

    orbs.sort((a, b) => a.sz.compareTo(b.sz));
    final strokePaint = Paint()
      ..color = tokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, tokens.stroke * 0.72);

    for (final o in orbs) {
      final center = Offset(o.sx, o.sy);
      final rect = Rect.fromCircle(center: center, radius: o.r);
      final grad = RadialGradient(
        center: const Alignment(-0.32, -0.34),
        radius: 1.05,
        colors: [Colors.white.withValues(alpha: 0.92), o.color, o.color, tokens.line],
        stops: const [0.0, 0.26, 0.84, 1.0],
      );
      canvas.drawCircle(center, o.r, Paint()..shader = grad.createShader(rect));
      canvas.drawCircle(center, o.r, strokePaint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(o.sx - o.r * 0.32, o.sy - o.r * 0.34), width: o.r * 0.44, height: o.r * 0.28),
        Paint()..color = Colors.white.withValues(alpha: 0.78),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KineticSpheres3DPainter old) => true;
}
