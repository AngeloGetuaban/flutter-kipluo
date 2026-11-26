import 'package:flutter/material.dart';

import 'appearance.dart';

export 'appearance.dart';

/// The three Kipluo looks. Same meaning as `data-kstyle` on the web.
enum KipluoStyle { playful, minimal, mono }

/// Brand colours, same values as the web tokens in globals.css.
class KipluoColors {
  static const gumball = Color(0xFFFFC83D);
  static const ink = Color(0xFF1F1B3D);
  static const inkDark = Color(0xFFECEAFB);
  static const success = Color(0xFF1D8F5A);
  static const successDark = Color(0xFF3FC985);
  static const destructive = Color(0xFFD73A45);
  static const destructiveDark = Color(0xFFFF6B74);
  static const ring = Color(0xFF4A3FD1);
  static const ringDark = Color(0xFF9D94FF);
}

/// Resolved drawing tokens for one style + brightness: the Dart version of the `--kp-*` variables.
@immutable
class KipluoTokens {
  const KipluoTokens({
    required this.stroke,
    required this.line,
    required this.accent,
    required this.accentInk,
    required this.ok,
    required this.bad,
    required this.track,
    required this.surface,
  });

  final double stroke;
  final Color line;
  final Color accent;
  final Color accentInk;
  final Color ok;
  final Color bad;
  final Color track;
  final Color surface;

  static KipluoTokens resolve(KipluoStyle style, Brightness brightness, ColorScheme scheme) {
    final dark = brightness == Brightness.dark;
    final fg = dark ? KipluoColors.inkDark : KipluoColors.ink;
    final muted = dark ? const Color(0xFFA7A3CB) : const Color(0xFF5D5980);
    final ok = dark ? KipluoColors.successDark : KipluoColors.success;
    final bad = dark ? KipluoColors.destructiveDark : KipluoColors.destructive;
    final track = dark ? const Color(0xFF2C2950) : const Color(0xFFE4E1F0);
    final surface = dark ? const Color(0xFF211E3C) : Colors.white;
    switch (style) {
      case KipluoStyle.playful:
        return KipluoTokens(stroke: 3, line: fg, accent: KipluoColors.gumball, accentInk: KipluoColors.ink, ok: ok, bad: bad, track: track, surface: surface);
      case KipluoStyle.minimal:
        return KipluoTokens(stroke: 1.5, line: muted, accent: dark ? KipluoColors.ringDark : KipluoColors.ring, accentInk: Colors.white, ok: ok, bad: bad, track: track, surface: surface);
      case KipluoStyle.mono:
        return KipluoTokens(stroke: 2, line: fg, accent: fg, accentInk: dark ? const Color(0xFF16142B) : Colors.white, ok: fg, bad: fg, track: track, surface: surface);
    }
  }
}

/// Puts a Kipluo look in scope for every component below it: style preset, colour overrides and
/// shadow. Nest it to restyle one section, or wrap a single component. Inner themes inherit the
/// outer style and merge colours (inner values win).
///
/// ```dart
/// KipluoTheme(
///   style: KipluoStyle.minimal,
///   colors: const KipluoColorOverrides(accent: Color(0xFFE11D48), fill: Color(0xFFFEF3C7)),
///   shadow: const KipluoShadow(direction: KipluoShadowDirection.bottomLeft, blur: 6),
///   child: StarRating(value: 4, onChanged: (_) {}),
/// )
/// ```
class KipluoTheme extends StatelessWidget {
  const KipluoTheme({super.key, this.style, this.colors, this.shadow, required this.child});

  /// Null inherits the enclosing theme's style (Playful at the top).
  final KipluoStyle? style;
  final KipluoColorOverrides? colors;

  /// Null inherits; [KipluoShadow.none] removes shadows.
  final KipluoShadow? shadow;
  final Widget child;

  static _KipluoScope? _scope(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_KipluoScope>();

  static KipluoStyle styleOf(BuildContext context) => _scope(context)?.style ?? KipluoStyle.playful;

  /// The merged colour overrides in scope (may be empty).
  static KipluoColorOverrides colorsOf(BuildContext context) => _scope(context)?.colors ?? const KipluoColorOverrides();

  /// Tokens for the current style and brightness, with colour overrides applied.
  static KipluoTokens tokensOf(BuildContext context) {
    final theme = Theme.of(context);
    final base = KipluoTokens.resolve(styleOf(context), theme.brightness, theme.colorScheme);
    final o = colorsOf(context);
    return KipluoTokens(
      stroke: base.stroke,
      line: o.outline ?? base.line,
      accent: o.accent ?? base.accent,
      accentInk: o.accentText ?? base.accentInk,
      ok: o.success ?? base.ok,
      bad: o.danger ?? base.bad,
      track: o.track ?? base.track,
      surface: o.fill ?? base.surface,
    );
  }

  /// The shadow setting in scope (the toy look unless overridden).
  static KipluoShadow shadowSettingOf(BuildContext context) => _scope(context)?.shadow ?? KipluoShadow.toy;

  /// Box shadows for a component surface, resolved against the current outline colour.
  /// Widgets use this instead of hard-coding a BoxShadow, so customers can turn it off or move it.
  static List<BoxShadow> shadowOf(BuildContext context) => shadowSettingOf(context).toBoxShadows(tokensOf(context).line);

  @override
  Widget build(BuildContext context) {
    final parent = _scope(context);
    final merged = (parent?.colors ?? const KipluoColorOverrides()).merge(colors);
    Widget body = _KipluoScope(style: style ?? parent?.style ?? KipluoStyle.playful, colors: merged, shadow: shadow ?? parent?.shadow, child: child);
    if (colors?.text != null) {
      body = DefaultTextStyle.merge(style: TextStyle(color: colors!.text), child: IconTheme.merge(data: IconThemeData(color: colors!.text), child: body));
    }
    return body;
  }
}

class _KipluoScope extends InheritedWidget {
  const _KipluoScope({required this.style, required this.colors, required this.shadow, required super.child});

  final KipluoStyle style;
  final KipluoColorOverrides colors;
  final KipluoShadow? shadow;

  @override
  bool updateShouldNotify(_KipluoScope old) => old.style != style || old.colors != colors || old.shadow != shadow;
}

/// True when the platform asks for less motion (Flutter's equivalent of prefers-reduced-motion).
bool kipluoReducedMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
