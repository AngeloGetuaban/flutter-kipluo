import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';
import 'rolling_counter.dart';

/// Stat block that counts up on a spring and pops in its percentage [delta] badge when landed.
class CountUpStat extends StatefulWidget {
  const CountUpStat({
    super.key,
    required this.value,
    this.label = 'Monthly revenue',
    this.prefix = '\$',
    this.delta,
    this.sound = true,
  });

  final double value;
  final String label;
  final String prefix;
  final double? delta;
  final bool sound;

  @override
  State<CountUpStat> createState() => _CountUpStatState();
}

class _CountUpStatState extends State<CountUpStat> with SingleTickerProviderStateMixin {
  late final KSprings _badge = KSprings(vsync: this, initial: {'s': widget.delta == null ? 0 : 100}, config: SpringConfig.bouncy);

  @override
  void didUpdateWidget(CountUpStat old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.delta != widget.delta) {
      if (widget.delta != null) {
        _badge.reducedMotion = kipluoReducedMotion(context);
        _badge.set({'s': 65});
        _badge.animateTo({'s': 100});
        KipluoSound.play(KSound.pop, at: context, volume: 0.5, componentEnabled: widget.sound);
      }
    }
  }

  @override
  void dispose() {
    _badge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final up = (widget.delta ?? 0) >= 0;
    return Semantics(
      label: '${widget.label}: ${widget.prefix}${widget.value.round()}${widget.delta == null ? '' : ', ${up ? 'up' : 'down'} ${widget.delta!.abs().toStringAsFixed(1)}%'}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.line, width: t.stroke * 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.line.withValues(alpha: 0.65))),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RollingCounter(value: widget.value, prefix: widget.prefix, fontSize: 28, sound: false),
                  if (widget.delta != null) ...[
                    const SizedBox(width: 10),
                    AnimatedBuilder(
                      animation: _badge,
                      builder: (context, child) => Transform.scale(scale: (_badge['s'] / 100).clamp(0.4, 1.3), child: child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (up ? t.ok : t.bad).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${up ? '+' : '-'}${widget.delta!.abs().toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: up ? t.ok : t.bad),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
