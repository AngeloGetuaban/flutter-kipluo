import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Text field that shakes once on validation failure using a single spring velocity impulse (never
/// stacking failures cleanly), reveals an inline error, and stays focused.
class ShakeInput extends StatefulWidget {
  const ShakeInput({
    super.key,
    this.label = 'Work email',
    this.hintText = 'you@company.com',
    this.validate,
    this.onValidSubmit,
    this.sound = true,
  });

  final String label;
  final String hintText;
  final String? Function(String value)? validate;
  final ValueChanged<String>? onValidSubmit;
  final bool sound;

  @override
  State<ShakeInput> createState() => _ShakeInputState();
}

class _ShakeInputState extends State<ShakeInput> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late final KSprings _s = KSprings(vsync: this, initial: {'x': 0}, config: const SpringConfig(stiffness: 520, damping: 14));
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _s.dispose();
    super.dispose();
  }

  String? _runValidate(String value) {
    if (widget.validate != null) return widget.validate!(value);
    if (!value.contains('@') || !value.contains('.')) return 'Enter a valid email address';
    return null;
  }

  void _submit() {
    final err = _runValidate(_ctrl.text.trim());
    if (err != null) {
      setState(() => _error = err);
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.set({'x': 0});
      _s.animateTo({'x': 0}, velocity: {'x': 420});
      KipluoSound.play(KSound.bonk, at: context, volume: 0.65, componentEnabled: widget.sound);
      _focus.requestFocus();
    } else {
      setState(() => _error = null);
      KipluoSound.play(KSound.chime, at: context, volume: 0.6, componentEnabled: widget.sound);
      widget.onValidSubmit?.call(_ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _s,
          builder: (context, child) => Transform.translate(offset: Offset(_s['x'], 0), child: child),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    filled: true,
                    fillColor: t.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _error != null ? t.bad : t.line, width: t.stroke * 0.55),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _error != null ? t.bad : t.accent, width: t.stroke * 0.75),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _submit, child: const Text('Submit')),
            ],
          ),
        ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!, style: TextStyle(color: t.bad, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}
