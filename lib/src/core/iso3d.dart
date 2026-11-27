import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 3D point/vector for Kipluo's zero-dependency 3D projection engine.
/// Mirrors `apps/web/src/components/demos/wave9/iso3d.ts`.
class KVec3 {
  const KVec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

class KVec2 {
  const KVec2(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  Offset get offset => Offset(x, y);
}

enum KFaceShade { top, left, right, front, back, bottom }

class KProjectedFace {
  const KProjectedFace({
    required this.points,
    required this.depth,
    required this.light,
    required this.shade,
  });

  final List<KVec2> points;
  final double depth;
  final double light;
  final KFaceShade shade;

  Path toPath() {
    final path = Path()..moveTo(points[0].x, points[0].y);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }
    path.close();
    return path;
  }
}

class KProjectedEdge {
  const KProjectedEdge({required this.a, required this.b, required this.depth});
  final KVec2 a;
  final KVec2 b;
  final double depth;
}

/// Rotates a 3D point by Euler angles in radians (Y -> X -> Z).
KVec3 kRotate3D(KVec3 p, double rx, double ry, [double rz = 0]) {
  final cy = math.cos(ry);
  final sy = math.sin(ry);
  final x1 = p.x * cy + p.z * sy;
  final z1 = -p.x * sy + p.z * cy;
  final y1 = p.y;

  final cx = math.cos(rx);
  final sx = math.sin(rx);
  final y2 = y1 * cx - z1 * sx;
  final z2 = y1 * sx + z1 * cx;
  final x2 = x1;

  if (rz == 0) return KVec3(x2, y2, z2);
  final cz = math.cos(rz);
  final sz = math.sin(rz);
  return KVec3(x2 * cz - y2 * sz, x2 * sz + y2 * cz, z2);
}

/// Projects a rotated 3D point onto a 2D 100×100 viewport (y-up world -> y-down screen).
KVec2 kProjectPoint(
  KVec3 p, {
  double cx = 50,
  double cy = 50,
  double scale = 1,
  double perspective = 0,
}) {
  final k = perspective > 0 ? perspective / math.max(0.5, perspective - p.z) : 1.0;
  return KVec2(cx + p.x * scale * k, cy - p.y * scale * k, p.z);
}

const _cubeVerts = <KVec3>[
  KVec3(-0.5, -0.5, -0.5),
  KVec3(0.5, -0.5, -0.5),
  KVec3(0.5, 0.5, -0.5),
  KVec3(-0.5, 0.5, -0.5),
  KVec3(-0.5, -0.5, 0.5),
  KVec3(0.5, -0.5, 0.5),
  KVec3(0.5, 0.5, 0.5),
  KVec3(-0.5, 0.5, 0.5),
];

const _cubeFaces = <({List<int> idx, KFaceShade shade})>[
  (idx: [4, 5, 6, 7], shade: KFaceShade.front),
  (idx: [1, 0, 3, 2], shade: KFaceShade.back),
  (idx: [7, 6, 2, 3], shade: KFaceShade.top),
  (idx: [0, 1, 5, 4], shade: KFaceShade.bottom),
  (idx: [5, 1, 2, 6], shade: KFaceShade.right),
  (idx: [0, 4, 7, 3], shade: KFaceShade.left),
];

const _cubeEdges = <(int, int)>[
  (0, 1), (1, 2), (2, 3), (3, 0),
  (4, 5), (5, 6), (6, 7), (7, 4),
  (0, 4), (1, 5), (2, 6), (3, 7),
];

const _light = KVec3(-0.38, 0.78, 0.49);

/// Builds backface-culled projected faces for a 3D box centered at [center].
List<KProjectedFace> kProjectBoxFaces(
  KVec3 center,
  KVec3 size,
  double rx,
  double ry, {
  double rz = 0,
  double cx = 50,
  double cy = 50,
  double scale = 1,
  double perspective = 0,
  double localRx = 0,
  double localRy = 0,
  double localRz = 0,
}) {
  final hasLocal = localRx != 0 || localRy != 0 || localRz != 0;
  final worldVerts = _cubeVerts.map((v) {
    var p = KVec3(v.x * size.x, v.y * size.y, v.z * size.z);
    if (hasLocal) p = kRotate3D(p, localRx, localRy, localRz);
    p = KVec3(p.x + center.x, p.y + center.y, p.z + center.z);
    return kRotate3D(p, rx, ry, rz);
  }).toList(growable: false);

  final projVerts = worldVerts
      .map((v) => kProjectPoint(v, cx: cx, cy: cy, scale: scale, perspective: perspective))
      .toList(growable: false);

  final faces = <KProjectedFace>[];
  for (final f in _cubeFaces) {
    final i0 = f.idx[0], i1 = f.idx[1], i2 = f.idx[2], i3 = f.idx[3];
    final w0 = worldVerts[i0], w1 = worldVerts[i1], w2 = worldVerts[i2], w3 = worldVerts[i3];
    final p0 = projVerts[i0], p1 = projVerts[i1], p2 = projVerts[i2], p3 = projVerts[i3];

    final area2d = (p1.x - p0.x) * (p2.y - p0.y) - (p1.y - p0.y) * (p2.x - p0.x);
    if (area2d >= 0) continue;

    final ux = w1.x - w0.x, uy = w1.y - w0.y, uz = w1.z - w0.z;
    final vx = w2.x - w0.x, vy = w2.y - w0.y, vz = w2.z - w0.z;
    final nx = uy * vz - uz * vy;
    final ny = uz * vx - ux * vz;
    final nz = ux * vy - uy * vx;
    final len = math.sqrt(nx * nx + ny * ny + nz * nz);
    final invLen = len > 0 ? 1 / len : 1.0;
    final dot = (nx * _light.x + ny * _light.y + nz * _light.z) * invLen;
    final light = (0.52 + dot * 0.48).clamp(0.0, 1.0);
    final depth = (w0.z + w1.z + w2.z + w3.z) * 0.25;

    faces.add(KProjectedFace(points: [p0, p1, p2, p3], depth: depth, light: light, shade: f.shade));
  }
  return faces;
}

/// Projects all 12 wireframe edges of a 3D box, sorted back-to-front by average Z.
List<KProjectedEdge> kProjectWireframeBox(
  KVec3 center,
  KVec3 size,
  double rx,
  double ry, {
  double rz = 0,
  double cx = 50,
  double cy = 50,
  double scale = 1,
  double perspective = 0,
}) {
  final worldVerts = _cubeVerts
      .map((v) => kRotate3D(KVec3(v.x * size.x + center.x, v.y * size.y + center.y, v.z * size.z + center.z), rx, ry, rz))
      .toList(growable: false);
  final projVerts = worldVerts
      .map((v) => kProjectPoint(v, cx: cx, cy: cy, scale: scale, perspective: perspective))
      .toList(growable: false);
  final edges = _cubeEdges
      .map((e) => KProjectedEdge(a: projVerts[e.$1], b: projVerts[e.$2], depth: (worldVerts[e.$1].z + worldVerts[e.$2].z) * 0.5))
      .toList(growable: false);
  edges.sort((a, b) => a.depth.compareTo(b.depth));
  return edges;
}

/// Shades a Kipluo token color using directional brightness [light] (0..1).
Color kShadeColor(Color base, Color line, double light) {
  if (light >= 0.78) {
    final t = ((light - 0.78) * 1.1).clamp(0.0, 0.45);
    return Color.lerp(base, Colors.white, t) ?? base;
  }
  final t = ((0.78 - light) * 0.58).clamp(0.0, 0.55);
  return Color.lerp(base, line, t) ?? base;
}
