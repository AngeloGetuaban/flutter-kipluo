import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Paints a crisp anime line-release aura + expanding halo ring for progress `t` in [0, 1].
void paintReleaseAura(
  Canvas canvas,
  Offset center,
  double maxRadius,
  double t, {
  required Color accent,
  required Color line,
  int rays = 8,
  bool ring = true,
  double? fanAngle,
  double fanSpread = 0,
}) {
  if (t <= 0 || t >= 1) return;
  final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
  final fade = (1.0 - eased).clamp(0.0, 1.0);

  // Expanding spring halo ring
  if (ring) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = accent.withValues(alpha: fade * 0.8)
      ..strokeWidth = (2.2 * (1.0 - eased * 0.72)).clamp(0.5, 2.2);
    canvas.drawCircle(center, maxRadius * (0.34 + eased * 0.46), ringPaint);
  }
  final fan = fanAngle != null;

  // Radiating anime burst lines
  for (var i = 0; i < rays; i++) {
    final angle = fan
        ? fanAngle - fanSpread / 2 + (rays > 1 ? i * fanSpread / (rays - 1) : fanSpread / 2)
        : (i * math.pi * 2) / rays;
    final inner = maxRadius * (fan ? (0.14 + eased * 0.34) : (0.36 + eased * 0.32));
    final outer = maxRadius *
        (i.isEven
            ? (fan ? 0.38 + eased * 0.24 : 0.56 + eased * 0.28)
            : (fan ? 0.32 + eased * 0.20 : 0.48 + eased * 0.22));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = i.isEven ? (fan ? 2.3 : 2.0) : (fan ? 1.6 : 1.35)
      ..color = (i.isEven ? accent : line).withValues(alpha: fade * 0.88);
    canvas.drawLine(
      center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
      center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
      p,
    );
  }
}

/// Overlay widget that fires a tactile anime line-release aura whenever [burstKey] increments.
class KipluoAuraBurst extends StatefulWidget {
  const KipluoAuraBurst({
    super.key,
    required this.burstKey,
    this.size = 92,
    this.rays = 8,
    this.color,
    this.ring = true,
    this.fanAngle,
    this.fanSpread = 0,
  });

  final int burstKey;
  final double size;
  final int rays;
  final Color? color;

  /// Draw the expanding halo ring. False gives a lines-only release.
  final bool ring;

  /// Spread the rays over an arc centred on [fanAngle] (radians, 0 = right) instead of a full circle.
  final double? fanAngle;
  final double fanSpread;

  @override
  State<KipluoAuraBurst> createState() => _KipluoAuraBurstState();
}

class _KipluoAuraBurstState extends State<KipluoAuraBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void didUpdateWidget(KipluoAuraBurst old) {
    super.didUpdateWidget(old);
    if (widget.burstKey > old.burstKey && !kipluoReducedMotion(context)) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _AuraPainter(
            progress: _ctrl.value,
            accent: widget.color ?? tokens.accent,
            line: tokens.line,
            rays: widget.rays,
            ring: widget.ring,
            fanAngle: widget.fanAngle,
            fanSpread: widget.fanSpread,
          ),
        ),
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter({
    required this.progress,
    required this.accent,
    required this.line,
    required this.rays,
    this.ring = true,
    this.fanAngle,
    this.fanSpread = 0,
  });
  final double progress;
  final Color accent;
  final Color line;
  final int rays;
  final bool ring;
  final double? fanAngle;
  final double fanSpread;

  @override
  void paint(Canvas canvas, Size size) {
    paintReleaseAura(
      canvas,
      size.center(Offset.zero),
      size.shortestSide * 0.48,
      progress,
      accent: accent,
      line: line,
      rays: rays,
      ring: ring,
      fanAngle: fanAngle,
      fanSpread: fanSpread,
    );
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.progress != progress || old.accent != accent || old.line != line;
}
