import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 1. Spring Drawer Handle (Free) */

enum DrawerDetent { peek, half, full }

class SpringDrawerHandle extends StatefulWidget {
  const SpringDrawerHandle({
    super.key,
    this.detent,
    this.initialDetent = DrawerDetent.half,
    this.onDetentChanged,
    this.sound = true,
  });

  final DrawerDetent? detent;
  final DrawerDetent initialDetent;
  final ValueChanged<DrawerDetent>? onDetentChanged;
  final bool sound;

  @override
  State<SpringDrawerHandle> createState() => _SpringDrawerHandleState();
}

class _SpringDrawerHandleState extends State<SpringDrawerHandle> with SingleTickerProviderStateMixin {
  static const _heights = {DrawerDetent.peek: 58.0, DrawerDetent.half: 112.0, DrawerDetent.full: 164.0};
  late DrawerDetent _inner = widget.initialDetent;
  late final KSprings _s = KSprings(vsync: this, initial: {'h': _heights[_active]!}, config: SpringConfig.snappy);
  int _burst = 0;

  DrawerDetent get _active => widget.detent ?? _inner;

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _commit(DrawerDetent next) {
    if (widget.detent == null) setState(() => _inner = next);
    widget.onDetentChanged?.call(next);
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'h': _heights[next]!});
    setState(() => _burst++);
    KipluoSound.play(KSound.pop, at: context, pitch: 0.9 + next.index * 0.14, volume: 0.5, componentEnabled: widget.sound);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Container(
      width: 248,
      height: 202,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: t.track.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.line, width: t.stroke),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 2,
            left: 2,
            right: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: DrawerDetent.values.map((d) {
                final sel = _active == d;
                return GestureDetector(
                  onTap: () => _commit(d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: sel ? t.accent : t.surface,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: t.line, width: 1.5),
                    ),
                    child: Text(d.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? t.accentInk : t.line)),
                  ),
                );
              }).toList(),
            ),
          ),
          AnimatedBuilder(
            animation: _s,
            builder: (_, _) => GestureDetector(
              onVerticalDragUpdate: (d) {
                final next = (_s['h'] - d.delta.dy).clamp(44.0, 176.0);
                _s.set({'h': next});
              },
              onVerticalDragEnd: (d) {
                final projected = _s['h'] - (d.primaryVelocity ?? 0) * 0.08;
                final nearest = DrawerDetent.values.reduce((a, b) => (_heights[b]! - projected).abs() < (_heights[a]! - projected).abs() ? b : a);
                _commit(nearest);
              },
              child: Container(
                width: double.infinity,
                height: _s['h'].clamp(44.0, 176.0),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.line, width: t.stroke),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 16,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          KipluoAuraBurst(burstKey: _burst, size: 58, rays: 8),
                          Container(
                            width: 44,
                            height: 6,
                            decoration: BoxDecoration(
                              color: t.accent,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: t.line, width: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Inspector', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.line)),
                        Text(_active.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t.line)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* 5. Spring Split Pane (Free) */

class SpringSplitPane extends StatefulWidget {
  const SpringSplitPane({super.key, this.initialRatio = 50, this.onRatioChanged, this.sound = true});
  final double initialRatio;
  final ValueChanged<double>? onRatioChanged;
  final bool sound;

  @override
  State<SpringSplitPane> createState() => _SpringSplitPaneState();
}

class _SpringSplitPaneState extends State<SpringSplitPane> with SingleTickerProviderStateMixin {
  static const _snaps = [33.0, 50.0, 67.0];
  late final KSprings _s = KSprings(vsync: this, initial: {'pct': widget.initialRatio}, config: SpringConfig.snappy);
  int _burst = 0;

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _snapTo(double v) {
    final c = v.clamp(22.0, 78.0);
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'pct': c});
    widget.onRatioChanged?.call(c);
    setState(() => _burst++);
    KipluoSound.play(KSound.pop, at: context, volume: 0.45, componentEnabled: widget.sound);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return SizedBox(
      width: 248,
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, _) {
          final pct = _s['pct'].clamp(20.0, 80.0);
          final leftW = (244 - 16) * (pct / 100);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 248,
                height: 108,
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.line, width: t.stroke),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Row(
                    children: [
                      Container(
                        width: leftW,
                        color: t.accent.withValues(alpha: 0.22),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('CODE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: t.line)),
                            Text('${pct.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: t.line)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onDoubleTap: () => _snapTo(50),
                        onHorizontalDragUpdate: (d) {
                          final next = (_s['pct'] + d.delta.dx * 0.44).clamp(20.0, 80.0);
                          _s.set({'pct': next});
                        },
                        onHorizontalDragEnd: (_) {
                          final cur = _s['pct'].clamp(22.0, 78.0);
                          final near = _snaps.where((s) => (s - cur).abs() < 5).firstOrNull;
                          _snapTo(near ?? cur);
                        },
                        child: Container(
                          width: 16,
                          color: t.surface,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              KipluoAuraBurst(burstKey: _burst, size: 54, rays: 8),
                              Container(width: 3, height: 28, decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(99))),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('VIEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: t.line)),
                              Text('${100 - pct.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: t.line)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _snaps.map((s) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => _snapTo(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (pct - s).abs() < 2 ? t.accent : t.surface,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: t.line, width: 1.5),
                        ),
                        child: Text('${s.round()}/${100 - s.round()}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: (pct - s).abs() < 2 ? t.accentInk : t.line)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
