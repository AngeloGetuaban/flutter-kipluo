import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// A switch whose knob stretches as it travels and settles with a little overshoot. Tap it, or
/// drag the knob — release velocity decides the side. The track colour follows the knob.
class SpringToggle extends StatefulWidget {
  const SpringToggle({super.key, required this.value, required this.onChanged, this.label, this.sound = true});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool sound;

  @override
  State<SpringToggle> createState() => _SpringToggleState();
}

class _SpringToggleState extends State<SpringToggle> with SingleTickerProviderStateMixin {
  static const _w = 66.0, _h = 36.0, _knob = 26.0, _pad = 4.0;
  static const _travel = _w - _knob - _pad * 2 - 2;
  late final KSprings _s = KSprings(vsync: this, initial: {'x': widget.value ? 1 : 0}, config: SpringConfig.bouncy);
  double? _dragStart;
  double _dragBase = 0;
  bool _focused = false;

  @override
  void didUpdateWidget(SpringToggle old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _dragStart == null) _s.animateTo({'x': widget.value ? 1 : 0});
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _set(bool next, {double velocity = 0}) {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'x': next ? 1 : 0}, velocity: {'x': velocity});
    KipluoSound.play(next ? KSound.boop : KSound.boopLow, at: context, pitch: next ? 1.25 : 1, componentEnabled: widget.sound);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final enabled = widget.onChanged != null;
    final toggle = FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      shortcuts: const {SingleActivator(LogicalKeyboardKey.space): ActivateIntent(), SingleActivator(LogicalKeyboardKey.enter): ActivateIntent()},
      actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _set(!widget.value))},
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        // Screen readers get one tap action from Semantics below, not drag "scroll" actions.
        excludeFromSemantics: true,
        dragStartBehavior: DragStartBehavior.down,
        onTap: enabled ? () => _set(!widget.value) : null,
        onHorizontalDragStart: enabled
            ? (d) {
                _dragStart = d.localPosition.dx;
                _dragBase = _s['x'];
              }
            : null,
        onHorizontalDragUpdate: enabled ? (d) => _s.set({'x': (_dragBase + (d.localPosition.dx - _dragStart!) / _travel).clamp(-0.08, 1.08)}) : null,
        onHorizontalDragEnd: enabled
            ? (d) {
                _dragStart = null;
                final v = d.velocity.pixelsPerSecond.dx / _travel;
                final next = v.abs() > 2 ? v > 0 : _s['x'] > 0.5;
                _set(next, velocity: v);
              }
            : null,
        child: AnimatedBuilder(
          animation: _s,
          builder: (context, _) {
            final x = _s['x'];
            final stretch = 1 + (_s.spring('x').velocity.abs() / 14).clamp(0.0, 0.35);
            return Container(
              width: _w,
              height: _h,
              decoration: BoxDecoration(
                color: Color.lerp(t.track, t.accent, x.clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(_h),
                border: Border.all(color: t.line, width: t.stroke * 0.5),
                boxShadow: _focused ? [BoxShadow(color: KipluoColors.ring.withValues(alpha: 0.6), spreadRadius: 3)] : null,
              ),
              child: Stack(children: [
                Positioned(
                  left: _pad - 1 + x * _travel,
                  top: (_h - _knob) / 2 - 1,
                  child: Transform.scale(
                    scaleX: stretch,
                    child: Container(
                      width: _knob,
                      height: _knob,
                      decoration: BoxDecoration(color: t.surface, shape: BoxShape.circle, border: Border.all(color: t.line, width: t.stroke * 0.5)),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
    return Semantics(
      toggled: widget.value,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? () => _set(!widget.value) : null,
      child: widget.label == null
          ? toggle
          : Row(mainAxisSize: MainAxisSize.min, children: [toggle, const SizedBox(width: 12), ExcludeSemantics(child: Text(widget.label!))]),
    );
  }
}
