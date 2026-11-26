import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';
import 'rolling_counter.dart';

/* 15. Slot Machine Counter (Free) */
class SlotMachineCounter extends StatefulWidget {
  const SlotMachineCounter({super.key, this.initialValue = 8420, this.sound = true});

  final double initialValue;
  final bool sound;

  @override
  State<SlotMachineCounter> createState() => _SlotMachineCounterState();
}

class _SlotMachineCounterState extends State<SlotMachineCounter> {
  static const _targets = [8420.0, 12950.0, 4880.0, 9999.0];
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.line, width: t.stroke * 0.55)),
          child: RollingCounter(value: _targets[_idx], sound: false),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            setState(() => _idx = (_idx + 1) % _targets.length);
            KipluoSound.play(KSound.ding, at: context, volume: 0.65, componentEnabled: widget.sound);
            KipluoSound.play(KSound.sparkle, at: context, volume: 0.45, componentEnabled: widget.sound);
          },
          child: const Text('Spin counter'),
        ),
      ],
    );
  }
}
