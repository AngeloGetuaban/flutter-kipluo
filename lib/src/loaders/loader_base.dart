import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

enum LoaderStatus { running, complete, error }

/// Shared shell for all Kipluo loaders: manages loop ticker, smoothed [p] progress spring,
/// status sound cues, and progressbar semantics.
class KipluoLoaderShell extends StatefulWidget {
  const KipluoLoaderShell({
    super.key,
    required this.value,
    required this.status,
    required this.size,
    required this.label,
    required this.sound,
    this.duration = const Duration(milliseconds: 2200),
    required this.painterBuilder,
  });

  final double? value;
  final LoaderStatus status;
  final double size;
  final String label;
  final bool sound;
  final Duration duration;
  final CustomPainter Function(double t, double progress, LoaderStatus status, KipluoTokens tokens) painterBuilder;

  @override
  State<KipluoLoaderShell> createState() => _KipluoLoaderShellState();
}

class _KipluoLoaderShellState extends State<KipluoLoaderShell> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: widget.duration);
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'p': widget.value?.clamp(0.0, 100.0) ?? 0},
    config: SpringConfig.snappy,
  );
  int _lastDecile = -1;

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
      if (widget.status == LoaderStatus.complete) {
        KipluoSound.play(KSound.chime, at: context, volume: 0.6, componentEnabled: widget.sound);
      } else if (widget.status == LoaderStatus.error) {
        KipluoSound.play(KSound.bonk, at: context, volume: 0.6, componentEnabled: widget.sound);
      }
    }
    if (widget.value != null && widget.value != old.value) {
      final v = widget.value!.clamp(0.0, 100.0);
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'p': v});
      final dec = (v / 10).floor();
      if (dec != _lastDecile) {
        _lastDecile = dec;
        KipluoSound.play(KSound.tick, at: context, pitch: 0.8 + (v / 100) * 0.55, volume: 0.35, componentEnabled: widget.sound);
      }
    }
    _syncLoop();
  }

  void _syncLoop() {
    final run = widget.status == LoaderStatus.running && !kipluoReducedMotion(context);
    if (run && !_loop.isAnimating) _loop.repeat();
    if (!run) _loop.stop();
  }

  @override
  void dispose() {
    _loop.dispose();
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
    return Semantics(
      label: statusText,
      value: widget.value == null ? null : '${widget.value!.round()}%',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _s]),
          builder: (context, _) {
            final p = widget.value != null ? _s['p'].clamp(0.0, 100.0) : (_loop.value * 100);
            return CustomPaint(
              painter: widget.painterBuilder(_loop.value, p, widget.status, t),
            );
          },
        ),
      ),
    );
  }
}
