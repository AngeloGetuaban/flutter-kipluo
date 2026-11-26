import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Tab entry for [AnimatedTabs].
class AnimatedTabItem {
  const AnimatedTabItem({required this.id, required this.label, required this.content});
  final String id;
  final String label;
  final Widget content;
}

/// Active indicator pill that springs between tabs and stretches with velocity while content
/// slides cleanly in the direction of travel.
class AnimatedTabs extends StatefulWidget {
  const AnimatedTabs({
    super.key,
    required this.tabs,
    this.value,
    this.defaultValue,
    this.onValueChange,
    this.sound = true,
  });

  final List<AnimatedTabItem> tabs;
  final String? value;
  final String? defaultValue;
  final ValueChanged<String>? onValueChange;
  final bool sound;

  @override
  State<AnimatedTabs> createState() => _AnimatedTabsState();
}

class _AnimatedTabsState extends State<AnimatedTabs> with SingleTickerProviderStateMixin {
  late String _activeId = widget.value ?? widget.defaultValue ?? (widget.tabs.isEmpty ? '' : widget.tabs.first.id);
  late final KSprings _s = KSprings(vsync: this, initial: {'idx': _indexOf(_activeId) * 100.0}, config: SpringConfig.bouncy);
  int _dir = 1;

  int _indexOf(String id) {
    final i = widget.tabs.indexWhere((t) => t.id == id);
    return i < 0 ? 0 : i;
  }

  String get _currentId => widget.value ?? _activeId;

  @override
  void didUpdateWidget(AnimatedTabs old) {
    super.didUpdateWidget(old);
    if (widget.value != null && widget.value != old.value) {
      final prev = _indexOf(old.value ?? _activeId);
      final next = _indexOf(widget.value!);
      _dir = next >= prev ? 1 : -1;
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'idx': next * 100.0});
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _select(int nextIdx) {
    if (widget.tabs.isEmpty) return;
    final clamped = nextIdx.clamp(0, widget.tabs.length - 1);
    final prevIdx = _indexOf(_currentId);
    final nextId = widget.tabs[clamped].id;
    _dir = clamped >= prevIdx ? 1 : -1;
    if (widget.value == null) setState(() => _activeId = nextId);
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'idx': clamped * 100.0});
    if (clamped != prevIdx) {
      KipluoSound.play(KSound.boop, at: context, pitch: 0.92 + clamped * 0.1, componentEnabled: widget.sound);
      widget.onValueChange?.call(nextId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    if (widget.tabs.isEmpty) return const SizedBox.shrink();
    final activeIdx = _indexOf(_currentId);
    return FocusableActionDetector(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowLeft): _TabNav(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _TabNav(1),
        SingleActivator(LogicalKeyboardKey.home): _TabNav(-9999),
        SingleActivator(LogicalKeyboardKey.end): _TabNav(9999),
      },
      actions: {
        _TabNav: CallbackAction<_TabNav>(
          onInvoke: (nav) {
            if (nav.delta <= -9999) {
              _select(0);
            } else if (nav.delta >= 9999) {
              _select(widget.tabs.length - 1);
            } else {
              _select(activeIdx + nav.delta);
            }
            return null;
          },
        ),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final totalW = (constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0).clamp(160.0, 520.0);
              final tabW = (totalW - 8) / widget.tabs.length;
              return Container(
                width: totalW,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: t.track,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.line, width: t.stroke * 0.5),
                ),
                child: SizedBox(
                  height: 36,
                  child: AnimatedBuilder(
                    animation: _s,
                    builder: (context, _) {
                      final idxPos = (_s['idx'] / 100).clamp(0.0, (widget.tabs.length - 1).toDouble());
                      final stretch = (_s.spring('idx').velocity.abs() / 1800).clamp(0.0, 0.25);
                      return Stack(
                        children: [
                          Positioned(
                            left: idxPos * tabW - (tabW * stretch * 0.5),
                            top: 0,
                            bottom: 0,
                            width: tabW * (1 + stretch),
                            child: Container(
                              decoration: BoxDecoration(
                                color: t.accent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: t.line, width: t.stroke * 0.45),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < widget.tabs.length; i++)
                                Expanded(
                                  child: Semantics(
                                    button: true,
                                    selected: i == activeIdx,
                                    label: widget.tabs[i].label,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _select(i),
                                      child: Center(
                                        child: Text(
                                          widget.tabs[i].label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: i == activeIdx ? t.accentInk : t.line,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: kipluoReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(begin: Offset(_dir * 0.12, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: KeyedSubtree(key: ValueKey(_currentId), child: widget.tabs[activeIdx].content),
          ),
        ],
      ),
    );
  }
}

class _TabNav extends Intent {
  const _TabNav(this.delta);
  final int delta;
}
