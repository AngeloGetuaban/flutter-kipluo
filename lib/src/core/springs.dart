import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'spring.dart';

/// A set of named springs on one [Ticker] — the Flutter equivalent of the web `useSprings` hook.
///
/// Values live in a [ValueListenable], so widgets repaint through `ValueListenableBuilder` or a
/// `CustomPainter(repaint: springs)` without rebuilding the tree each frame. The ticker runs only
/// while something is moving.
class KSprings extends ChangeNotifier {
  KSprings({
    required TickerProvider vsync,
    required Map<String, double> initial,
    this.config = SpringConfig.snappy,
  }) : _springs = {for (final e in initial.entries) e.key: Spring1D(e.value)} {
    _ticker = vsync.createTicker(_tick);
  }

  final Map<String, Spring1D> _springs;
  SpringConfig config;

  /// When true (reduced motion), [animateTo] jumps straight to the target.
  bool reducedMotion = false;

  late final Ticker _ticker;
  Duration? _last;

  double operator [](String key) => _springs[key]!.value;
  Spring1D spring(String key) => _springs[key]!;

  /// Animate toward [targets], optionally starting with [velocity] (e.g. a fling).
  void animateTo(Map<String, double> targets, {Map<String, double>? velocity}) {
    targets.forEach((k, v) => _springs[k]!.target = v);
    velocity?.forEach((k, v) => _springs[k]!.velocity = v);
    if (reducedMotion) {
      for (final s in _springs.values) {
        s.snap(s.target);
      }
      notifyListeners();
      return;
    }
    if (!_ticker.isActive) {
      _last = null;
      _ticker.start();
    }
  }

  /// Jump without animating.
  void set(Map<String, double> values) {
    values.forEach((k, v) => _springs[k]!.snap(v));
    notifyListeners();
  }

  void _tick(Duration elapsed) {
    final dt = _last == null ? 1 / 60 : (elapsed - _last!).inMicroseconds / 1e6;
    _last = elapsed;
    var moving = false;
    for (final s in _springs.values) {
      if (s.step(config, dt)) moving = true;
    }
    notifyListeners();
    if (!moving) _ticker.stop();
  }

  bool get isAnimating => _ticker.isActive;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
