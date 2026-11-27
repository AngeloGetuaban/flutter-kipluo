import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 36. Spring Color Swatches (Free) */

class SpringColorSwatches extends StatefulWidget {
  const SpringColorSwatches({super.key, this.sound = true});
  final bool sound;

  @override
  State<SpringColorSwatches> createState() => _SpringColorSwatchesState();
}

class _SpringColorSwatchesState extends State<SpringColorSwatches> {
  static const _swatches = [
    ('#FFC83D', Color(0xFFFFC83D)),
    ('#4A3FD1', Color(0xFF4A3FD1)),
    ('#1D8F5A', Color(0xFF1D8F5A)),
    ('#D73A45', Color(0xFFD73A45)),
    ('#0EA5E9', Color(0xFF0EA5E9)),
    ('#EC4899', Color(0xFFEC4899)),
  ];
  int _sel = 0;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Container(
      width: 244,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.line, width: t.stroke)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_swatches.length, (i) {
              final on = _sel == i;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _sel = i;
                  });
                  KipluoSound.play(KSound.pop, at: context, pitch: notePitch(i), volume: 0.45, componentEnabled: widget.sound);
                },
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedScale(
                        scale: on ? 1.14 : 0.94,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _swatches[i].$2,
                            shape: BoxShape.circle,
                            border: Border.all(color: t.line, width: 2),
                          ),
                          child: AnimatedScale(
                            scale: on ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            child: const Text('✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(_swatches[_sel].$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: t.line)),
        ],
      ),
    );
  }
}

/* 38. Pill Filter Bar (Free) */

class PillFilterBar extends StatefulWidget {
  const PillFilterBar({super.key, this.facets = const ['Free', 'Springs', 'Audio', 'Flutter', 'Icons'], this.sound = true});
  final List<String> facets;
  final bool sound;

  @override
  State<PillFilterBar> createState() => _PillFilterBarState();
}

class _PillFilterBarState extends State<PillFilterBar> {
  final Set<String> _active = {'Free', 'Flutter'};

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Container(
      width: 248,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.line, width: t.stroke)),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final f in widget.facets)
                GestureDetector(
                  onTap: () {
                    final has = _active.contains(f);
                    setState(() {
                      if (has) {
                        _active.remove(f);
                      } else {
                        _active.add(f);
                      }
                    });
                    KipluoSound.play(has ? KSound.boopLow : KSound.pop, at: context, volume: 0.45, componentEnabled: widget.sound);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _active.contains(f) ? t.accent : t.track,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: t.line, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: _active.contains(f) ? 1.0 : 0.65,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _active.contains(f) ? t.accentInk : t.line.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(f, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _active.contains(f) ? t.accentInk : t.line)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
