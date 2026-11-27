import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 14. Milestone Odometer (Free) */

class MilestoneOdometer extends StatefulWidget {
  const MilestoneOdometer({super.key, this.initialValue = 840, this.sound = true});
  final int initialValue;
  final bool sound;

  @override
  State<MilestoneOdometer> createState() => _MilestoneOdometerState();
}

class _MilestoneOdometerState extends State<MilestoneOdometer> with SingleTickerProviderStateMixin {
  static const _marks = [1000, 5000, 10000];
  late int _target = widget.initialValue;
  int _burst = 0;
  int? _celebrating;
  double _burstAlignX = 1.0;
  Timer? _celTimer;
  late final KSprings _s = KSprings(vsync: this, initial: {'n': _target.toDouble()}, config: SpringConfig.snappy);

  @override
  void dispose() {
    _celTimer?.cancel();
    _s.dispose();
    super.dispose();
  }

  void _bump(int delta) {
    final next = (_target + delta).clamp(0, 20000);
    int? crossed;
    for (final m in _marks.reversed) {
      if (_target < m && next >= m) {
        crossed = m;
        break;
      }
    }
    setState(() {
      _target = next;
      if (crossed != null) {
        _celebrating = crossed;
        _burstAlignX = (crossed / 10000) * 2 - 1;
        _burst++;
      }
    });
    if (crossed != null) {
      _celTimer?.cancel();
      _celTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && _celebrating == crossed) setState(() => _celebrating = null);
      });
    }
    _s.animateTo({'n': next.toDouble()});
    KipluoSound.play(crossed != null ? KSound.sparkle : KSound.tick, at: context, volume: 0.5, componentEnabled: widget.sound);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line, width: t.stroke),
      ),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, _) {
          final cur = _s['n'].round();
          final frac = (cur / 10000).clamp(0.0, 1.0);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$cur', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: t.line)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _celebrating != null ? t.ok : t.track,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _celebrating != null ? '★ ${_celebrating! ~/ 1000}K HIT!' : 'Goal 10K',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _celebrating != null ? Colors.white : t.line,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 14,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 8,
                        backgroundColor: t.track,
                        valueColor: AlwaysStoppedAnimation(frac >= 1 ? t.ok : t.accent),
                      ),
                    ),
                    ..._marks.map((m) {
                      final hit = cur >= m;
                      final alignX = (m / 10000) * 2 - 1;
                      return Align(
                        alignment: Alignment(alignX, 0),
                        child: AnimatedScale(
                          scale: hit ? 1.16 : 0.88,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hit ? t.ok : t.surface,
                              border: Border.all(color: t.line, width: 1.8),
                            ),
                          ),
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment(_burstAlignX, 0),
                      child: KipluoAuraBurst(burstKey: _burst, size: 52, rays: 8, color: t.ok),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [300, 1500, 4500].map((inc) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () => _bump(inc),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.line, width: 1.5),
                          ),
                          child: Text('+$inc', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.line)),
                        ),
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
