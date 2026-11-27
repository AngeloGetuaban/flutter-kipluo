import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// One control in a [SpringTooltip] toolbar.
@immutable
class SpringTooltipItem {
  const SpringTooltipItem({required this.label, required this.glyph, this.shortcut, this.glyphStyle});

  /// Accessible name and tooltip text.
  final String label;

  /// What the button shows (a letter or a short symbol).
  final String glyph;

  /// Optional keyboard shortcut shown in the tooltip.
  final String? shortcut;
  final TextStyle? glyphStyle;
}

const List<SpringTooltipItem> _formatting = [
  SpringTooltipItem(label: 'Bold', glyph: 'B', shortcut: 'Ctrl B', glyphStyle: TextStyle(fontWeight: FontWeight.w800)),
  SpringTooltipItem(label: 'Italic', glyph: 'I', shortcut: 'Ctrl I', glyphStyle: TextStyle(fontStyle: FontStyle.italic, fontFamily: 'Georgia')),
  SpringTooltipItem(label: 'Underline', glyph: 'U', shortcut: 'Ctrl U', glyphStyle: TextStyle(decoration: TextDecoration.underline)),
  SpringTooltipItem(label: 'Strikethrough', glyph: 'S', shortcut: 'Ctrl Shift X', glyphStyle: TextStyle(decoration: TextDecoration.lineThrough)),
  SpringTooltipItem(label: 'Inline code', glyph: '</>', shortcut: 'Ctrl E', glyphStyle: TextStyle(fontFamily: 'monospace', fontSize: 11)),
];

/* 4. Spring Tooltip (Free) */

/// One tooltip shared by a row of controls. It hangs from its arrow like a sign on a string:
/// moving between controls it glides on a spring and swings with its own momentum, the first
/// appearance pops, and leaving shrinks it away. Follows keyboard focus (arrow keys, Home, End);
/// Escape dismisses it. On touch, a tap shows the tip briefly.
class SpringTooltip extends StatefulWidget {
  const SpringTooltip({
    super.key,
    this.items = _formatting,
    this.label = 'Text formatting',
    this.delay = const Duration(milliseconds: 120),
    this.initialPressed,
    this.onPressedChanged,
    this.sound = true,
  });

  final List<SpringTooltipItem> items;

  /// Accessible name of the toolbar.
  final String label;

  /// Grace period before the tooltip hides after the pointer or focus leaves.
  final Duration delay;

  /// Which buttons start pressed (defaults to the first one).
  final List<bool>? initialPressed;

  /// Called with the button index and its new pressed state.
  final void Function(int index, bool pressed)? onPressedChanged;
  final bool sound;

  @override
  State<SpringTooltip> createState() => _SpringTooltipState();
}

class _SpringTooltipState extends State<SpringTooltip> with SingleTickerProviderStateMixin {
  static const _btn = 32.0, _gap = 4.0, _pad = 6.0;

  late final KSprings _s = KSprings(vsync: this, initial: {'x': 0, 's': 0}, config: const SpringConfig(stiffness: 320, damping: 19));
  late final List<bool> _pressed = List.generate(widget.items.length, (i) => widget.initialPressed != null && i < widget.initialPressed!.length ? widget.initialPressed![i] : i == 0);
  late final List<FocusNode> _nodes = List.generate(widget.items.length, (i) => FocusNode(debugLabel: 'SpringTooltip $i'));
  int _active = 0;
  bool _open = false;
  Timer? _hideTimer, _touchTimer;

