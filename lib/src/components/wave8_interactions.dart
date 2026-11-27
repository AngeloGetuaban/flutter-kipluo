import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';

/* 34. Elastic Signature Pad (Free) */

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key, this.sound = true});
  final bool sound;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _pts = [];
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return SizedBox(
      width: 244,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onPanUpdate: (d) => setState(() {
              _pts.add(d.localPosition);
              _saved = false;
            }),
            onPanEnd: (_) => _pts.add(null),
            child: Container(
              width: 244,
              height: 86,
              decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.line, width: t.stroke)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: const Size(244, 86), painter: _SigPainter(pts: _pts, line: t.line)),
                  if (_pts.isEmpty) Text('Sign here…', style: TextStyle(fontSize: 11, color: t.line.withValues(alpha: 0.45))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _pts.clear();
                    _saved = false;
                  });
                  KipluoSound.play(KSound.swish, at: context, volume: 0.42, componentEnabled: widget.sound);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: t.track, borderRadius: BorderRadius.circular(99)),
                  child: Text('Clear', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.line)),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _saved = true;
                  });
                  KipluoSound.play(KSound.chime, at: context, volume: 0.55, componentEnabled: widget.sound);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: _saved ? t.ok : t.accent, borderRadius: BorderRadius.circular(99), border: Border.all(color: t.line, width: 1.5)),
                  child: Text(_saved ? 'Saved ✓' : 'Save', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _saved ? Colors.white : t.accentInk)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SigPainter extends CustomPainter {
  const _SigPainter({required this.pts, required this.line});
  final List<Offset?> pts;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = line..strokeWidth = 2.6..strokeCap = StrokeCap.round;
    for (var i = 0; i < pts.length - 1; i++) {
      if (pts[i] != null && pts[i + 1] != null) canvas.drawLine(pts[i]!, pts[i + 1]!, p);
    }
  }

  @override
  bool shouldRepaint(_SigPainter old) => true;
}
