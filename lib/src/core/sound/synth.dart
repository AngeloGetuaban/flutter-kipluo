import 'dart:math' as math;
import 'dart:typed_data';

/// The Kipluo sound palette, same names as the web engine (apps/web/src/lib/sound.ts).
enum KSound { boop, boopLow, pop, drop, swish, swipe, chime, bonk, tick, boing, whoosh, sparkle, flip, bell, click, ding, meow }

const int kSampleRate = 44100;

/// Renders a recipe to mono PCM. A Dart port of the web recipes: the same oscillators, pitch glides,
/// filtered-noise sweeps and exponential envelopes, so a "pop" sounds like the web "pop".
Float32List renderSound(KSound name, double pitch) {
  final r = _Renderer();
  final p = pitch;
  switch (name) {
    case KSound.boop:
      r.tone(f0: 720 * p, f1: 430 * p, decay: 0.13, peak: 0.55);
      r.tone(wave: _Wave.triangle, f0: 1440 * p, f1: 900 * p, decay: 0.06, peak: 0.12);
    case KSound.boopLow:
      r.tone(f0: 420 * p, f1: 260 * p, decay: 0.15, peak: 0.55);
    case KSound.pop:
      r.tone(f0: 380 * p, f1: 980 * p, attack: 0.003, decay: 0.07, peak: 0.6, glide: 0.04);
    case KSound.drop:
      r.tone(f0: 520 * p, f1: 1500 * p, attack: 0.003, decay: 0.11, peak: 0.55, glide: 0.06);
      r.tone(f0: 900 * p, f1: 1900 * p, start: 0.075, attack: 0.002, decay: 0.05, peak: 0.18, glide: 0.03);
    case KSound.swish:
      r.noise(type: _Filter.bandpass, f0: 500 * p, f1: 3200 * p, attack: 0.07, decay: 0.2, peak: 0.55, q: 0.8);
    case KSound.swipe:
      r.noise(type: _Filter.highpass, f0: 1400 * p, f1: 4200 * p, attack: 0.025, decay: 0.1, peak: 0.35, q: 0.5);
    case KSound.chime:
      r.tone(f0: 1046.5 * p, decay: 0.55, peak: 0.32);
      r.tone(wave: _Wave.triangle, f0: 2093 * p, decay: 0.25, peak: 0.06);
      r.tone(f0: 1568 * p, start: 0.09, decay: 0.7, peak: 0.3);
    case KSound.bonk:
      r.tone(wave: _Wave.triangle, f0: 330 * p, decay: 0.16, peak: 0.45);
      r.tone(wave: _Wave.triangle, f0: 247 * p, start: 0.11, decay: 0.22, peak: 0.45);
    case KSound.tick:
      r.tone(f0: 2400 * p, attack: 0.001, decay: 0.025, peak: 0.18);
    case KSound.boing:
      r.tone(f0: 300 * p, f1: 420 * p, decay: 0.38, peak: 0.45, glide: 0.3, vibratoHz: 14, vibratoDepth: 60 * p);
    case KSound.whoosh:
      r.noise(type: _Filter.lowpass, f0: 400 * p, f1: 1400 * p, attack: 0.08, decay: 0.18, peak: 0.22, q: 0.3);
    case KSound.sparkle:
      for (var i = 0; i < 3; i++) {
        r.tone(f0: [1568, 2093, 2637][i] * p, start: i * 0.045, decay: 0.18, peak: 0.16);
      }
    case KSound.flip:
      // Paper flip: a short bright noise flick plus a soft tap.
      r.noise(type: _Filter.bandpass, f0: 2200 * p, f1: 900 * p, attack: 0.004, decay: 0.05, peak: 0.4, q: 1.2);
      r.tone(f0: 900 * p, f1: 500 * p, attack: 0.002, decay: 0.04, peak: 0.12);
    case KSound.bell:
      // Warm two-tone desk bell with soft clapper tap.
      r.tone(f0: 1318.5 * p, decay: 0.42, peak: 0.34);
      r.tone(wave: _Wave.triangle, f0: 2637 * p, decay: 0.22, peak: 0.10);
      r.tone(f0: 1975.5 * p, start: 0.015, decay: 0.14, peak: 0.14);
    case KSound.click:
      // Crisp mechanical shutter/latch click.
      r.noise(type: _Filter.bandpass, f0: 2800 * p, f1: 1100 * p, attack: 0.002, decay: 0.028, peak: 0.45, q: 1.8);
      r.tone(f0: 1600 * p, f1: 720 * p, attack: 0.001, decay: 0.025, peak: 0.25);
    case KSound.ding:
      // Cheerful two-note star ding.
      r.tone(f0: 1568 * p, decay: 0.26, peak: 0.28);
      r.tone(f0: 2349.3 * p, start: 0.055, decay: 0.34, peak: 0.24);
    case KSound.meow:
      // Cute tiny cat chirp: quick rising pitch bend then warm drop.
      r.tone(f0: 620 * p, f1: 1080 * p, attack: 0.012, decay: 0.09, peak: 0.32, glide: 0.075);
      r.tone(f0: 1040 * p, f1: 760 * p, start: 0.075, attack: 0.008, decay: 0.14, peak: 0.28, glide: 0.12);
      r.tone(wave: _Wave.triangle, f0: 1860 * p, f1: 1520 * p, start: 0.02, decay: 0.12, peak: 0.06);
  }
  return r.finish();
}

