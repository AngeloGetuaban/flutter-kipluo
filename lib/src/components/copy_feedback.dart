import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Button that copies [text] to the clipboard with a bouncy spring pop and check icon, resetting
/// cleanly even under rapid repeated clicks.
class CopyFeedback extends StatefulWidget {
  const CopyFeedback({
    super.key,
    this.text = 'flutter pub add kipluo',
    this.label = 'Copy',
    this.copiedLabel = 'Copied',
    this.resetAfter = const Duration(milliseconds: 1600),
    this.onCopied,
    this.sound = true,
  });

  final String text;
  final String label;
  final String copiedLabel;
  final Duration resetAfter;
  final VoidCallback? onCopied;
  final bool sound;

  @override
  State<CopyFeedback> createState() => _CopyFeedbackState();
}

class _CopyFeedbackState extends State<CopyFeedback> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(vsync: this, initial: {'scale': 100}, config: SpringConfig.bouncy);
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    _s.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.set({'scale': 88});
    _s.animateTo({'scale': 100}, velocity: {'scale': 160});
    try {
      await Clipboard.setData(ClipboardData(text: widget.text));
      if (!mounted) return;
      KipluoSound.play(KSound.pop, at: context, volume: 0.75, componentEnabled: widget.sound);
      setState(() => _copied = true);
      widget.onCopied?.call();
      _reset?.cancel();
      _reset = Timer(widget.resetAfter, () {
        if (mounted) setState(() => _copied = false);
      });
    } catch (_) {
      if (!mounted) return;
      KipluoSound.play(KSound.bonk, at: context, volume: 0.5, componentEnabled: widget.sound);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final label = _copied ? widget.copiedLabel : widget.label;
    return Semantics(
      button: true,
      liveRegion: true,
      label: label,
      child: AnimatedBuilder(
        animation: _s,
        builder: (context, child) => Transform.scale(scale: (_s['scale'] / 100).clamp(0.8, 1.25), child: child),
        child: Material(
          color: _copied ? t.ok : t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: t.line, width: t.stroke * 0.6),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _copy,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18, color: _copied ? Colors.white : t.line),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: _copied ? Colors.white : t.line)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
