import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/aura_fx.dart';
import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';
import 'icon_shell.dart';

/// Metadata for all 56 multi-part bespoke live icons added in v4 (44 -> 100 bespoke icons).
const List<({String slug, String title, KIconTier tier})> kipluoBespokeV4Icons = [
  (slug: 'terminal-cursor-icon', title: 'Terminal Cursor Icon', tier: KIconTier.free),
  (slug: 'cloud-sync-icon', title: 'Cloud Sync Icon', tier: KIconTier.free),
  (slug: 'api-plug-icon', title: 'API Plug Icon', tier: KIconTier.free),
  (slug: 'sparkle-brain-icon', title: 'Sparkle Brain Icon', tier: KIconTier.premium),
  (slug: 'git-merge-icon', title: 'Git Merge Icon', tier: KIconTier.premium),
  (slug: 'bug-squash-icon', title: 'Bug Squash Icon', tier: KIconTier.premium),
  (slug: 'database-pulse-icon', title: 'Database Pulse Icon', tier: KIconTier.premium),
  (slug: 'cpu-circuit-icon', title: 'CPU Circuit Icon', tier: KIconTier.premium),
  (slug: 'wallet-pop-icon', title: 'Wallet Pop Icon', tier: KIconTier.free),
  (slug: 'tag-swing-icon', title: 'Tag Swing Icon', tier: KIconTier.free),
  (slug: 'percent-bounce-icon', title: 'Percent Bounce Icon', tier: KIconTier.free),
  (slug: 'credit-card-swipe-icon', title: 'Credit Card Swipe Icon', tier: KIconTier.premium),
  (slug: 'coin-flip-icon', title: 'Coin Flip Icon', tier: KIconTier.premium),
  (slug: 'receipt-print-icon', title: 'Receipt Print Icon', tier: KIconTier.premium),
  (slug: 'package-unbox-icon', title: 'Package Unbox Icon', tier: KIconTier.premium),
  (slug: 'truck-deliver-icon', title: 'Truck Deliver Icon', tier: KIconTier.premium),
  (slug: 'play-pause-morph-icon', title: 'Play Pause Morph Icon', tier: KIconTier.free),
  (slug: 'mic-record-icon', title: 'Mic Record Icon', tier: KIconTier.free),
  (slug: 'crop-snap-icon', title: 'Crop Snap Icon', tier: KIconTier.free),
  (slug: 'headphones-bounce-icon', title: 'Headphones Bounce Icon', tier: KIconTier.premium),
  (slug: 'scissors-snip-icon', title: 'Scissors Snip Icon', tier: KIconTier.premium),
  (slug: 'paintbrush-stroke-icon', title: 'Paint Brush Icon', tier: KIconTier.premium),
  (slug: 'palette-spin-icon', title: 'Palette Spin Icon', tier: KIconTier.premium),
  (slug: 'film-reel-icon', title: 'Film Reel Icon', tier: KIconTier.premium),
  (slug: 'sidebar-slide-icon', title: 'Sidebar Slide Icon', tier: KIconTier.free),
  (slug: 'layers-stack-icon', title: 'Layers Stack Icon', tier: KIconTier.free),
  (slug: 'link-chain-icon', title: 'Link Chain Icon', tier: KIconTier.free),
  (slug: 'filter-funnel-icon', title: 'Filter Funnel Icon', tier: KIconTier.premium),
  (slug: 'sort-swap-icon', title: 'Sort Swap Icon', tier: KIconTier.premium),
  (slug: 'paperclip-bend-icon', title: 'Paperclip Bend Icon', tier: KIconTier.premium),
  (slug: 'qr-scan-icon', title: 'QR Scan Icon', tier: KIconTier.premium),
  (slug: 'share-burst-icon', title: 'Share Burst Icon', tier: KIconTier.premium),
  (slug: 'verified-stamp-icon', title: 'Verified Stamp Icon', tier: KIconTier.free),
  (slug: 'eye-peek-toggle-icon', title: 'Eye Peek Icon', tier: KIconTier.free),
  (slug: 'keycard-tap-icon', title: 'Keycard Tap Icon', tier: KIconTier.free),
  (slug: 'fingerprint-scan-icon', title: 'Fingerprint Scan Icon', tier: KIconTier.premium),
  (slug: 'face-id-scan-icon', title: 'Face ID Scan Icon', tier: KIconTier.premium),
  (slug: 'vault-dial-icon', title: 'Vault Dial Icon', tier: KIconTier.premium),
  (slug: 'alarm-siren-icon', title: 'Alarm Siren Icon', tier: KIconTier.premium),
  (slug: 'firewall-pulse-icon', title: 'Firewall Pulse Icon', tier: KIconTier.premium),
  (slug: 'sun-rays-icon', title: 'Sun Rays Icon', tier: KIconTier.free),
  (slug: 'leaf-sway-icon', title: 'Leaf Sway Icon', tier: KIconTier.free),
  (slug: 'wave-splash-icon', title: 'Wave Splash Icon', tier: KIconTier.free),
  (slug: 'snowflake-drift-icon', title: 'Snowflake Drift Icon', tier: KIconTier.premium),
  (slug: 'compass-rose-icon', title: 'Compass Rose Icon', tier: KIconTier.premium),
  (slug: 'plane-takeoff-icon', title: 'Plane Takeoff Icon', tier: KIconTier.premium),
  (slug: 'anchor-drop-icon', title: 'Anchor Drop Icon', tier: KIconTier.premium),
  (slug: 'campfire-flicker-icon', title: 'Campfire Flicker Icon', tier: KIconTier.premium),
  (slug: 'party-popper-icon', title: 'Party Popper Icon', tier: KIconTier.free),
  (slug: 'hourglass-flip-icon', title: 'Hourglass Flip Icon', tier: KIconTier.free),
  (slug: 'crown-bounce-icon', title: 'Crown Bounce Icon', tier: KIconTier.premium),
  (slug: 'magnet-pull-icon', title: 'Magnet Pull Icon', tier: KIconTier.premium),
  (slug: 'balloons-float-icon', title: 'Balloons Float Icon', tier: KIconTier.premium),
  (slug: 'sticker-peel-icon', title: 'Sticker Peel Icon', tier: KIconTier.premium),
  (slug: 'megaphone-shout-icon', title: 'Megaphone Shout Icon', tier: KIconTier.premium),
  (slug: 'corgi-paw-icon', title: 'Corgi Paw Icon', tier: KIconTier.premium),
];

enum _BFill { none, surface, accent, ok, bad, line }

sealed class _BShape {
  const _BShape();
}

class _BRect extends _BShape {
  const _BRect(this.x, this.y, this.w, this.h, this.rx, this.fill);
  final double x, y, w, h, rx;
  final _BFill fill;
}

class _BCircle extends _BShape {
  const _BCircle(this.cx, this.cy, this.r, this.fill);
  final double cx, cy, r;
  final _BFill fill;
}

class _BLine extends _BShape {
  const _BLine(this.x1, this.y1, this.x2, this.y2);
  final double x1, y1, x2, y2;
}

class _BPoly extends _BShape {
  const _BPoly(this.pts, this.closed, this.fill);
  final List<Offset> pts;
  final bool closed;
  final _BFill fill;
}

class _BArc extends _BShape {
  const _BArc(this.cx, this.cy, this.r, this.startDeg, this.endDeg);
  final double cx, cy, r, startDeg, endDeg;
}

class _BespokeV4Spec {
  const _BespokeV4Spec({
    required this.slug,
    required this.title,
    required this.tier,
    required this.motion,
    required this.fx,
    required this.hSfx,
    required this.cSfx,
    required this.px,
    required this.py,
    required this.base,
    required this.mover,
  });

  final String slug, title, motion, fx;
  final KIconTier tier;
  final KSound hSfx, cSfx;
  final double px, py;
  final List<_BShape> base, mover;
}

