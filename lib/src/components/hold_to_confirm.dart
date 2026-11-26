import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Press and hold (pointer or Space/Enter) to fill the ring and commit an action. Releasing early
/// snaps back cleanly and never triggers [onConfirm].
class HoldToConfirm extends StatefulWidget {
  const HoldToConfirm({
    super.key,
    required this.onConfirm,
    this.duration = const Duration(milliseconds: 900),
    this.label = 'Hold to delete',
    this.confirmedLabel = 'Confirmed',
    this.sound = true,
  });

  final VoidCallback onConfirm;
  final Duration duration;
  final String label;
  final String confirmedLabel;
  final bool sound;

  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm> with TickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: widget.duration);
  late final KSprings _s = KSprings(vsync: this, initial: {'scale': 100}, config: SpringConfig.bouncy);
  int _lastBucket = 0;
  bool _confirmed = false;
  Timer? _reset;

  @override
  void initState() {
    super.initState();
    _hold.addListener(_onHoldTick);
    _hold.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_confirmed) _commit();
    });
  }

  @override
  void didUpdateWidget(HoldToConfirm old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) _hold.duration = widget.duration;
  }

  @override
  void dispose() {
    _reset?.cancel();
    _hold.dispose();
    _s.dispose();
    super.dispose();
  }

  void _onHoldTick() {
    final bucket = (_hold.value * 5).floor();
    if (bucket > _lastBucket && bucket < 5) {
      _lastBucket = bucket;
      KipluoSound.play(KSound.tick, at: context, pitch: 0.9 + bucket * 0.14, volume: 0.55, componentEnabled: widget.sound);
    }
  }

  void _startHold() {
    if (_confirmed) return;
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'scale': 95});
    if (kipluoReducedMotion(context)) {
      _hold.value = 1;
      _commit();
    } else {
      _hold.forward();
    }
  }

  void _cancelHold() {
    if (_confirmed || !_hold.isAnimating) return;
    _hold.stop();
    _hold.value = 0;
    _lastBucket = 0;
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'scale': 100});
    KipluoSound.play(KSound.boopLow, at: context, volume: 0.45, componentEnabled: widget.sound);
  }

  void _commit() {
    setState(() => _confirmed = true);
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'scale': 100}, velocity: {'scale': 140});
    KipluoSound.play(KSound.chime, at: context, componentEnabled: widget.sound);
    widget.onConfirm();
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _hold.value = 0;
      _lastBucket = 0;
      setState(() => _confirmed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final label = _confirmed ? widget.confirmedLabel : widget.label;
    return Semantics(
      button: true,
      liveRegion: true,
      label: label,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
            if (event is KeyDownEvent) {
              _startHold();
              return KeyEventResult.handled;
            }
            if (event is KeyUpEvent) {
              _cancelHold();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Listener(
          onPointerDown: (_) => _startHold(),
          onPointerUp: (_) => _cancelHold(),
          onPointerCancel: (_) => _cancelHold(),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedBuilder(
            animation: Listenable.merge([_hold, _s]),
            builder: (context, _) {
              final progress = _confirmed ? 1.0 : _hold.value;
              final bg = _confirmed ? t.ok : t.surface;
              final fg = _confirmed ? Colors.white : t.bad;
              return Transform.scale(
                scale: _s['scale'] / 100,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.line, width: t.stroke * 0.6),
                    boxShadow: [BoxShadow(color: t.line, offset: const Offset(2, 3))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 20,
                        child: CustomPaint(
                          painter: _HoldRingPainter(progress: progress, confirmed: _confirmed, track: t.track, color: fg),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
          ),
        ),
      ),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  _HoldRingPainter({required this.progress, required this.confirmed, required this.track, required this.color});
  final double progress;
  final bool confirmed;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(2), 0, math.pi * 2, false, Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = 3);
    if (progress > 0) {
      canvas.drawArc(
        rect.deflate(2),
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    if (confirmed) {
      canvas.drawPath(
        Path()..moveTo(size.width * 0.28, size.height * 0.52)..lineTo(size.width * 0.45, size.height * 0.68)..lineTo(size.width * 0.74, size.height * 0.34),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_HoldRingPainter old) => old.progress != progress || old.confirmed != confirmed || old.color != color;
}
