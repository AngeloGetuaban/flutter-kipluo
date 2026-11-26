// Kipluo spring integrator — a line-for-line port of apps/web/src/lib/spring.ts.
// Semi-implicit Euler with a fixed timestep, so a component feels identical on the web and in Flutter.

/// Physical spring parameters. Same units and presets as the web engine.
class SpringConfig {
  const SpringConfig({required this.stiffness, required this.damping, this.mass = 1});

  final double stiffness;
  final double damping;
  final double mass;

  /// Small things: quick, little overshoot.
  static const snappy = SpringConfig(stiffness: 420, damping: 30);

  /// Rewards and landings: visible overshoot.
  static const bouncy = SpringConfig(stiffness: 260, damping: 14);

  /// Heavy panels.
  static const gentle = SpringConfig(stiffness: 140, damping: 20);
}

const double _step = 1 / 120;
const double _restVelocity = 0.02;
const double _restDistance = 0.02;

/// One animated value.
class Spring1D {
  Spring1D([this.value = 0]) : target = value;

  double value;
  double velocity = 0;
  double target;

  /// Advance by [dt] seconds. Returns true while still moving.
  bool step(SpringConfig cfg, double dt) {
    var remaining = dt > 1 / 20 ? 1 / 20 : dt; // clamp long frames (app resumed)
    while (remaining > 0) {
      final h = remaining < _step ? remaining : _step;
      final force = -cfg.stiffness * (value - target) - cfg.damping * velocity;
      velocity += (force / cfg.mass) * h;
      value += velocity * h;
      remaining -= h;
    }
    final moving = velocity.abs() > _restVelocity || (value - target).abs() > _restDistance;
    if (!moving) {
      value = target;
      velocity = 0;
    }
    return moving;
  }

  /// Jump to [v] with no motion (used while a finger is driving the value).
  void snap(double v) {
    value = v;
    target = v;
    velocity = 0;
  }
}
