import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Circular countdown timer that drains smoothly, switches into danger red pulse with rising ticks
/// during the final 10 seconds, and chimes at zero.
class CountdownRing extends StatefulWidget {
  const CountdownRing({
    super.key,
    this.seconds = 15,
    this.autoStart = false,
    this.size = 128,
    this.onDone,
    this.sound = true,
  });

  final int seconds;
  final bool autoStart;
  final double size;
  final VoidCallback? onDone;
  final bool sound;

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing> with TickerProviderStateMixin {
  late int _remaining = math.max(1, widget.seconds);
  late bool _running = widget.autoStart;
  Timer? _timer;
  late final KSprings _pulse = KSprings(vsync: this, initial: {'s': 100}, config: SpringConfig.bouncy);

  @override
  void initState() {
    super.initState();
    if (_running) _start();
  }

  @override
  void didUpdateWidget(CountdownRing old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) _reset();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running) return;
      if (_remaining <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining > 0 && _remaining <= 10) {
        _pulse.reducedMotion = kipluoReducedMotion(context);
        _pulse.set({'s': 112});
        _pulse.animateTo({'s': 100});
        KipluoSound.play(KSound.tick, at: context, pitch: 0.9 + (10 - _remaining) * 0.05, componentEnabled: widget.sound);
      }
      if (_remaining == 0) {
        _running = false;
        _timer?.cancel();
        KipluoSound.play(KSound.chime, at: context, componentEnabled: widget.sound);
        widget.onDone?.call();
      }
    });
  }

  void _toggle() {
    setState(() => _running = !_running);
    if (_running && _remaining > 0) {
      _start();
    } else {
      _timer?.cancel();
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = math.max(1, widget.seconds);
      _running = widget.autoStart;
    });
    if (_running) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final danger = _remaining <= 10 && _remaining > 0;
    final frac = (_remaining / math.max(1, widget.seconds)).clamp(0.0, 1.0);
    return Semantics(
      label: 'Timer: $_remaining seconds remaining',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Transform.scale(
              scale: (_pulse['s'] / 100).clamp(0.9, 1.25),
              child: SizedBox.square(
                dimension: widget.size,
                child: CustomPaint(
                  painter: _CountdownPainter(fraction: frac, danger: danger, tokens: t),
                  child: Center(
                    child: Text(
                      '$_remaining',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: danger ? t.bad : t.line),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: _toggle, child: Text(_running ? 'Pause' : 'Play')),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  _CountdownPainter({required this.fraction, required this.danger, required this.tokens});
  final double fraction;
  final bool danger;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    canvas.drawArc(rect, 0, math.pi * 2, false, Paint()..color = tokens.track..style = PaintingStyle.stroke..strokeWidth = stroke);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..color = danger ? tokens.bad : tokens.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter old) => old.fraction != fraction || old.danger != danger || old.tokens != tokens;
}