const Map<String, _BespokeV4Spec> _v4Specs = {
  'terminal-cursor-icon': _BespokeV4Spec(
    slug: 'terminal-cursor-icon',
    title: 'Terminal Cursor Icon',
    tier: KIconTier.free,
    motion: 'blink',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.click,
    px: 29,
    py: 28,
    base: [_BRect(7, 10, 34, 28, 6, _BFill.surface), _BLine(7, 17, 41, 17), _BCircle(12, 13.5, 1.3, _BFill.bad), _BCircle(16.5, 13.5, 1.3, _BFill.accent), _BCircle(21, 13.5, 1.3, _BFill.ok), _BPoly([Offset(14, 23), Offset(20, 27.5), Offset(14, 32)], false, _BFill.none)],
    mover: [_BRect(24, 29, 9, 3.2, 1.2, _BFill.accent)],
  ),
  'cloud-sync-icon': _BespokeV4Spec(
    slug: 'cloud-sync-icon',
    title: 'Cloud Sync Icon',
    tier: KIconTier.free,
    motion: 'spin',
    fx: 'ring',
    hSfx: KSound.whoosh,
    cSfx: KSound.chime,
    px: 24,
    py: 27,
    base: [_BPoly([Offset(14, 34), Offset(35, 34), Offset(39, 31), Offset(40, 26), Offset(36, 22), Offset(32, 22), Offset(29, 15), Offset(21, 14), Offset(15, 18), Offset(13, 23), Offset(9, 25), Offset(8, 30), Offset(11, 34)], true, _BFill.surface)],
    mover: [_BArc(24, 27, 6.5, -140, 20), _BArc(24, 27, 6.5, 40, 200), _BPoly([Offset(28.5, 22), Offset(31, 25.5), Offset(26.8, 25.5)], true, _BFill.accent), _BPoly([Offset(19.5, 32), Offset(17, 28.5), Offset(21.2, 28.5)], true, _BFill.accent)],
  ),
  'api-plug-icon': _BespokeV4Spec(
    slug: 'api-plug-icon',
    title: 'API Plug Icon',
    tier: KIconTier.free,
    motion: 'slideX',
    fx: 'zap',
    hSfx: KSound.tick,
    cSfx: KSound.pop,
    px: 24,
    py: 24,
    base: [_BRect(31, 15, 9, 18, 3, _BFill.surface), _BLine(35.5, 20, 35.5, 28), _BLine(40, 24, 44, 24)],
    mover: [_BRect(10, 17, 13, 14, 4, _BFill.accent), _BLine(23, 21, 29, 21), _BLine(23, 27, 29, 27), _BLine(5, 24, 10, 24)],
  ),
  'sparkle-brain-icon': _BespokeV4Spec(
    slug: 'sparkle-brain-icon',
    title: 'Sparkle Brain Icon',
    tier: KIconTier.premium,
    motion: 'burst',
    fx: 'sparkles',
    hSfx: KSound.boop,
    cSfx: KSound.sparkle,
    px: 24,
    py: 12,
    base: [_BCircle(18, 26, 8.5, _BFill.surface), _BCircle(30, 26, 8.5, _BFill.surface), _BLine(24, 18, 24, 34), _BArc(18, 26, 4.5, 110, 250), _BArc(30, 26, 4.5, -70, 70)],
    mover: [_BPoly([Offset(24, 6), Offset(26, 11), Offset(31, 13), Offset(26, 15), Offset(24, 20), Offset(22, 15), Offset(17, 13), Offset(22, 11)], true, _BFill.accent), _BCircle(38, 12, 2.2, _BFill.accent), _BCircle(10, 12, 1.8, _BFill.accent)],
  ),
  'git-merge-icon': _BespokeV4Spec(
    slug: 'git-merge-icon',
    title: 'Git Merge Icon',
    tier: KIconTier.premium,
    motion: 'popUp',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.chime,
    px: 33,
    py: 28,
    base: [_BLine(14, 15, 14, 33), _BCircle(14, 12, 4.2, _BFill.surface), _BCircle(14, 36, 4.2, _BFill.ok)],
    mover: [_BPoly([Offset(18, 15), Offset(28, 18), Offset(33, 26)], false, _BFill.none), _BCircle(34, 30, 4.5, _BFill.accent)],
  ),
  'bug-squash-icon': _BespokeV4Spec(
    slug: 'bug-squash-icon',
    title: 'Bug Squash Icon',
    tier: KIconTier.premium,
    motion: 'drop',
    fx: 'rays',
    hSfx: KSound.boop,
    cSfx: KSound.pop,
    px: 24,
    py: 26,
    base: [_BLine(18, 11, 21, 15), _BLine(30, 11, 27, 15), _BCircle(24, 17, 5, _BFill.surface)],
    mover: [_BRect(15, 19, 18, 18, 9, _BFill.accent), _BLine(24, 19, 24, 37), _BLine(9, 22, 15, 24), _BLine(9, 30, 15, 29), _BLine(39, 22, 33, 24), _BLine(39, 30, 33, 29)],
  ),
  'database-pulse-icon': _BespokeV4Spec(
    slug: 'database-pulse-icon',
    title: 'Database Pulse Icon',
    tier: KIconTier.premium,
    motion: 'slideY',
    fx: 'ring',
    hSfx: KSound.tick,
    cSfx: KSound.drop,
    px: 24,
    py: 14,
    base: [_BRect(11, 16, 26, 22, 5, _BFill.surface), _BLine(11, 24, 37, 24), _BLine(11, 31, 37, 31), _BCircle(16, 27.5, 1.5, _BFill.ok), _BCircle(16, 34.5, 1.5, _BFill.ok)],
    mover: [_BRect(11, 10, 26, 9, 4.5, _BFill.accent)],
  ),
  'cpu-circuit-icon': _BespokeV4Spec(
    slug: 'cpu-circuit-icon',
    title: 'CPU Circuit Icon',
    tier: KIconTier.premium,
    motion: 'burst',
    fx: 'zap',
    hSfx: KSound.tick,
    cSfx: KSound.ding,
    px: 24,
    py: 24,
    base: [_BRect(13, 13, 22, 22, 4, _BFill.surface), _BLine(19, 7, 19, 13), _BLine(29, 7, 29, 13), _BLine(19, 35, 19, 41), _BLine(29, 35, 29, 41), _BLine(7, 19, 13, 19), _BLine(7, 29, 13, 29), _BLine(35, 19, 41, 19), _BLine(35, 29, 41, 29)],
    mover: [_BRect(19, 19, 10, 10, 2.5, _BFill.accent)],
  ),
  'wallet-pop-icon': _BespokeV4Spec(
    slug: 'wallet-pop-icon',
    title: 'Wallet Pop Icon',
    tier: KIconTier.free,
    motion: 'popUp',
    fx: 'rays',
    hSfx: KSound.flip,
    cSfx: KSound.pop,
    px: 24,
    py: 16,
    base: [_BRect(8, 17, 32, 22, 5, _BFill.surface), _BRect(28, 24, 12, 8, 3, _BFill.surface), _BCircle(33, 28, 1.8, _BFill.line)],
    mover: [_BRect(13, 10, 21, 10, 3, _BFill.accent)],
  ),
  'tag-swing-icon': _BespokeV4Spec(
    slug: 'tag-swing-icon',
    title: 'Tag Swing Icon',
    tier: KIconTier.free,
    motion: 'swing',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.ding,
    px: 16,
    py: 15,
    base: [_BCircle(16, 15, 2.2, _BFill.line)],
    mover: [_BPoly([Offset(10, 11), Offset(23, 11), Offset(39, 27), Offset(27, 39), Offset(11, 23)], true, _BFill.accent), _BCircle(17, 17, 2.5, _BFill.surface)],
  ),
  'percent-bounce-icon': _BespokeV4Spec(
    slug: 'percent-bounce-icon',
    title: 'Percent Bounce Icon',
    tier: KIconTier.free,
    motion: 'burst',
    fx: 'sparkles',
    hSfx: KSound.boop,
    cSfx: KSound.sparkle,
    px: 24,
    py: 24,
    base: [_BLine(12, 36, 36, 12)],
    mover: [_BCircle(15, 15, 5.5, _BFill.accent), _BCircle(33, 33, 5.5, _BFill.accent)],
  ),
  'credit-card-swipe-icon': _BespokeV4Spec(
    slug: 'credit-card-swipe-icon',
    title: 'Credit Card Swipe Icon',
    tier: KIconTier.premium,
    motion: 'slideX',
    fx: 'rays',
    hSfx: KSound.whoosh,
    cSfx: KSound.chime,
    px: 24,
    py: 24,
    base: [_BRect(7, 13, 34, 22, 4.5, _BFill.surface), _BRect(7, 19, 34, 5, 0, _BFill.line)],
    mover: [_BRect(12, 27, 8, 5, 1.5, _BFill.accent), _BLine(24, 29.5, 35, 29.5)],
  ),
  'coin-flip-icon': _BespokeV4Spec(
    slug: 'coin-flip-icon',
    title: 'Coin Flip Icon',
    tier: KIconTier.premium,
    motion: 'spin',
    fx: 'sparkles',
    hSfx: KSound.tick,
    cSfx: KSound.ding,
    px: 24,
    py: 24,
    base: [_BCircle(24, 24, 15, _BFill.accent)],
    mover: [_BCircle(24, 24, 10.5, _BFill.surface), _BLine(24, 17, 24, 31), _BPoly([Offset(21, 20), Offset(27, 20), Offset(21, 28), Offset(27, 28)], false, _BFill.none)],
  ),
  'receipt-print-icon': _BespokeV4Spec(
    slug: 'receipt-print-icon',
    title: 'Receipt Print Icon',
    tier: KIconTier.premium,
    motion: 'slideY',
    fx: 'rays',
    hSfx: KSound.flip,
    cSfx: KSound.click,
    px: 24,
    py: 24,
    base: [_BRect(8, 9, 32, 8, 3, _BFill.line)],
    mover: [_BPoly([Offset(13, 14), Offset(35, 14), Offset(35, 39), Offset(31, 36), Offset(27, 39), Offset(24, 36), Offset(21, 39), Offset(17, 36), Offset(13, 39)], true, _BFill.surface), _BLine(18, 22, 30, 22), _BLine(18, 28, 27, 28)],
  ),
  'package-unbox-icon': _BespokeV4Spec(
    slug: 'package-unbox-icon',
    title: 'Package Unbox Icon',
    tier: KIconTier.premium,
    motion: 'popUp',
    fx: 'sparkles',
    hSfx: KSound.boop,
    cSfx: KSound.sparkle,
    px: 24,
    py: 16,
    base: [_BRect(11, 20, 26, 19, 3, _BFill.surface), _BLine(24, 20, 24, 39)],
    mover: [_BPoly([Offset(9, 20), Offset(14, 11), Offset(34, 11), Offset(39, 20)], true, _BFill.accent), _BLine(24, 11, 24, 20)],
  ),
  'truck-deliver-icon': _BespokeV4Spec(
    slug: 'truck-deliver-icon',
    title: 'Truck Deliver Icon',
    tier: KIconTier.premium,
    motion: 'slideX',
    fx: 'rays',
    hSfx: KSound.whoosh,
    cSfx: KSound.swish,
    px: 24,
    py: 26,
    base: [_BCircle(16, 35, 4, _BFill.surface), _BCircle(34, 35, 4, _BFill.surface)],
    mover: [_BRect(7, 16, 21, 16, 3, _BFill.accent), _BPoly([Offset(28, 20), Offset(37, 20), Offset(41, 26), Offset(41, 32), Offset(28, 32)], true, _BFill.surface)],
  ),
  'play-pause-morph-icon': _BespokeV4Spec(
    slug: 'play-pause-morph-icon',
    title: 'Play Pause Morph Icon',
    tier: KIconTier.free,
    motion: 'burst',
    fx: 'ring',
    hSfx: KSound.tick,
    cSfx: KSound.pop,
    px: 24,
    py: 24,
    base: [_BCircle(24, 24, 16, _BFill.surface)],
    mover: [_BPoly([Offset(19, 16), Offset(33, 24), Offset(19, 32)], true, _BFill.accent)],
  ),
  'mic-record-icon': _BespokeV4Spec(
    slug: 'mic-record-icon',
    title: 'Mic Record Icon',
    tier: KIconTier.free,
    motion: 'popUp',
    fx: 'ring',
    hSfx: KSound.boop,
    cSfx: KSound.pop,
    px: 24,
    py: 19,
    base: [_BArc(24, 23, 11, 0, 180), _BLine(24, 34, 24, 40), _BLine(18, 40, 30, 40)],
    mover: [_BRect(18, 9, 12, 19, 6, _BFill.accent), _BLine(21, 15, 27, 15), _BLine(21, 20, 27, 20)],
  ),
  'crop-snap-icon': _BespokeV4Spec(
    slug: 'crop-snap-icon',
    title: 'Crop Snap Icon',
    tier: KIconTier.free,
    motion: 'snip',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.click,
    px: 24,
    py: 24,
    base: [_BPoly([Offset(14, 8), Offset(14, 34), Offset(40, 34)], false, _BFill.none)],
    mover: [_BPoly([Offset(8, 14), Offset(34, 14), Offset(34, 40)], false, _BFill.none), _BRect(17, 17, 14, 14, 2, _BFill.accent)],
  ),
  'headphones-bounce-icon': _BespokeV4Spec(
    slug: 'headphones-bounce-icon',
    title: 'Headphones Bounce Icon',
    tier: KIconTier.premium,
    motion: 'burst',
    fx: 'ring',
    hSfx: KSound.boop,
    cSfx: KSound.ding,
    px: 24,
    py: 26,
    base: [_BArc(24, 26, 15, 180, 360)],
    mover: [_BRect(8, 24, 7, 13, 3.5, _BFill.accent), _BRect(33, 24, 7, 13, 3.5, _BFill.accent)],
  ),
  'scissors-snip-icon': _BespokeV4Spec(
    slug: 'scissors-snip-icon',
    title: 'Scissors Snip Icon',
    tier: KIconTier.premium,
    motion: 'snip',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.click,
    px: 24,
    py: 24,
    base: [_BCircle(14, 15, 5, _BFill.surface), _BCircle(14, 33, 5, _BFill.surface)],
    mover: [_BLine(18, 17, 38, 33), _BLine(18, 31, 38, 15), _BCircle(24, 24, 2.2, _BFill.accent)],
  ),
  'paintbrush-stroke-icon': _BespokeV4Spec(
    slug: 'paintbrush-stroke-icon',
    title: 'Paint Brush Icon',
    tier: KIconTier.premium,
    motion: 'swing',
    fx: 'sparkles',
    hSfx: KSound.whoosh,
    cSfx: KSound.sparkle,
    px: 26,
    py: 22,
    base: [_BPoly([Offset(10, 37), Offset(15, 29), Offset(20, 33), Offset(14, 39)], true, _BFill.accent)],
    mover: [_BPoly([Offset(16, 28), Offset(34, 10), Offset(39, 15), Offset(21, 33)], true, _BFill.surface)],
  ),
  'palette-spin-icon': _BespokeV4Spec(
    slug: 'palette-spin-icon',
    title: 'Palette Spin Icon',
    tier: KIconTier.premium,
    motion: 'spin',
    fx: 'sparkles',
    hSfx: KSound.boop,
    cSfx: KSound.pop,
    px: 24,
    py: 24,
    base: [_BCircle(24, 24, 16, _BFill.surface)],
    mover: [_BCircle(17, 17, 2.8, _BFill.accent), _BCircle(25, 14, 2.8, _BFill.bad), _BCircle(32, 19, 2.8, _BFill.ok), _BCircle(16, 26, 2.8, _BFill.line), _BCircle(28, 30, 3.8, _BFill.surface)],
  ),
  'film-reel-icon': _BespokeV4Spec(
    slug: 'film-reel-icon',
    title: 'Film Reel Icon',
    tier: KIconTier.premium,
    motion: 'spin',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.click,
    px: 24,
    py: 24,
    base: [_BCircle(24, 24, 16, _BFill.surface), _BLine(24, 40, 40, 40)],
    mover: [_BCircle(24, 24, 4, _BFill.accent), _BCircle(24, 14, 3, _BFill.line), _BCircle(24, 34, 3, _BFill.line), _BCircle(14, 24, 3, _BFill.line), _BCircle(34, 24, 3, _BFill.line)],
  ),
  'sidebar-slide-icon': _BespokeV4Spec(
    slug: 'sidebar-slide-icon',
    title: 'Sidebar Slide Icon',
    tier: KIconTier.free,
    motion: 'slideX',
    fx: 'rays',
    hSfx: KSound.flip,
    cSfx: KSound.pop,
    px: 15,
    py: 24,
    base: [_BRect(7, 10, 34, 28, 5, _BFill.surface), _BLine(23, 18, 35, 18), _BLine(23, 25, 33, 25)],
    mover: [_BRect(7, 10, 12, 28, 4, _BFill.accent), _BLine(11, 18, 15, 18), _BLine(11, 24, 15, 24)],
  ),
  'layers-stack-icon': _BespokeV4Spec(
    slug: 'layers-stack-icon',
    title: 'Layers Stack Icon',
    tier: KIconTier.free,
    motion: 'popUp',
    fx: 'rays',
    hSfx: KSound.flip,
    cSfx: KSound.pop,
    px: 24,
    py: 16,
    base: [_BPoly([Offset(9, 31), Offset(24, 38), Offset(39, 31)], false, _BFill.none), _BPoly([Offset(9, 24), Offset(24, 31), Offset(39, 24)], false, _BFill.none)],
    mover: [_BPoly([Offset(24, 9), Offset(39, 16), Offset(24, 23), Offset(9, 16)], true, _BFill.accent)],
  ),
  'link-chain-icon': _BespokeV4Spec(
    slug: 'link-chain-icon',
    title: 'Link Chain Icon',
    tier: KIconTier.free,
    motion: 'slideX',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.click,
    px: 24,
    py: 24,
    base: [_BRect(8, 18, 18, 12, 6, _BFill.surface)],
    mover: [_BRect(22, 18, 18, 12, 6, _BFill.accent), _BLine(19, 24, 29, 24)],
  ),
  'filter-funnel-icon': _BespokeV4Spec(
    slug: 'filter-funnel-icon',
    title: 'Filter Funnel Icon',
    tier: KIconTier.premium,
    motion: 'drop',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.drop,
    px: 24,
    py: 34,
    base: [_BPoly([Offset(8, 11), Offset(40, 11), Offset(28, 25), Offset(28, 35), Offset(20, 38), Offset(20, 25)], true, _BFill.surface)],
    mover: [_BCircle(24, 16, 3.2, _BFill.accent), _BCircle(24, 41, 2.6, _BFill.accent)],
  ),
  'sort-swap-icon': _BespokeV4Spec(
    slug: 'sort-swap-icon',
    title: 'Sort Swap Icon',
    tier: KIconTier.premium,
    motion: 'slideY',
    fx: 'rays',
    hSfx: KSound.flip,
    cSfx: KSound.pop,
    px: 24,
    py: 24,
    base: [_BLine(16, 12, 16, 36), _BPoly([Offset(11, 17), Offset(16, 11), Offset(21, 17)], false, _BFill.none)],
    mover: [_BLine(32, 12, 32, 36), _BPoly([Offset(27, 31), Offset(32, 37), Offset(37, 31)], true, _BFill.accent)],
  ),
  'paperclip-bend-icon': _BespokeV4Spec(
    slug: 'paperclip-bend-icon',
    title: 'Paperclip Bend Icon',
    tier: KIconTier.premium,
    motion: 'tilt',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.click,
    px: 24,
    py: 24,
    base: [_BPoly([Offset(16, 32), Offset(16, 16), Offset(20, 11), Offset(28, 11), Offset(32, 16), Offset(32, 33), Offset(27, 38), Offset(21, 38), Offset(19, 34), Offset(19, 19), Offset(23, 16), Offset(27, 19), Offset(27, 31)], false, _BFill.none)],
    mover: [_BCircle(33, 14, 4, _BFill.accent)],
  ),
  'qr-scan-icon': _BespokeV4Spec(
    slug: 'qr-scan-icon',
    title: 'QR Scan Icon',
    tier: KIconTier.premium,
    motion: 'scan',
    fx: 'zap',
    hSfx: KSound.tick,
    cSfx: KSound.ding,
    px: 24,
    py: 24,
    base: [_BRect(10, 10, 10, 10, 2, _BFill.surface), _BRect(28, 10, 10, 10, 2, _BFill.surface), _BRect(10, 28, 10, 10, 2, _BFill.surface), _BRect(28, 28, 5, 5, 1, _BFill.line), _BRect(34, 34, 4, 4, 1, _BFill.line)],
    mover: [_BLine(7, 24, 41, 24), _BRect(13, 13, 4, 4, 1, _BFill.accent), _BRect(31, 13, 4, 4, 1, _BFill.accent)],
  ),
  'share-burst-icon': _BespokeV4Spec(
    slug: 'share-burst-icon',
    title: 'Share Burst Icon',
    tier: KIconTier.premium,
    motion: 'burst',
    fx: 'rays',
    hSfx: KSound.whoosh,
    cSfx: KSound.sparkle,
    px: 24,
    py: 24,
    base: [_BLine(15, 24, 33, 14), _BLine(15, 24, 33, 34), _BCircle(14, 24, 5, _BFill.surface)],
    mover: [_BCircle(34, 14, 5, _BFill.accent), _BCircle(34, 34, 5, _BFill.accent)],
  ),
  'verified-stamp-icon': _BespokeV4Spec(
    slug: 'verified-stamp-icon',
    title: 'Verified Stamp Icon',
    tier: KIconTier.free,
    motion: 'burst',
    fx: 'sparkles',
    hSfx: KSound.boop,
    cSfx: KSound.chime,
    px: 24,
    py: 24,
    base: [_BCircle(24, 24, 15, _BFill.ok)],
    mover: [_BPoly([Offset(16, 24), Offset(22, 30), Offset(33, 18)], false, _BFill.none), _BCircle(24, 24, 17, _BFill.none)],
  ),
  'eye-peek-toggle-icon': _BespokeV4Spec(
    slug: 'eye-peek-toggle-icon',
    title: 'Eye Peek Icon',
    tier: KIconTier.free,
    motion: 'blink',
    fx: 'ring',
    hSfx: KSound.tick,
    cSfx: KSound.click,
    px: 24,
    py: 24,
    base: [_BPoly([Offset(7, 24), Offset(15, 14), Offset(33, 14), Offset(41, 24), Offset(33, 34), Offset(15, 34)], true, _BFill.surface)],
    mover: [_BCircle(24, 24, 6.5, _BFill.accent), _BCircle(24, 24, 2.5, _BFill.line)],
  ),
  'keycard-tap-icon': _BespokeV4Spec(
    slug: 'keycard-tap-icon',
    title: 'Keycard Tap Icon',
    tier: KIconTier.free,
    motion: 'tilt',
    fx: 'ring',
    hSfx: KSound.whoosh,
    cSfx: KSound.ding,
    px: 24,
    py: 26,
    base: [_BArc(34, 13, 5, -70, 20), _BArc(34, 13, 9, -70, 20)],
    mover: [_BRect(9, 17, 26, 20, 4, _BFill.accent), _BCircle(17, 25, 3, _BFill.surface), _BLine(23, 25, 31, 25), _BLine(23, 30, 29, 30)],
  ),
  'fingerprint-scan-icon': _BespokeV4Spec(
    slug: 'fingerprint-scan-icon',
    title: 'Fingerprint Scan Icon',
    tier: KIconTier.premium,
    motion: 'scan',
    fx: 'ring',
    hSfx: KSound.tick,
    cSfx: KSound.chime,
    px: 24,
    py: 24,
    base: [_BArc(24, 25, 14, 195, 345), _BArc(24, 25, 10, 185, 355), _BArc(24, 25, 6, 170, 360), _BLine(24, 24, 24, 35)],
    mover: [_BLine(9, 25, 39, 25), _BCircle(24, 25, 2.5, _BFill.accent)],
  ),
  'face-id-scan-icon': _BespokeV4Spec(
    slug: 'face-id-scan-icon',
    title: 'Face ID Scan Icon',
    tier: KIconTier.premium,
    motion: 'burst',
    fx: 'ring',
    hSfx: KSound.tick,
    cSfx: KSound.chime,
    px: 24,
    py: 24,
    base: [_BPoly([Offset(9, 16), Offset(9, 9), Offset(16, 9)], false, _BFill.none), _BPoly([Offset(32, 9), Offset(39, 9), Offset(39, 16)], false, _BFill.none), _BPoly([Offset(9, 32), Offset(9, 39), Offset(16, 39)], false, _BFill.none), _BPoly([Offset(32, 39), Offset(39, 39), Offset(39, 32)], false, _BFill.none)],
    mover: [_BCircle(18, 20, 2.2, _BFill.line), _BCircle(30, 20, 2.2, _BFill.line), _BArc(24, 25, 7, 20, 160), _BCircle(24, 24, 11, _BFill.accent)],
  ),
  'vault-dial-icon': _BespokeV4Spec(
    slug: 'vault-dial-icon',
    title: 'Vault Dial Icon',
    tier: KIconTier.premium,
    motion: 'spin',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.click,
    px: 24,
    py: 24,
    base: [_BRect(8, 8, 32, 32, 6, _BFill.surface)],
    mover: [_BCircle(24, 24, 9, _BFill.accent), _BLine(24, 15, 24, 33), _BLine(15, 24, 33, 24), _BCircle(24, 24, 3, _BFill.surface)],
  ),
  'alarm-siren-icon': _BespokeV4Spec(
    slug: 'alarm-siren-icon',
    title: 'Alarm Siren Icon',
    tier: KIconTier.premium,
    motion: 'burst',
    fx: 'zap',
    hSfx: KSound.tick,
    cSfx: KSound.bell,
    px: 24,
    py: 22,
    base: [_BRect(10, 34, 28, 6, 2.5, _BFill.surface), _BPoly([Offset(14, 34), Offset(17, 17), Offset(31, 17), Offset(34, 34)], true, _BFill.bad)],
    mover: [_BLine(24, 6, 24, 12), _BLine(10, 12, 14, 16), _BLine(38, 12, 34, 16), _BLine(7, 24, 12, 24), _BLine(41, 24, 36, 24)],
  ),
  'firewall-pulse-icon': _BespokeV4Spec(
    slug: 'firewall-pulse-icon',
    title: 'Firewall Pulse Icon',
    tier: KIconTier.premium,
    motion: 'popUp',
    fx: 'ring',
    hSfx: KSound.boop,
    cSfx: KSound.chime,
    px: 24,
    py: 22,
    base: [_BRect(8, 22, 32, 18, 3, _BFill.surface), _BLine(8, 31, 40, 31), _BLine(20, 22, 20, 31), _BLine(28, 31, 28, 40)],
    mover: [_BPoly([Offset(24, 8), Offset(31, 18), Offset(28, 25), Offset(20, 25), Offset(17, 18)], true, _BFill.accent)],
  ),
  'sun-rays-icon': _BespokeV4Spec(
    slug: 'sun-rays-icon',
    title: 'Sun Rays Icon',
    tier: KIconTier.free,
    motion: 'spin',
    fx: 'sparkles',
    hSfx: KSound.boop,
    cSfx: KSound.sparkle,
    px: 24,
    py: 24,
    base: [_BCircle(24, 24, 9, _BFill.accent)],
    mover: [_BLine(24, 6, 24, 11), _BLine(24, 37, 24, 42), _BLine(6, 24, 11, 24), _BLine(37, 24, 42, 24), _BLine(11, 11, 15, 15), _BLine(33, 33, 37, 37), _BLine(37, 11, 33, 15), _BLine(15, 33, 11, 37)],
  ),
  'leaf-sway-icon': _BespokeV4Spec(
    slug: 'leaf-sway-icon',
    title: 'Leaf Sway Icon',
    tier: KIconTier.free,
    motion: 'swing',
    fx: 'sparkles',
    hSfx: KSound.whoosh,
    cSfx: KSound.pop,
    px: 12,
    py: 36,
    base: [_BLine(11, 37, 28, 20)],
    mover: [_BPoly([Offset(12, 36), Offset(13, 21), Offset(23, 11), Offset(37, 11), Offset(37, 25), Offset(27, 35)], true, _BFill.ok), _BLine(18, 30, 31, 17)],
  ),
  'wave-splash-icon': _BespokeV4Spec(
    slug: 'wave-splash-icon',
    title: 'Wave Splash Icon',
    tier: KIconTier.free,
    motion: 'slideX',
    fx: 'ring',
    hSfx: KSound.whoosh,
    cSfx: KSound.drop,
    px: 24,
    py: 24,
    base: [_BPoly([Offset(7, 33), Offset(14, 28), Offset(21, 33), Offset(28, 28), Offset(35, 33), Offset(41, 29)], false, _BFill.none)],
    mover: [_BPoly([Offset(7, 24), Offset(15, 17), Offset(23, 24), Offset(31, 17), Offset(40, 24)], false, _BFill.none), _BCircle(16, 13, 2.5, _BFill.accent), _BCircle(32, 13, 2.5, _BFill.accent)],
  ),
  'snowflake-drift-icon': _BespokeV4Spec(
    slug: 'snowflake-drift-icon',
    title: 'Snowflake Drift Icon',
    tier: KIconTier.premium,
    motion: 'spin',
    fx: 'sparkles',
    hSfx: KSound.tick,
    cSfx: KSound.sparkle,
    px: 24,
    py: 24,
    base: [_BCircle(24, 24, 3.5, _BFill.accent)],
    mover: [_BLine(24, 8, 24, 40), _BLine(10, 16, 38, 32), _BLine(38, 16, 10, 32), _BCircle(24, 10, 2, _BFill.surface), _BCircle(24, 38, 2, _BFill.surface)],
  ),
  'compass-rose-icon': _BespokeV4Spec(
    slug: 'compass-rose-icon',
    title: 'Compass Rose Icon',
    tier: KIconTier.premium,
    motion: 'spin',
    fx: 'ring',
    hSfx: KSound.tick,
    cSfx: KSound.ding,
    px: 24,
    py: 24,
    base: [_BCircle(24, 24, 16, _BFill.surface), _BLine(24, 8, 24, 11), _BLine(24, 37, 24, 40), _BLine(8, 24, 11, 24), _BLine(37, 24, 40, 24)],
    mover: [_BPoly([Offset(24, 12), Offset(29, 24), Offset(24, 36), Offset(19, 24)], true, _BFill.accent), _BCircle(24, 24, 2.4, _BFill.surface)],
  ),
  'plane-takeoff-icon': _BespokeV4Spec(
    slug: 'plane-takeoff-icon',
    title: 'Plane Takeoff Icon',
    tier: KIconTier.premium,
    motion: 'popUp',
    fx: 'rays',
    hSfx: KSound.whoosh,
    cSfx: KSound.swish,
    px: 24,
    py: 24,
    base: [_BLine(8, 38, 40, 38)],
    mover: [_BPoly([Offset(9, 28), Offset(16, 25), Offset(22, 13), Offset(27, 13), Offset(26, 22), Offset(36, 19), Offset(40, 21), Offset(37, 26), Offset(14, 31)], true, _BFill.accent)],
  ),
  'anchor-drop-icon': _BespokeV4Spec(
    slug: 'anchor-drop-icon',
    title: 'Anchor Drop Icon',
    tier: KIconTier.premium,
    motion: 'drop',
    fx: 'ring',
    hSfx: KSound.boop,
    cSfx: KSound.drop,
    px: 24,
    py: 24,
    base: [_BCircle(24, 12, 4, _BFill.accent)],
    mover: [_BLine(24, 16, 24, 38), _BLine(16, 21, 32, 21), _BArc(24, 27, 12, 15, 165)],
  ),
  'campfire-flicker-icon': _BespokeV4Spec(
    slug: 'campfire-flicker-icon',
    title: 'Campfire Flicker Icon',
    tier: KIconTier.premium,
    motion: 'popUp',
    fx: 'sparkles',
    hSfx: KSound.whoosh,
    cSfx: KSound.sparkle,
    px: 24,
    py: 28,
    base: [_BLine(10, 39, 38, 31), _BLine(10, 31, 38, 39)],
    mover: [_BPoly([Offset(24, 8), Offset(33, 21), Offset(30, 31), Offset(18, 31), Offset(15, 21)], true, _BFill.accent), _BPoly([Offset(24, 17), Offset(28, 24), Offset(24, 29), Offset(20, 24)], true, _BFill.bad)],
  ),
  'party-popper-icon': _BespokeV4Spec(
    slug: 'party-popper-icon',
    title: 'Party Popper Icon',
    tier: KIconTier.free,
    motion: 'burst',
    fx: 'sparkles',
    hSfx: KSound.boop,
    cSfx: KSound.sparkle,
    px: 28,
    py: 18,
    base: [_BPoly([Offset(9, 39), Offset(16, 18), Offset(30, 32)], true, _BFill.accent), _BLine(13, 27, 21, 35)],
    mover: [_BCircle(28, 11, 2.8, _BFill.bad), _BCircle(38, 18, 2.8, _BFill.ok), _BRect(31, 21, 5, 5, 1, _BFill.accent), _BLine(23, 14, 27, 18)],
  ),
  'hourglass-flip-icon': _BespokeV4Spec(
    slug: 'hourglass-flip-icon',
    title: 'Hourglass Flip Icon',
    tier: KIconTier.free,
    motion: 'spin',
    fx: 'rays',
    hSfx: KSound.tick,
    cSfx: KSound.flip,
    px: 24,
    py: 24,
    base: [_BLine(12, 9, 36, 9), _BLine(12, 39, 36, 39)],
    mover: [_BPoly([Offset(15, 9), Offset(33, 9), Offset(24, 24), Offset(33, 39), Offset(15, 39), Offset(24, 24)], true, _BFill.surface), _BPoly([Offset(19, 37), Offset(29, 37), Offset(24, 29)], true, _BFill.accent)],
  ),
  'crown-bounce-icon': _BespokeV4Spec(
    slug: 'crown-bounce-icon',
    title: 'Crown Bounce Icon',
    tier: KIconTier.premium,
    motion: 'popUp',
    fx: 'sparkles',
    hSfx: KSound.boop,
    cSfx: KSound.chime,
    px: 24,
    py: 24,
    base: [_BRect(10, 33, 28, 5, 2, _BFill.surface)],
    mover: [_BPoly([Offset(10, 33), Offset(8, 17), Offset(18, 23), Offset(24, 11), Offset(30, 23), Offset(40, 17), Offset(38, 33)], true, _BFill.accent), _BCircle(24, 26, 2.5, _BFill.surface)],
  ),
  'magnet-pull-icon': _BespokeV4Spec(
    slug: 'magnet-pull-icon',
    title: 'Magnet Pull Icon',
    tier: KIconTier.premium,
    motion: 'burst',
    fx: 'zap',
    hSfx: KSound.whoosh,
    cSfx: KSound.pop,
    px: 24,
    py: 24,
    base: [_BArc(24, 24, 13, 0, 180), _BLine(11, 13, 11, 24), _BLine(37, 13, 37, 24)],
    mover: [_BRect(8.5, 11, 6, 7, 1.5, _BFill.accent), _BRect(33.5, 11, 6, 7, 1.5, _BFill.bad), _BLine(20, 8, 24, 12), _BLine(28, 8, 24, 12)],
  ),
  'balloons-float-icon': _BespokeV4Spec(
    slug: 'balloons-float-icon',
    title: 'Balloons Float Icon',
    tier: KIconTier.premium,
    motion: 'popUp',
    fx: 'sparkles',
    hSfx: KSound.whoosh,
    cSfx: KSound.pop,
    px: 24,
    py: 20,
    base: [_BLine(18, 29, 20, 40), _BLine(31, 31, 28, 40)],
    mover: [_BCircle(18, 19, 9, _BFill.accent), _BCircle(31, 22, 7.5, _BFill.ok), _BCircle(15, 16, 2, _BFill.surface)],
  ),
  'sticker-peel-icon': _BespokeV4Spec(
    slug: 'sticker-peel-icon',
    title: 'Sticker Peel Icon',
    tier: KIconTier.premium,
    motion: 'tilt',
    fx: 'rays',
    hSfx: KSound.flip,
    cSfx: KSound.pop,
    px: 33,
    py: 33,
    base: [_BRect(9, 9, 30, 30, 7, _BFill.surface), _BCircle(20, 21, 2.2, _BFill.line), _BCircle(28, 21, 2.2, _BFill.line), _BArc(24, 24, 5, 20, 160)],
    mover: [_BPoly([Offset(28, 39), Offset(28, 28), Offset(39, 28)], true, _BFill.accent)],
  ),
  'megaphone-shout-icon': _BespokeV4Spec(
    slug: 'megaphone-shout-icon',
    title: 'Megaphone Shout Icon',
    tier: KIconTier.premium,
    motion: 'burst',
    fx: 'ring',
    hSfx: KSound.boop,
    cSfx: KSound.bell,
    px: 36,
    py: 22,
    base: [_BPoly([Offset(10, 22), Offset(31, 12), Offset(31, 34), Offset(10, 26)], true, _BFill.accent), _BRect(13, 26, 5, 11, 2, _BFill.surface)],
    mover: [_BLine(36, 17, 42, 13), _BLine(37, 23, 44, 23), _BLine(36, 29, 42, 33)],
  ),
  'corgi-paw-icon': _BespokeV4Spec(
    slug: 'corgi-paw-icon',
    title: 'Corgi Paw Icon',
    tier: KIconTier.premium,
    motion: 'burst',
    fx: 'sparkles',
    hSfx: KSound.boop,
    cSfx: KSound.meow,
    px: 24,
    py: 24,
    base: [_BCircle(24, 30, 8.5, _BFill.accent)],
    mover: [_BCircle(12, 20, 3.8, _BFill.accent), _BCircle(19, 13, 3.8, _BFill.accent), _BCircle(29, 13, 3.8, _BFill.accent), _BCircle(36, 20, 3.8, _BFill.accent)],
  ),
};