enum _Wave { sine, triangle }

enum _Filter { bandpass, highpass, lowpass }

class _Renderer {
  final List<double> _buf = List<double>.filled(kSampleRate * 2, 0); // up to 2 s
  int _len = 0;
  final _rand = math.Random(7);

  // Exponential attack/decay envelope, like gain.exponentialRampToValueAtTime in the web engine.
  double _env(double t, double attack, double peak, double decay) {
    const floor = 0.0001;
    if (t < 0) return 0;
    if (t < attack) return floor * math.pow(peak / floor, t / attack);
    final d = t - attack;
    if (d > decay) return 0;
    return peak * math.pow(floor / peak, d / decay);
  }

  void tone({
    _Wave wave = _Wave.sine,
    required double f0,
    double? f1,
    double start = 0,
    double attack = 0.004,
    double decay = 0.15,
    double peak = 0.6,
    double? glide,
    double vibratoHz = 0,
    double vibratoDepth = 0,
  }) {
    final total = attack + decay;
    final glideT = glide ?? attack + decay * 0.6;
    final n = ((start + total + 0.02) * kSampleRate).ceil();
    var phase = 0.0;
    for (var i = (start * kSampleRate).floor(); i < n && i < _buf.length; i++) {
      final t = i / kSampleRate - start;
      var f = f1 == null ? f0 : (t < glideT ? f0 * math.pow(f1 / f0, t / glideT) : f1);
      if (vibratoHz > 0) f += math.sin(2 * math.pi * vibratoHz * t) * vibratoDepth * math.max(0, 1 - t / total);
      phase += f / kSampleRate;
      final x = phase % 1;
      final s = wave == _Wave.sine ? math.sin(2 * math.pi * x) : (x < 0.5 ? 4 * x - 1 : 3 - 4 * x);
      _buf[i] += s * _env(t, attack, peak, decay);
      if (i + 1 > _len) _len = i + 1;
    }
  }

  void noise({required _Filter type, required double f0, required double f1, double attack = 0.04, double decay = 0.2, double peak = 0.5, double q = 0.9}) {
    final total = attack + decay;
    final n = ((total + 0.02) * kSampleRate).ceil();
    // RBJ biquad, coefficients recomputed every 32 samples as the cutoff sweeps exponentially.
    double b0 = 0, b1 = 0, b2 = 0, a1 = 0, a2 = 0, x1 = 0, x2 = 0, y1 = 0, y2 = 0;
    for (var i = 0; i < n && i < _buf.length; i++) {
      final t = i / kSampleRate;
      if (i % 32 == 0) {
        final fc = (f0 * math.pow(f1 / f0, math.min(1, t / total))).clamp(20.0, kSampleRate / 2.2);
        final w = 2 * math.pi * fc / kSampleRate;
        final alpha = math.sin(w) / (2 * q);
        final c = math.cos(w);
        final a0 = 1 + alpha;
        switch (type) {
          case _Filter.bandpass:
            b0 = alpha / a0;
            b1 = 0;
            b2 = -alpha / a0;
          case _Filter.highpass:
            b0 = (1 + c) / 2 / a0;
            b1 = -(1 + c) / a0;
            b2 = (1 + c) / 2 / a0;
          case _Filter.lowpass:
            b0 = (1 - c) / 2 / a0;
            b1 = (1 - c) / a0;
            b2 = (1 - c) / 2 / a0;
        }
        a1 = -2 * c / a0;
        a2 = (1 - alpha) / a0;
      }
      final x = _rand.nextDouble() * 2 - 1;
      final y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      x2 = x1;
      x1 = x;
      y2 = y1;
      y1 = y;
      _buf[i] += y * _env(t, attack, peak, decay);
      if (i + 1 > _len) _len = i + 1;
    }
  }

  Float32List finish() {
    final out = Float32List(_len);
    for (var i = 0; i < _len; i++) {
      // Soft clip, like the web engine's limiter.
      final v = _buf[i];
      out[i] = (v / (1 + v.abs() * 0.6)).toDouble();
    }
    return out;
  }
}

/// Wraps mono float PCM as a 16-bit WAV file in memory.
Uint8List encodeWav(Float32List samples, {int sampleRate = kSampleRate}) {
  final dataLen = samples.length * 2;
  final b = ByteData(44 + dataLen);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  b.setUint32(4, 36 + dataLen, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  str(36, 'data');
  b.setUint32(40, dataLen, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    b.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}
