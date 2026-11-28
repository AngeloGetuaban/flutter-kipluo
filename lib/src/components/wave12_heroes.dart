import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* ==========================================================================
   Shared 3D Roaming Particle Backdrop — 5 Distinct Species & Motion Mechanics
   ========================================================================== */
enum _HeroParticleVariant { orbit, prism, warp, pulse, confetti }

class _HeroParticles3DBackdrop extends StatefulWidget {
  const _HeroParticles3DBackdrop({
    required this.accent,
    required this.line,
    this.variant = _HeroParticleVariant.orbit,
    this.count = 36,
    this.intensity = 0.8,
    this.seed = 17,
  });

  final Color accent;
  final Color line;
  final _HeroParticleVariant variant;
  final int count;
  final double intensity;
  final int seed;

  @override
  State<_HeroParticles3DBackdrop> createState() => _HeroParticles3DBackdropState();
}

class _HeroParticles3DBackdropState extends State<_HeroParticles3DBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = kipluoReducedMotion(context);
    if (reduced && _ctrl.isAnimating) {
      _ctrl.stop();
    } else if (!reduced && !_ctrl.isAnimating) {
      _ctrl.repeat();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _HeroParticles3DPainter(
            keepOut: _keepOut,
            t: reduced ? 0.25 : _ctrl.value * math.pi * 2,
            variant: widget.variant,
            accent: widget.accent,
            line: widget.line,
            count: widget.count,
            intensity: widget.intensity,
            seed: widget.seed,
          ),
        ),
      ),
    );
  }

  /// Boxes of the text drawn on top of the backdrop (its siblings in the hero's Stack), in the
  /// backdrop's coordinates. Solids fade out behind them so headlines and copy stay readable.
  List<Rect> _keepOut() {
    final self = context.findRenderObject();
    if (self is! RenderBox || !self.attached || !self.hasSize) return const [];
    final host = self.parent;
    if (host is! RenderStack) return const [];
    final origin = self.localToGlobal(Offset.zero);
    final rects = <Rect>[];
    void visit(RenderObject o) {
      if (identical(o, self)) return;
      if (o is RenderParagraph || o is RenderEditable) {
        final b = o as RenderBox;
        if (b.hasSize) rects.add((b.localToGlobal(Offset.zero) - origin) & b.size);
        return;
      }
      o.visitChildren(visit);
    }

    host.visitChildren(visit);
    return rects;
  }
}

class _Mesh3D {
  const _Mesh3D(this.verts, this.faces);
  final List<(double, double, double)> verts;
  final List<List<int>> faces;

  static _Mesh3D box(double w, double h, double d) {
    final x = w * 0.5, y = h * 0.5, z = d * 0.5;
    return _Mesh3D(
      [(-x, -y, z), (x, -y, z), (x, y, z), (-x, y, z), (-x, -y, -z), (x, -y, -z), (x, y, -z), (-x, y, -z)],
      const [[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7], [1, 5, 6, 2], [4, 5, 1, 0], [3, 2, 6, 7]],
    );
  }

  static _Mesh3D octahedron(double r, [double stretchY = 1.3]) => _Mesh3D(
        [(0, -r * stretchY, 0), (r, 0, 0), (0, 0, r), (-r, 0, 0), (0, 0, -r), (0, r * stretchY, 0)],
        const [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1], [5, 2, 1], [5, 3, 2], [5, 4, 3], [5, 1, 4]],
      );

  static _Mesh3D tetrahedron(double r) {
    final s = r * 0.88;
    return _Mesh3D(
      [(s, s, s), (-s, -s, s), (-s, s, -s), (s, -s, -s)],
      const [[0, 2, 1], [0, 1, 3], [0, 3, 2], [1, 2, 3]],
    );
  }

  static _Mesh3D prism(int sides, double r, double h) {
    final verts = <(double, double, double)>[];
    final half = h * 0.5;
    for (int i = 0; i < sides; i++) {
      final a = (i / sides) * math.pi * 2;
      verts.add((math.cos(a) * r, -half, math.sin(a) * r));
    }
    for (int i = 0; i < sides; i++) {
      final a = (i / sides) * math.pi * 2;
      verts.add((math.cos(a) * r, half, math.sin(a) * r));
    }
    final top = List.generate(sides, (i) => i);
    final bot = List.generate(sides, (i) => sides + (sides - 1 - i));
    final faces = <List<int>>[top, bot];
    for (int i = 0; i < sides; i++) {
      final nxt = (i + 1) % sides;
      faces.add([i, sides + i, sides + nxt, nxt]);
    }
    return _Mesh3D(verts, faces);
  }
}

