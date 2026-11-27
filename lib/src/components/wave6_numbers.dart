import 'package:flutter/material.dart';

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
  late final KSprings _s = KSprings(vsync: this, initial: {'n': _target.toDouble()}, config: SpringConfig.snappy);

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _bump(int delta) {
    final next = (_target + delta).clamp(0, 20000);
    final crossed = _marks.any((m) => _target < m && next >= m);
    setState(() {
      _target = next;
    });
    _s.animateTo({'n': next.toDouble()});
    KipluoSound.play(crossed ? KSound.sparkle : KSound.tick, at: context, volume: 0.5, componentEnabled: widget.sound);
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
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
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
                      Text('Goal 10K', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t.line)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: frac, minHeight: 8, backgroundColor: t.track, valueColor: AlwaysStoppedAnimation(t.accent)),
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
        ],
      ),
    );
  }
}