abstract class _BespokeV4Widget extends StatefulWidget {
  const _BespokeV4Widget({super.key, required this.slug, this.size = 56, this.label, this.onPressed, this.sound = true});
  final String slug;
  final double size;
  final String? label;
  final VoidCallback? onPressed;
  final bool sound;

  @override
  State<_BespokeV4Widget> createState() => _BespokeV4State();
}

class _V4SoundBeat {
  const _V4SoundBeat(this.sfx, {this.delayMs = 0, this.pitchMul = 1.0, this.volume = 0.52});
  final KSound sfx;
  final int delayMs;
  final double pitchMul;
  final double volume;
}

class _V4SoundRecipe {
  const _V4SoundRecipe({required this.hover, this.hoverPitch = 1.12, required this.beats});
  final KSound hover;
  final double hoverPitch;
  final List<_V4SoundBeat> beats;
}

const Map<String, _V4SoundRecipe> _v4SoundRecipes = {
  // Free (20)
  'terminal-cursor-icon': _V4SoundRecipe(hover: KSound.blip, hoverPitch: 1.15, beats: [_V4SoundBeat(KSound.click, volume: 0.56), _V4SoundBeat(KSound.blip, delayMs: 85, pitchMul: 1.24, volume: 0.42)]),
  'cloud-sync-icon': _V4SoundRecipe(hover: KSound.whoosh, hoverPitch: 1.1, beats: [_V4SoundBeat(KSound.whoosh, pitchMul: 1.02, volume: 0.48), _V4SoundBeat(KSound.space, delayMs: 110, pitchMul: 1.14, volume: 0.36), _V4SoundBeat(KSound.chime, delayMs: 195, pitchMul: 1.08, volume: 0.46)]),
  'api-plug-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 1.18, beats: [_V4SoundBeat(KSound.clack, volume: 0.54), _V4SoundBeat(KSound.zap, delayMs: 75, pitchMul: 1.15, volume: 0.46)]),
  'wallet-pop-icon': _V4SoundRecipe(hover: KSound.flip, hoverPitch: 1.08, beats: [_V4SoundBeat(KSound.flip, volume: 0.48), _V4SoundBeat(KSound.pop, delayMs: 75, pitchMul: 1.12, volume: 0.52), _V4SoundBeat(KSound.ding, delayMs: 150, pitchMul: 1.22, volume: 0.38)]),
  'tag-swing-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 1.25, beats: [_V4SoundBeat(KSound.swipe, pitchMul: 1.08, volume: 0.44), _V4SoundBeat(KSound.ding, delayMs: 90, pitchMul: 1.15, volume: 0.52)]),
  'percent-bounce-icon': _V4SoundRecipe(hover: KSound.boop, hoverPitch: 1.14, beats: [_V4SoundBeat(KSound.jump, pitchMul: 1.05, volume: 0.54), _V4SoundBeat(KSound.sparkle, delayMs: 85, pitchMul: 1.16, volume: 0.44)]),
  'play-pause-morph-icon': _V4SoundRecipe(hover: KSound.blip, hoverPitch: 1.18, beats: [_V4SoundBeat(KSound.pop, pitchMul: 1.06, volume: 0.56), _V4SoundBeat(KSound.click, delayMs: 75, pitchMul: 1.22, volume: 0.4)]),
  'mic-record-icon': _V4SoundRecipe(hover: KSound.blip, hoverPitch: 1.1, beats: [_V4SoundBeat(KSound.pop, volume: 0.54), _V4SoundBeat(KSound.ding, delayMs: 85, pitchMul: 1.28, volume: 0.46)]),
  'crop-snap-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 1.24, beats: [_V4SoundBeat(KSound.clack, pitchMul: 1.06, volume: 0.54), _V4SoundBeat(KSound.click, delayMs: 75, pitchMul: 1.28, volume: 0.46)]),
  'sidebar-slide-icon': _V4SoundRecipe(hover: KSound.flip, hoverPitch: 1.06, beats: [_V4SoundBeat(KSound.swipe, pitchMul: 1.02, volume: 0.5), _V4SoundBeat(KSound.click, delayMs: 95, pitchMul: 1.18, volume: 0.44)]),
  'layers-stack-icon': _V4SoundRecipe(hover: KSound.flip, hoverPitch: 1.12, beats: [_V4SoundBeat(KSound.flip, pitchMul: 0.96, volume: 0.48), _V4SoundBeat(KSound.pop, delayMs: 75, pitchMul: 1.1, volume: 0.48), _V4SoundBeat(KSound.clack, delayMs: 145, pitchMul: 1.22, volume: 0.36)]),
  'link-chain-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 1.2, beats: [_V4SoundBeat(KSound.clack, pitchMul: 1.02, volume: 0.54), _V4SoundBeat(KSound.click, delayMs: 80, pitchMul: 1.26, volume: 0.48)]),
  'verified-stamp-icon': _V4SoundRecipe(hover: KSound.boop, hoverPitch: 1.12, beats: [_V4SoundBeat(KSound.clack, pitchMul: 0.92, volume: 0.54), _V4SoundBeat(KSound.chime, delayMs: 85, pitchMul: 1.06, volume: 0.54), _V4SoundBeat(KSound.sparkle, delayMs: 165, pitchMul: 1.2, volume: 0.38)]),
  'eye-peek-toggle-icon': _V4SoundRecipe(hover: KSound.whoosh, hoverPitch: 1.32, beats: [_V4SoundBeat(KSound.click, pitchMul: 0.96, volume: 0.5), _V4SoundBeat(KSound.pop, delayMs: 95, pitchMul: 1.22, volume: 0.46)]),
  'keycard-tap-icon': _V4SoundRecipe(hover: KSound.whoosh, hoverPitch: 1.16, beats: [_V4SoundBeat(KSound.blip, pitchMul: 1.05, volume: 0.48), _V4SoundBeat(KSound.ding, delayMs: 105, pitchMul: 1.24, volume: 0.54)]),
  'sun-rays-icon': _V4SoundRecipe(hover: KSound.space, hoverPitch: 1.18, beats: [_V4SoundBeat(KSound.chime, pitchMul: 1.08, volume: 0.48), _V4SoundBeat(KSound.sparkle, delayMs: 95, pitchMul: 1.2, volume: 0.5)]),
  'leaf-sway-icon': _V4SoundRecipe(hover: KSound.flip, hoverPitch: 1.24, beats: [_V4SoundBeat(KSound.whoosh, pitchMul: 1.16, volume: 0.44), _V4SoundBeat(KSound.pop, delayMs: 85, pitchMul: 1.12, volume: 0.48)]),
  'wave-splash-icon': _V4SoundRecipe(hover: KSound.pour, hoverPitch: 1.12, beats: [_V4SoundBeat(KSound.splash, pitchMul: 1.02, volume: 0.54), _V4SoundBeat(KSound.drop, delayMs: 100, pitchMul: 1.22, volume: 0.44)]),
  'party-popper-icon': _V4SoundRecipe(hover: KSound.boop, hoverPitch: 1.18, beats: [_V4SoundBeat(KSound.pop, pitchMul: 1.08, volume: 0.58), _V4SoundBeat(KSound.giggle, delayMs: 65, pitchMul: 1.05, volume: 0.36), _V4SoundBeat(KSound.sparkle, delayMs: 135, pitchMul: 1.2, volume: 0.48)]),
  'hourglass-flip-icon': _V4SoundRecipe(hover: KSound.sand, hoverPitch: 1.12, beats: [_V4SoundBeat(KSound.flip, pitchMul: 0.96, volume: 0.52), _V4SoundBeat(KSound.sand, delayMs: 105, pitchMul: 1.08, volume: 0.48)]),
  // Paid (36)
  'sparkle-brain-icon': _V4SoundRecipe(hover: KSound.space, hoverPitch: 1.15, beats: [_V4SoundBeat(KSound.zap, pitchMul: 1.1, volume: 0.46), _V4SoundBeat(KSound.sparkle, delayMs: 80, pitchMul: 1.16, volume: 0.52), _V4SoundBeat(KSound.chime, delayMs: 160, pitchMul: 1.12, volume: 0.4)]),
  'git-merge-icon': _V4SoundRecipe(hover: KSound.blip, hoverPitch: 1.14, beats: [_V4SoundBeat(KSound.swipe, pitchMul: 1.06, volume: 0.46), _V4SoundBeat(KSound.chime, delayMs: 95, pitchMul: 1.08, volume: 0.54)]),
  'bug-squash-icon': _V4SoundRecipe(hover: KSound.squish, hoverPitch: 1.18, beats: [_V4SoundBeat(KSound.squish, pitchMul: 0.96, volume: 0.56), _V4SoundBeat(KSound.pop, delayMs: 75, pitchMul: 1.22, volume: 0.48)]),
  'database-pulse-icon': _V4SoundRecipe(hover: KSound.blip, hoverPitch: 1.06, beats: [_V4SoundBeat(KSound.blip, pitchMul: 0.96, volume: 0.48), _V4SoundBeat(KSound.drop, delayMs: 85, pitchMul: 1.12, volume: 0.48), _V4SoundBeat(KSound.click, delayMs: 155, pitchMul: 1.26, volume: 0.36)]),
  'cpu-circuit-icon': _V4SoundRecipe(hover: KSound.zap, hoverPitch: 1.22, beats: [_V4SoundBeat(KSound.zap, pitchMul: 1.08, volume: 0.5), _V4SoundBeat(KSound.blip, delayMs: 80, pitchMul: 1.2, volume: 0.42), _V4SoundBeat(KSound.ding, delayMs: 155, pitchMul: 1.24, volume: 0.44)]),
  'credit-card-swipe-icon': _V4SoundRecipe(hover: KSound.whoosh, hoverPitch: 1.12, beats: [_V4SoundBeat(KSound.swipe, pitchMul: 1.06, volume: 0.52), _V4SoundBeat(KSound.chime, delayMs: 115, pitchMul: 1.12, volume: 0.52)]),
  'coin-flip-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 1.3, beats: [_V4SoundBeat(KSound.clack, pitchMul: 1.24, volume: 0.5), _V4SoundBeat(KSound.ding, delayMs: 95, pitchMul: 1.18, volume: 0.54), _V4SoundBeat(KSound.sparkle, delayMs: 180, pitchMul: 1.24, volume: 0.38)]),
  'receipt-print-icon': _V4SoundRecipe(hover: KSound.flip, hoverPitch: 1.14, beats: [_V4SoundBeat(KSound.tick, pitchMul: 1.1, volume: 0.46), _V4SoundBeat(KSound.flip, delayMs: 80, pitchMul: 1.06, volume: 0.5), _V4SoundBeat(KSound.click, delayMs: 155, pitchMul: 1.24, volume: 0.44)]),
  'package-unbox-icon': _V4SoundRecipe(hover: KSound.flip, hoverPitch: 1.04, beats: [_V4SoundBeat(KSound.swipe, pitchMul: 0.98, volume: 0.48), _V4SoundBeat(KSound.pop, delayMs: 85, pitchMul: 1.08, volume: 0.54), _V4SoundBeat(KSound.sparkle, delayMs: 155, pitchMul: 1.18, volume: 0.44)]),
  'truck-deliver-icon': _V4SoundRecipe(hover: KSound.whoosh, hoverPitch: 0.96, beats: [_V4SoundBeat(KSound.thrust, pitchMul: 0.92, volume: 0.5), _V4SoundBeat(KSound.swish, delayMs: 95, pitchMul: 1.08, volume: 0.52)]),
  'headphones-bounce-icon': _V4SoundRecipe(hover: KSound.vinyl, hoverPitch: 1.1, beats: [_V4SoundBeat(KSound.boopLow, volume: 0.56), _V4SoundBeat(KSound.ding, delayMs: 85, pitchMul: 1.15, volume: 0.48)]),
  'scissors-snip-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 1.28, beats: [_V4SoundBeat(KSound.clack, pitchMul: 1.12, volume: 0.54), _V4SoundBeat(KSound.clack, delayMs: 85, pitchMul: 1.34, volume: 0.5)]),
  'paintbrush-stroke-icon': _V4SoundRecipe(hover: KSound.whoosh, hoverPitch: 1.18, beats: [_V4SoundBeat(KSound.swipe, pitchMul: 1.12, volume: 0.48), _V4SoundBeat(KSound.sparkle, delayMs: 95, pitchMul: 1.14, volume: 0.48)]),
  'palette-spin-icon': _V4SoundRecipe(hover: KSound.squish, hoverPitch: 1.14, beats: [_V4SoundBeat(KSound.whoosh, pitchMul: 1.08, volume: 0.46), _V4SoundBeat(KSound.pop, delayMs: 95, pitchMul: 1.14, volume: 0.5), _V4SoundBeat(KSound.sparkle, delayMs: 170, pitchMul: 1.2, volume: 0.38)]),
  'film-reel-icon': _V4SoundRecipe(hover: KSound.vinyl, hoverPitch: 1.06, beats: [_V4SoundBeat(KSound.clack, pitchMul: 1.04, volume: 0.5), _V4SoundBeat(KSound.click, delayMs: 80, pitchMul: 1.18, volume: 0.46), _V4SoundBeat(KSound.vinyl, delayMs: 155, pitchMul: 1.08, volume: 0.36)]),
  'filter-funnel-icon': _V4SoundRecipe(hover: KSound.pour, hoverPitch: 1.15, beats: [_V4SoundBeat(KSound.pour, pitchMul: 1.02, volume: 0.46), _V4SoundBeat(KSound.drop, delayMs: 110, pitchMul: 1.18, volume: 0.54)]),
  'sort-swap-icon': _V4SoundRecipe(hover: KSound.flip, hoverPitch: 1.12, beats: [_V4SoundBeat(KSound.flip, volume: 0.48), _V4SoundBeat(KSound.pop, delayMs: 85, pitchMul: 1.18, volume: 0.5)]),
  'paperclip-bend-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 1.22, beats: [_V4SoundBeat(KSound.boing, pitchMul: 1.16, volume: 0.48), _V4SoundBeat(KSound.click, delayMs: 85, pitchMul: 1.24, volume: 0.48)]),
  'qr-scan-icon': _V4SoundRecipe(hover: KSound.blip, hoverPitch: 1.22, beats: [_V4SoundBeat(KSound.blip, pitchMul: 1.08, volume: 0.48), _V4SoundBeat(KSound.ding, delayMs: 135, pitchMul: 1.26, volume: 0.54)]),
  'share-burst-icon': _V4SoundRecipe(hover: KSound.whoosh, hoverPitch: 1.16, beats: [_V4SoundBeat(KSound.swish, pitchMul: 1.1, volume: 0.5), _V4SoundBeat(KSound.sparkle, delayMs: 85, pitchMul: 1.18, volume: 0.48)]),
  'fingerprint-scan-icon': _V4SoundRecipe(hover: KSound.blip, hoverPitch: 1.08, beats: [_V4SoundBeat(KSound.space, pitchMul: 1.04, volume: 0.44), _V4SoundBeat(KSound.chime, delayMs: 140, pitchMul: 1.14, volume: 0.54)]),
  'face-id-scan-icon': _V4SoundRecipe(hover: KSound.blip, hoverPitch: 1.16, beats: [_V4SoundBeat(KSound.blip, pitchMul: 1.12, volume: 0.46), _V4SoundBeat(KSound.chime, delayMs: 105, pitchMul: 1.12, volume: 0.54), _V4SoundBeat(KSound.sparkle, delayMs: 185, pitchMul: 1.24, volume: 0.36)]),
  'vault-dial-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 1.06, beats: [_V4SoundBeat(KSound.tick, pitchMul: 0.96, volume: 0.48), _V4SoundBeat(KSound.clack, delayMs: 85, pitchMul: 1.08, volume: 0.52), _V4SoundBeat(KSound.click, delayMs: 175, pitchMul: 1.26, volume: 0.48)]),
  'alarm-siren-icon': _V4SoundRecipe(hover: KSound.zap, hoverPitch: 1.24, beats: [_V4SoundBeat(KSound.bell, pitchMul: 1.12, volume: 0.52), _V4SoundBeat(KSound.bell, delayMs: 115, pitchMul: 1.38, volume: 0.46)]),
  'firewall-pulse-icon': _V4SoundRecipe(hover: KSound.crackle, hoverPitch: 1.12, beats: [_V4SoundBeat(KSound.clack, pitchMul: 0.94, volume: 0.5), _V4SoundBeat(KSound.crackle, delayMs: 75, pitchMul: 1.15, volume: 0.46), _V4SoundBeat(KSound.chime, delayMs: 150, pitchMul: 1.1, volume: 0.44)]),
  'snowflake-drift-icon': _V4SoundRecipe(hover: KSound.space, hoverPitch: 1.28, beats: [_V4SoundBeat(KSound.sparkle, pitchMul: 1.16, volume: 0.5), _V4SoundBeat(KSound.bell, delayMs: 105, pitchMul: 1.36, volume: 0.36)]),
  'compass-rose-icon': _V4SoundRecipe(hover: KSound.tick, hoverPitch: 1.14, beats: [_V4SoundBeat(KSound.whoosh, pitchMul: 1.06, volume: 0.46), _V4SoundBeat(KSound.clack, delayMs: 115, pitchMul: 1.12, volume: 0.44), _V4SoundBeat(KSound.ding, delayMs: 190, pitchMul: 1.2, volume: 0.44)]),
  'plane-takeoff-icon': _V4SoundRecipe(hover: KSound.whoosh, hoverPitch: 1.1, beats: [_V4SoundBeat(KSound.thrust, pitchMul: 1.04, volume: 0.52), _V4SoundBeat(KSound.swish, delayMs: 100, pitchMul: 1.2, volume: 0.5)]),
  'anchor-drop-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 0.94, beats: [_V4SoundBeat(KSound.clack, pitchMul: 0.88, volume: 0.54), _V4SoundBeat(KSound.splash, delayMs: 115, pitchMul: 0.96, volume: 0.5), _V4SoundBeat(KSound.drop, delayMs: 195, pitchMul: 1.08, volume: 0.4)]),
  'campfire-flicker-icon': _V4SoundRecipe(hover: KSound.crackle, hoverPitch: 1.08, beats: [_V4SoundBeat(KSound.crackle, pitchMul: 0.96, volume: 0.54), _V4SoundBeat(KSound.crackle, delayMs: 95, pitchMul: 1.24, volume: 0.44), _V4SoundBeat(KSound.sparkle, delayMs: 165, pitchMul: 1.16, volume: 0.36)]),
  'crown-bounce-icon': _V4SoundRecipe(hover: KSound.clack, hoverPitch: 1.24, beats: [_V4SoundBeat(KSound.jump, pitchMul: 1.06, volume: 0.5), _V4SoundBeat(KSound.chime, delayMs: 85, pitchMul: 1.08, volume: 0.54), _V4SoundBeat(KSound.sparkle, delayMs: 165, pitchMul: 1.22, volume: 0.4)]),
  'magnet-pull-icon': _V4SoundRecipe(hover: KSound.zap, hoverPitch: 1.1, beats: [_V4SoundBeat(KSound.whoosh, pitchMul: 1.1, volume: 0.46), _V4SoundBeat(KSound.clack, delayMs: 75, pitchMul: 1.08, volume: 0.54), _V4SoundBeat(KSound.zap, delayMs: 135, pitchMul: 1.24, volume: 0.4)]),
  'balloons-float-icon': _V4SoundRecipe(hover: KSound.whoosh, hoverPitch: 1.24, beats: [_V4SoundBeat(KSound.boing, pitchMul: 1.14, volume: 0.48), _V4SoundBeat(KSound.pop, delayMs: 95, pitchMul: 1.2, volume: 0.5), _V4SoundBeat(KSound.sparkle, delayMs: 160, pitchMul: 1.22, volume: 0.36)]),
  'sticker-peel-icon': _V4SoundRecipe(hover: KSound.flip, hoverPitch: 1.16, beats: [_V4SoundBeat(KSound.swipe, pitchMul: 1.12, volume: 0.48), _V4SoundBeat(KSound.pop, delayMs: 95, pitchMul: 1.18, volume: 0.5)]),
  'megaphone-shout-icon': _V4SoundRecipe(hover: KSound.boop, hoverPitch: 1.15, beats: [_V4SoundBeat(KSound.bell, pitchMul: 1.08, volume: 0.54), _V4SoundBeat(KSound.boing, delayMs: 85, pitchMul: 1.22, volume: 0.42)]),
  'corgi-paw-icon': _V4SoundRecipe(hover: KSound.squish, hoverPitch: 1.18, beats: [_V4SoundBeat(KSound.squish, pitchMul: 1.08, volume: 0.52), _V4SoundBeat(KSound.meow, delayMs: 80, pitchMul: 1.16, volume: 0.54), _V4SoundBeat(KSound.giggle, delayMs: 155, pitchMul: 1.08, volume: 0.34)]),
};