final _kCube = _Mesh3D.box(1.15, 1.15, 1.15);
final _kTriPrism = _Mesh3D.prism(3, 0.92, 1.25);
final _kHexPrism = _Mesh3D.prism(6, 0.88, 0.55);
final _kOcta = _Mesh3D.octahedron(0.95, 1.32);
final _kTetra = _Mesh3D.tetrahedron(1.0);
final _kDataBar = _Mesh3D.box(0.55, 1.55, 0.55);
final _kSlab = _Mesh3D.box(1.75, 1.12, 0.24);
final _kPillSlab = _Mesh3D.box(1.5, 0.62, 0.28);

class _HeroParticles3DPainter extends CustomPainter {
  const _HeroParticles3DPainter({
    required this.keepOut,
    required this.t,
    required this.variant,
    required this.accent,
    required this.line,
    required this.count,
    required this.intensity,
    required this.seed,
  });

  final List<Rect> Function() keepOut;
  final double t;
  final _HeroParticleVariant variant;

  /// Breathing room around text, and how visible a solid stays while behind it.
  static const double _keepOutPad = 10;
  static const double _keepOutAlpha = 0.06;

  /// 0 behind text, rising smoothly to 1 within 18px of clearing it (no popping as solids drift).
  static double _textFade(List<Rect> zones, double x, double y, double rad) {
    var nearest = double.infinity;
    for (final r in zones) {
      final q = r.inflate(_keepOutPad);
      final dx = math.max(0.0, math.max(q.left - x, x - q.right));
      final dy = math.max(0.0, math.max(q.top - y, y - q.bottom));
      nearest = math.min(nearest, math.sqrt(dx * dx + dy * dy) - rad);
    }
    if (nearest == double.infinity) return 1;
    final k = (nearest / 18).clamp(0.0, 1.0);
    final smooth = k * k * (3 - 2 * k);
    return _keepOutAlpha + (1 - _keepOutAlpha) * smooth;
  }
  final Color accent;
  final Color line;
  final int count;
  final double intensity;
  final int seed;

  static (double, double, double) _rot((double, double, double) v, double rx, double ry, double rz) {
    var (x, y, z) = v;
    final cx = math.cos(rx), sx = math.sin(rx);
    final y1 = y * cx - z * sx;
    final z1 = y * sx + z * cx;
    y = y1;
    z = z1;
    final cy = math.cos(ry), sy = math.sin(ry);
    final x2 = x * cy + z * sy;
    final z2 = -x * sy + z * cy;
    x = x2;
    z = z2;
    final cz = math.cos(rz), sz = math.sin(rz);
    return (x * cz - y * sz, x * sz + y * cz, z);
  }

