import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/theme.dart';

/* 42. Elastic Countdown (Free) */

class CountdownBlocks extends StatefulWidget {
  const CountdownBlocks({super.key, this.initialSeconds = 12, this.sound = true});
  final int initialSeconds;
  final bool sound;

  @override
  State<CountdownBlocks> createState() => _CountdownBlocksState();
}

class _CountdownBlocksState extends State<CountdownBlocks> {
  late int _sec = widget.initialSeconds;
  int _burst = 0;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final urgent = _sec > 0 && _sec <= 5;
    final bg = _sec == 0 ? t.ok : (urgent ? t.bad : t.surface);
    final fg = (_sec == 0 || urgent) ? Colors.white : t.line;
    final blocks = [('HR', '00'), ('MIN', (_sec ~/ 60).toString().padLeft(2, '0')), ('SEC', (_sec % 60).toString().padLeft(2, '0'))];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: blocks.map((b) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.line, width: t.stroke),
                  ),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                          child: child,
                        ),
                        child: Text(
                          b.$2,
                          key: ValueKey('${b.$1}-${b.$2}'),
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: fg),
                        ),
                      ),
                      Text(b.$1, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: fg)),
                    ],
                  ),
                );
              }).toList(),
            ),
            KipluoAuraBurst(burstKey: _burst, size: 84, rays: 8, color: t.ok),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            final next = _sec == 0 ? widget.initialSeconds : (_sec - 1).clamp(0, 999);
            setState(() {
              _sec = next;
              if (next == 0) _burst++;
            });
            KipluoSound.play(_sec == 0 ? KSound.sparkle : KSound.tick, at: context, volume: 0.45, componentEnabled: widget.sound);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(99), border: Border.all(color: t.line, width: 1.5)),
            child: Text(_sec == 0 ? 'Reset' : 'Tick −1s', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: t.accentInk)),
          ),
        ),
      ],
    );
  }
}
