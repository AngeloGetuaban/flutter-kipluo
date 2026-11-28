import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/iso3d.dart';
import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* ==========================================================================
   Wave 10 — Six Zero-Dependency 3D Interactive Components
   1. Floating3DNav (Free)
   2. Flip3DCard (Free)
   3. StepDeck3D (Paid)
   4. PerspectiveSelector3D (Paid)
   5. ExtrudedGauge3D (Paid)
   6. ArcReveal3D (Paid)
   ========================================================================== */

/* --------------------------------------------------------------------------
   1. Floating3DNav (Free)
   -------------------------------------------------------------------------- */

class Floating3DNav extends StatefulWidget {
  const Floating3DNav({
    super.key,
    this.items = const ['Home', 'Work', '3D Lab', 'About'],
    this.initialIndex = 0,
    this.onChanged,
    this.sound = true,
  });

  final List<String> items;
  final int initialIndex;
  final ValueChanged<int>? onChanged;
  final bool sound;

  @override
  State<Floating3DNav> createState() => _Floating3DNavState();
}

class _Floating3DNavState extends State<Floating3DNav> with TickerProviderStateMixin {
  late int _index = widget.initialIndex.clamp(0, math.max(0, widget.items.length - 1));
  late final KSprings _springs = KSprings(
    vsync: this,
    initial: {'idx': _index.toDouble(), 'ry': 0.0, 'press': 0.0},
    config: SpringConfig.snappy,
  );

  void _select(int next) {
    if (next < 0 || next >= widget.items.length) return;
    setState(() => _index = next);
    widget.onChanged?.call(next);
    final reduced = kipluoReducedMotion(context);
    _springs.reducedMotion = reduced;
    final tilt = widget.items.length > 1 ? ((next / (widget.items.length - 1)) - 0.5) * 0.14 : 0.0;
    _springs.animateTo({'idx': next.toDouble(), 'ry': tilt, 'press': 0.0}, velocity: {'press': 28.0});
    KipluoSound.play(KSound.pop, at: context, pitch: 0.9 + next * 0.09, volume: 0.48, componentEnabled: widget.sound);
  }

  @override
  void dispose() {
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final shadows = KipluoTheme.shadowOf(context);
    final count = widget.items.length;

    return AnimatedBuilder(
      animation: _springs,
      builder: (context, _) {
        final ry = _springs['ry'];
        final press = _springs['press'].clamp(0.0, 4.0);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateY(ry),
          child: Transform.translate(
            offset: Offset(0, press),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tokens.line, width: tokens.stroke * 0.85),
                boxShadow: shadows,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(count, (i) {
                  final active = i == _index;
                  return Semantics(
                    selected: active,
                    button: true,
                    label: widget.items[i],
                    child: GestureDetector(
                      onTap: () => _select(i),
                      child: AnimatedContainer(
                        duration: kipluoReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? tokens.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: active ? Border.all(color: tokens.line, width: math.max(1.0, tokens.stroke * 0.6)) : null,
                          boxShadow: active ? shadows : const [],
                        ),
                        child: Text(
                          widget.items[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? tokens.accentInk : tokens.line,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

/* --------------------------------------------------------------------------
   2. Flip3DCard (Free)
   -------------------------------------------------------------------------- */

class Flip3DCard extends StatefulWidget {
  const Flip3DCard({
    super.key,
    this.initialFlipped = false,
    this.onFlippedChanged,
    this.front,
    this.back,
    this.sound = true,
  });

  final bool initialFlipped;
  final ValueChanged<bool>? onFlippedChanged;
  final Widget? front;
  final Widget? back;
  final bool sound;

  @override
  State<Flip3DCard> createState() => _Flip3DCardState();
}

class _Flip3DCardState extends State<Flip3DCard> with TickerProviderStateMixin {
  late bool _flipped = widget.initialFlipped;
  late final KSprings _springs = KSprings(
    vsync: this,
    initial: {'ry': widget.initialFlipped ? math.pi : 0.0},
    config: const SpringConfig(stiffness: 210, damping: 21),
  );

  void _commit(bool next, [double vel = 0]) {
    setState(() => _flipped = next);
    widget.onFlippedChanged?.call(next);
    _springs.reducedMotion = kipluoReducedMotion(context);
    _springs.animateTo({'ry': next ? math.pi : 0.0}, velocity: vel != 0 ? {'ry': vel} : null);
    KipluoSound.play(KSound.swish, at: context, pitch: next ? 1.15 : 0.92, volume: 0.45, componentEnabled: widget.sound);
  }

  @override
  void dispose() {
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final shadows = KipluoTheme.shadowOf(context);

    return Semantics(
      button: true,
      toggled: _flipped,
      label: _flipped ? 'Flip card to front' : 'Flip card to back',
      child: GestureDetector(
        onTap: () => _commit(!_flipped),
        onHorizontalDragUpdate: (d) {
          if (kipluoReducedMotion(context)) return;
          final next = (_springs['ry'] + d.delta.dx * 0.018).clamp(-0.35, math.pi + 0.35);
          _springs.set({'ry': next});
        },
        onHorizontalDragEnd: (d) {
          final vx = d.velocity.pixelsPerSecond.dx * 0.0022;
          final projected = _springs['ry'] + vx * 0.45;
          _commit(projected >= math.pi * 0.5, vx);
        },
        child: SizedBox(
          width: 210,
          height: 144,
          child: AnimatedBuilder(
            animation: _springs,
            builder: (context, _) {
              final angle = _springs['ry'];
              final showBack = angle > math.pi * 0.5;
              final displayAngle = showBack ? angle - math.pi : angle;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(displayAngle),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: showBack ? tokens.accent : tokens.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: tokens.line, width: tokens.stroke * 0.9),
                    boxShadow: shadows,
                  ),
                  child: showBack
                      ? (widget.back ??
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Gold member', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tokens.accentInk)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Show this at the front desk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: tokens.accentInk)),
                                  Text('Release halfway to snap back.', style: TextStyle(fontSize: 11, color: tokens.accentInk.withValues(alpha: 0.8))),
                                ],
                              ),
                            ],
                          ))
                      : (widget.front ??
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Member card', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: tokens.line)),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: tokens.accent,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: tokens.line, width: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Alex Moreno', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.line)),
                                  Text('Drag or tap to flip', style: TextStyle(fontSize: 11, color: tokens.line.withValues(alpha: 0.72))),
                                ],
                              ),
                            ],
                          )),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