  void _drawMesh(
    Canvas canvas,
    _Mesh3D mesh,
    double cx,
    double cy,
    double pxScale,
    double rx,
    double ry,
    double rz,
    Color baseCol,
    Color shadowCol,
    Color edgeCol,
    double alpha,
  ) {
    final xf = [for (final v in mesh.verts) _rot(v, rx, ry, rz)];
    final proj = [
      for (final (vx, vy, vz) in xf)
        (cx + vx * pxScale * (3.2 / (3.2 - vz * 0.42)), cy + vy * pxScale * (3.2 / (3.2 - vz * 0.42)), vz),
    ];

    final vis = <({List<Offset> pts, double zAvg, double diff, double rim, double spec})>[];
    for (final idx in mesh.faces) {
      final a = xf[idx[0]], b = xf[idx[1]], c = xf[idx[2]];
      final ux = b.$1 - a.$1, uy = b.$2 - a.$2, uz = b.$3 - a.$3;
      final vx = c.$1 - a.$1, vy = c.$2 - a.$2, vz = c.$3 - a.$3;
      var nx = uy * vz - uz * vy;
      var ny = uz * vx - ux * vz;
      var nz = ux * vy - uy * vx;
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len < 1e-5) continue;
      nx /= len;
      ny /= len;
      nz /= len;
      if (nz <= 0.01) continue;

      final diff = math.max(0.0, nx * -0.46 + ny * -0.62 + nz * 0.64);
      final rim = math.max(0.0, nx * 0.58 + ny * 0.48 + nz * 0.42);
      final hDot = math.max(0.0, nx * -0.24 + ny * -0.32 + nz * 0.92);
      final spec = math.pow(hDot, 16).toDouble();

      double zAvg = 0;
      final pts = <Offset>[];
      for (final k in idx) {
        final p = proj[k];
        pts.add(Offset(p.$1, p.$2));
        zAvg += p.$3;
      }
      vis.add((pts: pts, zAvg: zAvg / idx.length, diff: diff, rim: rim, spec: spec));
    }

    vis.sort((a, b) => a.zAvg.compareTo(b.zAvg));
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (pxScale * 0.065).clamp(0.75, 1.35)
      ..strokeJoin = StrokeJoin.round;

