import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 10. Spring Area Spark (Free) */

class SpringAreaSpark extends StatefulWidget {
  const SpringAreaSpark({super.key, this.label = 'Active sessions', this.sound = true});
  final String label;
  final bool sound;

  @override
  State<SpringAreaSpark> createState() => _SpringAreaSparkState();
}

class _SpringAreaSparkState extends State<SpringAreaSpark> with SingleTickerProviderStateMixin {
  static const _sets = [
    [28.0, 42.0, 39.0, 64.0, 58.0, 82.0, 91.0],
    [45.0, 52.0, 48.0, 62.0, 74.0, 69.0, 86.0],
  ];
  int _idx = 0;
  int _burst = 0;
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'a': 28, 'b': 42, 'c': 39, 'd': 64, 'e': 58, 'f': 82, 'g': 91},
    config: SpringConfig.gentle,
  );

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _pick(int i) {
    setState(() {
      _idx = i;
      _burst++;
    });
    final d = _sets[i];
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'a': d[0], 'b': d[1], 'c': d[2], 'd': d[3], 'e': d[4], 'f': d[5], 'g': d[6]});
    KipluoSound.play(KSound.swish, at: context, volume: 0.42, componentEnabled: widget.sound);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Container(
      width: 244,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line, width: t.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: t.line)),
                    Text('${_sets[_idx].last.round()}k', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: t.line)),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  KipluoAuraBurst(burstKey: _burst, size: 54, rays: 8),
                  Row(
                    children: ['7D', '30D'].asMap().entries.map((e) {
                      final on = _idx == e.key;
                      return GestureDetector(
                        onTap: () => _pick(e.key),
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: on ? t.accent : t.track, borderRadius: BorderRadius.circular(99)),
                          child: Text(e.value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: on ? t.accentInk : t.line)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _s,
            builder: (_, _) => CustomPaint(
              size: const Size(216, 76),
              painter: _AreaSparkPainter(
                values: [_s['a'], _s['b'], _s['c'], _s['d'], _s['e'], _s['f'], _s['g']],
                tokens: t,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaSparkPainter extends CustomPainter {
  const _AreaSparkPainter({required this.values, required this.tokens});
  final List<double> values;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(i / (values.length - 1) * size.width, size.height - (values[i] / 100) * (size.height - 10) - 5),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final cx = (pts[i].dx + pts[i + 1].dx) / 2;
      line.cubicTo(cx, pts[i].dy, cx, pts[i + 1].dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = tokens.accent.withValues(alpha: 0.25));
    canvas.drawPath(line, Paint()..color = tokens.line..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_AreaSparkPainter old) => true;
}
