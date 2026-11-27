import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';
import 'icon_shell.dart';

/// Metadata for the 8 live icons added in wave 5 (v3 expansion).
const List<({String slug, String title, KIconTier tier})> kipluoBespokeV3Icons = [
  (slug: 'umbrella-pop-icon', title: 'Umbrella Pop Icon', tier: KIconTier.free),
  (slug: 'battery-charge-icon', title: 'Battery Charge Icon', tier: KIconTier.premium),
  (slug: 'wifi-pulse-icon', title: 'Wifi Pulse Icon', tier: KIconTier.free),
  (slug: 'winking-moon-icon', title: 'Winking Moon Icon', tier: KIconTier.premium),
  (slug: 'rain-cloud-icon', title: 'Rain Cloud Icon', tier: KIconTier.free),
  (slug: 'drop-pin-icon', title: 'Drop Pin Icon', tier: KIconTier.free),
  (slug: 'growing-plant-icon', title: 'Growing Plant Icon', tier: KIconTier.premium),
  (slug: 'rolling-dice-icon', title: 'Rolling Dice Icon', tier: KIconTier.premium),
];

double _clamp01(double v) => v.clamp(0.0, 1.0);

/// Shared base for the v3 live icons: each one is drawn on a 48×48 canvas, like the web SVGs.
abstract class _V3Icon extends StatefulWidget {
  const _V3Icon({super.key, this.size = 56, this.label, this.onPressed, this.sound = true});

  final double size;
  final String? label;
  final VoidCallback? onPressed;
  final bool sound;
}

abstract class _V3State<W extends _V3Icon> extends State<W> with SingleTickerProviderStateMixin {
  late final KSprings s = KSprings(vsync: this, initial: initial, config: config);
  final List<Timer> _timers = [];
  int _hoverIdx = 0;
  int _streak = 0;
  DateTime? _lastTriggerAt;

  static const List<double> _hoverSteps = [0.95, 1.06, 1.15, 1.02];

  double nextHoverMul() => _hoverSteps[_hoverIdx++ % _hoverSteps.length];

  double nextComboPitch() {
    final now = DateTime.now();
    _streak = (_lastTriggerAt != null && now.difference(_lastTriggerAt!).inMilliseconds < 950)
        ? (_streak + 1) % 6
        : 0;
    _lastTriggerAt = now;
    return notePitch(_streak);
  }

  Map<String, double> get initial;
  SpringConfig get config => SpringConfig.bouncy;
  String get defaultLabel;
  String get semanticLabel => widget.label ?? defaultLabel;
  bool? get pressed => null;

  void onHover() {}
  void onExit() {}
  void onTrigger();
  void paintIcon(Canvas c, KipluoTokens t, double stroke);

  void sfx(KSound name, {double pitch = 1, double volume = 1}) =>
      KipluoSound.play(name, at: context, pitch: pitch, volume: volume, componentEnabled: widget.sound);

  void later(int ms, VoidCallback fn) {
    late final Timer timer;
    timer = Timer(Duration(milliseconds: ms), () {
      _timers.remove(timer);
      if (mounted) fn();
    });
    _timers.add(timer);
  }

  void cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void animate(Map<String, double> targets) {
    s.reducedMotion = kipluoReducedMotion(context);
    s.animateTo(targets);
  }

  @override
  void dispose() {
    cancelTimers();
    s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    Widget button = KipluoIconButton(
      label: semanticLabel,
      size: widget.size,
      onHover: onHover,
      onExit: onExit,
      onActivate: () {
        onTrigger();
        widget.onPressed?.call();
      },
      child: SizedBox.square(
        dimension: widget.size * 0.62,
        child: CustomPaint(painter: _V3Painter(state: this, t: t)),
      ),
    );
    if (pressed != null) button = Semantics(toggled: pressed, child: button);
    return button;
  }
}

class _V3Painter extends CustomPainter {
  _V3Painter({required this.state, required this.t}) : super(repaint: state.s);
  final _V3State state;
  final KipluoTokens t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48);
    state.paintIcon(canvas, t, t.stroke * 0.85);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_V3Painter old) => true;
}

