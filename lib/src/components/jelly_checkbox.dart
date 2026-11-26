import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Checkbox that squashes while pressed, wobbles on spring release, draws its check mark or
/// indeterminate dash, and supports [tristate] (`true`, `false`, or `null` for mixed).
class JellyCheckbox extends StatefulWidget {
  const JellyCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.label,
    this.size = 26,
    this.sound = true,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;
  final String? label;
  final double size;
  final bool sound;

  @override
  State<JellyCheckbox> createState() => _JellyCheckboxState();
}

class _JellyCheckboxState extends State<JellyCheckbox> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'fill': _fillTarget(widget.value), 'draw': _fillTarget(widget.value), 'scale': 100},
    config: SpringConfig.bouncy,
  );

  static double _fillTarget(bool? v) => v == false ? 0 : 100;

  @override
  void didUpdateWidget(JellyCheckbox old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'fill': _fillTarget(widget.value), 'draw': _fillTarget(widget.value)});
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.onChanged == null) return;
    final bool? next;
    if (widget.value == null) {
      next = true;
    } else if (widget.tristate && widget.value == true) {
      next = false;
    } else {
      next = !widget.value!;
    }
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'scale': 100, 'fill': _fillTarget(next), 'draw': _fillTarget(next)}, velocity: {'scale': 220});
    KipluoSound.play(next == false ? KSound.boopLow : KSound.pop, at: context, volume: 0.7, componentEnabled: widget.sound);
    widget.onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final enabled = widget.onChanged != null;
    final box = FocusableActionDetector(
      enabled: enabled,
      shortcuts: const {SingleActivator(LogicalKeyboardKey.space): ActivateIntent()},
      actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _toggle())},
      child: GestureDetector(
        excludeFromSemantics: true,
        onTapDown: enabled
            ? (_) {
                _s.reducedMotion = kipluoReducedMotion(context);
                _s.animateTo({'scale': 84});
              }
            : null,
        onTapCancel: enabled ? () => _s.animateTo({'scale': 100}) : null,
        onTap: enabled ? _toggle : null,
        child: AnimatedBuilder(
          animation: _s,
          builder: (context, _) {
            final scale = (_s['scale'] / 100).clamp(0.75, 1.3);
            final fill = (_s['fill'] / 100).clamp(0.0, 1.0);
            final draw = (_s['draw'] / 100).clamp(0.0, 1.0);
            return Transform.scale(
              scale: scale,
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _JellyBoxPainter(fill: fill, draw: draw, mixed: widget.value == null, tokens: t),
              ),
            );
          },
        ),
      ),
    );
    return Semantics(
      checked: widget.value == true,
      mixed: widget.value == null,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? _toggle : null,
      child: widget.label == null
          ? box
          : InkWell(
              onTap: enabled ? _toggle : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [box, const SizedBox(width: 10), ExcludeSemantics(child: Text(widget.label!, style: const TextStyle(fontWeight: FontWeight.w600)))],
                ),
              ),
            ),
    );
  }
}

class _JellyBoxPainter extends CustomPainter {
  _JellyBoxPainter({required this.fill, required this.draw, required this.mixed, required this.tokens});
  final double fill;
  final double draw;
  final bool mixed;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.28));
    canvas.drawRRect(rr, Paint()..color = Color.lerp(tokens.surface, tokens.accent, fill)!);
    canvas.drawRRect(
      rr,
      Paint()
        ..color = tokens.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.stroke * 0.65,
    );
    if (draw > 0.02) {
      final path = Path();
      if (mixed) {
        path.moveTo(size.width * 0.28, size.height * 0.5);
        path.lineTo(size.width * 0.72, size.height * 0.5);
      } else {
        path.moveTo(size.width * 0.24, size.height * 0.52);
        path.lineTo(size.width * 0.43, size.height * 0.7);
        path.lineTo(size.width * 0.76, size.height * 0.32);
      }
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * draw),
        Paint()
          ..color = tokens.accentInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = tokens.stroke * 0.85
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_JellyBoxPainter old) => old.fill != fill || old.draw != draw || old.mixed != mixed || old.tokens != tokens;
}
