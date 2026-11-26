import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Numeric readout whose value rolls smoothly on a spring, rendering animated digit wheels along
/// the shortest step path while reporting the final value cleanly to screen readers.
class RollingCounter extends StatefulWidget {
  const RollingCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.fontSize = 32,
    this.spring = const SpringConfig(stiffness: 220, damping: 22),
    this.sound = true,
  });

  final double value;
  final String prefix;
  final String suffix;
  final int decimals;
  final double fontSize;
  final SpringConfig spring;
  final bool sound;

  @override
  State<RollingCounter> createState() => _RollingCounterState();
}

class _RollingCounterState extends State<RollingCounter> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(vsync: this, initial: {'v': widget.value}, config: widget.spring);
  int _lastSoundStep = 0;

  @override
  void initState() {
    super.initState();
    _lastSoundStep = widget.value.round();
    _s.addListener(_onFrame);
  }

  @override
  void didUpdateWidget(RollingCounter old) {
    super.didUpdateWidget(old);
    _s.config = widget.spring;
    if (old.value != widget.value) {
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'v': widget.value});
    }
  }

  void _onFrame() {
    final cur = _s['v'].round();
    if (cur != _lastSoundStep) {
      _lastSoundStep = cur;
      KipluoSound.play(KSound.tick, at: context, pitch: 1.0 + (_s.spring('v').velocity.abs() / 1200).clamp(0.0, 0.35), volume: 0.35, componentEnabled: widget.sound);
    }
    if (!_s.isAnimating && (_s['v'] - widget.value).abs() < 0.01 && (_lastSoundStep != widget.value.round())) {
      KipluoSound.play(KSound.pop, at: context, volume: 0.45, componentEnabled: widget.sound);
    }
  }

  @override
  void dispose() {
    _s.removeListener(_onFrame);
    _s.dispose();
    super.dispose();
  }

  String _format(double v) {
    final abs = v.abs().toStringAsFixed(widget.decimals);
    final parts = abs.split('.');
    final whole = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    final sign = v < 0 ? '-' : '';
    final dec = parts.length > 1 ? '.${parts[1]}' : '';
    return '$sign${widget.prefix}$whole$dec${widget.suffix}';
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final finalStr = _format(widget.value);
    return Semantics(
      label: finalStr,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _s,
          builder: (context, _) {
            final shown = _format(_s['v']);
            final chars = shown.split('');
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < chars.length; i++)
                  _WheelChar(
                    char: chars[i],
                    fontSize: widget.fontSize,
                    color: t.line,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WheelChar extends StatelessWidget {
  const _WheelChar({required this.char, required this.fontSize, required this.color});
  final String char;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
    if (!isDigit) {
      return Text(char, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: color, fontFeatures: const [FontFeature.tabularFigures()]));
    }
    final d = int.parse(char);
    final h = fontSize * 1.25;
    return SizedBox(
      height: h,
      width: fontSize * 0.62,
      child: Center(
        child: Text(
          char,
          key: ValueKey(d),
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: color, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}

/// Helper used for modular shortest digit distance (exposed cleanly if apps want wheel angles).
int shortestDigitDelta(int from, int to) => ((to - from + 15) % 10) - 5;

double clampProgress(double v) => math.max(0.0, math.min(100.0, v));
