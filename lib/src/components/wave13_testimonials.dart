import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* ==========================================================================
   Wave 13 — Five Interactive Testimonial Widgets
   1. CoverflowTestimonials (Free)
   2. MarqueeTestimonials (Free)
   3. VoiceTestimonials (Paid)
   4. BentoTestimonials (Paid)
   5. EditorialQuoteSwitcher (Paid)
   ========================================================================== */

/* 1. CoverflowTestimonials (Free) */
class CoverflowTestimonials extends StatefulWidget {
  const CoverflowTestimonials({super.key, this.sound = true});
  final bool sound;

  @override
  State<CoverflowTestimonials> createState() => _CoverflowTestimonialsState();
}

class _CoverflowTestimonialsState extends State<CoverflowTestimonials> with TickerProviderStateMixin {
  // Start on the middle quote so neighbours fan out on both sides.
  late int _idx = _quotes.length ~/ 2;
  static const _quotes = [
    ('Mara Santos', 'Nurse, Lisbon', 'I now chat with patients in their own language.'),
    ('Devon Park', 'Teacher, Busan', 'Ten minutes a day got me through my N4 exam.'),
    ('Aiko Tanaka', 'Product designer', 'The speaking drills fixed my accent mistakes.'),
  ];
  late final KSprings _springs = KSprings(vsync: this, initial: {'pos': (_quotes.length ~/ 2).toDouble()}, config: const SpringConfig(stiffness: 210, damping: 22));

  void _go(int next) {
    final w = ((next % _quotes.length) + _quotes.length) % _quotes.length;
    setState(() => _idx = w);
    _springs.reducedMotion = kipluoReducedMotion(context);
    _springs.animateTo({'pos': w.toDouble()});
    KipluoSound.play(KSound.swish, at: context, pitch: 0.92 + w * 0.12, volume: 0.42, componentEnabled: widget.sound);
  }

  @override
  void dispose() {
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final shadows = KipluoTheme.shadowOf(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onHorizontalDragEnd: (d) {
              final vx = d.velocity.pixelsPerSecond.dx;
              if (vx < -100) _go(_idx + 1);
              if (vx > 100) _go(_idx - 1);
            },
            child: SizedBox(
              height: 126,
              child: AnimatedBuilder(
                animation: _springs,
                builder: (context, _) {
                  final pos = _springs['pos'];
                  final order = [0, 1, 2]..sort((a, b) => (b - pos).abs().compareTo((a - pos).abs()));
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final i in order)
                        Builder(
                          builder: (context) {
                            final rel = i - pos;
                            final abs = rel.abs();
                            return Opacity(
                              opacity: (1 - abs * 0.36).clamp(0.28, 1.0),
                              child: Transform.translate(
                                offset: Offset(rel * 96, 0),
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0014)
                                    ..rotateY((-rel * 0.36).clamp(-0.6, 0.6)),
                                  child: Transform.scale(
                                    scale: (1 - abs * 0.14).clamp(0.76, 1.0),
                                    child: Container(
                                      width: 224,
                                      constraints: const BoxConstraints(minHeight: 108),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: i == _idx ? tokens.surface : tokens.track,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: tokens.line),
                                        boxShadow: shadows,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('“${_quotes[i].$3}”', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tokens.line)),
                                          const SizedBox(height: 6),
                                          Text('${_quotes[i].$1}, ${_quotes[i].$2}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: tokens.line.withValues(alpha: 0.72))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(onTap: () => _go(_idx - 1), child: Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: tokens.surface, shape: BoxShape.circle, border: Border.all(color: tokens.line)), child: Text('←', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.line)))),
              const SizedBox(width: 10),
              GestureDetector(onTap: () => _go(_idx + 1), child: Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: tokens.accent, shape: BoxShape.circle, border: Border.all(color: tokens.line)), child: Text('→', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.accentInk)))),
            ],
          ),
        ],
      ),
    );
  }
}

/* 2. MarqueeTestimonials (Free) */
class MarqueeTestimonials extends StatefulWidget {
  const MarqueeTestimonials({super.key, this.sound = true});
  final bool sound;

  @override
  State<MarqueeTestimonials> createState() => _MarqueeTestimonialsState();
}

class _MarqueeTestimonialsState extends State<MarqueeTestimonials> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 10));
  bool _paused = false;
  static const _items = [('Mira, barista', 'Fresh beans every time.'), ('Kyle, café owner', 'Regulars noticed at once.'), ('Leo, works from home', 'A new origin every month.')];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final run = !_paused && !kipluoReducedMotion(context);
    if (run && !_loop.isAnimating) _loop.repeat();
    if (!run) _loop.stop();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(
            child: SizedBox(
              height: 68,
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, _) {
                  final dx = -_loop.value * 160;
                  return OverflowBox(
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: Row(
                        children: [
                          for (final item in [..._items, ..._items])
                            Container(
                              width: 170,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: tokens.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: tokens.line)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('“${item.$2}”', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.line)),
                                  Text(item.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: tokens.line.withValues(alpha: 0.65))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() => _paused = !_paused);
              _sync();
              KipluoSound.play(KSound.tick, at: context, volume: 0.4, componentEnabled: widget.sound);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: tokens.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: tokens.line)),
              child: Text(_paused ? 'Resume reviews' : 'Pause reviews', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tokens.line)),
            ),
          ),
        ],
      ),
    );
  }
}
