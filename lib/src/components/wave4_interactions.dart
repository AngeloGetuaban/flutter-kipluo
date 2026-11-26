import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 1. Infinite Marquee (Free) */
class InfiniteMarquee extends StatefulWidget {
  const InfiniteMarquee({
    super.key,
    this.items = const ['Next.js', 'React 19', 'Flutter', 'TypeScript', 'Tailwind v4', 'Web Audio'],
    this.speed = 42,
    this.sound = true,
  });

  final List<String> items;
  final double speed;
  final bool sound;

  @override
  State<InfiniteMarquee> createState() => _InfiniteMarqueeState();
}

class _InfiniteMarqueeState extends State<InfiniteMarquee> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _last;
  double _offset = 0;
  double _vel = 0;
  bool _paused = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _vel = -widget.speed;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final dt = _last == null ? 1 / 60 : ((elapsed - _last!).inMicroseconds / 1e6).clamp(0.001, 0.05);
    _last = elapsed;
    if (kipluoReducedMotion(context)) return;
    if (!_dragging) {
      final target = _paused ? -widget.speed * 0.2 : -widget.speed;
      _vel += (target - _vel) * math.min(1, dt * 6);
      _offset += _vel * dt;
    }
    const loopW = 360.0;
    if (_offset <= -loopW) _offset += loopW;
    if (_offset > 0) _offset -= loopW;
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return MouseRegion(
      onEnter: (_) => _paused = true,
      onExit: (_) => _paused = false,
      child: GestureDetector(
        onHorizontalDragStart: (_) => _dragging = true,
        onHorizontalDragUpdate: (d) {
          _offset += d.delta.dx;
          _vel = d.delta.dx * 25;
          setState(() {});
        },
        onHorizontalDragEnd: (d) {
          _dragging = false;
          _vel = d.velocity.pixelsPerSecond.dx.clamp(-600, 600);
          if (_vel.abs() > 100) KipluoSound.play(KSound.whoosh, at: context, volume: 0.38, componentEnabled: widget.sound);
        },
        child: Container(
          height: 46,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.line, width: t.stroke * 0.55),
          ),
          child: OverflowBox(
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final label in [...widget.items, ...widget.items])
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: t.track,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: t.line, width: 1.2),
                      ),
                      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.line)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* 2. Expandable Search Pill (Free) */
class ExpandableSearchPill extends StatefulWidget {
  const ExpandableSearchPill({super.key, this.placeholder = 'Search docs...', this.onSearch, this.sound = true});

  final String placeholder;
  final ValueChanged<String>? onSearch;
  final bool sound;

  @override
  State<ExpandableSearchPill> createState() => _ExpandableSearchPillState();
}

class _ExpandableSearchPillState extends State<ExpandableSearchPill> with SingleTickerProviderStateMixin {
  bool _open = false;
  late final KSprings _s = KSprings(vsync: this, initial: {'w': 52}, config: SpringConfig.bouncy);
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _s.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !_open;
    setState(() => _open = next);
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'w': next ? 230 : 52});
    KipluoSound.play(next ? KSound.pop : KSound.boopLow, at: context, volume: 0.5, componentEnabled: widget.sound);
    if (next) {
      Future.microtask(() => mounted ? _focus.requestFocus() : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return AnimatedBuilder(
      animation: _s,
      builder: (context, _) => Container(
        width: _s['w'].clamp(50.0, 260.0),
        height: 46,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.line, width: t.stroke * 0.55),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: _open ? 'Close search' : 'Open search',
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              onPressed: _toggle,
              icon: Icon(Icons.search_rounded, color: t.line, size: 20),
            ),
            if (_open)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    decoration: InputDecoration.collapsed(hintText: widget.placeholder),
                    onChanged: widget.onSearch,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
