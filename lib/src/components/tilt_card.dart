import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// A card that tilts toward the pointer in 3D with a sliding glare highlight and springs flat on exit.
class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 12,
    this.glare = true,
    this.sound = true,
  });

  final Widget child;
  final double maxTilt;
  final bool glare;
  final bool sound;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(vsync: this, initial: {'rx': 0, 'ry': 0, 'gx': 50, 'gy': 50, 'glare': 0}, config: SpringConfig.snappy);

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _updateTilt(Offset pos, Size size) {
    if (kipluoReducedMotion(context)) return;
    final nx = ((pos.dx / math.max(1.0, size.width)) * 2 - 1).clamp(-1.0, 1.0);
    final ny = ((pos.dy / math.max(1.0, size.height)) * 2 - 1).clamp(-1.0, 1.0);
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({
      'rx': -ny * widget.maxTilt * 10,
      'ry': nx * widget.maxTilt * 10,
      'gx': (pos.dx / math.max(1.0, size.width)) * 100,
      'gy': (pos.dy / math.max(1.0, size.height)) * 100,
      'glare': 100,
    });
  }

  void _reset() {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'rx': 0, 'ry': 0, 'gx': 50, 'gy': 50, 'glare': 0});
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (focused) {
        if (kipluoReducedMotion(context)) return;
        _s.animateTo({'rx': focused ? 40 : 0, 'ry': focused ? -40 : 0, 'glare': focused ? 60 : 0});
      },
      child: MouseRegion(
        onEnter: (_) => KipluoSound.play(KSound.whoosh, at: context, volume: 0.25, componentEnabled: widget.sound),
        onHover: (e) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) _updateTilt(e.localPosition, box.size);
        },
        onExit: (_) => _reset(),
        child: AnimatedBuilder(
          animation: _s,
          builder: (context, child) {
            final rx = (_s['rx'] / 10) * math.pi / 180;
            final ry = (_s['ry'] / 10) * math.pi / 180;
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(rx)
              ..rotateY(ry);
            final glareAlpha = ((_s['glare'] / 100) * 0.22).clamp(0.0, 0.22);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: Stack(
                children: [
                  child!,
                  if (widget.glare && glareAlpha > 0.01)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: RadialGradient(
                              center: Alignment((_s['gx'] / 50) - 1, (_s['gy'] / 50) - 1),
                              radius: 0.9,
                              colors: [Colors.white.withValues(alpha: glareAlpha), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
