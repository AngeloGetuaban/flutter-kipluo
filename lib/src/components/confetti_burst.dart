import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';

class _Piece {
  _Piece({required this.x, required this.y, required this.vx, required this.vy, required this.rot, required this.vr, required this.color, required this.w, required this.h});
  double x, y, vx, vy, rot, vr;
  final Color color;
  final double w, h;
}

/// Celebration button emitting physics confetti (gravity, drag, tumble) capped at 220 active
/// pieces so rapid spam stays cheap; ticker automatically stops when all pieces land.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.pieces = 60,
    this.label = 'Celebrate',
    this.colors,
    this.onPressed,
    this.sound = true,
  });

  final int pieces;
  final String label;
  final List<Color>? colors;
  final VoidCallback? onPressed;
  final bool sound;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  final List<_Piece> _pieces = [];
  late final Ticker _ticker;
  Duration? _last;
  final _rand = math.Random(19);
  bool _reducedGlow = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_step);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _step(Duration elapsed) {
    final dt = _last == null ? 1 / 60 : ((elapsed - _last!).inMicroseconds / 1e6).clamp(0.001, 0.05);
    _last = elapsed;
    for (final p in _pieces) {
      p.vy += 420 * dt;
      p.vx *= math.pow(0.28, dt).toDouble();
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += p.vr * dt;
    }
    _pieces.removeWhere((p) => p.y > 160);
    if (_pieces.isEmpty) {
      _ticker.stop();
      _last = null;
    }
    if (mounted) setState(() {});
  }

  void _fire() {
    KipluoSound.play(KSound.pop, at: context, volume: 0.7, componentEnabled: widget.sound);
    KipluoSound.play(KSound.sparkle, at: context, volume: 0.65, componentEnabled: widget.sound);
    widget.onPressed?.call();

    if (kipluoReducedMotion(context)) {
      setState(() => _reducedGlow = true);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _reducedGlow = false);
      });
      return;
    }

    final t = KipluoTheme.tokensOf(context);
    final palette = widget.colors ?? [t.accent, t.ok, t.bad, KipluoColors.ring, t.line];
    final room = (220 - _pieces.length).clamp(0, widget.pieces);
    for (var i = 0; i < room; i++) {
      final angle = -math.pi / 2 + (_rand.nextDouble() - 0.5) * 1.65;
      final speed = 110 + _rand.nextDouble() * 190;
      _pieces.add(_Piece(
        x: 70 + (_rand.nextDouble() - 0.5) * 26,
        y: 26,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        rot: _rand.nextDouble() * math.pi * 2,
        vr: (_rand.nextDouble() - 0.5) * 14,
        color: palette[i % palette.length],
        w: 5 + _rand.nextDouble() * 4,
        h: 4 + _rand.nextDouble() * 3,
      ));
    }
    if (!_ticker.isActive && _pieces.isNotEmpty) {
      _last = null;
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (_pieces.isNotEmpty)
          Positioned(
            left: -40,
            top: -80,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _ConfettiPainter(pieces: _pieces),
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: _reducedGlow ? [BoxShadow(color: t.accent, blurRadius: 16, spreadRadius: 3)] : [BoxShadow(color: t.line, offset: const Offset(2, 3))],
          ),
          child: Material(
            color: t.accent,
            shape: StadiumBorder(side: BorderSide(color: t.line, width: t.stroke * 0.6)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: _fire,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration_rounded, size: 18, color: t.accentInk),
                    const SizedBox(width: 8),
                    Text(widget.label, style: TextStyle(color: t.accentInk, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces});
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      canvas.save();
      canvas.translate(p.x + 40, p.y + 80);
      canvas.rotate(p.rot);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h), Paint()..color = p.color);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
