import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// One-time code input where digits pop into boxes on springs, pasting fills with a cascade,
/// Backspace walks backward, and an invalid code shakes and clears.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    this.verify,
    this.onComplete,
    this.sound = true,
  });

  final int length;
  final bool Function(String code)? verify;
  final ValueChanged<String>? onComplete;
  final bool sound;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> with SingleTickerProviderStateMixin {
  late List<TextEditingController> _ctrls;
  late List<FocusNode> _nodes;
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'shake': 0, for (var i = 0; i < widget.length; i++) 'b$i': 100},
    config: SpringConfig.bouncy,
  );
  bool _verified = false;
  bool _invalid = false;
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _s.dispose();
    super.dispose();
  }

  void _popBox(int i) {
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.set({'b$i': 120});
    _s.animateTo({'b$i': 100});
  }

  void _checkCode() {
    final code = _ctrls.map((c) => c.text).join();
    if (code.length < widget.length) return;
    final ok = widget.verify == null ? code == '246810' : widget.verify!(code);
    if (ok) {
      setState(() {
        _verified = true;
        _invalid = false;
      });
      KipluoSound.play(KSound.chime, at: context, componentEnabled: widget.sound);
      widget.onComplete?.call(code);
    } else {
      setState(() {
        _verified = false;
        _invalid = true;
      });
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.set({'shake': 0});
      _s.animateTo({'shake': 0}, velocity: {'shake': 420});
      KipluoSound.play(KSound.bonk, at: context, componentEnabled: widget.sound);
      _clearTimer?.cancel();
      _clearTimer = Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        for (final c in _ctrls) {
          c.clear();
        }
        setState(() => _invalid = false);
        _nodes.first.requestFocus();
      });
    }
  }

  void _onChanged(int i, String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (var k = 0; k < widget.length && (i + k) < widget.length && k < digits.length; k++) {
        _ctrls[i + k].text = digits[k];
        _popBox(i + k);
        KipluoSound.play(KSound.tick, at: context, pitch: notePitch(i + k), volume: 0.5, componentEnabled: widget.sound);
      }
      final nextIdx = (i + digits.length).clamp(0, widget.length - 1);
      _nodes[nextIdx].requestFocus();
      _checkCode();
      return;
    }
    if (digits.isNotEmpty) {
      _ctrls[i].text = digits;
      _popBox(i);
      KipluoSound.play(KSound.tick, at: context, pitch: notePitch(i), volume: 0.55, componentEnabled: widget.sound);
      if (i + 1 < widget.length) {
        _nodes[i + 1].requestFocus();
      } else {
        _nodes[i].unfocus();
      }
      _checkCode();
    } else if (i > 0) {
      _nodes[i - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return AnimatedBuilder(
      animation: _s,
      builder: (context, _) => Transform.translate(
        offset: Offset(_s['shake'], 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.length; i++)
              Padding(
                padding: EdgeInsets.only(right: i == widget.length - 1 ? 0 : 8),
                child: Transform.scale(
                  scale: (_s['b$i'] / 100).clamp(0.85, 1.3),
                  child: SizedBox(
                    width: 40,
                    height: 48,
                    child: Semantics(
                      label: 'Digit ${i + 1} of ${widget.length}',
                      child: Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        onKeyEvent: (_, e) {
                          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.backspace && _ctrls[i].text.isEmpty && i > 0) {
                            _ctrls[i - 1].clear();
                            _nodes[i - 1].requestFocus();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _ctrls[i],
                          focusNode: _nodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: _verified ? t.ok.withValues(alpha: 0.14) : (_invalid ? t.bad.withValues(alpha: 0.14) : t.surface),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _verified ? t.ok : (_invalid ? t.bad : t.line), width: t.stroke * 0.55),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: t.accent, width: t.stroke * 0.75),
                            ),
                          ),
                          onChanged: (v) => _onChanged(i, v),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
