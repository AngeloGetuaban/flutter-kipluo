import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Optional segment for a multi-segment [DonutProgress].
class DonutSegment {
  const DonutSegment({required this.label, required this.value, this.color});
  final String label;
  final double value;
  final Color? color;
}

/// A ring that springs to its value, with threshold colour shifts and optional multi-segment mode.
class DonutProgress extends StatefulWidget {
  const DonutProgress({
    super.key,
    required this.value,
    this.segments,
    this.warnAt = 85,
    this.dangerAt = 95,
    this.label = 'Storage used',
    this.caption = 'storage',
    this.size = 144,
    this.sound = true,
  });

  /// 0–100 single-ring value (used if [segments] is null).
  final double value;
  final List<DonutSegment>? segments;
  final double warnAt;
  final double dangerAt;
  final String label;
  final String caption;
  final double size;
  final bool sound;

  @override
  State<DonutProgress> createState() => _DonutProgressState();
}

class _DonutProgressState extends State<DonutProgress> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(vsync: this, initial: {'v': 0}, config: const SpringConfig(stiffness: 140, damping: 14));

  double get _effectiveValue {
    if (widget.segments == null || widget.segments!.isEmpty) return widget.value.clamp(0.0, 100.0);
    return widget.segments!.fold<double>(0, (sum, seg) => sum + seg.value).clamp(0.0, 100.0);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'v': _effectiveValue});
    });
  }

  @override
  void didUpdateWidget(DonutProgress old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.segments != widget.segments) {
      final target = _effectiveValue;
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'v': target});
      KipluoSound.play(KSound.drop, at: context, pitch: 0.75 + (target / 100) * 0.6, volume: 0.55, componentEnabled: widget.sound);
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
    final semanticVal = _effectiveValue.round();
    return Semantics(
      label: widget.label,
      value: '$semanticVal%',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _s,
            builder: (context, _) {
              final v = math.max(0.0, _s['v']);
              return CustomPaint(
                painter: _RingPainter(
                  value: v,
                  segments: widget.segments,
                  warnAt: widget.warnAt,
                  dangerAt: widget.dangerAt,
                  tokens: t,
                ),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${v.round()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(widget.caption, style: TextStyle(fontSize: 12, color: t.line.withValues(alpha: 0.6))),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.segments, required this.warnAt, required this.dangerAt, required this.tokens});
  final double value;
  final List<DonutSegment>? segments;
  final double warnAt;
  final double dangerAt;
  final KipluoTokens tokens;

  Color _ringColor(double v) {
    if (v >= dangerAt) return tokens.bad;
    if (v >= warnAt) {
      final blend = ((v - warnAt) / math.max(1.0, dangerAt - warnAt)).clamp(0.0, 1.0);
      return Color.lerp(tokens.accent, tokens.bad, blend) ?? tokens.bad;
    }
    return tokens.accent;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    canvas.drawArc(rect, 0, math.pi * 2, false, Paint()..color = tokens.track..style = PaintingStyle.stroke..strokeWidth = stroke);

    if (segments != null && segments!.isNotEmpty) {
      final totalTarget = segments!.fold<double>(0, (s, seg) => s + seg.value);
      final ratio = totalTarget > 0 ? (value / totalTarget).clamp(0.0, 1.0) : 0.0;
      var angle = -math.pi / 2;
      final palette = [tokens.accent, tokens.ok, tokens.line, tokens.bad];
      for (var i = 0; i < segments!.length; i++) {
        final sweep = math.pi * 2 * (segments![i].value.clamp(0.0, 100.0) / 100.0) * ratio;
        if (sweep > 0.005) {
          canvas.drawArc(
            rect,
            angle,
            sweep,
            false,
            Paint()
              ..color = segments![i].color ?? palette[i % palette.length]
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeCap = StrokeCap.round,
          );
          angle += sweep;
        }
      }
      return;
    }

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * (value / 100).clamp(0.0, 1.0),
      false,
      Paint()
        ..color = _ringColor(value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.segments != segments || old.tokens != tokens;
}
