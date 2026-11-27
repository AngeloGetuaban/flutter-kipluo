import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/theme.dart';

/// One category in a [SpringWaffleChart] dataset. [value] is a percentage.
@immutable
class WaffleSegment {
  const WaffleSegment(this.label, this.value);
  final String label;
  final double value;
}

/// A named breakdown for [SpringWaffleChart]; the remainder up to 100 shows as empty squares.
@immutable
class WaffleDataset {
  const WaffleDataset(this.label, this.segments);
  final String label;
  final List<WaffleSegment> segments;
}

const List<WaffleDataset> _waffleDefault = [
  WaffleDataset('2025', [WaffleSegment('Mobile', 46), WaffleSegment('Desktop', 31), WaffleSegment('Tablet', 13)]),
  WaffleDataset('2026', [WaffleSegment('Mobile', 58), WaffleSegment('Desktop', 24), WaffleSegment('Tablet', 9)]),
];

/// Category colours, derived from the theme like the web `color-mix` palette.
List<Color> _palette(KipluoTokens t) => [
      t.accent,
      Color.lerp(t.surface, t.line, 0.62)!,
      Color.lerp(t.surface, t.accent, 0.42)!,
      Color.lerp(t.surface, t.ok, 0.66)!,
      Color.lerp(t.surface, t.bad, 0.55)!,
      t.track,
    ];

String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// A pill-shaped radio group used to switch datasets.
class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.labels, required this.index, required this.onSelect, required this.label, required this.t});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onSelect;
  final String label;
  final KipluoTokens t;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          final k = e.logicalKey;
          final dir = (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowDown)
              ? 1
              : (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowUp)
                  ? -1
                  : 0;
          if (dir == 0) return KeyEventResult.ignored;
          onSelect((index + dir + labels.length) % labels.length);
          return KeyEventResult.handled;
        },
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: t.track, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < labels.length; i++)
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: i == index,
                  button: true,
                  label: labels[i],
                  onTap: () => onSelect(i),
                  excludeSemantics: true,
                  child: FocusableActionDetector(
                    actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onSelect(i))},
                    mouseCursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onSelect(i),
                      child: AnimatedContainer(
                        duration: kipluoReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: i == index ? t.accent : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                        child: Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: i == index ? t.accentInk : t.line)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* 6. Spring Waffle Chart (Free) */

/// A 10×10 waffle where each square is one percent. Switching datasets sends a diagonal wave
/// across the grid: squares that change category pop in on bouncy springs. Hover a square or a
/// legend chip to lift that category and dim the rest; tap a chip to pin the highlight.
class SpringWaffleChart extends StatefulWidget {
  const SpringWaffleChart({
    super.key,
    this.datasets = _waffleDefault,
    this.initialIndex = 0,
    this.label = 'Traffic by device',
    this.cell = 14,
    this.sound = true,
  });

  final List<WaffleDataset> datasets;
  final int initialIndex;

  /// Accessible name; the current breakdown is appended for screen readers.
  final String label;

  /// Square size in logical px.
  final double cell;
  final bool sound;

  @override
  State<SpringWaffleChart> createState() => _SpringWaffleChartState();
}

class _SpringWaffleChartState extends State<SpringWaffleChart> with SingleTickerProviderStateMixin {
  static const _pop = SpringConfig(stiffness: 380, damping: 12);
  static const _stagger = 22; // ms per diagonal

  late int _index = widget.initialIndex.clamp(0, math.max(0, widget.datasets.length - 1));
  int? _hover;
  int? _locked;
  late List<int> _shown = _assign(_data.segments);
  final List<Spring1D> _springs = List.generate(100, (_) => Spring1D(1));
  ({double t, List<int> next, List<bool> fired})? _wave;
  late final Ticker _ticker;
  Duration? _last;
  final ValueNotifier<int> _frame = ValueNotifier(0);
  Timer? _popTimer;

  WaffleDataset get _data => widget.datasets[_index];
  int? get _highlight => _hover ?? _locked;

