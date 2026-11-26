import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Pulls its child toward the pointer with nonlinear strength, subtle 3D tilt, and a soft
/// center snap, then springs home when the pointer leaves.
class MagneticSurface extends StatefulWidget {
  const MagneticSurface({
    super.key,
    required this.child,
    this.strength = 0.35,
    this.radius = 120,
    this.spring = const SpringConfig(stiffness: 260, damping: 14),
    this.disabled = false,
    this.sound = true,
  });

  final Widget child;
  final double strength;
  final double radius;
  final SpringConfig spring;
  final bool disabled;
  final bool sound;

  @override
  State<MagneticSurface> createState() => _MagneticSurfaceState();
}

class _MagneticSurfaceState extends State<MagneticSurface> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'x': 0, 'y': 0, 'tiltX': 0, 'tiltY': 0, 'lift': 0},
    config: widget.spring,
  );
  bool _engaged = false;
  bool _centerSnapped = false;

  @override
  void didUpdateWidget(MagneticSurface old) {
    super.didUpdateWidget(old);
    _s.config = widget.spring;
    if (widget.disabled && !old.disabled) _release();
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _updateFromLocal(Offset localPos, Size size) {
    if (widget.disabled || kipluoReducedMotion(context)) return;
    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPos - center;
    final dist = delta.distance;
    if (dist > widget.radius) {
      _release();
      return;
    }
    if (!_engaged) {
      _engaged = true;
      KipluoSound.play(KSound.whoosh, at: context, volume: 0.45, componentEnabled: widget.sound);
    }
    final norm = (1 - dist / widget.radius).clamp(0.0, 1.0);
    final pull = widget.strength * (0.4 + 0.6 * norm);
    final tx = delta.dx * pull;
    final ty = delta.dy * pull;
    if (dist < 10 && !_centerSnapped) {
      _centerSnapped = true;
      KipluoSound.play(KSound.tick, at: context, pitch: 1.2, volume: 0.35, componentEnabled: widget.sound);
    } else if (dist > 16) {
      _centerSnapped = false;
    }
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({
      'x': tx,
      'y': ty,
      'tiltX': (-delta.dy / math.max(1.0, size.height)) * 12,
      'tiltY': (delta.dx / math.max(1.0, size.width)) * 12,
      'lift': 100,
    });
  }

  void _release() {
    if (_engaged) {
      _engaged = false;
      _centerSnapped = false;
      KipluoSound.play(KSound.whoosh, at: context, pitch: 0.78, volume: 0.35, componentEnabled: widget.sound);
    }
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'x': 0, 'y': 0, 'tiltX': 0, 'tiltY': 0, 'lift': 0});
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (focused) {
        if (widget.disabled) return;
        _s.reducedMotion = kipluoReducedMotion(context);
        _s.animateTo({'y': focused ? -4 : 0, 'lift': focused ? 100 : 0});
      },
      child: LayoutBuilder(
        builder: (context, _) => MouseRegion(
          onHover: (e) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) _updateFromLocal(e.localPosition, box.size);
          },
          onExit: (_) => _release(),
          child: AnimatedBuilder(
            animation: _s,
            builder: (context, child) {
              final rx = (_s['tiltX'] / 100) * math.pi / 18;
              final ry = (_s['tiltY'] / 100) * math.pi / 18;
              final scale = 1.0 + (_s['lift'] / 100) * 0.03;
              final m = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(rx)
                ..rotateY(ry);
              return Transform.translate(
                offset: Offset(_s['x'], _s['y']),
                child: Transform.scale(
                  scale: scale,
                  child: Transform(alignment: Alignment.center, transform: m, child: child),
                ),
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