    for (final f in vis) {
      final lit = Color.lerp(shadowCol, baseCol, (0.32 + f.diff * 0.78).clamp(0.0, 1.0))!;
      final shaded = Color.lerp(lit, Colors.white, (f.rim * 0.22 + f.spec * 0.55).clamp(0.0, 1.0))!;
      final path = Path()..addPolygon(f.pts, true);
      fillPaint.color = shaded.withValues(alpha: alpha);
      canvas.drawPath(path, fillPaint);
      strokePaint.color = edgeCol.withValues(alpha: alpha * 0.55);
      canvas.drawPath(path, strokePaint);
    }
  }

  void _drawSphere(Canvas canvas, double cx, double cy, double r, double tilt, bool ringed, Color baseCol, Color shadowCol, double alpha) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, r * 0.26);
    void ringHalf(bool front) {
      if (!ringed) return;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(tilt);
      canvas.scale(1.0, 0.34);
      ringPaint.color = accent.withValues(alpha: alpha * (front ? 0.85 : 0.42));
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 1.75), front ? 0 : math.pi, math.pi, false, ringPaint);
      canvas.restore();
    }

    ringHalf(false);
    final hi = Color.lerp(baseCol, Colors.white, 0.72)!;
    final dark = Color.lerp(shadowCol, baseCol, 0.25)!;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.34, -0.36),
        radius: 0.95,
        colors: [hi.withValues(alpha: alpha), baseCol.withValues(alpha: alpha), dark.withValues(alpha: alpha)],
      ).createShader(rect);
    canvas.drawCircle(Offset(cx, cy), r, paint);
    ringHalf(true);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rand = math.Random(seed);
    final isDark = line.computeLuminance() > 0.45;
    final surfaceCol = isDark ? Color.lerp(const Color(0xFF2C2950), line, 0.22)! : Color.lerp(const Color(0xFFE4E1F0), line, 0.16)!;
    final shadowCol = isDark ? const Color(0xFF0A081A) : Color.lerp(line, Colors.black, 0.25)!;

    final items = <({double sx, double sy, double z, double pxSz, double rx, double ry, double rz, int kind, bool acc})>[];
    for (int i = 0; i < count; i++) {
      var bx = (rand.nextDouble() - 0.5) * 0.92;
      final by = (rand.nextDouble() - 0.5) * 0.88;
      if (bx.abs() < 0.18 && by.abs() < 0.2 && i.isEven) {
        bx = (bx < 0 ? -1 : 1) * (0.24 + rand.nextDouble() * 0.22);
      }
      final bz = 0.36 + rand.nextDouble() * 1.25;
      final orbR = 0.22 + rand.nextDouble() * 0.32;
      final inc = (rand.nextDouble() - 0.5) * 0.65;
      final ph = rand.nextDouble() * math.pi * 2;
      final ph2 = rand.nextDouble() * math.pi * 2;
      final sz = 9.0 + rand.nextDouble() * 8.0;
      final rx0 = rand.nextDouble() * math.pi * 2;
      final ry0 = rand.nextDouble() * math.pi * 2;
      final rz0 = rand.nextDouble() * math.pi * 2;
      final kind = i % 3;

      double x = bx, y = by, z = bz;
      double rx = rx0 + t * (1 + (i % 2));
      double ry = ry0 + t * (1 + ((i + 1) % 2));
      double rz = rz0 + t * 0.7;

      switch (variant) {
        case _HeroParticleVariant.orbit:
          final ang = ph + t * (1 + (i % 2));
          x = math.cos(ang) * orbR * 1.15;
          y = -0.02 + math.sin(ang) * orbR * 0.45 + math.cos(ang + ph2) * inc * 0.25;
          z = (0.85 + math.sin(ang) * orbR * 1.05).clamp(0.32, 1.65);
        case _HeroParticleVariant.prism:
          final rawY = (by - (t / (math.pi * 2)) * (1 + (i % 2))) % 1.0;
          y = rawY - 0.5;
          x = (bx + math.sin(t * 2 + ph) * 0.06).clamp(-0.48, 0.48);
          z = (bz + math.cos(t + ph2) * 0.14).clamp(0.36, 1.6);
        case _HeroParticleVariant.warp:
          final cycle = (bz - (t / (math.pi * 2)) * (1.2 + (i % 3) * 0.4)) % 1.65;
          z = 0.28 + (cycle < 0 ? cycle + 1.65 : cycle);
        case _HeroParticleVariant.pulse:
          x = (bx + math.sin(t + ph) * 0.05).clamp(-0.48, 0.48);
          y = (by + math.sin(t * 2 + ph2) * 0.05).clamp(-0.46, 0.46);
          z = (bz + math.cos(t + ph) * 0.12).clamp(0.38, 1.58);
          if (kind != 0) {
            rx = 0.36 + math.sin(t + ph) * 0.14;
            rz = math.cos(t + ph2) * 0.12;
          }
        case _HeroParticleVariant.confetti:
          final amp = 0.08 + orbR * 0.22;
          x = (bx + math.sin(t + ph) * amp).clamp(-0.48, 0.48);
          y = (by + math.sin(t * 2 + ph2) * amp * 0.52).clamp(-0.48, 0.48);
          z = (bz + math.cos(t + ph) * 0.22).clamp(0.36, 1.58);
      }

      final scale = 1.05 / (1.05 + z);
      final spread = variant == _HeroParticleVariant.warp ? scale * 1.45 : 0.78 + scale * 0.48;
      items.add((
        sx: (0.5 + x * spread) * size.width,
        sy: (0.5 + y * spread) * size.height,
        z: z,
        pxSz: sz * scale,
        rx: rx,
        ry: ry,
        rz: rz,
        kind: kind,
        acc: i.isEven,
      ));
    }

    items.sort((a, b) => b.z.compareTo(a.z));
    final zones = keepOut();

    for (final it in items) {
      final fade = _textFade(zones, it.sx, it.sy, it.pxSz * 0.9);
      if (fade < 0.02) continue;
      final alpha = ((1.85 - it.z) * 0.72 * intensity).clamp(0.24, 0.92) * fade;
      final baseCol = it.acc ? accent : surfaceCol;
      final edgeCol = it.acc ? Color.lerp(accent, line, 0.35)! : line;

      switch (variant) {
        case _HeroParticleVariant.orbit:
          if (it.kind == 0) {
            _drawMesh(canvas, _kOcta, it.sx, it.sy, it.pxSz * 0.95, it.rx, it.ry, it.rz, baseCol, shadowCol, edgeCol, alpha);
          } else {
            _drawSphere(canvas, it.sx, it.sy, it.pxSz * 0.8, it.rz * 0.45, it.kind == 1, baseCol, shadowCol, alpha);
          }
        case _HeroParticleVariant.prism:
          final m = it.kind == 0 ? _kCube : it.kind == 1 ? _kTriPrism : _kOcta;
          _drawMesh(canvas, m, it.sx, it.sy, it.pxSz, it.rx, it.ry, it.rz, baseCol, shadowCol, edgeCol, alpha);
        case _HeroParticleVariant.warp:
          final m = it.kind == 0 ? _kHexPrism : it.kind == 1 ? _kTetra : _kOcta;
          _drawMesh(canvas, m, it.sx, it.sy, it.pxSz * 1.05, it.rx, it.ry, it.rz, baseCol, shadowCol, edgeCol, alpha);
        case _HeroParticleVariant.pulse:
          final m = it.kind == 0 ? _kOcta : _kDataBar;
          _drawMesh(canvas, m, it.sx, it.sy, it.pxSz * 0.95, it.rx, it.ry, it.rz, baseCol, shadowCol, edgeCol, alpha);
        case _HeroParticleVariant.confetti:
          final m = it.kind == 0 ? _kSlab : it.kind == 1 ? _kPillSlab : _kCube;
          _drawMesh(canvas, m, it.sx, it.sy, it.pxSz * 0.85, it.rx, it.ry, it.rz, baseCol, shadowCol, edgeCol, alpha);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeroParticles3DPainter old) =>
      old.t != t || old.variant != variant || old.accent != accent || old.line != line || old.intensity != intensity;
}