  /// 100 cells, each assigned a segment index (or -1 for the remainder). Largest-remainder rounding.
  static List<int> _assign(List<WaffleSegment> segments) {
    final total = segments.fold<double>(0, (a, s) => a + math.max(0, s.value));
    final scale = total > 100 ? 100 / total : 1.0;
    final exact = [for (final s in segments) math.max(0.0, s.value) * scale];
    final counts = [for (final e in exact) e.floor()];
    var left = math.min(100.0, total * scale).round() - counts.fold<int>(0, (a, b) => a + b);
    final order = List.generate(exact.length, (i) => i)..sort((a, b) => (exact[b] - exact[b].floor()).compareTo(exact[a] - exact[a].floor()));
    for (final i in order) {
      if (left-- > 0) counts[i]++;
    }
    final out = <int>[];
    for (var i = 0; i < counts.length; i++) {
      for (var k = 0; k < counts[i]; k++) {
        out.add(i);
      }
    }
    while (out.length < 100) {
      out.add(-1);
    }
    return out.sublist(0, 100);
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _popTimer?.cancel();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _sfx(KSound s, {double pitch = 1, double volume = 1}) =>
      KipluoSound.play(s, at: context, pitch: pitch, volume: volume, componentEnabled: widget.sound);

  void _run() {
    if (!_ticker.isActive) {
      _last = null;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = math.min(1 / 20, _last == null ? 1 / 60 : (elapsed - _last!).inMicroseconds / 1e6);
    _last = elapsed;
    var moving = false;
    final w = _wave;
    if (w != null) {
      final t = w.t + dt * 1000;
      var pending = false;
      for (var i = 0; i < 100; i++) {
        if (w.fired[i]) continue;
        final delay = ((i ~/ 10) + (i % 10)) * _stagger;
        if (t < delay) {
          pending = true;
          continue;
        }
        w.fired[i] = true;
        final changed = _shown[i] != w.next[i];
        _shown[i] = w.next[i];
        final s = _springs[i];
        s.value = changed ? 0.3 : math.min(s.value, 0.9);
        s.velocity = changed ? 2 : 0;
      }
      _wave = pending ? (t: t, next: w.next, fired: w.fired) : null;
      if (pending) moving = true;
    }
    final h = _highlight;
    for (var i = 0; i < 100; i++) {
      final s = _springs[i];
      s.target = h != null && _shown[i] == h ? 1.1 : 1;
      if (s.step(_pop, dt)) moving = true;
    }
    _frame.value++;
    if (!moving) _ticker.stop();
  }

  void _setHighlight({int? hover, int? locked, bool clearHover = false, bool toggleLock = false}) {
    setState(() {
      if (clearHover) _hover = null;
      if (hover != null) _hover = hover;
      if (toggleLock) _locked = _locked == locked ? null : locked;
    });
    if (kipluoReducedMotion(context)) {
      for (final s in _springs) {
        s.snap(1);
      }
      _frame.value++;
      return;
    }
    _run();
  }

  void _choose(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _sfx(KSound.flip, volume: 0.6);
    final reduced = kipluoReducedMotion(context);
    _popTimer?.cancel();
    _popTimer = Timer(Duration(milliseconds: reduced ? 0 : 18 * _stagger), () {
      if (mounted) _sfx(KSound.pop, pitch: 1.2, volume: 0.45);
    });
    final next = _assign(_data.segments);
    if (reduced) {
      _shown = next;
      _frame.value++;
      return;
    }
    _wave = (t: 0, next: next, fired: List.filled(100, false));
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final colors = _palette(t).sublist(0, 4);
    Color colorOf(int cat) => cat < 0 ? t.track : colors[cat % colors.length];
    final data = _data;
    final filled = _assign(data.segments).where((c) => c >= 0).length;
    final remainder = math.max(0, 100 - filled);
    final summary = '${widget.label}, ${data.label}: ${data.segments.map((s) => '${s.label} ${_num(s.value)}%').join(', ')}${remainder > 0 ? ', other $remainder%' : ''}';
    final gap = math.max(2.0, (widget.cell * 0.2).roundToDouble());
    final reduced = kipluoReducedMotion(context);

    final grid = MouseRegion(
      onExit: (_) => _setHighlight(clearHover: true),
      child: ValueListenableBuilder<int>(
        valueListenable: _frame,
        builder: (context, _, _) {
          final h = _highlight;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < 10; r++)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < 10; c++)
                        Padding(
                          padding: EdgeInsets.only(left: c == 0 ? 0 : gap),
                          child: Builder(builder: (context) {
                            final i = r * 10 + c;
                            final cat = _shown[i];
                            final lifted = h != null && cat == h;
                            return MouseRegion(
                              onEnter: (_) {
                                final cc = _shown[i];
                                if (cc >= 0) {
                                  _setHighlight(hover: cc);
                                } else {
                                  _setHighlight(clearHover: true);
                                }
                              },
                              child: AnimatedOpacity(
                                opacity: h == null || lifted ? 1 : 0.28,
                                duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
                                child: Transform.scale(
                                  scale: _springs[i].value,
                                  child: Container(
                                    width: widget.cell,
                                    height: widget.cell,
                                    decoration: BoxDecoration(
                                      color: colorOf(cat),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: t.line.withValues(alpha: 0.35), width: t.stroke * 0.3),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );

    final legend = Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < data.segments.length; i++)
          Semantics(
            button: true,
            toggled: _locked == i,
            label: '${data.segments[i].label} ${_num(data.segments[i].value)}%',
            onTap: () => _tapChip(i),
            excludeSemantics: true,
            child: FocusableActionDetector(
              onFocusChange: (f) => f ? _setHighlight(hover: i) : _setHighlight(clearHover: true),
              actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _tapChip(i))},
              mouseCursor: SystemMouseCursors.click,
              child: MouseRegion(
                onEnter: (e) {
                  if (e.kind == PointerDeviceKind.touch) return;
                  _setHighlight(hover: i);
                  _sfx(KSound.tick, pitch: notePitch(i), volume: 0.4);
                },
                onExit: (_) => _setHighlight(clearHover: true),
                child: GestureDetector(
                  onTap: () => _tapChip(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _locked == i ? t.track : t.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: t.line, width: t.stroke * 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: colorOf(i), borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 6),
                        Text(data.segments[i].label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.line)),
                        const SizedBox(width: 4),
                        Text('${_num(data.segments[i].value)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.line.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PeriodSwitch(labels: [for (final d in widget.datasets) d.label], index: _index, onSelect: _choose, label: 'Period', t: t),
        const SizedBox(height: 10),
        Semantics(image: true, label: summary, liveRegion: true, excludeSemantics: true, child: grid),
        const SizedBox(height: 10),
        legend,
      ],
    );
  }

  void _tapChip(int i) {
    final wasLocked = _locked == i;
    _setHighlight(locked: i, toggleLock: true);
    _sfx(wasLocked ? KSound.boopLow : KSound.pop, pitch: notePitch(i), volume: 0.45);
  }
}

/* 7. Bubble Physics Chart (Premium) */

/// One bubble in a [BubblePhysicsChart] dataset.
@immutable
class BubbleDatum {
  const BubbleDatum(this.label, this.value);
  final String label;
  final double value;
}

/// A named set of values for [BubblePhysicsChart].
@immutable
class BubbleDataset {
  const BubbleDataset(this.label, this.items);
  final String label;
  final List<BubbleDatum> items;
}
