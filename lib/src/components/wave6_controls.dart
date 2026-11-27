import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 7. Spring Date Strip (Free) */

class SpringDateStrip extends StatefulWidget {
  const SpringDateStrip({super.key, this.initialIndex = 3, this.onSelected, this.sound = true});
  final int initialIndex;
  final ValueChanged<int>? onSelected;
  final bool sound;

  @override
  State<SpringDateStrip> createState() => _SpringDateStripState();
}

class _SpringDateStripState extends State<SpringDateStrip> with SingleTickerProviderStateMixin {
  static const _days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  late int _sel = widget.initialIndex.clamp(0, 6);
  int _week = 0;
  late final KSprings _s = KSprings(vsync: this, initial: {'x': _sel * 32.0}, config: SpringConfig.snappy);

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _pick(int i) {
    final next = i.clamp(0, 6);
    setState(() {
      _sel = next;
    });
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'x': next * 32.0});
    widget.onSelected?.call(next);
    KipluoSound.play(KSound.boop, at: context, pitch: notePitch(next), volume: 0.45, componentEnabled: widget.sound);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final baseDay = 10 + _week * 7;
    return SizedBox(
      width: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _week--);
                  KipluoSound.play(KSound.flip, at: context, volume: 0.4, componentEnabled: widget.sound);
                },
                child: Icon(Icons.chevron_left_rounded, color: t.line, size: 20),
              ),
              Text('Nov $baseDay – ${baseDay + 6}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.line)),
              GestureDetector(
                onTap: () {
                  setState(() => _week++);
                  KipluoSound.play(KSound.flip, at: context, volume: 0.4, componentEnabled: widget.sound);
                },
                child: Icon(Icons.chevron_right_rounded, color: t.line, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 236,
            height: 52,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.line, width: t.stroke),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _s,
                  builder: (_, _) => Positioned(
                    left: _s['x'].clamp(0.0, 192.0),
                    top: 2,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 30,
                          height: 42,
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: t.line, width: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(7, (i) {
                    final on = _sel == i;
                    return GestureDetector(
                      onTap: () => _pick(i),
                      child: SizedBox(
                        width: 32,
                        height: 46,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_days[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: on ? t.accentInk : t.line)),
                            Text('${baseDay + i}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: on ? t.accentInk : t.line)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* 9. Spring Multi-Select (Free) */

class SpringMultiSelect extends StatefulWidget {
  const SpringMultiSelect({super.key, this.options = const ['Springs', 'Audio', 'Flutter', 'React', 'Aura FX', 'A11y'], this.sound = true});
  final List<String> options;
  final bool sound;

  @override
  State<SpringMultiSelect> createState() => _SpringMultiSelectState();
}

class _SpringMultiSelectState extends State<SpringMultiSelect> {
  final Set<String> _selected = {'Springs', 'Audio'};

  void _toggle(String opt) {
    final had = _selected.contains(opt);
    setState(() {
      if (had) {
        _selected.remove(opt);
      } else {
        _selected.add(opt);
      }
    });
    KipluoSound.play(had ? KSound.boopLow : KSound.pop, at: context, volume: 0.45, componentEnabled: widget.sound);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return SizedBox(
      width: 244,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.line, width: t.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _selected.isEmpty
                        ? [Text('Pick tags…', style: TextStyle(fontSize: 11, color: t.line.withValues(alpha: 0.6)))]
                        : _selected
                            .map((s) => GestureDetector(
                                  onTap: () => _toggle(s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: t.accent,
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(color: t.line, width: 1.5),
                                    ),
                                    child: Text('$s ×', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.accentInk)),
                                  ),
                                ))
                            .toList(),
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: t.track, shape: BoxShape.circle),
                      child: Text('${_selected.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: t.line)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.options.map((o) {
              final on = _selected.contains(o);
              return GestureDetector(
                onTap: () => _toggle(o),
                child: Container(
                  width: 118,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: on ? t.accent.withValues(alpha: 0.25) : t.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.line, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.line)),
                      Text(on ? '✓' : '○', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: on ? t.ok : t.track)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
