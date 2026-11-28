import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* ==========================================================================
   Wave 13 — Five Interactive Pricing Section Widgets
   1. ToggleTierPricing (Free)
   2. AddonCalculatorPricing (Paid)
   3. SegmentedPlanPricing (Free)
   4. LifetimePassPricing (Paid)
   5. ComparisonMatrixPricing (Paid)
   ========================================================================== */

/* 1. ToggleTierPricing (Free) */
class ToggleTierPricing extends StatefulWidget {
  const ToggleTierPricing({super.key, this.initialAnnual = true, this.onSelectPlan, this.sound = true});
  final bool initialAnnual;
  final void Function(String plan, bool annual)? onSelectPlan;
  final bool sound;

  @override
  State<ToggleTierPricing> createState() => _ToggleTierPricingState();
}

class _ToggleTierPricingState extends State<ToggleTierPricing> with TickerProviderStateMixin {
  late bool _annual = widget.initialAnnual;
  String _chosen = 'pro';
  static const _tiers = [
    ('starter', 'Starter', 19.0, 15.0, false, 'Up to 3 projects'),
    ('pro', 'Pro', 49.0, 39.0, true, 'Unlimited projects'),
    ('scale', 'Scale', 129.0, 99.0, false, 'SSO and audit log'),
  ];
  late final KSprings _springs = KSprings(
    vsync: this,
    initial: {'p0': _annual ? 15.0 : 19.0, 'p1': _annual ? 39.0 : 49.0, 'p2': _annual ? 99.0 : 129.0},
    config: SpringConfig.snappy,
  );

  void _toggleBilling() {
    setState(() => _annual = !_annual);
    _springs.reducedMotion = kipluoReducedMotion(context);
    _springs.animateTo({'p0': _annual ? 15.0 : 19.0, 'p1': _annual ? 39.0 : 49.0, 'p2': _annual ? 99.0 : 129.0});
    KipluoSound.play(KSound.boop, at: context, pitch: _annual ? 1.22 : 0.9, volume: 0.45, componentEnabled: widget.sound);
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
            onTap: _toggleBilling,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Monthly', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.line.withValues(alpha: _annual ? 0.55 : 1))),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 22,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: _annual ? tokens.accent : tokens.track, borderRadius: BorderRadius.circular(999), border: Border.all(color: tokens.line)),
                  child: AnimatedAlign(
                    duration: kipluoReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 160),
                    alignment: _annual ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(width: 16, height: 16, decoration: BoxDecoration(color: tokens.surface, shape: BoxShape.circle, border: Border.all(color: tokens.line))),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Annual', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.line.withValues(alpha: _annual ? 1 : 0.55))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _springs,
            builder: (context, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_tiers.length, (i) {
                final t = _tiers[i];
                final pop = t.$5;
                final sel = _chosen == t.$1;
                final fg = pop ? tokens.surface : tokens.line;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pop ? tokens.line : tokens.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tokens.line),
                      boxShadow: shadows,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: fg)),
                        const SizedBox(height: 4),
                        Text('\$${_springs['p$i'].round()}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: fg)),
                        Text(t.$6, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.78))),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() => _chosen = t.$1);
                            widget.onSelectPlan?.call(t.$1, _annual);
                            KipluoSound.play(pop ? KSound.chime : KSound.pop, at: context, volume: 0.45, componentEnabled: widget.sound);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: pop || sel ? tokens.accent : tokens.track,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: pop ? tokens.surface : tokens.line),
                            ),
                            child: Text(
                              sel ? 'Selected' : 'Choose',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: pop || sel ? tokens.accentInk : tokens.line),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/* 3. SegmentedPlanPricing (Free) */
class SegmentedPlanPricing extends StatefulWidget {
  const SegmentedPlanPricing({super.key, this.sound = true});
  final bool sound;

  @override
  State<SegmentedPlanPricing> createState() => _SegmentedPlanPricingState();
}

class _SegmentedPlanPricingState extends State<SegmentedPlanPricing> with TickerProviderStateMixin {
  int _idx = 1;
  static const _plans = [('Starter', 29.0, 'For solo creators'), ('Growth', 79.0, 'Teams of up to 5'), ('Scale', 199.0, 'For organisations')];
  late final KSprings _springs = KSprings(vsync: this, initial: {'price': 79.0}, config: SpringConfig.snappy);

  @override
  void dispose() {
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final shadows = KipluoTheme.shadowOf(context);
    final cur = _plans[_idx];

    return Container(
      constraints: const BoxConstraints(maxWidth: 540),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tokens.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: tokens.line), boxShadow: shadows),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: tokens.track, borderRadius: BorderRadius.circular(999), border: Border.all(color: tokens.line)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_plans.length, (i) {
                final active = i == _idx;
                return GestureDetector(
                  onTap: () {
                    setState(() => _idx = i);
                    _springs.reducedMotion = kipluoReducedMotion(context);
                    _springs.animateTo({'price': _plans[i].$2});
                    KipluoSound.play(KSound.tick, at: context, pitch: 0.92 + i * 0.12, volume: 0.44, componentEnabled: widget.sound);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: active ? tokens.accent : Colors.transparent, borderRadius: BorderRadius.circular(999), border: active ? Border.all(color: tokens.line) : null),
                    child: Text(_plans[i].$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? tokens.accentInk : tokens.line)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cur.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tokens.line.withValues(alpha: 0.75))),
                    const SizedBox(height: 4),
                    Text('✓ Unlimited downloads', style: TextStyle(fontSize: 11, color: tokens.line)),
                    Text('✓ Commercial license', style: TextStyle(fontSize: 11, color: tokens.line)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: tokens.track, borderRadius: BorderRadius.circular(14), border: Border.all(color: tokens.line)),
                child: AnimatedBuilder(
                  animation: _springs,
                  builder: (context, _) => Text('\$${_springs['price'].round()}/mo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: tokens.line)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
