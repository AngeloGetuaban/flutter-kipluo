import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';
import 'icon_shell.dart';
import 'vector_glyph.dart';
import 'vector_glyph_data.dart';

/// Physics-driven animated icon supporting all 24 [KIconMotion] archetypes, line-release aura FX,
/// cute spatial sound cues, hover/tap/keyboard accessibility, and all 2,000 [kipluoIconPack] icons
/// with 1:1 Lucide-matched vector rendering across Playful, Minimal, and Mono themes.
class KipluoIcon extends StatefulWidget {
  const KipluoIcon._({
    super.key,
    required this.icon,
    required this.label,
    this.slug,
    this.vectorCommands,
    this.useMaterialIcon = false,
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
    bool useMaterialIcon = false,
    VoidCallback? onPressed,
  }) =>
      KipluoIcon._(
        key: key,
        icon: spec.icon,
        label: spec.title,
        slug: spec.slug,
        vectorCommands: kipluoVectorGlyphs[spec.slug],
        useMaterialIcon: useMaterialIcon,
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
    bool useMaterialIcon = false,
    VoidCallback? onPressed,
  }) {
    final spec = kipluoIconBySlug[slug];
    if (spec == null) {
      throw ArgumentError.value(slug, 'slug', 'Unknown Kipluo icon slug');
    }
    return KipluoIcon.fromSpec(
      spec,
      key: key,
      size: size,
      sound: sound,
      useMaterialIcon: useMaterialIcon,
      onPressed: onPressed,
    );
  }

  final IconData icon;
  final String label;
  final String? slug;
  final String? vectorCommands;
  final bool useMaterialIcon;
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
  int _hoverIdx = 0;
  int _streak = 0;
  DateTime? _lastClickAt;
  final List<Timer> _audioTimers = [];

  static const List<double> _hoverSteps = [0.95, 1.06, 1.15, 1.02];

  void _cancelAudioTimers() {
    for (final t in _audioTimers) {
      t.cancel();
    }
    _audioTimers.clear();
  }

  void _playLater(int ms, VoidCallback fn) {
    if (!widget.sound || !KipluoSound.enabled.value) return;
    late final Timer timer;
    timer = Timer(Duration(milliseconds: ms), () {
      _audioTimers.remove(timer);
      if (mounted) fn();
    });
    _audioTimers.add(timer);
  }

  @override
  void dispose() {
    _cancelAudioTimers();
    _s.dispose();
    super.dispose();
  }

  (KSound hover, KSound click, KSound? echo, int echoMs, double hoverPitch, double clickPitch)? _semanticSoundsFor() {
    final key = '${widget.slug ?? ''} ${widget.label}'.toLowerCase();
    if (RegExp(r'flame|fire|candle|campfire|torch|bonfire|ember').hasMatch(key)) {
      return (KSound.crackle, KSound.crackle, KSound.sparkle, 95, 1.1, 1.0);
    }
    if (RegExp(r'water|wave|rain|drop|droplet|cloud|umbrella|anchor|boat|ship|fish|swim|pool|bath|shower|ocean|sea').hasMatch(key)) {
      return (KSound.drop, KSound.splash, KSound.drop, 95, 1.18, 1.02);
    }
    if (RegExp(r'coffee|tea|cup|mug|drink|wine|beer|glass|bottle|milk|boba|juice|pour|cocktail|soup').hasMatch(key)) {
      return (KSound.pour, KSound.pour, KSound.clack, 115, 1.12, 1.0);
    }
    if (RegExp(r'zap|bolt|lightning|flash|battery|power|plug|cpu|chip|circuit|spark|electric|magnet|wifi|signal|radio|antenna').hasMatch(key)) {
      return (KSound.zap, KSound.zap, KSound.sparkle, 85, 1.18, 1.04);
    }
    if (RegExp(r'rocket|plane|flight|jet|launch|takeoff|send|upload|truck|car|bike|train|bus|drone|missile').hasMatch(key)) {
      return (KSound.whoosh, KSound.thrust, KSound.swish, 85, 1.1, 1.02);
    }
    if (RegExp(r'music|disc|vinyl|record|audio|headphone|speaker|mic|radio|song|album|guitar|piano|drum|note|sound|volume').hasMatch(key)) {
      return (KSound.vinyl, KSound.ding, KSound.bell, 90, 1.08, 1.04);
    }
    if (RegExp(r'bell|alarm|siren|alert|notif|ring|clock|timer|watch').hasMatch(key)) {
      return (KSound.clack, KSound.bell, KSound.bell, 110, 1.16, 1.02);
    }
    if (RegExp(r'hourglass|sand|desert|beach|clock-?sand|time').hasMatch(key)) {
      return (KSound.sand, KSound.flip, KSound.sand, 100, 1.1, 0.98);
    }
    if (RegExp(r'cat|paw|dog|pet|bird|duck|fox|bunny|bear|animal|shiba|corgi|meow').hasMatch(key)) {
      return (KSound.squish, KSound.meow, KSound.giggle, 105, 1.18, 1.06);
    }
    if (RegExp(r'bug|slime|sponge|pillow|soft|jelly|blob|cookie|cake|donut|burger|pizza|food|apple|fruit').hasMatch(key)) {
      return (KSound.squish, KSound.squish, KSound.pop, 80, 1.14, 1.02);
    }
    if (RegExp(r'party|gift|confetti|trophy|crown|award|medal|star|smile|laugh|happy|heart|love|sparkle|wand|magic|gem|diamond').hasMatch(key)) {
      return (KSound.boop, KSound.pop, KSound.sparkle, 85, 1.16, 1.06);
    }
    if (RegExp(r'sad|frown|cry|skull|ghost|trash|delete|ban|error|alert|warning|broken|bomb').hasMatch(key)) {
      return (KSound.tick, KSound.aww, KSound.boopLow, 95, 0.94, 1.02);
    }
    if (RegExp(r'lock|key|shield|vault|safe|sword|hammer|wrench|tool|scissor|cut|crop|link|chain|clip|gear|cog|settings|dice|coin|camera').hasMatch(key)) {
      return (KSound.clack, KSound.clack, KSound.click, 80, 1.18, 1.04);
    }
    if (RegExp(r'terminal|code|console|command|keyboard|laptop|monitor|server|database|qr|scan|fingerprint|face|bot|robot|ai|brain|chip').hasMatch(key)) {
      return (KSound.blip, KSound.blip, KSound.ding, 95, 1.15, 1.05);
    }
    if (RegExp(r'moon|sun|planet|orbit|globe|earth|space|galaxy|cosmos|compass|telescope|snow|ice|crystal').hasMatch(key)) {
      return (KSound.space, KSound.space, KSound.sparkle, 100, 1.12, 1.04);
    }
    if (RegExp(r'jump|bounce|hop|arrow-up|chevron-up|thumb|like|check|verified|badge').hasMatch(key)) {
      return (KSound.boop, KSound.jump, KSound.sparkle, 85, 1.14, 1.04);
    }
    return null;
  }

  (KSound hoverSound, KSound clickSound, KSound? echoSound, int echoMs, double hoverPitch, double clickPitch) _soundsFor() {
    if (widget.cuteSound != null) {
      return (KSound.tick, widget.cuteSound!, KSound.sparkle, 95, 1.15, 1.0);
    }
    final semantic = _semanticSoundsFor();
    if (semantic != null) return semantic;
    return switch (widget.motion) {
      KIconMotion.ring => (KSound.clack, KSound.bell, KSound.bell, 110, 1.12, 1.0),
      KIconMotion.pulse => (KSound.boop, KSound.pop, KSound.sparkle, 90, 1.15, 1.0),
      KIconMotion.spin => (KSound.tick, KSound.whoosh, KSound.ding, 120, 1.18, 1.02),
      KIconMotion.fly => (KSound.whoosh, KSound.thrust, KSound.swish, 85, 1.05, 1.02),
      KIconMotion.bounce => (KSound.whoosh, KSound.jump, KSound.boop, 110, 1.08, 1.0),
      KIconMotion.wiggle => (KSound.boop, KSound.pop, KSound.boing, 85, 1.1, 1.02),
      KIconMotion.snap => (KSound.clack, KSound.click, KSound.clack, 75, 1.12, 1.02),
      KIconMotion.nudgeRight => (KSound.whoosh, KSound.swipe, KSound.click, 90, 1.06, 1.02),
      KIconMotion.nudgeLeft => (KSound.whoosh, KSound.swipe, KSound.click, 90, 0.96, 0.94),
      KIconMotion.flip => (KSound.flip, KSound.flip, KSound.pop, 90, 1.1, 0.96),
      KIconMotion.zap => (KSound.zap, KSound.zap, KSound.sparkle, 85, 1.22, 1.1),
      KIconMotion.draw => (KSound.tick, KSound.swipe, KSound.sparkle, 90, 1.18, 1.02),
      KIconMotion.shake => (KSound.clack, KSound.boopLow, KSound.clack, 85, 0.92, 1.0),
      KIconMotion.squish => (KSound.squish, KSound.squish, KSound.pop, 80, 1.16, 1.02),
      KIconMotion.orbit => (KSound.space, KSound.space, KSound.swish, 100, 1.14, 1.04),
      KIconMotion.pendulum => (KSound.clack, KSound.clack, KSound.boing, 95, 1.12, 1.02),
      KIconMotion.inflate => (KSound.boop, KSound.pop, KSound.bubble, 85, 1.22, 1.12),
      KIconMotion.type => (KSound.blip, KSound.click, KSound.blip, 75, 1.28, 1.08),
      KIconMotion.heartbeat => (KSound.boopLow, KSound.boopLow, KSound.pop, 105, 1.18, 1.04),
      KIconMotion.tilt3d => (KSound.whoosh, KSound.flip, KSound.ding, 95, 1.16, 1.06),
      KIconMotion.float => (KSound.space, KSound.drop, KSound.sparkle, 100, 1.22, 1.14),
      KIconMotion.stamp => (KSound.clack, KSound.clack, KSound.boop, 85, 1.12, 0.94),
      KIconMotion.cascade => (KSound.flip, KSound.flip, KSound.ding, 95, 1.22, 1.12),
      KIconMotion.breathe => (KSound.space, KSound.boop, KSound.sparkle, 105, 1.1, 1.02),
    };
  }

  void _onHover() {
    _s.reducedMotion = kipluoReducedMotion(context);
    final (hs, _, _, _, hp, _) = _soundsFor();
    final step = _hoverSteps[_hoverIdx++ % _hoverSteps.length];
    KipluoSound.play(hs, at: context, pitch: (hp * step).clamp(0.5, 2.2), volume: 0.28, componentEnabled: widget.sound);
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
      case KIconMotion.heartbeat:
        _s.animateTo({'sx': 112, 'sy': 112});
      case KIconMotion.tilt3d:
        _s.animateTo({'rot': -60, 'sx': 108, 'sy': 108});
      case KIconMotion.float:
        _s.animateTo({'y': -4.5, 'rot': 50, 'sx': 104, 'sy': 104});
      case KIconMotion.stamp:
        _s.animateTo({'y': -3, 'sx': 106, 'sy': 106});
      case KIconMotion.cascade:
        _s.animateTo({'y': -2.5, 'x': 2, 'sx': 105, 'sy': 105});
      case KIconMotion.breathe:
        _s.animateTo({'sx': 111, 'sy': 111});
    }
  }

  void _onExit() {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'x': 0, 'y': 0, 'rot': 0, 'sx': 100, 'sy': 100});
  }

  void _onActivate() {
    _clicks++;
    _s.reducedMotion = kipluoReducedMotion(context);
    _cancelAudioTimers();
    final now = DateTime.now();
    _streak = (_lastClickAt != null && now.difference(_lastClickAt!).inMilliseconds < 950)
        ? (_streak + 1) % 6
        : 0;
    _lastClickAt = now;
    final combo = notePitch(_streak);
    final (_, cs, echo, echoMs, _, cp) = _soundsFor();
    final mainPitch = (cp * combo).clamp(0.5, 2.2);
    KipluoSound.play(cs, at: context, pitch: mainPitch, volume: 0.68, componentEnabled: widget.sound);
    if (echo != null) {
      _playLater(echoMs, () {
        KipluoSound.play(echo, at: context, pitch: (mainPitch * 1.14).clamp(0.5, 2.3), volume: 0.42, componentEnabled: widget.sound);
      });
    }

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
      case KIconMotion.heartbeat:
        _s.set({'sx': 126, 'sy': 126, 'fx': 100});
      case KIconMotion.tilt3d:
        _s.set({'sx': -100, 'sy': 114, 'rot': -100, 'fx': 100});
      case KIconMotion.float:
        _s.set({'y': -10, 'rot': -80, 'sx': 108, 'sy': 108, 'fx': 100});
      case KIconMotion.stamp:
        _s.set({'y': 5, 'sx': 128, 'sy': 74, 'fx': 100});
      case KIconMotion.cascade:
        _s.set({'y': -7, 'x': -5, 'sx': 112, 'sy': 92, 'fx': 100});
      case KIconMotion.breathe:
        _s.set({'sx': 124, 'sy': 124, 'fx': 100});
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
                    child: (!widget.useMaterialIcon && (widget.vectorCommands ?? (widget.slug != null ? kipluoVectorGlyphs[widget.slug] : null)) != null)
                        ? KipluoVectorGlyph(
                            commands: (widget.vectorCommands ?? kipluoVectorGlyphs[widget.slug])!,
                            size: widget.size * 0.48,
                            color: t.line,
                            strokeWidth: t.stroke * 0.72,
                          )
                        : Icon(widget.icon, size: widget.size * 0.44, color: t.line),
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
      case KIconMotion.heartbeat:
      case KIconMotion.breathe:
        canvas.drawCircle(c, size.width * (0.32 + (1 - fx) * 0.16), p);
        canvas.drawCircle(c, size.width * (0.42 + (1 - fx) * 0.18), p..color = color.withValues(alpha: fx * 0.5));
      case KIconMotion.stamp:
        canvas.drawCircle(c, size.width * (0.30 + (1 - fx) * 0.16), p);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final r0 = size.width * 0.34;
          final r1 = size.width * (0.48 + (1 - fx) * 0.14);
          canvas.drawLine(c + Offset(math.cos(a) * r0, math.sin(a) * r0), c + Offset(math.cos(a) * r1, math.sin(a) * r1), p);
        }
      default:
        canvas.drawCircle(c, size.width * (0.30 + (1 - fx) * 0.14), p..color = color.withValues(alpha: fx * 0.55));
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final r0 = size.width * 0.34;
          final r1 = size.width * (0.46 + (1 - fx) * 0.12);
          canvas.drawLine(c + Offset(math.cos(a) * r0, math.sin(a) * r0), c + Offset(math.cos(a) * r1, math.sin(a) * r1), p..color = color.withValues(alpha: fx));
        }
    }
  }

  @override
  bool shouldRepaint(_IconFxPainter old) => old.fx != fx || old.motion != motion || old.color != color;
}