class _BespokeV4State extends State<_BespokeV4Widget> with SingleTickerProviderStateMixin {
  late final _BespokeV4Spec _spec = _v4Specs[widget.slug]!;
  late final KSprings _s = KSprings(vsync: this, initial: {'mx': 0, 'my': 0, 'mrot': 0, 'msc': 100, 'bsc': 100, 'fx': 0}, config: SpringConfig.bouncy);
  double _rotTarget = 0;
  int _hoverIdx = 0;
  int _streak = 0;
  DateTime? _lastTriggerAt;
  final List<Timer> _audioTimers = [];

  static const List<double> _hoverSteps = [0.95, 1.06, 1.15, 1.02];

  void _cancelAudioTimers() {
    for (final t in _audioTimers) {
      t.cancel();
    }
    _audioTimers.clear();
  }

  void _playLater(int ms, VoidCallback fn) {
    if (!widget.sound || !KipluoSound.enabled.value) return;
    late final Timer timer;
    timer = Timer(Duration(milliseconds: ms), () {
      _audioTimers.remove(timer);
      if (mounted) fn();
    });
    _audioTimers.add(timer);
  }

  @override
  void dispose() {
    _cancelAudioTimers();
    _s.dispose();
    super.dispose();
  }

  void _onHover() {
    _s.reducedMotion = kipluoReducedMotion(context);
    final recipe = _v4SoundRecipes[_spec.slug];
    final step = _hoverSteps[_hoverIdx++ % _hoverSteps.length];
    KipluoSound.play(
      recipe?.hover ?? _spec.hSfx,
      at: context,
      pitch: ((recipe?.hoverPitch ?? 1.12) * step).clamp(0.5, 2.2),
      volume: 0.32,
      componentEnabled: widget.sound,
    );
    switch (_spec.motion) {
      case 'spin':
        _rotTarget += 45;
        _s.animateTo({'mrot': _rotTarget, 'msc': 108, 'fx': 35});
      case 'popUp':
        _s.animateTo({'my': -3.5, 'msc': 108, 'fx': 40});
      case 'slideX':
        _s.animateTo({'mx': 3.5, 'msc': 104, 'fx': 35});
      case 'slideY':
        _s.animateTo({'my': 3.2, 'msc': 105, 'fx': 35});
      case 'swing':
      case 'tilt':
        _s.animateTo({'mrot': -14, 'msc': 106, 'fx': 40});
      case 'scan':
        _s.animateTo({'my': -6, 'fx': 55});
      case 'snip':
        _s.animateTo({'msc': 90, 'mrot': -10, 'fx': 35});
      case 'drop':
        _s.animateTo({'my': -3, 'bsc': 104, 'fx': 35});
      default:
        _s.animateTo({'msc': 114, 'bsc': 103, 'fx': 45});
    }
  }

