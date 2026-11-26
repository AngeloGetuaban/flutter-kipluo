import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colours a customer can override. Same keys as the web `colors` prop (lib/appearance.ts).
/// Any null field keeps the current style's colour.
@immutable
class KipluoColorOverrides {
  const KipluoColorOverrides({this.outline, this.fill, this.accent, this.accentText, this.text, this.track, this.success, this.danger});

  /// Outline / stroke colour.
  final Color? outline;

  /// Body colour: card faces, button bodies, knobs, bubble backgrounds.
  final Color? fill;

  /// The bright colour: active states, filled stars, progress.
  final Color? accent;

  /// Text/icons drawn on top of [accent].
  final Color? accentText;

  /// Text colour inside the component.
  final Color? text;

  /// Empty tracks: slider rails, ring backgrounds, unfilled stars.
  final Color? track;
  final Color? success;
  final Color? danger;

  /// Values from [other] win where set.
  KipluoColorOverrides merge(KipluoColorOverrides? other) => other == null
      ? this
      : KipluoColorOverrides(
          outline: other.outline ?? outline,
          fill: other.fill ?? fill,
          accent: other.accent ?? accent,
          accentText: other.accentText ?? accentText,
          text: other.text ?? text,
          track: other.track ?? track,
          success: other.success ?? success,
          danger: other.danger ?? danger,
        );

  @override
  bool operator ==(Object other) =>
      other is KipluoColorOverrides &&
      other.outline == outline &&
      other.fill == fill &&
      other.accent == accent &&
      other.accentText == accentText &&
      other.text == text &&
      other.track == track &&
      other.success == success &&
      other.danger == danger;

  @override
  int get hashCode => Object.hash(outline, fill, accent, accentText, text, track, success, danger);
}

/// Where the shadow falls. Same presets as the web `shadow` prop.
enum KipluoShadowDirection { bottomRight, bottomLeft, topRight, topLeft, bottom, top, glow }

/// Shadow setting: off, a direction preset, or full control.
@immutable
class KipluoShadow {
  const KipluoShadow({this.enabled = true, this.direction = KipluoShadowDirection.bottomRight, this.distance = 4, this.blur = 0, this.color});

  /// No shadow.
  static const none = KipluoShadow(enabled: false);

  /// The Kipluo toy look: a hard shadow 4 px down and to the right.
  static const toy = KipluoShadow();

  final bool enabled;
  final KipluoShadowDirection direction;
  final double distance;
  final double blur;

  /// Defaults to the outline colour.
  final Color? color;

  /// The box shadows to paint, given the component's outline colour.
  List<BoxShadow> toBoxShadows(Color outline) {
    if (!enabled) return const [];
    final c = color ?? outline;
    if (direction == KipluoShadowDirection.glow) {
      return [BoxShadow(color: c, blurRadius: blur == 0 ? 14 : blur, spreadRadius: distance / 2)];
    }
    final (dx, dy) = switch (direction) {
      KipluoShadowDirection.bottomRight => (1.0, 1.0),
      KipluoShadowDirection.bottomLeft => (-1.0, 1.0),
      KipluoShadowDirection.topRight => (1.0, -1.0),
      KipluoShadowDirection.topLeft => (-1.0, -1.0),
      KipluoShadowDirection.bottom => (0.0, 1.0),
      KipluoShadowDirection.top => (0.0, -1.0),
      KipluoShadowDirection.glow => (0.0, 0.0),
    };
    return [BoxShadow(color: c, offset: Offset(dx * distance, dy * distance), blurRadius: blur)];
  }

  @override
  bool operator ==(Object other) => other is KipluoShadow && other.enabled == enabled && other.direction == direction && other.distance == distance && other.blur == blur && other.color == color;

  @override
  int get hashCode => Object.hash(enabled, direction, distance, blur, color);
}
