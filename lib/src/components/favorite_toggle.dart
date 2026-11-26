import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Heart toggle that fills from the bottom, squashes on press, pops on spring release, and
/// emits a gravity-driven particle burst (never stacking bursts on spam clicks).
class FavoriteToggle extends StatefulWidget {
  const FavoriteToggle({
    super.key,
    required this.pressed,
    required this.onChanged,
    this.size = 48,
    this.label = 'Favorite',
    this.sound = true,
  });

  final bool pressed;
  final ValueChanged<bool>? onChanged;
  final double size;
  final String label;
  final bool sound;

  @override
  State<FavoriteToggle> createState() => _FavoriteToggleState();
}

class _FavoriteToggleState extends State<FavoriteToggle> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'fill': widget.pressed ? 100 : 0, 'scale': 100, 'burst': 0},
    config: SpringConfig.bouncy,
  );

  @override
  void didUpdateWidget(FavoriteToggle old) {
    super.didUpdateWidget(old);
    if (old.pressed != widget.pressed) {
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'fill': widget.pressed ? 100 : 0, 'burst': widget.pressed ? 100 : 0});
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.onChanged == null) return;
    final next = !widget.pressed;
    _s.reducedMotion = kipluoReducedMotion(context);
    if (next) {
      _s.set({'scale': 78, 'burst': 0});
      _s.animateTo({'fill': 100, 'scale': 100, 'burst': 100}, velocity: {'scale': 160});
      KipluoSound.play(KSound.pop, at: context, volume: 0.75, componentEnabled: widget.sound);
      KipluoSound.play(KSound.sparkle, at: context, volume: 0.6, componentEnabled: widget.sound);
    } else {
      _s.set({'burst': 0});
      _s.animateTo({'fill': 0, 'scale': 100, 'burst': 0}, velocity: {'scale': -90});
      KipluoSound.play(KSound.boopLow, at: context, volume: 0.5, componentEnabled: widget.sound);
    }
    widget.onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final enabled = widget.onChanged != null;
    return Semantics(
      button: true,
      toggled: widget.pressed,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? _toggle : null,
      child: FocusableActionDetector(
        enabled: enabled,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _toggle())},
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: enabled ? _toggle : null,
          child: SizedBox.square(
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: _s,
              builder: (context, _) => Transform.scale(
                scale: (_s['scale'] / 100).clamp(0.7, 1.35),
                child: CustomPaint(
                  painter: _HeartPainter(
                    fill: (_s['fill'] / 100).clamp(0.0, 1.0),
                    burst: (_s['burst'] / 100).clamp(0.0, 1.0),
                    tokens: t,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  _HeartPainter({required this.fill, required this.burst, required this.tokens});
  final double fill;
  final double burst;
  final KipluoTokens tokens;

  Path _heart(Size s) {
    final w = s.width;
    final h = s.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.78)
      ..cubicTo(w * 0.14, h * 0.54, w * 0.16, h * 0.24, w * 0.36, h * 0.24)
      ..cubicTo(w * 0.45, h * 0.24, w * 0.5, h * 0.32, w * 0.5, h * 0.37)
      ..cubicTo(w * 0.5, h * 0.32, w * 0.55, h * 0.24, w * 0.64, h * 0.24)
      ..cubicTo(w * 0.84, h * 0.24, w * 0.86, h * 0.54, w * 0.5, h * 0.78)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final heart = _heart(size);
    canvas.drawPath(heart, Paint()..color = tokens.surface);
    if (fill > 0.01) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, size.height * (1 - fill), size.width, size.height * fill));
      canvas.drawPath(heart, Paint()..color = tokens.bad);
      canvas.restore();
    }
    canvas.drawPath(
      heart,
      Paint()
        ..color = tokens.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.stroke * 0.7
        ..strokeJoin = StrokeJoin.round,
    );
    if (burst > 0.02 && burst < 0.99) {
      final c = size.center(Offset.zero);
      final alpha = (1 - burst).clamp(0.0, 1.0);
      for (var i = 0; i < 6; i++) {
        final a = -math.pi / 2 + (i / 6) * math.pi * 2;
        final r = size.width * (0.28 + burst * 0.24);
        final pt = c + Offset(math.cos(a) * r, math.sin(a) * r + burst * burst * 4);
        canvas.drawCircle(pt, 2.5 * (1 - burst * 0.5), Paint()..color = tokens.accent.withValues(alpha: alpha));
      }
    }
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.fill != fill || old.burst != burst || old.tokens != tokens;
}
