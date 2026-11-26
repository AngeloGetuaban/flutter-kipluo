import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';
import 'icon_shell.dart';

/// Physics-driven animated icon supporting all 14 [KIconMotion] archetypes, anime FX overlays,
/// cute spatial sound cues, hover/tap/keyboard accessibility, and all 500 [kipluoIconPack] icons.
class KipluoIcon extends StatefulWidget {
  const KipluoIcon._({
    super.key,
    required this.icon,
    required this.label,
    this.motion = KIconMotion.squish,
    this.cuteSound,
    this.size = 56,
    this.sound = true,
    this.onPressed,
  });

  factory KipluoIcon.fromSpec(
    KIconSpec spec, {
    Key? key,
    double size = 56,
    bool sound = true,
    VoidCallback? onPressed,
  }) =>
      KipluoIcon._(
        key: key,
        icon: spec.icon,
        label: spec.title,
        motion: spec.motion,
        cuteSound: spec.cuteSound,
        size: size,
        sound: sound,
        onPressed: onPressed,
      );

  factory KipluoIcon.bySlug(
    String slug, {
    Key? key,
    double size = 56,
    bool sound = true,
    VoidCallback? onPressed,
  }) {
    final spec = kipluoIconBySlug[slug];
    if (spec == null) {
      throw ArgumentError.value(slug, 'slug', 'Unknown Kipluo icon slug');
    }
    return KipluoIcon.fromSpec(spec, key: key, size: size, sound: sound, onPressed: onPressed);
  }

  final IconData icon;
  final String label;
  final KIconMotion motion;
  final KSound? cuteSound;
  final double size;
  final bool sound;
  final VoidCallback? onPressed;

  @override
  State<KipluoIcon> createState() => _KipluoIconState();
}

