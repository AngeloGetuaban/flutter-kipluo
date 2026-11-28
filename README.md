# Kipluo for Flutter

Interactive Flutter widgets with real spring physics, touch gestures and synthesized spatial sound. They keep behaving when people drag, fling, spam and interrupt them.

This package is the free part of [Kipluo](https://kipluo.com): the engine plus 78 free widgets and loaders and 638 free animated icons. Premium widgets install as Dart source from [kipluo.com](https://kipluo.com/pricing).

```bash
flutter pub add kipluo
```

## Quick start

```dart
import 'package:kipluo/kipluo.dart';

KipluoTheme(
  style: KipluoStyle.playful, // or minimal, mono
  child: SpringToggle(
    value: notificationsOn,
    label: 'Notifications',
    onChanged: (v) => setState(() => notificationsOn = v),
  ),
)
```

## What's free

- **Interactions:** MagneticSurface, HoldToConfirm, TiltCard, ElasticAccordion, SwipeToUnlock, InfiniteMarquee, ExpandableSearchPill, ElasticStepTracker, SpringDrawerHandle, SpringSplitPane, SpotlightBentoCard, SignaturePad, Flip3DCard
- **Feedback:** FavoriteToggle, CopyFeedback, ConfettiBurst, ShakeInput, SuccessCheck, ReactionPickerBar, InlineStatusPill, SpringTooltip, InlineConfirmPill, BannerAnnouncement, StepChecklistCard
- **Controls:** SpringToggle, AnimatedTabs, StepperInput, StarRating, JellyCheckbox, OtpInput, SpringSegmentedControl, TagChipInput, PullChainToggle, SpringDateStrip, SpringMultiSelect, SpringCombobox, TactileRadioCards, SpringColorSwatches, PillFilterBar, Floating3DNav
- **Numbers:** RollingCounter, SpringBadgeCount, CountUpStat, CountdownRing, SlotMachineCounter, MilestoneOdometer, BatteryLevelMeter, CountdownBlocks
- **Charts:** DonutProgress, SpringSparkline, StackedProgressBar, SpringWaffleChart, SpringAreaSpark, StackedBarChart, WaterfallDeltaChart
- **Loaders:** WormLoader, PixelProgressLoader, PaperPlaneLoader, TypingIndicator, BouncingCubeLoader, HourglassSandLoader, PendulumCradleLoader, VinylSpinLoader, IsometricCubeGridLoader, BrickBar3DLoader, KineticSpheres3DLoader
- **Shaders:** FlutedGlassShader, MeshSilkShader
- **Backgrounds:** AuroraBeamsBackground, SpotlightGridBackground
- **Heroes:** EditorialSplitHero, ShaderHorizonHero
- **Features:** LiveBentoFeatures, TabbedFeatureMatrix
- **Pricing:** ToggleTierPricing, SegmentedPlanPricing
- **Testimonials:** CoverflowTestimonials, MarqueeTestimonials
- **Icons:** free bespoke icons such as `KBellIcon()` and `KHeartIcon()`, plus the free icon pack: `KipluoIcon.bySlug('user-icon')`

Browse all of them, live, at [kipluo.com/browse](https://kipluo.com/browse).

## Styles, colours and shadow

`KipluoTheme` sets the style (`playful`, `minimal`, `mono`), colours (`KipluoColorOverrides`) and shadow (`KipluoShadow`) for every Kipluo widget below it. Nest it to theme one section, or wrap a single widget.

## Sound

Every widget has small synthesized sounds, panned toward where the interaction happened. Turn them off for one widget with `sound: false`, or for the whole app:

```dart
KipluoSound.enabled.value = false;
```

## Premium widgets

Premium widgets (Physics Card Stack, Swipe Action, Gauge Meter, Radar Chart, and the rest) and the premium icons install into `lib/kipluo/` as editable source, on top of this package:

```bash
npx kipluo login <license-key>
npx kipluo add physics-card-stack --flutter
```

See [kipluo.com/pricing](https://kipluo.com/pricing).

## License

This package is MIT licensed. Premium widgets are covered by the [Kipluo license](https://kipluo.com/license).
