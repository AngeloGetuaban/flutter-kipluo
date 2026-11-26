import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Compact KPI sparkline that morphs between periods on springs with hover/arrow scrubbing
/// and automatic trend coloration.
class SpringSparkline extends StatefulWidget {
  const SpringSparkline({
    super.key,
    required this.data,
    this.label = 'KPI sparkline',
    this.width = 200,
    this.height = 56,
    this.sound = true,
  });

  final List<double> data;
  final String label;
  final double width;
  final double height;
  final bool sound;

  @override
  State<SpringSparkline> createState() => _SpringSparklineState();
}

class _SpringSparklineState extends State<SpringSparkline> with SingleTickerProviderStateMixin {
  late KSprings _s = _makeSprings();
  int? _active;

  KSprings _makeSprings() => KSprings(
        vsync: this,
        initial: {for (var i = 0; i < widget.data.length; i++) 'v$i': widget.data[i]},
        config: const SpringConfig(stiffness: 200, damping: 18),
      );

  @override
  void didUpdateWidget(SpringSparkline old) {
    super.didUpdateWidget(old);
    if (old.data.length != widget.data.length) {
      _s.dispose();
      _s = _makeSprings();
      setState(() {});
    } else if (old.data != widget.data) {
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({for (var i = 0; i < widget.data.length; i++) 'v$i': widget.data[i]});
      KipluoSound.play(KSound.swish, at: context, volume: 0.38, componentEnabled: widget.sound);
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _scrub(int? idx) {
    if (idx == _active) return;
    setState(() => _active = idx);
    if (idx != null && idx < widget.data.length) {
      final minV = widget.data.reduce(math.min);
      final maxV = widget.data.reduce(math.max);
      final norm = ((widget.data[idx] - minV) / math.max(1e-4, maxV - minV)).clamp(0.0, 1.0);
      KipluoSound.play(KSound.tick, at: context, pitch: 0.85 + norm * 0.55, volume: 0.35, componentEnabled: widget.sound);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final rising = widget.data.length < 2 || widget.data.last >= widget.data.first;
    final strokeColor = rising ? t.ok : t.bad;
    return Semantics(
      label: widget.label,
      value: _active != null && _active! < widget.data.length ? '${widget.data[_active!].round()}' : null,
      child: FocusableActionDetector(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowLeft): _SparkStep(-1),
          SingleActivator(LogicalKeyboardKey.arrowRight): _SparkStep(1),
        },
        actions: {
          _SparkStep: CallbackAction<_SparkStep>(
            onInvoke: (s) {
              if (widget.data.isEmpty) return;
              _scrub(((_active ?? 0) + s.delta).clamp(0, widget.data.length - 1));
              return null;
            },
          ),
        },
        child: MouseRegion(
          onHover: (e) {
            if (widget.data.isEmpty) return;
            _scrub(((e.localPosition.dx / widget.width) * (widget.data.length - 1)).round().clamp(0, widget.data.length - 1));
          },
          onExit: (_) => _scrub(null),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: AnimatedBuilder(
              animation: _s,
              builder: (context, _) => CustomPaint(
                painter: _SparkPainter(
                  values: [for (var i = 0; i < widget.data.length; i++) _s['v$i']],
                  active: _active,
                  color: strokeColor,
                  dotFill: t.surface,
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

class _SparkStep extends Intent {
  const _SparkStep(this.delta);
  final int delta;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.active, required this.color, required this.dotFill, required this.tokens});
  final List<double> values;
  final int? active;
  final Color color;
  final Color dotFill;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = math.max(1e-4, maxV - minV);
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(
          6 + (i / (values.length - 1)) * (size.width - 12),
          6 + (1 - (values[i] - minV) / span) * (size.height - 12),
        ),
    ];
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final midX = (pts[i].dx + pts[i + 1].dx) / 2;
      p.cubicTo(midX, pts[i].dy, midX, pts[i + 1].dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    canvas.drawPath(p, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round);
    if (active != null && active! < pts.length) {
      canvas.drawCircle(pts[active!], 4.5, Paint()..color = dotFill);
      canvas.drawCircle(pts[active!], 4.5, Paint()..color = tokens.line..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}
