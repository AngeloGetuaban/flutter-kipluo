import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 1. Elastic Step Tracker (Free) */

/// A wizard progress rail whose active marker is a gooey pill. Its leading edge runs ahead on a
/// stiff spring and its trailing edge catches up on a softer one, so the pill stretches while it
/// travels and snaps round when it lands. Drag the pill along the rail and release: it projects
/// your flick to the nearest step. Arrow keys, Home and End move between steps.
class ElasticStepTracker extends StatefulWidget {
  const ElasticStepTracker({
    super.key,
    this.steps = const ['Cart', 'Shipping', 'Payment', 'Done'],
    this.step,
    this.initialStep = 1,
    this.onStepChanged,
    this.width = 280,
    this.label = 'Checkout progress',
    this.sound = true,
  });

  /// Step labels, in order.
  final List<String> steps;

  /// Controlled active step index. Leave null to let the tracker keep its own state.
  final int? step;
  final int initialStep;
  final ValueChanged<int>? onStepChanged;

  /// Rail width in logical pixels.
  final double width;

  /// Accessible name of the step list.
  final String label;
  final bool sound;

  @override
  State<ElasticStepTracker> createState() => _ElasticStepTrackerState();
}

class _ElasticStepTrackerState extends State<ElasticStepTracker> with TickerProviderStateMixin {
  static const _dot = 26.0;
  static const _pad = _dot / 2 + 4;

  late int _inner = widget.initialStep;
  late final KSprings _head = KSprings(vsync: this, initial: {'x': _xOf(_active)}, config: const SpringConfig(stiffness: 430, damping: 30));
  late final KSprings _tail = KSprings(vsync: this, initial: {'x': _xOf(_active)}, config: const SpringConfig(stiffness: 150, damping: 17));
  late int _lastNear = _active;
  double? _dragStartGlobal;
  double _dragStartHead = 0;
  final _focus = FocusNode(debugLabel: 'ElasticStepTracker');
  bool _focused = false;
  Timer? _chime;

  int get _n => widget.steps.length;
  int get _active => (widget.step ?? _inner).clamp(0, math.max(0, _n - 1)).toInt();
  double _xOf(int i) => _pad + (_n > 1 ? (i * (widget.width - _pad * 2)) / (_n - 1) : 0);

  @override
  void initState() {
    super.initState();
    _head.addListener(_onHead);
  }

  @override
  void didUpdateWidget(ElasticStepTracker old) {
    super.didUpdateWidget(old);
    if (old.width != widget.width || old.steps.length != widget.steps.length) {
      _head.set({'x': _xOf(_active)});
      _tail.set({'x': _xOf(_active)});
    } else if (widget.step != null && widget.step != old.step && _dragStartGlobal == null) {
      _glide(_active);
    }
  }

  @override
  void dispose() {
    _chime?.cancel();
    _focus.dispose();
    _head.dispose();
    _tail.dispose();
    super.dispose();
  }

  void _onHead() {
    // A tick for each step the leading edge passes, pitched up the scale.
    final near = (((_head['x'] - _pad) / math.max(1, widget.width - _pad * 2)) * (_n - 1)).round().clamp(0, math.max(0, _n - 1)).toInt();
    if (near != _lastNear) {
      _lastNear = near;
      KipluoSound.play(KSound.tick, at: context, pitch: notePitch(near), volume: 0.45, componentEnabled: widget.sound);
    }
  }

  void _glide(int i, [double velocity = 0]) {
    final reduced = kipluoReducedMotion(context);
    _head.reducedMotion = reduced;
    _tail.reducedMotion = reduced;
    _head.animateTo({'x': _xOf(i)}, velocity: {'x': velocity});
    _tail.animateTo({'x': _xOf(i)}, velocity: {'x': velocity * 0.4});
  }

  void _go(int i, [double velocity = 0]) {
    if (_n == 0) return;
    final next = i.clamp(0, _n - 1);
    final active = _active;
    if (next == active) {
      _glide(next, velocity);
      return;
    }
    if (widget.step == null) setState(() => _inner = next);
    widget.onStepChanged?.call(next);
    _glide(next, velocity);
    if (next == _n - 1) {
      _chime?.cancel();
      _chime = Timer(const Duration(milliseconds: 220), () {
        if (mounted) KipluoSound.play(KSound.chime, at: context, volume: 0.55, componentEnabled: widget.sound);
      });
    } else {
      KipluoSound.play(next > active ? KSound.boop : KSound.boopLow, at: context, pitch: next > active ? 1.1 : 0.95, volume: 0.5, componentEnabled: widget.sound);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    int? next;
    if (k == LogicalKeyboardKey.arrowRight) next = _active + 1;
    if (k == LogicalKeyboardKey.arrowLeft) next = _active - 1;
    if (k == LogicalKeyboardKey.home) next = 0;
    if (k == LogicalKeyboardKey.end) next = _n - 1;
    if (next == null) return KeyEventResult.ignored;
    _go(next);
    return KeyEventResult.handled;
  }

  void _dragStart(DragStartDetails d) {
    _focus.requestFocus();
    _dragStartGlobal = d.globalPosition.dx;
    _dragStartHead = _head['x'];
    KipluoSound.play(KSound.pop, at: context, pitch: 0.9, volume: 0.35, componentEnabled: widget.sound);
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_dragStartGlobal == null) return;
    var x = _dragStartHead + d.globalPosition.dx - _dragStartGlobal!;
    final lo = _xOf(0), hi = _xOf(_n - 1);
    if (x < lo) x = lo - math.sqrt(lo - x) * 2.5;
    if (x > hi) x = hi + math.sqrt(x - hi) * 2.5;
    _head.set({'x': x});
    _tail.reducedMotion = kipluoReducedMotion(context);
    _tail.animateTo({'x': x}); // the tail lags behind the finger: the pill stretches
  }

