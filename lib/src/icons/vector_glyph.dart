import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Zero-dependency 24x24 SVG stroke-vector renderer for Kipluo icons in Flutter.
/// Parses compact Lucide-compatible SVG primitive strings (`p:...` path, `c:cx,cy,r`,
/// `r:x,y,w,h,rx`, `l:x1,y1,x2,y2`, `y:x1,y1,...` polyline, `g:x1,y1,...` polygon,
/// `e:cx,cy,rx,ry`) so Flutter renders pixel-identical stroke geometry to React
/// while adapting dynamically to [KipluoTheme] strokeWidth and color tokens.
class KipluoVectorGlyph extends StatelessWidget {
  const KipluoVectorGlyph({
    super.key,
    required this.commands,
    required this.size,
    required this.color,
    this.strokeWidth = 2.0,
  });

  final String commands;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _VectorGlyphPainter(commands: commands, color: color, strokeWidth: strokeWidth),
    );
  }
}

class _VectorGlyphPainter extends CustomPainter {
  const _VectorGlyphPainter({required this.commands, required this.color, required this.strokeWidth});
  final String commands;
  final Color color;
  final double strokeWidth;

  static final Map<String, Path> _cache = {};

  static Path _compiled(String commands) {
    return _cache.putIfAbsent(commands, () {
      final path = Path();
      for (final raw in commands.split('|')) {
        if (raw.length < 3) continue;
        final kind = raw[0];
        final body = raw.substring(2);
        if (kind == 'p') {
          _appendSvgPath(path, body);
        } else {
          final nums = body.split(',').map((s) => double.tryParse(s) ?? 0).toList();
          if (kind == 'c' && nums.length >= 3) {
            path.addOval(Rect.fromCircle(center: Offset(nums[0], nums[1]), radius: nums[2]));
          } else if (kind == 'e' && nums.length >= 4) {
            path.addOval(Rect.fromCenter(center: Offset(nums[0], nums[1]), width: nums[2] * 2, height: nums[3] * 2));
          } else if (kind == 'r' && nums.length >= 4) {
            final rx = nums.length >= 5 ? nums[4] : 0.0;
            path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(nums[0], nums[1], nums[2], nums[3]), Radius.circular(rx)));
          } else if (kind == 'l' && nums.length >= 4) {
            path.moveTo(nums[0], nums[1]);
            path.lineTo(nums[2], nums[3]);
          } else if ((kind == 'y' || kind == 'g') && nums.length >= 4) {
            path.moveTo(nums[0], nums[1]);
            for (var i = 2; i + 1 < nums.length; i += 2) {
              path.lineTo(nums[i], nums[i + 1]);
            }
            if (kind == 'g') path.close();
          }
        }
      }
      return path;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final compiled = _compiled(commands);
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (strokeWidth / math.max(0.5, scale)).clamp(1.2, 2.8)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(compiled, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VectorGlyphPainter old) =>
      old.commands != commands || old.color != color || old.strokeWidth != strokeWidth;
}

final _tokenRe = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?');

void _appendSvgPath(Path path, String d) {
  final tokens = _tokenRe.allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cmd = '';
  var cx = 0.0, cy = 0.0;
  var sx = 0.0, sy = 0.0;
  var lastCtrlX = 0.0, lastCtrlY = 0.0;
  var prevCmd = '';

  double nextNum() => i < tokens.length ? (double.tryParse(tokens[i++]) ?? 0.0) : 0.0;
  bool isCmd(String s) => s.length == 1 && RegExp(r'[A-Za-z]').hasMatch(s);

  while (i < tokens.length) {
    if (isCmd(tokens[i])) {
      cmd = tokens[i++];
    } else if (cmd.isEmpty) {
      i++;
      continue;
    }

    switch (cmd) {
      case 'M':
        cx = nextNum();
        cy = nextNum();
        sx = cx;
        sy = cy;
        path.moveTo(cx, cy);
        cmd = 'L';
      case 'm':
        cx += nextNum();
        cy += nextNum();
        sx = cx;
        sy = cy;
        path.moveTo(cx, cy);
        cmd = 'l';
      case 'L':
        cx = nextNum();
        cy = nextNum();
        path.lineTo(cx, cy);
      case 'l':
        cx += nextNum();
        cy += nextNum();
        path.lineTo(cx, cy);
      case 'H':
        cx = nextNum();
        path.lineTo(cx, cy);
      case 'h':
        cx += nextNum();
        path.lineTo(cx, cy);
      case 'V':
        cy = nextNum();
        path.lineTo(cx, cy);
      case 'v':
        cy += nextNum();
        path.lineTo(cx, cy);
      case 'C':
        final x1 = nextNum(), y1 = nextNum(), x2 = nextNum(), y2 = nextNum(), x = nextNum(), y = nextNum();
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCtrlX = x2;
        lastCtrlY = y2;
        cx = x;
        cy = y;
      case 'c':
        final x1 = cx + nextNum(), y1 = cy + nextNum(), x2 = cx + nextNum(), y2 = cy + nextNum(), x = cx + nextNum(), y = cy + nextNum();
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCtrlX = x2;
        lastCtrlY = y2;
        cx = x;
        cy = y;
      case 'S':
        final x1 = (prevCmd == 'C' || prevCmd == 'c' || prevCmd == 'S' || prevCmd == 's') ? 2 * cx - lastCtrlX : cx;
        final y1 = (prevCmd == 'C' || prevCmd == 'c' || prevCmd == 'S' || prevCmd == 's') ? 2 * cy - lastCtrlY : cy;
        final x2 = nextNum(), y2 = nextNum(), x = nextNum(), y = nextNum();
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCtrlX = x2;
        lastCtrlY = y2;
        cx = x;
        cy = y;
      case 's':
        final x1 = (prevCmd == 'C' || prevCmd == 'c' || prevCmd == 'S' || prevCmd == 's') ? 2 * cx - lastCtrlX : cx;
        final y1 = (prevCmd == 'C' || prevCmd == 'c' || prevCmd == 'S' || prevCmd == 's') ? 2 * cy - lastCtrlY : cy;
        final x2 = cx + nextNum(), y2 = cy + nextNum(), x = cx + nextNum(), y = cy + nextNum();
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCtrlX = x2;
        lastCtrlY = y2;
        cx = x;
        cy = y;
      case 'Q':
        final x1 = nextNum(), y1 = nextNum(), x = nextNum(), y = nextNum();
        path.quadraticBezierTo(x1, y1, x, y);
        lastCtrlX = x1;
        lastCtrlY = y1;
        cx = x;
        cy = y;
      case 'q':
        final x1 = cx + nextNum(), y1 = cy + nextNum(), x = cx + nextNum(), y = cy + nextNum();
        path.quadraticBezierTo(x1, y1, x, y);
        lastCtrlX = x1;
        lastCtrlY = y1;
        cx = x;
        cy = y;
      case 'T':
        final x1 = (prevCmd == 'Q' || prevCmd == 'q' || prevCmd == 'T' || prevCmd == 't') ? 2 * cx - lastCtrlX : cx;
        final y1 = (prevCmd == 'Q' || prevCmd == 'q' || prevCmd == 'T' || prevCmd == 't') ? 2 * cy - lastCtrlY : cy;
        final x = nextNum(), y = nextNum();
        path.quadraticBezierTo(x1, y1, x, y);
        lastCtrlX = x1;
        lastCtrlY = y1;
        cx = x;
        cy = y;
      case 't':
        final x1 = (prevCmd == 'Q' || prevCmd == 'q' || prevCmd == 'T' || prevCmd == 't') ? 2 * cx - lastCtrlX : cx;
        final y1 = (prevCmd == 'Q' || prevCmd == 'q' || prevCmd == 'T' || prevCmd == 't') ? 2 * cy - lastCtrlY : cy;
        final x = cx + nextNum(), y = cy + nextNum();
        path.quadraticBezierTo(x1, y1, x, y);
        lastCtrlX = x1;
        lastCtrlY = y1;
        cx = x;
        cy = y;
      case 'A':
      case 'a':
        final rx = nextNum();
        final ry = nextNum();
        final rot = nextNum();
        final largeArc = nextNum() != 0;
        final sweep = nextNum() != 0;
        final tx = cmd == 'a' ? cx + nextNum() : nextNum();
        final ty = cmd == 'a' ? cy + nextNum() : nextNum();
        path.arcToPoint(
          Offset(tx, ty),
          radius: Radius.elliptical(rx.abs(), ry.abs()),
          rotation: rot,
          largeArc: largeArc,
          clockwise: sweep,
        );
        cx = tx;
        cy = ty;
      case 'Z':
      case 'z':
        path.close();
        cx = sx;
        cy = sy;
      default:
        i++;
    }
    prevCmd = cmd;
  }
}
