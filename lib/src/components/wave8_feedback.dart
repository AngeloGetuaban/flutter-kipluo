import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/theme.dart';

/* 43. Spring Checklist (Free) */

class StepChecklistCard extends StatefulWidget {
  const StepChecklistCard({super.key, this.sound = true});
  final bool sound;

  @override
  State<StepChecklistCard> createState() => _StepChecklistCardState();
}

class _StepChecklistCardState extends State<StepChecklistCard> {
  static const _labels = ['Install core', 'Enable SFX', 'Ship Flutter'];
  final List<bool> _done = [true, false, false];
  int _burst = 0;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final pct = (_done.where((e) => e).length / _done.length);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.line, width: t.stroke)),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          KipluoAuraBurst(burstKey: _burst, size: 112, rays: 12, color: t.ok),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Launch Checklist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: t.line)),
                  Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: pct == 1 ? t.ok : t.line)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: t.track, valueColor: AlwaysStoppedAnimation(pct == 1 ? t.ok : t.accent)),
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < _labels.length; i++)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _done[i] = !_done[i];
                      if (_done.every((e) => e)) _burst++;
                    });
                    KipluoSound.play(_done.every((e) => e) ? KSound.chime : KSound.pop, at: context, volume: 0.45, componentEnabled: widget.sound);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: _done[i] ? t.ok : t.surface, borderRadius: BorderRadius.circular(5), border: Border.all(color: t.line, width: 1.5)),
                          child: _done[i] ? const Text('✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)) : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.line, decoration: _done[i] ? TextDecoration.lineThrough : null)),
                        ),
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