  void _dragEnd(DragEndDetails d) {
    if (_dragStartGlobal == null) return;
    _dragStartGlobal = null;
    final v = d.velocity.pixelsPerSecond.dx;
    final projected = _head['x'] + v * 0.15;
    final i = (((projected - _pad) / math.max(1, widget.width - _pad * 2)) * (_n - 1)).round();
    _go(i, v);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final reduced = kipluoReducedMotion(context);
    final active = _active;
    final n = _n;
    if (n == 0) return SizedBox(width: widget.width);

    final rail = AnimatedBuilder(
      animation: Listenable.merge([_head, _tail]),
      builder: (context, _) {
        final head = _head['x'], tail = _tail['x'];
        final lo = math.min(head, tail);
        final len = (head - tail).abs();
        // Stretching thins the pill slightly, like a drop being pulled.
        final thin = math.max(0.72, 1 - len / 260);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: _pad,
              right: _pad,
              top: _dot / 2 - 2,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(color: t.track, borderRadius: BorderRadius.circular(4)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: math.max(0, math.max(head, tail) - _pad),
                    decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: lo - _dot / 2 - 4,
              top: _dot / 2 - (_dot + 8) / 2,
              width: len + _dot + 8,
              height: _dot + 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                dragStartBehavior: DragStartBehavior.down,
                onHorizontalDragStart: _dragStart,
                onHorizontalDragUpdate: _dragUpdate,
                onHorizontalDragEnd: _dragEnd,
                onHorizontalDragCancel: () {
                  _dragStartGlobal = null;
                  _glide(_active);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Transform.scale(
                    scaleX: 1,
                    scaleY: thin,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(_dot),
                        border: Border.all(color: t.line, width: t.stroke * 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (var i = 0; i < n; i++)
              Positioned(
                left: _xOf(i) - 30,
                top: 0,
                width: 60,
                child: _StepDot(
                  index: i,
                  count: n,
                  label: widget.steps[i],
                  done: i < active,
                  current: i == active,
                  reduced: reduced,
                  tokens: t,
                  onTap: () {
                    _focus.requestFocus();
                    _go(i);
                  },
                ),
              ),
          ],
        );
      },
    );

    Widget pillButton(String text, {required bool primary, required bool enabled, required VoidCallback onTap}) => Semantics(
          button: true,
          enabled: enabled,
          onTap: enabled ? onTap : null,
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: enabled ? onTap : null,
              child: MouseRegion(
                cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: Opacity(
                  opacity: enabled ? 1 : 0.4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary ? t.accent : t.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: t.line, width: t.stroke * 0.5),
                    ),
                    child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary ? t.accentInk : t.line)),
                  ),
                ),
              ),
            ),
          ),
        );

    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      onFocusChange: (f) => setState(() => _focused = f),
      child: SizedBox(
        width: widget.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: widget.label,
              container: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _focused ? [BoxShadow(color: KipluoColors.ring.withValues(alpha: 0.6), spreadRadius: 2)] : null,
                ),
                child: SizedBox(width: widget.width, height: _dot + 22, child: rail),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                pillButton('Back', primary: false, enabled: active > 0, onTap: () => _go(active - 1)),
                Flexible(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      'Step ${active + 1} of $n: ${widget.steps[active]}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.line.withValues(alpha: 0.7)),
                    ),
                  ),
                ),
                pillButton('Next', primary: true, enabled: active < n - 1, onTap: () => _go(active + 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.count,
    required this.label,
    required this.done,
    required this.current,
    required this.reduced,
    required this.tokens,
    required this.onTap,
  });

  final int index, count;
  final String label;
  final bool done, current, reduced;
  final KipluoTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final fg = current ? t.accentInk : (done ? t.surface : t.line);
    final dot = AnimatedContainer(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: current ? Colors.transparent : (done ? t.line : t.surface),
        shape: BoxShape.circle,
        border: current ? null : Border.all(color: t.line, width: t.stroke * 0.5),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedScale(
            scale: done ? 0 : 1,
            duration: reduced ? Duration.zero : const Duration(milliseconds: 300),
            child: Text('${index + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ),
          AnimatedScale(
            scale: done ? 1 : 0,
            curve: const Cubic(0.3, 1.7, 0.5, 1),
            duration: reduced ? Duration.zero : const Duration(milliseconds: 380),
            child: CustomPaint(size: const Size.square(12), painter: _CheckPainter(fg)),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: current,
      label: 'Step ${index + 1} of $count: $label${done ? ', completed' : ''}${current ? ', current step' : ''}',
      onTap: current ? null : onTap,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The current dot sits under the pill: let pointer events reach the pill so it can be dragged.
          IgnorePointer(
            ignoring: current,
            child: GestureDetector(
              onTap: onTap,
              child: MouseRegion(cursor: SystemMouseCursors.click, child: dot),
            ),
          ),
          const SizedBox(height: 4),
          IgnorePointer(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: current ? t.line : t.line.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 12);
    canvas.drawPath(
      Path()
        ..moveTo(2.5, 6.3)
        ..lineTo(5, 8.6)
        ..lineTo(9.5, 3.6),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
