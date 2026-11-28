import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* ==========================================================================
   Wave 12 — Five Interactive Feature Section Widgets
   1. LiveBentoFeatures (Free)
   2. TabbedFeatureMatrix (Free)
   3. SpotlightFeatureGrid (Paid)
   4. AlternatingFeatureRows (Paid)
   5. IDEBentoFeatures (Paid)
   ========================================================================== */

/* 1. LiveBentoFeatures (Free) */
class LiveBentoFeatures extends StatefulWidget {
  const LiveBentoFeatures({super.key, this.sound = true});
  final bool sound;

  @override
  State<LiveBentoFeatures> createState() => _LiveBentoFeaturesState();
}

class _LiveBentoFeaturesState extends State<LiveBentoFeatures> {
  bool _autoSync = true;
  int _boost = 72;
  bool _secured = true;

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final shadows = KipluoTheme.shadowOf(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _autoSync = !_autoSync);
                    KipluoSound.play(KSound.boop, at: context, pitch: _autoSync ? 1.25 : 0.9, volume: 0.45, componentEnabled: widget.sound);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: tokens.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: tokens.line), boxShadow: shadows),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('21°C', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: tokens.line)),
                            Container(
                              width: 34,
                              height: 18,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _autoSync ? tokens.accent : tokens.track,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: tokens.line),
                              ),
                              child: AnimatedAlign(
                                duration: kipluoReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 160),
                                alignment: _autoSync ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(width: 12, height: 12, decoration: BoxDecoration(color: tokens.surface, shape: BoxShape.circle, border: Border.all(color: tokens.line))),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Living room heating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.line)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _boost = _boost >= 96 ? 48 : _boost + 16);
                    KipluoSound.play(KSound.drop, at: context, pitch: 0.9 + (_boost / 100) * 0.4, volume: 0.45, componentEnabled: widget.sound);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: tokens.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: tokens.line), boxShadow: shadows),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Energy saved', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tokens.line.withValues(alpha: 0.7))),
                            Text('$_boost%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: tokens.line)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(color: tokens.track, borderRadius: BorderRadius.circular(999), border: Border.all(color: tokens.line)),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _boost / 100,
                            child: DecoratedBox(decoration: BoxDecoration(color: tokens.accent, borderRadius: BorderRadius.circular(999))),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Tap to refresh', style: TextStyle(fontSize: 11, color: tokens.line.withValues(alpha: 0.72))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _secured = !_secured);
                    KipluoSound.play(_secured ? KSound.chime : KSound.tick, at: context, volume: 0.42, componentEnabled: widget.sound);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: tokens.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: tokens.line), boxShadow: shadows),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: _secured ? tokens.ok : tokens.track, borderRadius: BorderRadius.circular(999)),
                          child: Text(_secured ? 'Locked' : 'Unlocked', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _secured ? Colors.white : tokens.line)),
                        ),
                        const SizedBox(height: 6),
                        Text('Front door', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tokens.line)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: tokens.accent, borderRadius: BorderRadius.circular(16), border: Border.all(color: tokens.line), boxShadow: shadows),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shared with family', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: tokens.accentInk)),
                      const SizedBox(height: 4),
                      Text('Everyone hears when the door unlocks.', style: TextStyle(fontSize: 11, color: tokens.accentInk.withValues(alpha: 0.85))),
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

/* 2. TabbedFeatureMatrix (Free) */
class TabbedFeatureMatrix extends StatefulWidget {
  const TabbedFeatureMatrix({super.key, this.sound = true});
  final bool sound;

  @override
  State<TabbedFeatureMatrix> createState() => _TabbedFeatureMatrixState();
}

class _TabbedFeatureMatrixState extends State<TabbedFeatureMatrix> {
  int _idx = 0;
  static const _tabs = [
    ('Planning', [('Shared boards', 'Edits land live'), ('Timeline view', 'Dependencies follow'), ('Guest access', 'Free client seats')]),
    ('Automation', [('Recurring tasks', 'Reports write themselves'), ('Smart reminders', 'Only when late'), ('Status sync', 'Merges close tasks')]),
    ('Security', [('Single sign-on', 'Company accounts'), ('Audit log', 'Who changed what'), ('Data residency', 'EU or US')]),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final shadows = KipluoTheme.shadowOf(context);
    final cards = _tabs[_idx].$2;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: tokens.track, borderRadius: BorderRadius.circular(999), border: Border.all(color: tokens.line)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_tabs.length, (i) {
                final active = i == _idx;
                return GestureDetector(
                  onTap: () {
                    setState(() => _idx = i);
                    KipluoSound.play(KSound.tick, at: context, pitch: 0.92 + i * 0.12, volume: 0.45, componentEnabled: widget.sound);
                  },
                  child: AnimatedContainer(
                    duration: kipluoReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? tokens.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: active ? Border.all(color: tokens.line) : null,
                    ),
                    child: Text(_tabs[i].$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? tokens.accentInk : tokens.line)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(cards.length, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: tokens.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: tokens.line), boxShadow: shadows),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('0${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tokens.line.withValues(alpha: 0.6))),
                      const SizedBox(height: 3),
                      Text(cards[i].$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: tokens.line), overflow: TextOverflow.ellipsis),
                      Text(cards[i].$2, style: TextStyle(fontSize: 10, color: tokens.line.withValues(alpha: 0.72)), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
