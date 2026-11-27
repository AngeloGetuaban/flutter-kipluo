import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/theme.dart';

/* 18. Spotlight Bento Card (Free) */

class SpotlightBentoCard extends StatefulWidget {
  const SpotlightBentoCard({super.key, this.title = '120Hz Springs', this.metric = '0.4ms', this.sound = true});
  final String title;
  final String metric;
  final bool sound;

  @override
  State<SpotlightBentoCard> createState() => _SpotlightBentoCardState();
}

class _SpotlightBentoCardState extends State<SpotlightBentoCard> {
  Offset _spot = const Offset(118, 56);
  int _clicks = 0;
  int _burst = 0;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return MouseRegion(
      onHover: (e) => setState(() => _spot = e.localPosition),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _clicks++;
            _burst++;
          });
          KipluoSound.play(KSound.pop, at: context, pitch: notePitch(_clicks % 5), volume: 0.48, componentEnabled: widget.sound);
        },
        child: Container(
          width: 236,
          height: 116,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.line, width: t.stroke),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment((_spot.dx / 236) * 2 - 1, (_spot.dy / 116) * 2 - 1),
                      radius: 0.9,
                      colors: [t.accent.withValues(alpha: 0.36), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Center(child: KipluoAuraBurst(burstKey: _burst, size: 108, rays: 10)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('BENTO', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.line))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(99), border: Border.all(color: t.line, width: 1.5)),
                          child: Text(widget.metric, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: t.accentInk)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: t.line)),
                        Text(_clicks > 0 ? 'Pinged ×$_clicks' : 'Tap for aura', style: TextStyle(fontSize: 10, color: t.line.withValues(alpha: 0.75))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
