import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Slide the thumb to the right end to confirm. Rubber-bands at the start, counts velocity flicks,
/// springs back short of the end, and plays [KSound.swish] + [KSound.chime] on completion.
class SwipeToUnlock extends StatefulWidget {
  const SwipeToUnlock({
    super.key,
    required this.onComplete,
    this.label = 'Slide to pay \$29',
    this.doneLabel = 'Paid',
    this.width = 280,
    this.sound = true,
  });

  final VoidCallback onComplete;
  final String label;
  final String doneLabel;
  final double width;
  final bool sound;

  @override
  State<SwipeToUnlock> createState() => _SwipeToUnlockState();
}

class _SwipeToUnlockState extends State<SwipeToUnlock> with SingleTickerProviderStateMixin {
  static const _height = 54.0, _knob = 44.0, _pad = 4.0;
  double get _travel => widget.width - _knob - _pad * 2;
  late final KSprings _s = KSprings(vsync: this, initial: {'x': 0}, config: SpringConfig.bouncy);
  bool _done = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    _s.dispose();
    super.dispose();
  }

  void _complete() {
    if (_done) return;
    _done = true;
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'x': _travel});
    KipluoSound.play(KSound.swish, at: context, volume: 0.7, componentEnabled: widget.sound);
    KipluoSound.play(KSound.chime, at: context, componentEnabled: widget.sound);
    setState(() {});
    widget.onComplete();
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _done = false;
      _s.animateTo({'x': 0});
      setState(() {});
    });
  }

  void _springBack(double vx) {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'x': 0}, velocity: {'x': vx});
    KipluoSound.play(KSound.boopLow, at: context, volume: 0.5, componentEnabled: widget.sound);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Semantics(
      button: true,
      liveRegion: true,
      label: _done ? widget.doneLabel : widget.label,
      onTap: _complete,
      child: FocusableActionDetector(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _complete())},
        child: Container(
          width: widget.width,
          height: _height,
          decoration: BoxDecoration(
            color: _done ? t.ok : t.track,
            borderRadius: BorderRadius.circular(_height),
            border: Border.all(color: t.line, width: t.stroke * 0.6),
          ),
          child: AnimatedBuilder(
            animation: _s,
            builder: (context, _) {
              final x = _s['x'];
              final progress = (x / _travel).clamp(0.0, 1.0);
              return Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: _done ? 1 : (1 - progress * 1.15).clamp(0.0, 1.0),
                    child: Text(
                      _done ? widget.doneLabel : widget.label,
                      style: TextStyle(color: _done ? Colors.white : t.line, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Positioned(
                    left: _pad + x,
                    child: GestureDetector(
                      excludeFromSemantics: true,
                      onHorizontalDragStart: (_) {
                        if (!_done) KipluoSound.play(KSound.tick, at: context, componentEnabled: widget.sound);
                      },
                      onHorizontalDragUpdate: (d) {
                        if (_done) return;
                        final raw = _s['x'] + d.delta.dx;
                        final clamped = raw < 0 ? raw * 0.25 : raw.clamp(0.0, _travel);
                        _s.set({'x': clamped});
                      },
                      onHorizontalDragEnd: (d) {
                        if (_done) return;
                        final vx = d.velocity.pixelsPerSecond.dx;
                        if (_s['x'] >= _travel * 0.78 || (vx > 680 && _s['x'] > _travel * 0.25)) {
                          _complete();
                        } else {
                          _springBack(vx);
                        }
                      },
                      child: Container(
                        width: _knob,
                        height: _knob,
                        decoration: BoxDecoration(
                          color: _done ? Colors.white : t.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.line, width: t.stroke * 0.5),
                        ),
                        child: Icon(_done ? Icons.check_rounded : Icons.arrow_forward_rounded, color: _done ? t.ok : t.accentInk, size: 20),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