Paint _fill(Color c) => Paint()..color = c;
Paint _line(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Scales about ([cx], [cy]).
void _scaleAbout(Canvas c, double cx, double cy, double sx, double sy) {
  c.translate(cx, cy);
  c.scale(sx, sy);
  c.translate(-cx, -cy);
}

/// Rotates [deg] degrees about ([cx], [cy]).
void _rotateAbout(Canvas c, double deg, double cx, double cy) {
  c.translate(cx, cy);
  c.rotate(deg * math.pi / 180);
  c.translate(-cx, -cy);
}

/* 37. Umbrella Pop Icon (Free) */

/// Canopy tilts into a few raindrops on hover; tap folds it shut and springs it back open.
class KUmbrellaPopIcon extends _V3Icon {
  const KUmbrellaPopIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KUmbrellaPopIcon> createState() => _KUmbrellaPopState();
}

class _KUmbrellaPopState extends _V3State<KUmbrellaPopIcon> {
  @override
  Map<String, double> get initial => {'open': 100, 'tilt': 0, 'fx': 0};
  @override
  String get defaultLabel => 'Umbrella Pop Icon';

  @override
  void onHover() {
    sfx(KSound.drop, pitch: 1.24 * nextHoverMul(), volume: 0.32);
    animate({'tilt': -9, 'fx': 70});
  }

  @override
  void onExit() => animate({'tilt': 0, 'fx': 0});

  @override
  void onTrigger() {
    final p = nextComboPitch();
    cancelTimers();
    sfx(KSound.whoosh, pitch: 1.15 * p, volume: 0.54);
    later(85, () => sfx(KSound.pop, pitch: 0.96 * p, volume: 0.56));
    later(155, () => sfx(KSound.splash, pitch: 1.12 * p, volume: 0.38));
    s.set({'open': 18, 'tilt': 0, 'fx': 100});
    animate({'open': 100, 'fx': 0});
  }

  @override
  void paintIcon(Canvas c, KipluoTokens t, double w) {
    final f = _clamp01(s['fx'] / 100);
    if (f > 0.01) {
      c.save();
      c.translate(0, (1 - f) * 6);
      final p = _line(t.accent.withValues(alpha: f), w);
      c.drawLine(const Offset(10, 6), const Offset(9, 9), p);
      c.drawLine(const Offset(38, 5), const Offset(37, 8), p);
      c.drawLine(const Offset(24, 2), const Offset(23, 5), p);
      c.restore();
    }
    c.drawPath(
      Path()
        ..moveTo(24, 13)
        ..lineTo(24, 35)
        ..arcToPoint(const Offset(17, 35), radius: const Radius.circular(3.5)),
      _line(t.line, w),
    );
    final o = math.max(0.15, s['open'] / 100);
    c.save();
    _rotateAbout(c, s['tilt'], 24, 36);
    _scaleAbout(c, 24, 12, o, 0.7 + o * 0.3);
    final canopy = Path()
      ..moveTo(7, 25)
      ..cubicTo(7, 15, 15, 9, 24, 9)
      ..cubicTo(33, 9, 41, 15, 41, 25)
      ..cubicTo(38, 22, 34, 22, 31, 25)
      ..cubicTo(28, 22, 20, 22, 17, 25)
      ..cubicTo(14, 22, 10, 22, 7, 25)
      ..close();
    c.drawPath(canopy, _fill(t.accent));
    c.drawPath(canopy, _line(t.line, w));
    c.drawPath(
      Path()
        ..moveTo(24, 9)
        ..cubicTo(20, 13, 17, 19, 17, 25)
        ..moveTo(24, 9)
        ..cubicTo(28, 13, 31, 19, 31, 25),
      _line(t.line, w),
    );
    c.restore();
  }
}

/* 39. Wifi Pulse Icon (Free) */

/// Signal arcs fade in from the dot on hover; tap sends a pulse rippling outward ring by ring.
class KWifiPulseIcon extends _V3Icon {
  const KWifiPulseIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KWifiPulseIcon> createState() => _KWifiPulseState();
}

class _KWifiPulseState extends _V3State<KWifiPulseIcon> {
  @override
  Map<String, double> get initial => {'a0': 100, 'a1': 100, 'a2': 100, 'dot': 0};
  @override
  String get defaultLabel => 'Wifi Pulse Icon';

  @override
  void onHover() {
    sfx(KSound.blip, pitch: 1.28 * nextHoverMul(), volume: 0.28);
    s.set({'a0': 20, 'a1': 20, 'a2': 20});
    animate({'a0': 100, 'a1': 100, 'a2': 100});
  }

  @override
  void onExit() => animate({'a0': 100, 'a1': 100, 'a2': 100});

  @override
  void onTrigger() {
    final p = nextComboPitch();
    s.set({'dot': 100, 'a0': 30, 'a1': 30, 'a2': 30});
    animate({'dot': 0});
    sfx(KSound.pop, pitch: 1.18 * p, volume: 0.5);
    // Rings light up from the dot outward, one after another.
    cancelTimers();
    for (var i = 0; i < 3; i++) {
      later(i * 90, () {
        animate({'a$i': 160});
        sfx(KSound.blip, pitch: (0.95 + i * 0.22) * p, volume: 0.42);
        later(160, () => animate({'a$i': 100}));
      });
    }
    later(270, () => sfx(KSound.space, pitch: 1.2 * p, volume: 0.34));
  }

  @override
  void paintIcon(Canvas c, KipluoTokens t, double w) {
    const arcs = [
      (start: Offset(18, 31), end: Offset(30, 31), r: 8.5),
      (start: Offset(12.5, 25), end: Offset(35.5, 25), r: 16.0),
      (start: Offset(7, 19), end: Offset(41, 19), r: 24.0),
    ];
    for (var i = 0; i < 3; i++) {
      final a = s['a$i'];
      final k = _clamp01(a / 100);
      final colour = (k > 0.5 ? t.accent : t.line).withValues(alpha: _clamp01(0.35 + k * 0.65));
      c.save();
      final sc = 1 + (a / 100) * 0.08;
      _scaleAbout(c, 24, 36, sc, sc);
      c.drawPath(Path()..moveTo(arcs[i].start.dx, arcs[i].start.dy)..arcToPoint(arcs[i].end, radius: Radius.circular(arcs[i].r)), _line(colour, w));
      c.restore();
    }
    final r = 3 + (s['dot'] / 100) * 1.6;
    c.drawCircle(const Offset(24, 37), r, _fill(t.accent));
    c.drawCircle(const Offset(24, 37), r, _line(t.line, w));
  }
}

/* 41. Rain Cloud Icon (Free) */

/// Cloud puffs up and drifts on hover; tap squeezes it and three staggered drops fall and fade.
class KRainCloudIcon extends _V3Icon {
  const KRainCloudIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KRainCloudIcon> createState() => _KRainCloudState();
}

class _KRainCloudState extends _V3State<KRainCloudIcon> {
  @override
  Map<String, double> get initial => {'puff': 0, 'rain': 0, 'x': 0};
  @override
  SpringConfig get config => const SpringConfig(stiffness: 150, damping: 15);
  @override
  String get defaultLabel => 'Rain Cloud Icon';

  @override
  void onHover() {
    sfx(KSound.whoosh, pitch: 1.05 * nextHoverMul(), volume: 0.3);
    animate({'puff': 60, 'x': 1.5});
  }

  @override
  void onExit() => animate({'puff': 0, 'x': 0});

  @override
  void onTrigger() {
    final p = nextComboPitch();
    cancelTimers();
    sfx(KSound.pour, pitch: 1.05 * p, volume: 0.36);
    const pitches = [1.08, 1.32, 1.18];
    for (var i = 0; i < 3; i++) {
      later(75 + i * 100, () => sfx(i == 1 ? KSound.splash : KSound.drop, pitch: pitches[i] * p, volume: 0.46));
    }
    s.set({'puff': -80, 'rain': 0});
    animate({'puff': 0, 'rain': 100});
  }

  @override
  void paintIcon(Canvas c, KipluoTokens t, double w) {
    const drops = [15.0, 23.0, 31.0];
    for (var i = 0; i < 3; i++) {
      // Each drop starts a little later, falls and fades out.
      final k = _clamp01((s['rain'] - i * 14) / 72);
      final o = k > 0 && k < 1 ? 1 - k * k : 0.0;
      if (o <= 0) continue;
      final dy = k * 12;
      c.drawLine(Offset(drops[i], 31 + dy), Offset(drops[i] - 1, 35 + dy), _line(t.accent.withValues(alpha: o), w));
    }
    final p = s['puff'] / 100;
    c.save();
    c.translate(s['x'], 0);
    _scaleAbout(c, 24, 22, 1 + p * 0.06, 1 - p * 0.05);
    final cloud = Path()
      ..moveTo(14, 31)
      ..arcToPoint(const Offset(13.5, 17), radius: const Radius.circular(7))
      ..arcToPoint(const Offset(32.5, 15), radius: const Radius.circular(10))
      ..arcToPoint(const Offset(34.5, 31), radius: const Radius.circular(8))
      ..close();
    c.drawPath(cloud, _fill(t.surface));
    c.drawPath(cloud, _line(t.line, w));
    c.restore();
  }
}

/* 42. Drop Pin Icon (Free) */

/// Pin lifts as its shadow shrinks on hover; tap drops it from height with stretch, a squash on
/// landing and a ground ripple.
class KDropPinIcon extends _V3Icon {
  const KDropPinIcon({super.key, super.size, super.label, super.onPressed, super.sound});
  @override
  State<KDropPinIcon> createState() => _KDropPinState();
}

class _KDropPinState extends _V3State<KDropPinIcon> {
  @override
  Map<String, double> get initial => {'y': 0, 'ring': 0};
  @override
  SpringConfig get config => const SpringConfig(stiffness: 340, damping: 13);
  @override
  String get defaultLabel => 'Drop Pin Icon';

  @override
  void onHover() {
    sfx(KSound.boop, pitch: 1.24 * nextHoverMul(), volume: 0.32);
    animate({'y': -4});
  }

  @override
  void onExit() => animate({'y': 0});

  @override
  void onTrigger() {
    final p = nextComboPitch();
    cancelTimers();
    sfx(KSound.whoosh, pitch: 1.32 * p, volume: 0.42);
    later(155, () => sfx(KSound.clack, pitch: 0.96 * p, volume: 0.5));
    later(195, () => sfx(KSound.drop, pitch: 1.1 * p, volume: 0.46));
    s.set({'y': -16, 'ring': 0});
    animate({'y': 0});
    later(150, () {
      s.set({'ring': 1});
      animate({'ring': 100});
    });
  }

  @override
  void paintIcon(Canvas c, KipluoTokens t, double w) {
    final y = s['y'];
    // Per-frame movement (the web measures it between frames): squash landing, stretch falling.
    final v = s.spring('y').velocity / 60;
    final near = y > -2;
    final sq = near && v > 0 ? math.min(0.22, v * 0.09) : 0.0;
    final st = !near ? math.min(0.12, v.abs() * 0.03) : 0.0;

    final r = _clamp01(s['ring'] / 100);
    if (r > 0 && r < 1) {
      c.drawOval(Rect.fromCenter(center: const Offset(24, 39), width: (5 + r * 12) * 2, height: (1.5 + r * 3.5) * 2), _line(t.accent.withValues(alpha: 1 - r), w));
    }
    final h = _clamp01(-y / 14);
    c.drawOval(Rect.fromCenter(center: const Offset(24, 39), width: (7 - h * 3.5) * 2, height: 4), _fill(t.line.withValues(alpha: _clamp01(0.35 - h * 0.2))));

    c.save();
    c.translate(0, y);
    _scaleAbout(c, 24, 38, 1 + sq - st * 0.5, 1 - sq + st);
    final pin = Path()
      ..moveTo(24, 38)
      ..cubicTo(18, 30, 13, 25, 13, 19)
      ..arcToPoint(const Offset(35, 19), radius: const Radius.circular(11))
      ..cubicTo(35, 25, 30, 30, 24, 38)
      ..close();
    c.drawPath(pin, _fill(t.accent));
    c.drawPath(pin, _line(t.line, w));
    c.drawCircle(const Offset(24, 19), 4, _fill(t.surface));
    c.drawCircle(const Offset(24, 19), 4, _line(t.line, w));
    c.restore();
  }
}
