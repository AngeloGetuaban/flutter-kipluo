import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 11. Stacked Progress Bar (Free) */
class StackedProgressBar extends StatefulWidget {
  const StackedProgressBar({super.key, this.sound = true});
  final bool sound;

  @override
  State<StackedProgressBar> createState() => _StackedProgressBarState();
}

class _StackedProgressBarState extends State<StackedProgressBar> {
  bool _alt = false;
  int? _active;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final segs = _alt
        ? [('Apps', 26, t.accent), ('Media', 48, t.ok), ('Docs', 16, t.line)]
        : [('Apps', 44, t.accent), ('Media', 28, t.ok), ('Docs', 18, t.line)];

    return SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 18,
              decoration: BoxDecoration(color: t.track, border: Border.all(color: t.line, width: 1.5)),
              child: Row(
                children: [
                  for (var i = 0; i < segs.length; i++)
                    Expanded(
                      flex: segs[i].$2,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _active = _active == i ? null : i);
                          KipluoSound.play(KSound.tick, at: context, pitch: notePitch(i), volume: 0.4, componentEnabled: widget.sound);
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: _active == null || _active == i ? 1 : 0.45,
                          child: Container(color: segs[i].$3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  segs.map((e) => '${e.$1} ${e.$2}%').join(' · '),
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _alt = !_alt);
                  KipluoSound.play(KSound.swish, at: context, volume: 0.45, componentEnabled: widget.sound);
                },
                child: const Text('Switch'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