  double _centerOf(int i) => _pad + i * (_btn + _gap) + _btn / 2;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _touchTimer?.cancel();
    for (final n in _nodes) {
      n.dispose();
    }
    _s.dispose();
    super.dispose();
  }

  void _sfx(KSound s, {double pitch = 1, double volume = 1}) =>
      KipluoSound.play(s, at: context, pitch: pitch, volume: volume, componentEnabled: widget.sound);

  void _show(int i) {
    _hideTimer?.cancel();
    _s.reducedMotion = kipluoReducedMotion(context);
    if (!_open) {
      _s.set({'x': _centerOf(i), 's': 0.55});
      _s.animateTo({'s': 1});
      _sfx(KSound.pop, pitch: 1.3, volume: 0.3);
    } else if (i != _active) {
      _s.animateTo({'x': _centerOf(i)});
      _sfx(KSound.tick, pitch: notePitch(i), volume: 0.4);
    }
    setState(() {
      _active = i;
      _open = true;
    });
  }

  void _hide({bool now = false}) {
    _hideTimer?.cancel();
    void go() {
      if (!mounted) return;
      setState(() => _open = false);
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'s': 0});
    }

    if (now) {
      go();
    } else {
      _hideTimer = Timer(widget.delay, go);
    }
  }

  void _toggle(int i) {
    final next = !_pressed[i];
    setState(() => _pressed[i] = next);
    _sfx(KSound.click, pitch: next ? 1.15 : 0.85, volume: 0.6);
    widget.onPressedChanged?.call(i, next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final n = widget.items.length;
    if (k == LogicalKeyboardKey.escape && _open) {
      _hide(now: true);
      return KeyEventResult.handled;
    }
    int? next;
    if (k == LogicalKeyboardKey.arrowRight) next = (_active + 1) % n;
    if (k == LogicalKeyboardKey.arrowLeft) next = (_active - 1 + n) % n;
    if (k == LogicalKeyboardKey.home) next = 0;
    if (k == LogicalKeyboardKey.end) next = n - 1;
    if (next == null) return KeyEventResult.ignored;
    _nodes[next].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final item = widget.items[_active.clamp(0, widget.items.length - 1)];

    final buttons = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      final it = widget.items[i];
      final on = _pressed[i];
      if (i > 0) buttons.add(const SizedBox(width: _gap));
      buttons.add(
        Semantics(
          button: true,
          toggled: on,
          label: it.label,
          tooltip: it.shortcut,
          onTap: () => _toggle(i),
          excludeSemantics: true,
          child: Focus(
            focusNode: _nodes[i],
            onFocusChange: (f) {
              if (f) {
                _touchTimer?.cancel(); // keyboard focus keeps the tip open
                _show(i);
              }
              setState(() {});
            },
            onKeyEvent: (node, e) {
              if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.space)) {
                _toggle(i);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (e) {
                if (e.kind != PointerDeviceKind.touch) {
                  _touchTimer?.cancel();
                  _show(i);
                }
              },
              child: GestureDetector(
                onTapDown: (d) {
                  if (d.kind != PointerDeviceKind.touch) return;
                  // Touch has no hover: a tap shows the tip briefly.
                  _show(i);
                  _touchTimer?.cancel();
                  _touchTimer = Timer(const Duration(milliseconds: 1600), () => _hide(now: true));
                },
                onTap: () => _toggle(i),
                child: AnimatedContainer(
                  duration: kipluoReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 150),
                  width: _btn,
                  height: _btn,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? t.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: _nodes[i].hasFocus ? Border.all(color: KipluoColors.ring, width: 2) : null,
                  ),
                  child: Text(it.glyph, style: TextStyle(fontSize: 14, color: on ? t.accentInk : t.line).merge(it.glyphStyle)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final tip = AnimatedBuilder(
      animation: _s,
      builder: (context, _) {
        // Hanging from the arrow: it swings opposite to the direction of travel.
        final v = _s.spring('x').velocity;
        final swing = (v * 0.009).clamp(-14.0, 14.0);
        final scale = math.max(0.0, _s['s']);
        final opacity = (_s['s'] * 1.6).clamp(0.0, 1.0);
        if (opacity <= 0.001) return const SizedBox.shrink();
        return Transform.translate(
          offset: Offset(_s['x'], 0),
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Transform(
                alignment: Alignment.topCenter,
                origin: const Offset(0, -6),
                transform: Matrix4.identity()
                  ..rotateZ(swing * math.pi / 180)
                  ..scaleByDouble(scale, scale, 1, 1),
                child: Opacity(
                  opacity: opacity,
                  child: _TipBubble(item: item, t: t),
                ),
              ),
            ),
          ),
        );
      },
    );

    return Semantics(
      container: true,
      label: widget.label,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        onFocusChange: (f) {
          if (!f) _hide();
        },
        child: MouseRegion(
          onExit: (e) {
            if (e.kind != PointerDeviceKind.touch) _hide();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(_pad),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.line, width: t.stroke * 0.5),
                  boxShadow: KipluoTheme.shadowOf(context),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
              ),
              Positioned(left: 0, top: _btn + _pad * 2, child: IgnorePointer(child: ExcludeSemantics(child: tip))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipBubble extends StatelessWidget {
  const _TipBubble({required this.item, required this.t});
  final SpringTooltipItem item;
  final KipluoTokens t;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: -4,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 10, height: 10, decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(2))),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: t.line,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.surface)),
              if (item.shortcut != null) ...[
                const SizedBox(width: 6),
                Opacity(
                  opacity: 0.75,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(border: Border.all(color: t.surface), borderRadius: BorderRadius.circular(4)),
                    child: Text(item.shortcut!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: t.surface)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
