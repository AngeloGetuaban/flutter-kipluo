import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Unread or cart badge that pops with overshoot on increment, softens on decrement,
/// caps cleanly at [max]+, and announces updates politely.
class SpringBadgeCount extends StatefulWidget {
  const SpringBadgeCount({
    super.key,
    required this.value,
    this.max = 99,
    this.showZero = false,
    this.sound = true,
  });

  final int value;
  final int max;
  final bool showZero;
  final bool sound;

  @override
  State<SpringBadgeCount> createState() => _SpringBadgeCountState();
}

class _SpringBadgeCountState extends State<SpringBadgeCount> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(vsync: this, initial: {'scale': widget.value == 0 && !widget.showZero ? 0 : 100}, config: SpringConfig.bouncy);

  @override
  void didUpdateWidget(SpringBadgeCount old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _s.reducedMotion = kipluoReducedMotion(context);
      final visible = widget.value > 0 || widget.showZero;
      if (!visible) {
        _s.animateTo({'scale': 0});
        KipluoSound.play(KSound.boopLow, at: context, volume: 0.45, componentEnabled: widget.sound);
      } else if (widget.value > old.value) {
        _s.set({'scale': 134});
        _s.animateTo({'scale': 100});
        KipluoSound.play(KSound.pop, at: context, volume: 0.7, componentEnabled: widget.sound);
      } else {
        _s.set({'scale': 84});
        _s.animateTo({'scale': 100});
        KipluoSound.play(KSound.boopLow, at: context, volume: 0.45, componentEnabled: widget.sound);
      }
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final text = widget.value > widget.max ? '${widget.max}+' : '${widget.value}';
    return Semantics(
      liveRegion: true,
      label: widget.value == 0 && !widget.showZero ? 'No unread items' : '$text unread',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _s,
          builder: (context, _) {
            final scale = (_s['scale'] / 100).clamp(0.0, 1.5);
            if (scale <= 0.01 && widget.value == 0 && !widget.showZero) return const SizedBox.shrink();
            return Transform.scale(
              scale: scale,
              child: Container(
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.line, width: t.stroke * 0.55),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(color: t.accentInk, fontWeight: FontWeight.w900, fontSize: 13),
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
