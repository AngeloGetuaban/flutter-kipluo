import 'dart:async';

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';

/* 15. Inline Confirm Pill (Free) */

class InlineConfirmPill extends StatefulWidget {
  const InlineConfirmPill({super.key, this.label = 'Archive item', this.onConfirm, this.sound = true});
  final String label;
  final VoidCallback? onConfirm;
  final bool sound;

  @override
  State<InlineConfirmPill> createState() => _InlineConfirmPillState();
}

class _InlineConfirmPillState extends State<InlineConfirmPill> {
  String _stage = 'idle';
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    setState(() => _stage = 'armed');
    KipluoSound.play(KSound.boop, at: context, volume: 0.45, componentEnabled: widget.sound);
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _stage = 'idle');
    });
  }

  void _confirm() {
    _timer?.cancel();
    setState(() {
      _stage = 'done';
    });
    widget.onConfirm?.call();
    KipluoSound.play(KSound.chime, at: context, volume: 0.55, componentEnabled: widget.sound);
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _stage = 'idle');
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_stage == 'idle')
          GestureDetector(
            onTap: _arm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: t.line, width: t.stroke),
              ),
              child: Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.line)),
            ),
          )
        else if (_stage == 'armed')
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: t.line, width: t.stroke),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    _timer?.cancel();
                    setState(() => _stage = 'idle');
                    KipluoSound.play(KSound.boopLow, at: context, volume: 0.4, componentEnabled: widget.sound);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: t.track, borderRadius: BorderRadius.circular(99)),
                    child: Text('Cancel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.line)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _confirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: t.bad, borderRadius: BorderRadius.circular(99)),
                    child: const Text('Confirm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: t.ok,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: t.line, width: t.stroke),
            ),
            child: const Text('✓ Archived', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
      ],
    );
  }
}
