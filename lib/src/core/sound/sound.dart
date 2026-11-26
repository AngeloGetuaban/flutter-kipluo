import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'synth.dart';

export 'synth.dart' show KSound;

const List<int> _pentatonicSemis = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24];

/// Musical pitch ratio along a C-major pentatonic scale so sequences always sound cohesive.
double notePitch(int index) {
  final i = index.clamp(0, _pentatonicSemis.length - 1);
  return math.pow(2, _pentatonicSemis[i] / 12.0).toDouble();
}

/// Renders a sound at pitch 1 (used by tests to check every recipe makes noise).
Float32List renderSoundForTest(KSound name) => renderSound(name, 1);

/// Plays rendered Kipluo sounds. Swap it out (e.g. in tests, or to route through your own mixer).
abstract class KipluoSoundBackend {
  Future<void> play(KSound name, {required double pitch, required double pan, required double volume});
}

/// Global sound switch and player — the Dart equivalent of setSoundEnabled / play on the web.
class KipluoSound {
  KipluoSound._();

  /// Turn every Kipluo sound on or off. Persisting the choice is up to the app.
  static final ValueNotifier<bool> enabled = ValueNotifier(true);

  /// The output. Defaults to SoLoud; tests can set [SilentBackend].
  static KipluoSoundBackend backend = SoLoudBackend();

  static final Map<String, DateTime> _last = {};

  /// Plays [name] from the horizontal position of [at] (its centre), optionally travelling.
  static void play(
    KSound name, {
    BuildContext? at,
    double pitch = 1,
    double volume = 1,
    bool componentEnabled = true,
  }) {
    if (!componentEnabled || !enabled.value) return;
    final pan = at == null ? 0.0 : panOf(at);
    // Same burst throttle as the web: per sound and screen region.
    final key = '$name:${(pan * 3).round()}';
    final now = DateTime.now();
    final gap = const {
          KSound.tick: 28,
          KSound.swipe: 60,
          KSound.swish: 70,
          KSound.boop: 35,
          KSound.pop: 40,
          KSound.bell: 45,
          KSound.click: 28,
          KSound.ding: 45,
          KSound.meow: 80,
        }[name] ??
        20;
    if (now.difference(_last[key] ?? DateTime(2000)).inMilliseconds < gap) return;
    _last[key] = now;
    unawaited(backend.play(name, pitch: pitch, pan: pan, volume: volume * 0.32));
  }

  /// -0.85..0.85 from the widget's position on screen.
  static double panOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return 0;
    final centre = box.localToGlobal(box.size.center(Offset.zero)).dx;
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 1;
    return ((centre / width) * 2 - 1).clamp(-0.85, 0.85);
  }
}

/// Discards every sound. Use in widget tests.
class SilentBackend implements KipluoSoundBackend {
  @override
  Future<void> play(KSound name, {required double pitch, required double pan, required double volume}) async {}
}

/// Renders each (sound, pitch) once, caches it in SoLoud, and plays it with pan.
class SoLoudBackend implements KipluoSoundBackend {
  final Map<String, Future<AudioSource?>> _cache = {};
  Future<bool>? _init;

  Future<bool> _ready() => _init ??= () async {
        try {
          final s = SoLoud.instance;
          if (!s.isInitialized) await s.init();
          return true;
        } catch (_) {
          return false; // no audio device: stay silent rather than crash
        }
      }();

  @override
  Future<void> play(KSound name, {required double pitch, required double pan, required double volume}) async {
    if (!await _ready()) return;
    // Quantise pitch to 1/48 octave so the cache stays small.
    final q = (pitch.clamp(0.25, 4.0) * 48).round() / 48;
    final key = '${name.name}@$q';
    final source = await (_cache[key] ??= () async {
      try {
        return await SoLoud.instance.loadMem('kipluo-$key.wav', encodeWav(renderSound(name, q)));
      } catch (_) {
        return null;
      }
    }());
    if (source == null) return;
    await SoLoud.instance.play(source, volume: volume, pan: pan);
  }
}
