import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';
import 'loader_base.dart';

export 'loader_base.dart' show LoaderStatus;

/// A chat "typing…" bubble: three dots hop in turn. When [value] is set, the bubble widens with
/// progress. Complete shows a check, error a cross.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.value, this.status = LoaderStatus.running, this.size = 96, this.label = 'Loading', this.sound = true});

  /// 0–100, or null for the classic loop.
  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TypingIndicator old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      if (widget.status == LoaderStatus.complete) KipluoSound.play(KSound.chime, at: context, volume: 0.6, componentEnabled: widget.sound);
      if (widget.status == LoaderStatus.error) KipluoSound.play(KSound.bonk, at: context, volume: 0.6, componentEnabled: widget.sound);
    }
    _sync();
  }

  void _sync() {
    final run = widget.status == LoaderStatus.running && !kipluoReducedMotion(context);
    if (run && !_loop.isAnimating) _loop.repeat();
    if (!run) _loop.stop();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final status = switch (widget.status) {
      LoaderStatus.complete => '${widget.label} complete',
      LoaderStatus.error => '${widget.label} failed',
      LoaderStatus.running => widget.label,
    };
    return Semantics(
      label: status,
      value: widget.value == null ? null : '${widget.value!.round()}%',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) => CustomPaint(painter: _BubblePainter(t: _loop.value, value: widget.value, status: widget.status, tokens: t)),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.t, required this.value, required this.status, required this.tokens});
  final double t;
  final double? value;
  final LoaderStatus status;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final w = value == null ? 56.0 : 40 + (value!.clamp(0, 100) / 100) * 28;
    final line = Paint()
      ..color = tokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final bubble = RRect.fromRectAndRadius(Rect.fromLTWH(50 - w / 2, 36, w, 28), const Radius.circular(14));
    final tail = Path()
      ..moveTo(30, 62)
      ..lineTo(24, 72)
      ..lineTo(38, 63);
    canvas.drawRRect(bubble, Paint()..color = tokens.surface);
    canvas.drawPath(tail, Paint()..color = tokens.surface);
    canvas.drawRRect(bubble, line);
    canvas.drawPath(tail, line);
    switch (status) {
      case LoaderStatus.running:
        for (var i = 0; i < 3; i++) {
          final ph = (t - i * 0.22) % 1;
          final hop = ph < 0.35 ? math.sin((ph / 0.35) * math.pi) : 0.0;
          canvas.drawCircle(Offset(38 + i * 12.0, 50 - hop * 7), 4, Paint()..color = tokens.accent.withValues(alpha: 0.55 + hop * 0.45));
        }
      case LoaderStatus.complete:
        canvas.drawPath(Path()..moveTo(40, 50)..lineTo(47, 57)..lineTo(61, 43), line..color = tokens.ok..strokeWidth = tokens.stroke * 1.3);
      case LoaderStatus.error:
        canvas.drawPath(Path()..moveTo(43, 44)..lineTo(57, 58)..moveTo(57, 44)..lineTo(43, 58), line..color = tokens.bad..strokeWidth = tokens.stroke * 1.3);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.t != t || old.value != value || old.status != status || old.tokens != tokens;
}