  void _onExit() {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'mx': 0, 'my': 0, 'mrot': _rotTarget, 'msc': 100, 'bsc': 100, 'fx': 0});
  }

  void _onActivate() {
    _s.reducedMotion = kipluoReducedMotion(context);
    _cancelAudioTimers();
    final now = DateTime.now();
    _streak = (_lastTriggerAt != null && now.difference(_lastTriggerAt!).inMilliseconds < 950)
        ? (_streak + 1) % 6
        : 0;
    _lastTriggerAt = now;
    final combo = notePitch(_streak);
    final recipe = _v4SoundRecipes[_spec.slug];
    final beats = recipe?.beats ?? [_V4SoundBeat(_spec.cSfx, volume: 0.62)];
    for (final beat in beats) {
      void play() {
        KipluoSound.play(
          beat.sfx,
          at: context,
          pitch: (beat.pitchMul * combo).clamp(0.5, 2.2),
          volume: beat.volume,
          componentEnabled: widget.sound,
        );
      }
      if (beat.delayMs <= 0) {
        play();
      } else {
        _playLater(beat.delayMs, play);
      }
    }
    switch (_spec.motion) {
      case 'spin':
        _rotTarget += 360;
        _s.set({'msc': 120, 'bsc': 92, 'fx': 100});
        _s.animateTo({'mrot': _rotTarget, 'msc': 100, 'bsc': 100, 'fx': 0});
      case 'popUp':
        _s.set({'my': -9, 'msc': 124, 'bsc': 92, 'fx': 100});
        _s.animateTo({'my': 0, 'msc': 100, 'bsc': 100, 'fx': 0});
      case 'slideX':
        _s.set({'mx': 8, 'msc': 112, 'bsc': 94, 'fx': 100});
        _s.animateTo({'mx': 0, 'msc': 100, 'bsc': 100, 'fx': 0});
      case 'slideY':
        _s.set({'my': 7, 'msc': 114, 'bsc': 92, 'fx': 100});
        _s.animateTo({'my': 0, 'msc': 100, 'bsc': 100, 'fx': 0});
      case 'swing':
      case 'tilt':
        _s.set({'mrot': 26, 'msc': 116, 'bsc': 94, 'fx': 100});
        _s.animateTo({'mrot': 0, 'msc': 100, 'bsc': 100, 'fx': 0});
      default:
        _s.set({'msc': 130, 'bsc': 90, 'fx': 100});
        _s.animateTo({'msc': 100, 'bsc': 100, 'fx': 0});
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return KipluoIconButton(
      label: widget.label ?? _spec.title,
      size: widget.size,
      onHover: _onHover,
      onExit: _onExit,
      onActivate: _onActivate,
      child: SizedBox.square(
        dimension: widget.size * 0.64,
        child: CustomPaint(painter: _BespokeV4Painter(spec: _spec, s: _s, t: t)),
      ),
    );
  }
}

