import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Soft limit: grows linearly at first, then approaches [limit] asymptotically.
double _rubber(double d, double limit) => limit * (1 - 1 / (d / limit + 1));

double _tanh(double x) {
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

/* 2. Pull Chain Toggle (Free) */

/// A lamp switch you actually pull. Drag the bead down past the click point and let go: the chain
/// recoils on a spring, swings like a pendulum and the light flips. Short pulls snap back without
/// toggling. A tap, Enter or Space gives it a full pull.
class PullChainToggle extends StatefulWidget {
  const PullChainToggle({
    super.key,
    this.value,
    this.initialValue = false,
    this.onChanged,
    this.label = 'Desk lamp',
    this.threshold = 30,
    this.size = 180,
    this.sound = true,
  });

  /// Controlled state. Leave null to let the toggle keep its own state.
  final bool? value;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  /// Accessible name and caption.
  final String label;

  /// Pull distance (about logical px at the default size) that clicks the switch.
  final double threshold;

  /// Height in logical px; the width follows at 2:3.
  final double size;
  final bool sound;

  @override
  State<PullChainToggle> createState() => _PullChainToggleState();
}

class _PullChainToggleState extends State<PullChainToggle> with TickerProviderStateMixin {
  // Vertical recoil is stiff and bouncy; the sideways swing is a loose pendulum.
  late final KSprings _pull = KSprings(vsync: this, initial: {'y': 0}, config: const SpringConfig(stiffness: 380, damping: 11));
  late final KSprings _swing = KSprings(vsync: this, initial: {'x': 0}, config: const SpringConfig(stiffness: 85, damping: 3.4));
  late bool _inner = widget.initialValue;
  bool _armed = false;
  Offset? _start;
  bool _moved = false;
  bool _focused = false;
  Timer? _pop;
  final _rng = math.Random();

  bool get _on => widget.value ?? _inner;
  double get _scale => 180 / widget.size; // screen px -> viewBox units

  @override
  void dispose() {
    _pop?.cancel();
    _pull.dispose();
    _swing.dispose();
    super.dispose();
  }

  void _sfx(KSound s, {double pitch = 1, double volume = 1}) =>
      KipluoSound.play(s, at: context, pitch: pitch, volume: volume, componentEnabled: widget.sound);

  void _motion() {
    final reduced = kipluoReducedMotion(context);
    _pull.reducedMotion = reduced;
    _swing.reducedMotion = reduced;
  }

  void _flip() {
    final next = !_on;
    if (widget.value == null) setState(() => _inner = next);
    widget.onChanged?.call(next);
    _sfx(KSound.click, pitch: next ? 1.1 : 0.82);
    if (next) {
      _pop?.cancel();
      _pop = Timer(const Duration(milliseconds: 60), () {
        if (mounted) _sfx(KSound.pop, pitch: 1.4, volume: 0.35);
      });
    }
  }

  /// A full pull without a drag (tap, Enter, Space): kick the chain down and let it recoil.
  void _kick() {
    _flip();
    _motion();
    _pull.animateTo({'y': 0}, velocity: {'y': 520});
    _swing.animateTo({'x': 0}, velocity: {'x': (_rng.nextBool() ? 1 : -1) * 60});
  }

  void _down(DragDownDetails d) {
    _start = d.localPosition;
    _moved = false;
    _armed = false;
    _sfx(KSound.tick, pitch: 0.8, volume: 0.35);
  }

  void _update(DragUpdateDetails d) {
    if (_start == null) return;
    final dx = (d.localPosition.dx - _start!.dx) * _scale;
    final dy = (d.localPosition.dy - _start!.dy) * _scale;
    if (math.sqrt(dx * dx + dy * dy) > 4) _moved = true;
    final th = widget.threshold;
    final y = dy <= 0 ? -_rubber(-dy, 8) : (dy < th ? dy : th + _rubber(dy - th, 22));
    final x = 16 * _tanh(dx / 42);
    final armed = dy >= th;
    if (armed != _armed) {
      _armed = armed;
      _sfx(KSound.tick, pitch: armed ? 1.35 : 1, volume: 0.5);
    }
    _pull.set({'y': y});
    _swing.set({'x': x});
  }

  void _end(DragEndDetails d) {
    if (_start == null) return;
    _start = null;
    if (!_moved) {
      _kick();
      return;
    }
    final vx = d.velocity.pixelsPerSecond.dx;
    final armed = _armed;
    _armed = false;
    if (armed) {
      _flip();
    } else {
      _sfx(KSound.boopLow, volume: 0.35);
    }
    // Armed: the chain jerks back up past rest. Not armed: it just settles.
    _motion();
    _pull.animateTo({'y': 0}, velocity: {'y': armed ? -420 : 0});
    _swing.animateTo({'x': 0}, velocity: {'x': vx * _scale * 0.25 + (armed ? 40 : 0)});
  }

  void _cancel() {
    _start = null;
    _armed = false;
    _motion();
    _pull.animateTo({'y': 0});
    _swing.animateTo({'x': 0});
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final reduced = kipluoReducedMotion(context);
    final lamp = FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _kick())},
      mouseCursor: SystemMouseCursors.grab,
      child: GestureDetector(
        excludeFromSemantics: true,
        dragStartBehavior: DragStartBehavior.down,
        onTap: _kick,
        onPanDown: _down,
        onPanUpdate: _update,
        onPanEnd: _end,
        onPanCancel: () {
          if (_moved) _cancel();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _focused ? [BoxShadow(color: KipluoColors.ring.withValues(alpha: 0.6), spreadRadius: 3)] : null,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _on ? 1 : 0),
            duration: reduced ? Duration.zero : const Duration(milliseconds: 260),
            builder: (context, glow, _) => CustomPaint(
              size: Size(widget.size * 2 / 3, widget.size),
              painter: _LampPainter(pull: _pull, swing: _swing, glow: glow, armed: () => _armed, t: t),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      toggled: _on,
      label: widget.label,
      onTap: _kick,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          lamp,
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Text(
              '${widget.label}: ${_on ? 'on' : 'off'}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.line.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LampPainter extends CustomPainter {
  _LampPainter({required this.pull, required this.swing, required this.glow, required this.armed, required this.t}) : super(repaint: Listenable.merge([pull, swing]));

  final KSprings pull, swing;
  final double glow;
  final bool Function() armed;
  final KipluoTokens t;

  static const _ax = 82.0, _ay = 38.0, _rest = 62.0, _beads = 10;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 180);
    final stroke = Paint()
      ..color = t.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = t.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // light cone
    if (glow > 0.01) {
      final cone = Path()
        ..moveTo(40, 40)
        ..lineTo(12, 172)
        ..lineTo(108, 172)
        ..lineTo(80, 40)
        ..close();
      canvas.drawPath(
        cone,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.accent.withValues(alpha: 0.75 * 0.55 * glow), t.accent.withValues(alpha: 0)],
          ).createShader(const Rect.fromLTWH(12, 40, 96, 132)),
      );
    }
    // ceiling cord + shade
    canvas.drawLine(const Offset(60, 0), const Offset(60, 14), stroke);
    final bulb = Color.lerp(t.track, t.accent, glow)!;
    canvas.drawCircle(const Offset(60, 42), 8, Paint()..color = bulb);
    canvas.drawCircle(const Offset(60, 42), 8, stroke);
    final shade = Path()
      ..moveTo(36, 40)
      ..lineTo(46, 14)
      ..lineTo(74, 14)
      ..lineTo(84, 40)
      ..close();
    canvas.drawPath(shade, Paint()..color = t.surface);
    canvas.drawPath(shade, stroke);

    // chain: beads spread along it and bow sideways while it swings
    final x = swing['x'], y = pull['y'];
    final hx = _ax + x, hy = _ay + _rest + y;
    final bead = Paint()..color = t.line;
    for (var i = 0; i < _beads; i++) {
      final k = (i + 1) / (_beads + 1);
      final bow = math.sin(math.pi * k) * x * 0.22;
      canvas.drawCircle(Offset(_ax + (hx - _ax) * k - bow, _ay + (hy - _ay) * k), 1.9, bead);
    }
    final tilt = math.atan2(x, _rest + y) * -1;
    canvas.save();
    canvas.translate(hx, hy);
    canvas.rotate(tilt);
    canvas.scale(armed() ? 1.18 : 1);
    final handle = Path()
      ..moveTo(0, -3)
      ..cubicTo(5, 2, 7, 6, 7, 9)
      ..arcToPoint(const Offset(-7, 9), radius: const Radius.circular(7))
      ..cubicTo(-7, 6, -5, 2, 0, -3)
      ..close();
    canvas.drawPath(handle, Paint()..color = t.accent);
    canvas.drawPath(handle, stroke);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.glow != glow || old.t != t;
}
