import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 28. Battery Level Meter (Free) */

class BatteryLevelMeter extends StatefulWidget {
  const BatteryLevelMeter({super.key, this.initialLevel = 75, this.sound = true});
  final int initialLevel;
  final bool sound;

  @override
  State<BatteryLevelMeter> createState() => _BatteryLevelMeterState();
}

class _BatteryLevelMeterState extends State<BatteryLevelMeter> {
  late int _level = widget.initialLevel;
  int _dir = 1;
  int _burst = 0;

  void _set(int next) {
    final c = next.clamp(0, 100);
    final reachedFull = c == 100 && _level < 100;
    setState(() {
      _dir = c >= _level ? 1 : -1;
      _level = c;
      if (reachedFull) _burst++;
    });
    KipluoSound.play(c == 100 ? KSound.ding : KSound.tick, at: context, volume: 0.45, componentEnabled: widget.sound);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final lit = (_level / 100 * 8).round();
    final tone = _level <= 25 ? t.bad : (_level >= 88 ? t.ok : t.accent);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 176,
                  height: 42,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.line, width: t.stroke)),
                  child: Row(
                    children: List.generate(8, (i) {
                      final on = i < lit;
                      final waveIdx = _dir > 0 ? i : 7 - i;
                      return Expanded(
                        child: AnimatedScale(
                          scale: on ? 1.0 : 0.78,
                          duration: Duration(milliseconds: 190 + waveIdx * 18),
                          curve: Curves.easeOutBack,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 190 + waveIdx * 18),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(color: on ? tone : t.track, borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Container(width: 6, height: 18, decoration: BoxDecoration(color: t.line, borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)))),
              ],
            ),
            KipluoAuraBurst(burstKey: _burst, size: 80, rays: 8, color: t.ok),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _set(_level - 25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(99), border: Border.all(color: t.line, width: 1.5)),
                child: Text('-25%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.line)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('$_level%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: t.line)),
            ),
            GestureDetector(
              onTap: () => _set(_level + 25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(99), border: Border.all(color: t.line, width: 1.5)),
                child: Text('+25%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.accentInk)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
