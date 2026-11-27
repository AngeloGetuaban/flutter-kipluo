import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/theme.dart';

/* 40. Waterfall Delta Chart (Free) */

class WaterfallDeltaChart extends StatefulWidget {
  const WaterfallDeltaChart({super.key, this.sound = true});
  final bool sound;

  @override
  State<WaterfallDeltaChart> createState() => _WaterfallDeltaChartState();
}

class _WaterfallDeltaChartState extends State<WaterfallDeltaChart> {
  int _q = 0;
  int _burst = 0;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final bars = _q == 0
        ? [(0.0, 34.0, t.track), (34.0, 18.0, t.ok), (52.0, 12.0, t.ok), (56.0, 8.0, t.bad), (0.0, 56.0, t.accent)]
        : [(0.0, 40.0, t.track), (40.0, 22.0, t.ok), (62.0, 10.0, t.ok), (64.0, 8.0, t.bad), (0.0, 64.0, t.accent)];
    return Container(
      width: 244,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.line, width: t.stroke)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text('MRR Bridge', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.line))),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  KipluoAuraBurst(burstKey: _burst, size: 50, rays: 8),
                  Row(
                    children: ['Q3', 'Q4'].asMap().entries.map((e) {
                      final on = _q == e.key;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _q = e.key;
                            _burst++;
                          });
                          KipluoSound.play(KSound.drop, at: context, volume: 0.45, componentEnabled: widget.sound);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: on ? t.accent : t.track, borderRadius: BorderRadius.circular(99)),
                          child: Text(e.value, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: on ? t.accentInk : t.line)),
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
              children: bars.map((b) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 240),
                          left: 0,
                          right: 0,
                          bottom: b.$1,
                          height: b.$2,
                          child: Container(decoration: BoxDecoration(color: b.$3, borderRadius: BorderRadius.circular(5), border: Border.all(color: t.line, width: 1.2))),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