/* ==========================================================================
   Wave 12 — Five Interactive Hero Widgets
   1. EditorialSplitHero (Free)
   2. ScrollExpandHero (Paid)
   3. ShaderHorizonHero (Free)
   4. InteractiveDashboardHero (Paid)
   5. CardFanHero (Paid)
   ========================================================================== */

/* 1. EditorialSplitHero (Free) */
class EditorialSplitHero extends StatefulWidget {
  const EditorialSplitHero({
    super.key,
    this.headline = 'Every trip detail in one shared plan',
    this.emphasis = '',
    this.subtitle = "Flights, stays and day plans your whole group can edit, even offline.",
    this.ctaLabel = 'Join the waitlist',
    this.onSubscribe,
    this.particles = true,
    this.sound = true,
  });

  final String headline, emphasis, subtitle, ctaLabel;
  final ValueChanged<String>? onSubscribe;
  final bool particles;
  final bool sound;

  @override
  State<EditorialSplitHero> createState() => _EditorialSplitHeroState();
}

class _EditorialSplitHeroState extends State<EditorialSplitHero> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  late final KSprings _springs = KSprings(vsync: this, initial: {'shake': 0.0}, config: SpringConfig.snappy);
  String _status = 'idle';

  void _submit() {
    final v = _ctrl.text.trim();
    if (!v.contains('@') || v.length < 5) {
      setState(() => _status = 'error');
      _springs.reducedMotion = kipluoReducedMotion(context);
      _springs.animateTo({'shake': 0}, velocity: {'shake': 240.0});
      KipluoSound.play(KSound.bonk, at: context, pitch: 0.95, volume: 0.5, componentEnabled: widget.sound);
      return;
    }
    setState(() => _status = 'done');
    widget.onSubscribe?.call(v);
    KipluoSound.play(KSound.chime, at: context, volume: 0.55, componentEnabled: widget.sound);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _springs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final shadows = KipluoTheme.shadowOf(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 540),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.line, width: tokens.stroke * 0.75),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            if (widget.particles)
              Positioned.fill(
                child: _HeroParticles3DBackdrop(
                  variant: _HeroParticleVariant.prism,
                  accent: tokens.accent,
                  line: tokens.line,
                  count: 14,
                  intensity: 0.76,
                  seed: 202,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: tokens.track, borderRadius: BorderRadius.circular(999), border: Border.all(color: tokens.line)),
            child: Text('New: offline trip plans', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tokens.line)),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: widget.emphasis.isEmpty ? widget.headline : '${widget.headline} ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.15, color: tokens.line),
              children: [
                if (widget.emphasis.isNotEmpty)
                  TextSpan(
                    text: widget.emphasis,
                    style: TextStyle(fontStyle: FontStyle.italic, decoration: TextDecoration.underline, decorationColor: tokens.accent),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(widget.subtitle, style: TextStyle(fontSize: 12, color: tokens.line.withValues(alpha: 0.75))),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _springs,
            builder: (context, child) => Transform.translate(offset: Offset(_springs['shake'], 0), child: child),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (_) {
                      if (_status != 'idle') setState(() => _status = 'idle');
                    },
                    style: TextStyle(fontSize: 12, color: tokens.line),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'you@example.com',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(color: _status == 'error' ? tokens.bad : tokens.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(color: _status == 'error' ? tokens.bad : tokens.accent, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _status == 'done' ? tokens.ok : tokens.accent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: tokens.line),
                    ),
                    child: Text(
                      _status == 'done' ? "You're in ✓" : widget.ctaLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _status == 'done' ? Colors.white : tokens.accentInk),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
            ),
          ],
        ),
      ),
    );
  }
}

