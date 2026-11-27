import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';

part 'icon_pack.dart';

/// 24 physics and sound motion archetypes matching the web animated icon pack.
enum KIconMotion {
  ring,
  pulse,
  spin,
  fly,
  bounce,
  wiggle,
  snap,
  nudgeRight,
  nudgeLeft,
  flip,
  zap,
  draw,
  shake,
  squish,
  orbit,
  pendulum,
  inflate,
  type,
  heartbeat,
  tilt3d,
  float,
  stamp,
  cascade,
  breathe,
}

enum KIconTier { free, premium }

/// Metadata record describing one Kipluo animated icon.
class KIconSpec {
  const KIconSpec._({
    required this.slug,
    required this.title,
    required this.icon,
    required this.tier,
    required this.motion,
    required this.useCases,
    this.cuteSound,
  });

  final String slug;
  final String title;
  final IconData icon;
  final KIconTier tier;
  final KIconMotion motion;
  final List<String> useCases;
  final KSound? cuteSound;
}

/// Shared accessible interactive container for every animated Kipluo icon. Handles pointer hover,
/// tap, keyboard Space/Enter activation, and [KipluoTheme] Playful/Minimal/Mono styling.
class KipluoIconButton extends StatefulWidget {
  const KipluoIconButton({
    super.key,
    required this.label,
    required this.child,
    this.size = 56,
    this.onHover,
    this.onExit,
    this.onActivate,
    this.onDown,
    this.onUp,
  });

  final String label;
  final Widget child;
  final double size;
  final VoidCallback? onHover;
  final VoidCallback? onExit;
  final VoidCallback? onActivate;
  final VoidCallback? onDown;
  final VoidCallback? onUp;

  @override
  State<KipluoIconButton> createState() => _KipluoIconButtonState();
}

class _KipluoIconButtonState extends State<KipluoIconButton> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final style = KipluoTheme.styleOf(context);
    final isPlayful = style == KipluoStyle.playful;
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onActivate,
      child: FocusableActionDetector(
        onShowFocusHighlight: (f) => setState(() => _focused = f),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onActivate?.call()),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            setState(() => _hovered = true);
            widget.onHover?.call();
          },
          onExit: (_) {
            setState(() => _hovered = false);
            widget.onExit?.call();
          },
          child: GestureDetector(
            excludeFromSemantics: true,
            onTapDown: (_) => widget.onDown?.call(),
            onTapCancel: () => widget.onUp?.call(),
            onTapUp: (_) => widget.onUp?.call(),
            onTap: widget.onActivate,
            child: AnimatedContainer(
              duration: kipluoReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 140),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _hovered ? t.accent.withValues(alpha: 0.16) : t.surface,
                borderRadius: BorderRadius.circular(widget.size * 0.28),
                border: Border.all(
                  color: _focused ? KipluoColors.ring : t.line,
                  width: _focused ? 2.2 : t.stroke * 0.55,
                ),
                boxShadow: isPlayful ? [BoxShadow(color: t.line, offset: const Offset(2, 3))] : null,
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