class _KipluoIconState extends State<KipluoIcon> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'x': 0, 'y': 0, 'rot': 0, 'sx': 100, 'sy': 100, 'fx': 0},
    config: SpringConfig.bouncy,
  );
  int _clicks = 0;

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  (KSound hoverSound, KSound clickSound, double hoverPitch, double clickPitch) _soundsFor() {
    if (widget.cuteSound != null) {
      return (KSound.tick, widget.cuteSound!, 1.15, 1.0);
    }
    return switch (widget.motion) {
      KIconMotion.ring => (KSound.tick, KSound.bell, 1.1, 1.0),
      KIconMotion.pulse => (KSound.boop, KSound.pop, 1.15, 1.0),
      KIconMotion.spin => (KSound.tick, KSound.ding, 1.2, 1.0),
      KIconMotion.fly => (KSound.whoosh, KSound.swish, 1.0, 1.0),
      KIconMotion.bounce => (KSound.whoosh, KSound.drop, 1.05, 1.0),
      KIconMotion.wiggle => (KSound.boop, KSound.pop, 1.1, 1.0),
      KIconMotion.snap => (KSound.tick, KSound.click, 1.1, 1.0),
      KIconMotion.nudgeRight => (KSound.whoosh, KSound.swipe, 1.05, 1.0),
      KIconMotion.nudgeLeft => (KSound.whoosh, KSound.swipe, 0.95, 0.92),
      KIconMotion.flip => (KSound.flip, KSound.flip, 1.1, 0.95),
      KIconMotion.zap => (KSound.tick, KSound.ding, 1.35, 1.18),
      KIconMotion.draw => (KSound.tick, KSound.sparkle, 1.2, 1.0),
      KIconMotion.shake => (KSound.tick, KSound.boopLow, 0.9, 1.0),
      KIconMotion.squish => (KSound.boop, KSound.pop, 1.2, 1.0),
      KIconMotion.orbit => (KSound.whoosh, KSound.swish, 1.15, 1.05),
      KIconMotion.pendulum => (KSound.tick, KSound.boing, 1.1, 1.0),
      KIconMotion.inflate => (KSound.boop, KSound.pop, 1.25, 1.2),
      KIconMotion.type => (KSound.tick, KSound.click, 1.35, 1.1),
    };
  }

  void _onHover() {
    _s.reducedMotion = kipluoReducedMotion(context);
    final (hs, _, hp, _) = _soundsFor();
    KipluoSound.play(hs, at: context, pitch: hp, volume: 0.25, componentEnabled: widget.sound);
    switch (widget.motion) {
      case KIconMotion.ring:
        _s.animateTo({'rot': 120, 'sx': 108, 'sy': 108});
      case KIconMotion.pulse:
        _s.animateTo({'sx': 114, 'sy': 114});
      case KIconMotion.spin:
        _s.animateTo({'rot': 450, 'sx': 106, 'sy': 106});
      case KIconMotion.fly:
        _s.animateTo({'x': 3, 'y': -3, 'rot': -80});
      case KIconMotion.bounce:
        _s.animateTo({'y': 3, 'sx': 108, 'sy': 95});
      case KIconMotion.wiggle:
        _s.animateTo({'rot': -100, 'sx': 106, 'sy': 106});
      case KIconMotion.snap:
        _s.animateTo({'sx': 110, 'sy': 110});
      case KIconMotion.nudgeRight:
        _s.animateTo({'x': 4});
      case KIconMotion.nudgeLeft:
        _s.animateTo({'x': -4});
      case KIconMotion.flip:
        _s.animateTo({'sx': 92, 'sy': 110, 'y': -2});
      case KIconMotion.zap:
        _s.animateTo({'rot': -100, 'sx': 110, 'sy': 110});
      case KIconMotion.draw:
        _s.animateTo({'rot': -120, 'sx': 108, 'sy': 108});
      case KIconMotion.shake:
        _s.animateTo({'rot': -80});
      case KIconMotion.squish:
        _s.animateTo({'sx': 112, 'sy': 92});
      case KIconMotion.orbit:
        _s.animateTo({'x': 3, 'y': -2, 'rot': 120});
      case KIconMotion.pendulum:
        _s.animateTo({'rot': -140});
      case KIconMotion.inflate:
        _s.animateTo({'sx': 114, 'sy': 114});
      case KIconMotion.type:
        _s.animateTo({'y': 2, 'sx': 103, 'sy': 97});
    }
  }

  void _onExit() {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'x': 0, 'y': 0, 'rot': 0, 'sx': 100, 'sy': 100});
  }

  void _onActivate() {
    _clicks++;
    _s.reducedMotion = kipluoReducedMotion(context);
    final (_, cs, _, cp) = _soundsFor();
    KipluoSound.play(cs, at: context, pitch: cp, volume: 0.72, componentEnabled: widget.sound);

    switch (widget.motion) {
      case KIconMotion.ring:
        _s.set({'rot': _clicks.isEven ? 240 : -240, 'fx': 100, 'sx': 115, 'sy': 115});
      case KIconMotion.pulse:
        _s.set({'sx': 132, 'sy': 132, 'fx': 100});
      case KIconMotion.spin:
        _s.set({'rot': -1800, 'sx': 118, 'sy': 118, 'fx': 100});
      case KIconMotion.fly:
        _s.set({'x': 10, 'y': -10, 'rot': -180, 'fx': 100});
      case KIconMotion.bounce:
        _s.set({'y': 7, 'sx': 122, 'sy': 84, 'fx': 100});
      case KIconMotion.wiggle:
        _s.set({'rot': -220, 'sx': 115, 'sy': 115, 'fx': 100});
      case KIconMotion.snap:
        _s.set({'sx': 82, 'sy': 82, 'fx': 100});
      case KIconMotion.nudgeRight:
        _s.set({'x': 9, 'sx': 114, 'sy': 92, 'fx': 100});
      case KIconMotion.nudgeLeft:
        _s.set({'x': -9, 'sx': 114, 'sy': 92, 'fx': 100});
      case KIconMotion.flip:
        _s.set({'sx': -100, 'sy': 112, 'fx': 100});
      case KIconMotion.zap:
        _s.set({'y': 4, 'rot': 120, 'sx': 122, 'sy': 122, 'fx': 100});
      case KIconMotion.draw:
        _s.set({'rot': 220, 'y': -4, 'fx': 100});
      case KIconMotion.shake:
        _s.set({'x': 7, 'rot': -160, 'fx': 100});
      case KIconMotion.squish:
        _s.set({'sx': 128, 'sy': 78, 'fx': 100});
      case KIconMotion.orbit:
        _s.set({'x': 5, 'y': -5, 'rot': -1800, 'fx': 100});
      case KIconMotion.pendulum:
        _s.set({'rot': 260, 'fx': 95});
      case KIconMotion.inflate:
        _s.set({'sx': 132, 'sy': 132, 'fx': 100});
      case KIconMotion.type:
        _s.set({'y': 4, 'sx': 106, 'sy': 90, 'fx': 90});
    }
    _s.animateTo({'x': 0, 'y': 0, 'rot': 0, 'sx': 100, 'sy': 100, 'fx': 0});
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return KipluoIconButton(
      label: widget.label,
      size: widget.size,
      onHover: _onHover,
      onExit: _onExit,
      onActivate: _onActivate,
      child: AnimatedBuilder(
        animation: _s,
        builder: (context, _) {
          final fx = (_s['fx'] / 100).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              if (fx > 0.04)
                CustomPaint(
                  size: Size.square(widget.size * 0.78),
                  painter: _IconFxPainter(motion: widget.motion, fx: fx, color: t.accent),
                ),
              Transform.translate(
                offset: Offset(_s['x'], _s['y']),
                child: Transform.rotate(
                  angle: (_s['rot'] / 10) * math.pi / 180,
                  child: Transform.scale(
                    scaleX: (_s['sx'] / 100).clamp(-1.4, 1.45),
                    scaleY: (_s['sy'] / 100).clamp(0.65, 1.45),
                    child: Icon(widget.icon, size: widget.size * 0.44, color: t.line),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IconFxPainter extends CustomPainter {
  _IconFxPainter({required this.motion, required this.fx, required this.color});
  final KIconMotion motion;
  final double fx;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()
      ..color = color.withValues(alpha: fx)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    switch (motion) {
      case KIconMotion.ring:
        for (final sign in [-1.0, 1.0]) {
          canvas.drawArc(
            Rect.fromCircle(center: c + Offset(sign * size.width * 0.2, 0), radius: size.width * (0.2 + (1 - fx) * 0.12)),
            sign > 0 ? -0.7 : math.pi - 0.7,
            1.4,
            false,
            p,
          );
        }
      case KIconMotion.fly:
      case KIconMotion.nudgeRight:
      case KIconMotion.nudgeLeft:
        final dir = motion == KIconMotion.nudgeLeft ? 1.0 : -1.0;
        for (final dy in [-6.0, 0.0, 6.0]) {
          canvas.drawLine(c + Offset(dir * 6, dy), c + Offset(dir * (14 + (1 - fx) * 8), dy), p);
        }
      case KIconMotion.snap:
      case KIconMotion.orbit:
      case KIconMotion.inflate:
        canvas.drawCircle(c, size.width * (0.34 + (1 - fx) * 0.14), p);
      default:
        for (var i = 0; i < 4; i++) {
          final a = math.pi / 4 + i * math.pi / 2;
          final r0 = size.width * 0.34;
          final r1 = size.width * (0.45 + (1 - fx) * 0.1);
          canvas.drawLine(c + Offset(math.cos(a) * r0, math.sin(a) * r0), c + Offset(math.cos(a) * r1, math.sin(a) * r1), p);
        }
    }
  }

  @override
  bool shouldRepaint(_IconFxPainter old) => old.fx != fx || old.motion != motion || old.color != color;
}
