import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

const _pentatonic = [1.0, 9 / 8, 5 / 4, 3 / 2, 5 / 3, 2.0, 9 / 4, 5 / 2];

/// Stars that preview as you hover or drag, support half stars, and pop when chosen.
/// Each star is a note, so sliding across them plays a little scale.
class StarRating extends StatefulWidget {
  const StarRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.allowHalf = true,
    this.size = 36,
    this.label = 'Rating',
    this.sound = true,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final int max;
  final bool allowHalf;
  final double size;
  final String label;
  final bool sound;

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> with SingleTickerProviderStateMixin {
  double? _preview;
  double? _lastPreview;
  int _popIndex = -1;
  late final KSprings _pop = KSprings(vsync: this, initial: {'s': 0}, config: SpringConfig.bouncy);

  double get _step => widget.allowHalf ? 0.5 : 1;

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  double _fromDx(double dx) {
    final raw = dx / (widget.size + 4) ;
    final v = widget.allowHalf ? (raw * 2).ceil() / 2 : raw.ceilToDouble();
    return v.clamp(_step, widget.max.toDouble());
  }

  void _showPreview(double v) {
    if (v != _lastPreview) {
      final i = v.ceil() - 1;
      KipluoSound.play(KSound.tick, at: context, pitch: _pentatonic[i % 8] * (v % 1 == 0 ? 1 : 0.95), volume: 0.5, componentEnabled: widget.sound);
      _lastPreview = v;
    }
    setState(() => _preview = v);
  }

  void _commit(double v) {
    final i = v.ceil() - 1;
    setState(() {
      _preview = null;
      _lastPreview = null;
      _popIndex = i;
    });
    _pop.reducedMotion = kipluoReducedMotion(context);
    _pop.set({'s': 0});
    _pop.animateTo({'s': 0}, velocity: {'s': 9});
    KipluoSound.play(KSound.pop, at: context, pitch: _pentatonic[i % 8], componentEnabled: widget.sound);
    if (v == widget.max) KipluoSound.play(KSound.sparkle, at: context, volume: 0.7, componentEnabled: widget.sound);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final shown = _preview ?? widget.value;
    final enabled = widget.onChanged != null;
    return Semantics(
      slider: true,
      label: widget.label,
      value: '${widget.value} out of ${widget.max} stars',
      increasedValue: '${math.min(widget.max.toDouble(), widget.value + _step)}',
      decreasedValue: '${math.max(_step, widget.value - _step)}',
      onIncrease: enabled ? () => _commit(math.min(widget.max.toDouble(), widget.value + _step)) : null,
      onDecrease: enabled ? () => _commit(math.max(_step, widget.value - _step)) : null,
      child: FocusableActionDetector(
        enabled: enabled,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight): _Step(1),
          SingleActivator(LogicalKeyboardKey.arrowUp): _Step(1),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _Step(-1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _Step(-1),
        },
        actions: {
          _Step: CallbackAction<_Step>(onInvoke: (s) => _commit((widget.value + s.dir * _step).clamp(_step, widget.max.toDouble()))),
        },
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onHover: enabled ? (e) => _showPreview(_fromDx(e.localPosition.dx)) : null,
          onExit: (_) => setState(() {
            _preview = null;
            _lastPreview = null;
          }),
          child: GestureDetector(
            onTapUp: enabled ? (d) => _commit(_fromDx(d.localPosition.dx)) : null,
            onHorizontalDragUpdate: enabled ? (d) => _showPreview(_fromDx(d.localPosition.dx)) : null,
            onHorizontalDragEnd: enabled ? (_) => _commit(_preview ?? widget.value) : null,
            child: AnimatedBuilder(
              animation: _pop,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.max; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Transform.scale(
                        scale: i == _popIndex ? 1 + _pop['s'] * 0.06 : 1,
                        child: CustomPaint(
                          size: Size.square(widget.size),
                          painter: _StarPainter(fill: (shown - i).clamp(0.0, 1.0), tokens: t),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends Intent {
  const _Step(this.dir);
  final int dir;
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.fill, required this.tokens});
  final double fill;
  final KipluoTokens tokens;

  Path _star(Size s) {
    final p = Path();
    final c = s.center(Offset.zero);
    final outer = s.width * 0.47, inner = outer * 0.45;
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final star = _star(size);
    canvas.drawPath(star, Paint()..color = tokens.track);
    if (fill > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * fill, size.height));
      canvas.drawPath(star, Paint()..color = tokens.accent);
      canvas.restore();
    }
    canvas.drawPath(
      star,
      Paint()
        ..color = tokens.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.stroke * 0.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.fill != fill || old.tokens != tokens;
}