/* 3. ShaderHorizonHero (Free) */
class ShaderHorizonHero extends StatefulWidget {
  const ShaderHorizonHero({
    super.key,
    this.badge = 'New: meteor shower alerts',
    this.headline = 'Know exactly when to look up',
    this.subtitle = 'Clear-sky forecasts, rocket launches and meteor showers for wherever you are tonight.',
    this.primaryCta = 'Get the app',
    this.secondaryCta = "See tonight's sky",
    this.particles = true,
    this.sound = true,
  });

  final String badge, headline, subtitle, primaryCta, secondaryCta;
  final bool particles;
  final bool sound;

  @override
  State<ShaderHorizonHero> createState() => _ShaderHorizonHeroState();
}

class _ShaderHorizonHeroState extends State<ShaderHorizonHero> {
  bool _launched = false;

  @override
  Widget build(BuildContext context) {
    final tokens = KipluoTheme.tokensOf(context);
    final shadows = KipluoTheme.shadowOf(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 540),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.line, width: tokens.stroke * 0.75),
        boxShadow: shadows,
        gradient: RadialGradient(
          center: const Alignment(0, 1.18),
          radius: 1.05,
          colors: [tokens.accent.withValues(alpha: 0.36), tokens.surface],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            if (widget.particles)
              Positioned.fill(
                child: _HeroParticles3DBackdrop(
                  variant: _HeroParticleVariant.orbit,
                  accent: tokens.accent,
                  line: tokens.line,
                  count: 18,
                  intensity: 0.92,
                  seed: 101,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: tokens.track,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: tokens.line),
                    ),
                    child: Text('✦ ${widget.badge}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tokens.line)),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.headline, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: tokens.line)),
                  const SizedBox(height: 6),
                  Text(widget.subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: tokens.line.withValues(alpha: 0.8))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _launched = !_launched);
                          KipluoSound.play(KSound.chime, at: context, volume: 0.48, componentEnabled: widget.sound);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: tokens.accent, borderRadius: BorderRadius.circular(999), border: Border.all(color: tokens.line)),
                          child: Text(_launched ? 'Link sent ✦' : widget.primaryCta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: tokens.accentInk)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => KipluoSound.play(KSound.boop, at: context, volume: 0.4, componentEnabled: widget.sound),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: tokens.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: tokens.line)),
                          child: Text(widget.secondaryCta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tokens.line)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