class _BespokeV4Painter extends CustomPainter {
  _BespokeV4Painter({required this.spec, required this.s, required this.t}) : super(repaint: s);
  final _BespokeV4Spec spec;
  final KSprings s;
  final KipluoTokens t;

  Color? _fill(_BFill f) => switch (f) {
        _BFill.none => null,
        _BFill.surface => t.surface,
        _BFill.accent => t.accent,
        _BFill.ok => t.ok,
        _BFill.bad => t.bad,
        _BFill.line => t.line,
      };

  void _drawList(Canvas canvas, List<_BShape> list, Paint stroke) {
    for (final sh in list) {
      switch (sh) {
        case _BRect():
          final rr = RRect.fromRectAndRadius(Rect.fromLTWH(sh.x, sh.y, sh.w, sh.h), Radius.circular(sh.rx));
          final f = _fill(sh.fill);
          if (f != null) canvas.drawRRect(rr, Paint()..color = f);
          canvas.drawRRect(rr, stroke);
        case _BCircle():
          final f = _fill(sh.fill);
          if (f != null) canvas.drawCircle(Offset(sh.cx, sh.cy), sh.r, Paint()..color = f);
          canvas.drawCircle(Offset(sh.cx, sh.cy), sh.r, stroke);
        case _BLine():
          canvas.drawLine(Offset(sh.x1, sh.y1), Offset(sh.x2, sh.y2), stroke);
        case _BPoly():
          if (sh.pts.isEmpty) continue;
          final path = Path()..moveTo(sh.pts.first.dx, sh.pts.first.dy);
          for (var i = 1; i < sh.pts.length; i++) {
            path.lineTo(sh.pts[i].dx, sh.pts[i].dy);
          }
          if (sh.closed) path.close();
          final f = _fill(sh.fill);
          if (f != null) canvas.drawPath(path, Paint()..color = f);
          canvas.drawPath(path, stroke);
        case _BArc():
          final start = sh.startDeg * math.pi / 180;
          final sweep = (sh.endDeg - sh.startDeg) * math.pi / 180;
          canvas.drawArc(Rect.fromCircle(center: Offset(sh.cx, sh.cy), radius: sh.r), start, sweep, false, stroke);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48);
    final fx = (s['fx'] / 100).clamp(0.0, 1.0);
    if (fx > 0.04) {
      paintReleaseAura(canvas, const Offset(24, 24), 24, 1.0 - fx, accent: t.accent, line: t.line, rays: 8);
    }
    final stroke = Paint()
      ..color = t.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = t.stroke * 0.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bs = (s['bsc'] / 100).clamp(0.75, 1.3);
    canvas.save();
    canvas.translate(24, 24);
    canvas.scale(bs);
    canvas.translate(-24, -24);
    _drawList(canvas, spec.base, stroke);
    canvas.restore();

    final ms = (s['msc'] / 100).clamp(0.45, 1.45);
    canvas.save();
    canvas.translate(s['mx'], s['my']);
    canvas.translate(spec.px, spec.py);
    canvas.rotate(s['mrot'] * math.pi / 180);
    canvas.scale(ms);
    canvas.translate(-spec.px, -spec.py);
    _drawList(canvas, spec.mover, stroke);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BespokeV4Painter old) => true;
}

class KTerminalCursorIcon extends _BespokeV4Widget {
  const KTerminalCursorIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'terminal-cursor-icon');
}
class KApiPlugIcon extends _BespokeV4Widget {
  const KApiPlugIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'api-plug-icon');
}
class KWalletPopIcon extends _BespokeV4Widget {
  const KWalletPopIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'wallet-pop-icon');
}
class KTagSwingIcon extends _BespokeV4Widget {
  const KTagSwingIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'tag-swing-icon');
}
class KPercentBounceIcon extends _BespokeV4Widget {
  const KPercentBounceIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'percent-bounce-icon');
}
class KPlayPauseMorphIcon extends _BespokeV4Widget {
  const KPlayPauseMorphIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'play-pause-morph-icon');
}
class KMicRecordIcon extends _BespokeV4Widget {
  const KMicRecordIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'mic-record-icon');
}
class KCropSnapIcon extends _BespokeV4Widget {
  const KCropSnapIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'crop-snap-icon');
}
class KSidebarSlideIcon extends _BespokeV4Widget {
  const KSidebarSlideIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'sidebar-slide-icon');
}
class KLayersStackIcon extends _BespokeV4Widget {
  const KLayersStackIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'layers-stack-icon');
}
class KLinkChainIcon extends _BespokeV4Widget {
  const KLinkChainIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'link-chain-icon');
}
class KVerifiedStampIcon extends _BespokeV4Widget {
  const KVerifiedStampIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'verified-stamp-icon');
}
class KEyePeekToggleIcon extends _BespokeV4Widget {
  const KEyePeekToggleIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'eye-peek-toggle-icon');
}
class KKeycardTapIcon extends _BespokeV4Widget {
  const KKeycardTapIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'keycard-tap-icon');
}
class KSunRaysIcon extends _BespokeV4Widget {
  const KSunRaysIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'sun-rays-icon');
}
class KLeafSwayIcon extends _BespokeV4Widget {
  const KLeafSwayIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'leaf-sway-icon');
}
class KWaveSplashIcon extends _BespokeV4Widget {
  const KWaveSplashIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'wave-splash-icon');
}
class KPartyPopperIcon extends _BespokeV4Widget {
  const KPartyPopperIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'party-popper-icon');
}
class KHourglassFlipIcon extends _BespokeV4Widget {
  const KHourglassFlipIcon({super.key, super.size, super.label, super.onPressed, super.sound}) : super(slug: 'hourglass-flip-icon');
}

/// Factory map for building any v4 bespoke icon by slug.
Widget? kipluoBespokeV4BySlug(String slug, {double size = 56, bool sound = true, VoidCallback? onPressed}) {
  if (!_v4Specs.containsKey(slug)) return null;
  return _DynamicV4Icon(slug: slug, size: size, sound: sound, onPressed: onPressed);
}

class _DynamicV4Icon extends _BespokeV4Widget {
  const _DynamicV4Icon({required super.slug, super.size, super.sound, super.onPressed});
}
