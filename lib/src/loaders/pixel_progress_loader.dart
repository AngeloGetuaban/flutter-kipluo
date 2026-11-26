import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'loader_base.dart';

/// Beveled 8-bit progress bar whose pixel blocks pop in with top highlights, shimmer sweep,
/// complete pixel confetti, and error red glitch blocks.
class PixelProgressLoader extends StatelessWidget {
  const PixelProgressLoader({super.key, this.value, this.status = LoaderStatus.running, this.size = 96, this.label = 'Loading', this.sound = true});

  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;

  @override
  Widget build(BuildContext context) {
    return KipluoLoaderShell(
      value: value,
      status: status,
      size: size,
      label: label,
      sound: sound,
      duration: const Duration(milliseconds: 1800),
      painterBuilder: (t, p, s, tokens) => _PixelPainter(t: t, progress: p, status: s, tokens: tokens),
    );
  }
}

class _PixelPainter extends CustomPainter {
  _PixelPainter({required this.t, required this.progress, required this.status, required this.tokens});
  final double t;
  final double progress;
  final LoaderStatus status;
  final KipluoTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    const cols = 8;
    const frame = Rect.fromLTWH(10, 41, 80, 18);
    canvas.drawRect(frame, Paint()..color = tokens.surface);
    canvas.drawRect(frame, Paint()..color = tokens.line..style = PaintingStyle.stroke..strokeWidth = 2.4);

    final filled = status == LoaderStatus.complete ? cols : ((progress / 100) * cols).ceil().clamp(1, cols);
    final sweepIdx = (t * cols).floor() % cols;
    final cellColor = status == LoaderStatus.error ? tokens.bad : (status == LoaderStatus.complete ? tokens.ok : tokens.accent);

    for (var i = 0; i < filled; i++) {
      final bx = 14.0 + i * 9.0;
      final isGlitch = status == LoaderStatus.error && i.isOdd;
      final r = Rect.fromLTWH(bx, isGlitch ? 43 : 45, 7, 10);
      canvas.drawRect(r, Paint()..color = cellColor);
      canvas.drawRect(Rect.fromLTWH(bx, r.top, 7, 2.5), Paint()..color = Colors.white.withValues(alpha: i == sweepIdx ? 0.8 : 0.35));
    }

    if (status == LoaderStatus.complete) {
      for (var i = 0; i < 4; i++) {
        canvas.drawRect(Rect.fromLTWH(20.0 + i * 18, 28 + (i.isEven ? 0 : 4), 4, 4), Paint()..color = tokens.accent);
      }
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) => old.t != t || old.progress != progress || old.status != status || old.tokens != tokens;
}
