import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 25. Stacked Bar Chart (Free) */

class StackedBarChart extends StatefulWidget {
  const StackedBarChart({super.key, this.label = 'Weekly traffic', this.sound = true});
  final String label;
  final bool sound;

  @override
  State<StackedBarChart> createState() => _StackedBarChartState();
}

class _StackedBarChartState extends State<StackedBarChart> {
  static const _web = [36.0, 44.0, 38.0, 52.0, 48.0];
  static const _fl = [24.0, 28.0, 34.0, 30.0, 36.0];
  String? _isolated;
  int _burst = 0;

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
            children: [
              Expanded(child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.line))),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  KipluoAuraBurst(burstKey: _burst, size: 52, rays: 8),
                  Row(
                    children: [('web', 'Web', t.accent), ('fl', 'Dart', t.ok)].map((s) {
                      final on = _isolated == s.$1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _isolated = on ? null : s.$1;
                            _burst++;
                          });
                          KipluoSound.play(KSound.pop, at: context, volume: 0.45, componentEnabled: widget.sound);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: on ? s.$3 : t.track, borderRadius: BorderRadius.circular(99)),
                          child: Text(s.$2, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: t.line)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (i) {
                final hw = _isolated == 'fl' ? 0.0 : _web[i] * 0.65;
                final hf = _isolated == 'web' ? 0.0 : _fl[i] * 0.65;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(duration: const Duration(milliseconds: 240), height: hf, decoration: BoxDecoration(color: t.ok, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
                        const SizedBox(height: 2),
                        AnimatedContainer(duration: const Duration(milliseconds: 240), height: hw, decoration: BoxDecoration(color: t.accent, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)))),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
