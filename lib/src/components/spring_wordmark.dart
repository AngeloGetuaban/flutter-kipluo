import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Playful interactive wordmark whose individual letters stretch, bounce on springs, and play
/// ascending pentatonic notes when hovered or tapped.
class SpringWordmark extends StatefulWidget {
  const SpringWordmark({
    super.key,
    this.text = 'kipluo',
    this.fontSize = 44,
    this.sound = true,
  });

  final String text;
  final double fontSize;
  final bool sound;

  @override
  State<SpringWordmark> createState() => _SpringWordmarkState();
}

class _SpringWordmarkState extends State<SpringWordmark> {
  @override
  Widget build(BuildContext context) {
    final chars = widget.text.split('');
    return Semantics(
      label: widget.text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chars.length; i++)
            _SpringLetter(
              char: chars[i],
              index: i,
              fontSize: widget.fontSize,
              sound: widget.sound,
            ),
        ],
      ),
    );
  }
}

class _SpringLetter extends StatefulWidget {
  const _SpringLetter({required this.char, required this.index, required this.fontSize, required this.sound});
  final String char;
  final int index;
  final double fontSize;
  final bool sound;

  @override
  State<_SpringLetter> createState() => _SpringLetterState();
}

class _SpringLetterState extends State<_SpringLetter> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(vsync: this, initial: {'y': 0, 'sy': 100, 'rot': 0}, config: SpringConfig.bouncy);

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _pluck({bool big = false}) {
    _s.reducedMotion = kipluoReducedMotion(context);
    KipluoSound.play(
      big ? KSound.pop : KSound.boop,
      at: context,
      pitch: notePitch(widget.index),
      volume: big ? 0.75 : 0.45,
      componentEnabled: widget.sound,
    );
    _s.set({'y': big ? -8 : -4, 'sy': big ? 124 : 114, 'rot': widget.index.isEven ? 6 : -6});
    _s.animateTo({'y': 0, 'sy': 100, 'rot': 0});
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _pluck(),
      child: GestureDetector(
        onTap: () => _pluck(big: true),
        child: AnimatedBuilder(
          animation: _s,
          builder: (context, _) {
            final sy = (_s['sy'] / 100).clamp(0.75, 1.4);
            final sx = 1 / math.sqrt(sy);
            return Transform.translate(
              offset: Offset(0, _s['y']),
              child: Transform.rotate(
                angle: (_s['rot'] / 100) * 0.4,
                child: Transform.scale(
                  scaleX: sx,
                  scaleY: sy,
                  child: Text(
                    widget.char,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: t.line,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
