import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';

/* ==========================================================================
   Wave 11 — Five Procedural Shader Widgets (zero native asset dependencies)
   1. FlutedGlassShader (Free)
   2. PrismWaveShader (Paid)
   3. MeshSilkShader (Free)
   4. DitherVortexShader (Paid)
   5. AuroraNebulaShader (Paid)
   ========================================================================== */

class _ShaderShell extends StatefulWidget {
  const _ShaderShell({
    required this.title,
    required this.subtitle,
    required this.speed,
    required this.interactive,
    required this.sound,
    required this.tapSound,
    required this.painterBuilder,
    this.child,
  });

  final String title;
  final String subtitle;
  final double speed;
  final bool interactive;
  final bool sound;
  final KSound tapSound;
  final CustomPainter Function(double t, Offset pointer, double pulse, KipluoTokens tokens) painterBuilder;
  final Widget? child;

  @override
  State<_ShaderShell> createState() => _ShaderShellState();
}

class _ShaderShellState extends State<_ShaderShell> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  Offset _pointer = const Offset(0.5, 0.5);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  void _syncLoop() {
    final run = !kipluoReducedMotion(context) && widget.speed > 0;
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
    final tokens = KipluoTheme.tokensOf(context);
    final reduced = kipluoReducedMotion(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 180.0;
        return GestureDetector(
          onTap: widget.interactive
              ? () {
                  if (!reduced) _pulse.forward(from: 0);
                  KipluoSound.play(widget.tapSound, at: context, pitch: 1.15, volume: 0.36, componentEnabled: widget.sound);
                }
              : null,
          onPanUpdate: widget.interactive && !reduced
              ? (d) {
                  setState(() {
                    _pointer = Offset(
                      (d.localPosition.dx / math.max(1, w)).clamp(0.0, 1.0),
                      (d.localPosition.dy / math.max(1, h)).clamp(0.0, 1.0),
                    );
                  });
                }
              : null,
          child: ClipRect(
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_loop, _pulse]),
                    builder: (context, _) => CustomPaint(
                      painter: widget.painterBuilder(
                        reduced ? 1.8 : _loop.value * math.pi * 2 * widget.speed,
                        _pointer,
                        reduced ? 0 : (1 - _pulse.value) * (_pulse.isAnimating ? 1 : 0),
                        tokens,
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: widget.child ??
                            // Busy shader output behind bare white text is unreadable: give the caption a backing.
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.62),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 2),
                                    Text(widget.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                      ),
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

/* 1. FlutedGlassShader (Free) */
class FlutedGlassShader extends StatelessWidget {
  const FlutedGlassShader({super.key, this.speed = 1, this.interactive = true, this.sound = true, this.child});
  final double speed;
  final bool interactive;
  final bool sound;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return _ShaderShell(
      title: 'Fluted Glass',
      subtitle: 'Tap or drag to refract',
      speed: speed,
      interactive: interactive,
      sound: sound,
      tapSound: KSound.whoosh,
      painterBuilder: (t, ptr, pulse, tokens) => _FlutedGlassPainter(t: t, ptr: ptr, pulse: pulse, tokens: tokens),
      child: child,
    );
  }
}

class _FlutedGlassPainter extends CustomPainter {
  const _FlutedGlassPainter({required this.t, required this.ptr, required this.pulse, required this.tokens});
  final double t, pulse;
  final Offset ptr;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final deep = Color.lerp(tokens.line, const Color(0xFF0A1432), 0.55)!;
    final mid = Color.lerp(tokens.accent, const Color(0xFF3B82F6), 0.35)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + ptr.dx * 0.6, -1),
          end: Alignment(1, 1 - ptr.dy * 0.6),
          colors: [deep, mid, Color.lerp(tokens.surface, tokens.accent, 0.4)!],
        ).createShader(rect),
    );
    const ribs = 16;
    final ribW = size.width / ribs;
    for (var i = 0; i < ribs; i++) {
      final phase = math.sin(i * 0.7 + t + ptr.dx * 4) * 0.5 + 0.5;
      final r = Rect.fromLTWH(i * ribW, 0, ribW + 0.8, size.height);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.04 + phase * 0.14 + pulse * 0.12),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.16),
            ],
          ).createShader(r),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlutedGlassPainter old) => true;
}

/* 3. MeshSilkShader (Free) */
class MeshSilkShader extends StatelessWidget {
  const MeshSilkShader({super.key, this.speed = 1, this.interactive = true, this.sound = true, this.child});
  final double speed;
  final bool interactive;
  final bool sound;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return _ShaderShell(
      title: 'Mesh Silk',
      subtitle: 'Live theme-token silk mesh',
      speed: speed,
      interactive: interactive,
      sound: sound,
      tapSound: KSound.drop,
      painterBuilder: (t, ptr, pulse, tokens) => _MeshSilkPainter(t: t, ptr: ptr, pulse: pulse, tokens: tokens),
      child: child,
    );
  }
}

class _MeshSilkPainter extends CustomPainter {
  const _MeshSilkPainter({required this.t, required this.ptr, required this.pulse, required this.tokens});
  final double t, pulse;
  final Offset ptr;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c1 = Color.lerp(tokens.accent, const Color(0xFF4F46E5), 0.42)!;
    final c2 = Color.lerp(tokens.accent, const Color(0xFFEC4899), 0.42)!;
    canvas.drawRect(rect, Paint()..color = Color.lerp(tokens.line, c1, 0.35)!);
    for (var i = 0; i < 3; i++) {
      final cx = size.width * (0.25 + i * 0.25 + math.sin(t + i * 2.1) * 0.16 + (ptr.dx - 0.5) * 0.2);
      final cy = size.height * (0.5 + math.cos(t * 0.8 + i * 1.7) * 0.24 + (ptr.dy - 0.5) * 0.2);
      final r = math.max(size.width, size.height) * (0.52 + pulse * 0.12);
      final col = i == 0 ? c1 : (i == 1 ? c2 : tokens.accent);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [col.withValues(alpha: 0.78), col.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeshSilkPainter old) => true;
}
