import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Numeric stepper with accelerating press-and-hold repeat, directional value transition,
/// limit bump feedback, and spinbutton arrow-key support.
class StepperInput extends StatefulWidget {
  const StepperInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 12,
    this.step = 1,
    this.label = 'Guests',
    this.sound = true,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;
  final int step;
  final String label;
  final bool sound;

  @override
  State<StepperInput> createState() => _StepperInputState();
}

class _StepperInputState extends State<StepperInput> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(vsync: this, initial: {'x': 0}, config: SpringConfig.bouncy);
  Timer? _holdTimer;
  int _holdCount = 0;
  int _dir = 1;

  @override
  void dispose() {
    _holdTimer?.cancel();
    _s.dispose();
    super.dispose();
  }

  void _stepBy(int delta) {
    if (widget.onChanged == null) return;
    _dir = delta >= 0 ? 1 : -1;
    final next = widget.value + delta * widget.step;
    if (next < widget.min || next > widget.max) {
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.set({'x': _dir * 6});
      _s.animateTo({'x': 0});
      KipluoSound.play(KSound.boopLow, at: context, volume: 0.45, componentEnabled: widget.sound);
      return;
    }
    final ratio = (next - widget.min) / ((widget.max - widget.min).clamp(1, 100));
    KipluoSound.play(KSound.tick, at: context, pitch: 0.8 + ratio * 0.55, componentEnabled: widget.sound);
    widget.onChanged!(next);
  }

  void _startRepeat(int delta) {
    _stepBy(delta);
    _holdCount = 0;
    _holdTimer?.cancel();
    void scheduleNext() {
      _holdCount++;
      final delayMs = (_holdCount < 4) ? 180 : (_holdCount < 10 ? 95 : 55);
      _holdTimer = Timer(Duration(milliseconds: delayMs), () {
        if (!mounted) return;
        _stepBy(delta);
        scheduleNext();
      });
    }

    _holdTimer = Timer(const Duration(milliseconds: 340), scheduleNext);
  }

  void _stopRepeat() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final enabled = widget.onChanged != null;
    return Semantics(
      label: widget.label,
      value: '${widget.value}',
      increasedValue: '${(widget.value + widget.step).clamp(widget.min, widget.max)}',
      decreasedValue: '${(widget.value - widget.step).clamp(widget.min, widget.max)}',
      onIncrease: enabled ? () => _stepBy(1) : null,
      onDecrease: enabled ? () => _stepBy(-1) : null,
      child: FocusableActionDetector(
        enabled: enabled,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp): _StepDir(1),
          SingleActivator(LogicalKeyboardKey.arrowRight): _StepDir(1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _StepDir(-1),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _StepDir(-1),
        },
        actions: {
          _StepDir: CallbackAction<_StepDir>(onInvoke: (d) => _stepBy(d.dir)),
        },
        child: AnimatedBuilder(
          animation: _s,
          builder: (context, child) => Transform.translate(offset: Offset(_s['x'], 0), child: child),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.line, width: t.stroke * 0.55),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepBtn(
                  icon: Icons.remove_rounded,
                  tokens: t,
                  enabled: enabled,
                  onDown: () => _startRepeat(-1),
                  onUp: _stopRepeat,
                ),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: kipluoReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 140),
                      transitionBuilder: (c, anim) => SlideTransition(
                        position: Tween<Offset>(begin: Offset(0, _dir * 0.35), end: Offset.zero).animate(anim),
                        child: FadeTransition(opacity: anim, child: c),
                      ),
                      child: Text(
                        '${widget.value}',
                        key: ValueKey(widget.value),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add_rounded,
                  tokens: t,
                  enabled: enabled,
                  onDown: () => _startRepeat(1),
                  onUp: _stopRepeat,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.tokens, required this.enabled, required this.onDown, required this.onUp});
  final IconData icon;
  final KipluoTokens tokens;
  final bool enabled;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: enabled ? (_) => onDown() : null,
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: tokens.track,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: tokens.line),
      ),
    );
  }
}

class _StepDir extends Intent {
  const _StepDir(this.dir);
  final int dir;
}
