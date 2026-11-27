import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

enum LoaderStatus { running, complete, error }

/// Shared shell for all Kipluo loaders: manages loop ticker, smoothed [p] progress spring,
/// interactive tap burst impulse, status sound cues, and progressbar semantics.
class KipluoLoaderShell extends StatefulWidget {
  const KipluoLoaderShell({
    super.key,
    required this.value,
    required this.status,
    required this.size,
    required this.label,
    required this.sound,
    this.duration = const Duration(milliseconds: 2200),
    this.painterBuilder,
    this.interactivePainterBuilder,
    this.tapSound,
    this.completeSound = KSound.chime,
    this.errorSound = KSound.bonk,
    this.hopSound,
    this.hopsPerLoop = 2,
  }) : assert(painterBuilder != null || interactivePainterBuilder != null);

  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;
  final Duration duration;
  final CustomPainter Function(double t, double progress, LoaderStatus status, KipluoTokens tokens)? painterBuilder;
  final CustomPainter Function(double t, double progress, double pulse, LoaderStatus status, KipluoTokens tokens)? interactivePainterBuilder;
  final KSound? tapSound;
  final KSound completeSound;
  final KSound errorSound;
  final KSound? hopSound;
  final int hopsPerLoop;

  @override
  State<KipluoLoaderShell> createState() => _KipluoLoaderShellState();
}

class _KipluoLoaderShellState extends State<KipluoLoaderShell> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: widget.duration)..addListener(_onLoopTick);
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'p': widget.value?.clamp(0.0, 100.0) ?? 0},
    config: SpringConfig.snappy,
  );
  int _lastDecile = -1;
  int _lastHopBucket = -1;

  void _onLoopTick() {
    if (widget.hopSound == null || widget.status != LoaderStatus.running || !mounted) return;
    final bucket = (_loop.value * widget.hopsPerLoop).floor();
    if (_lastHopBucket == -1) {
      _lastHopBucket = bucket;
    } else if (bucket != _lastHopBucket) {
      _lastHopBucket = bucket;
      KipluoSound.play(widget.hopSound!, at: context, pitch: bucket.isEven ? 0.98 : 1.07, volume: 0.32, componentEnabled: widget.sound);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(KipluoLoaderShell old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) _loop.duration = widget.duration;
    if (old.status != widget.status) {
      _lastHopBucket = -1;
      if (widget.status == LoaderStatus.complete) {
        KipluoSound.play(widget.completeSound, at: context, volume: 0.65, componentEnabled: widget.sound);
        _triggerPulse();
      } else if (widget.status == LoaderStatus.error) {
        KipluoSound.play(widget.errorSound, at: context, volume: 0.65, componentEnabled: widget.sound);
        _triggerPulse();
      }
    }
    if (widget.value != null && widget.value != old.value) {
      final v = widget.value!.clamp(0.0, 100.0);
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'p': v});
      final dec = (v / 10).floor();
      if (dec != _lastDecile) {
        _lastDecile = dec;
        if (widget.hopSound == null) {
          KipluoSound.play(KSound.tick, at: context, pitch: 0.8 + (v / 100) * 0.55, volume: 0.35, componentEnabled: widget.sound);
        }
      }
    }
    _syncLoop();
  }

  void _triggerPulse() {
    if (kipluoReducedMotion(context)) return;
    _pulse.forward(from: 0);
  }

  void _syncLoop() {
    final run = widget.status == LoaderStatus.running && !kipluoReducedMotion(context);
    if (run && !_loop.isAnimating) _loop.repeat();
    if (!run) _loop.stop();
  }

  void _handleTap() {
    if (widget.interactivePainterBuilder == null) return;
    _triggerPulse();
    final snd = switch (widget.status) {
      LoaderStatus.error => widget.errorSound,
      LoaderStatus.complete => widget.completeSound,
      LoaderStatus.running => widget.tapSound ?? KSound.pop,
    };
    KipluoSound.play(snd, at: context, pitch: 1.12, volume: 0.55, componentEnabled: widget.sound);
  }

  @override
  void dispose() {
    _loop.dispose();
    _pulse.dispose();
    _s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final statusText = switch (widget.status) {
      LoaderStatus.complete => '${widget.label} complete',
      LoaderStatus.error => '${widget.label} failed',
      LoaderStatus.running => widget.label,
    };
    final interactive = widget.interactivePainterBuilder != null;
    final paintWidget = SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _pulse, _s]),
        builder: (context, _) {
          final p = widget.value != null ? _s['p'].clamp(0.0, 100.0) : (_loop.value * 100);
          final pulse = _pulse.isAnimating ? (1.0 - _pulse.value) : 0.0;
          final painter = interactive
              ? widget.interactivePainterBuilder!(_loop.value, p, pulse, widget.status, t)
              : widget.painterBuilder!(_loop.value, p, widget.status, t);
          return CustomPaint(painter: painter);
        },
      ),
    );
    return Semantics(
      label: statusText,
      value: widget.value == null ? null : '${widget.value!.round()}%',
      child: interactive
          ? GestureDetector(
              excludeFromSemantics: true,
              onTap: _handleTap,
              child: MouseRegion(cursor: SystemMouseCursors.click, child: paintWidget),
            )
          : paintWidget,
    );
  }
}
