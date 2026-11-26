import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 6. Spring Segmented Control (Free) */
class SpringSegmentedControl extends StatefulWidget {
  const SpringSegmentedControl({
    super.key,
    this.options = const ['Daily', 'Weekly', 'Monthly'],
    this.initialIndex = 0,
    this.onChanged,
    this.sound = true,
  });

  final List<String> options;
  final int initialIndex;
  final ValueChanged<int>? onChanged;
  final bool sound;

  @override
  State<SpringSegmentedControl> createState() => _SpringSegmentedControlState();
}

class _SpringSegmentedControlState extends State<SpringSegmentedControl> with SingleTickerProviderStateMixin {
  late int _idx = widget.initialIndex.clamp(0, math.max(0, widget.options.length - 1));
  late final KSprings _s = KSprings(vsync: this, initial: {'idx': _idx * 100.0}, config: SpringConfig.bouncy);

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _idx) return;
    final prev = _idx;
    setState(() => _idx = i);
    _s.reducedMotion = kipluoReducedMotion(context);
    _s.animateTo({'idx': i * 100.0});
    KipluoSound.play(KSound.boop, at: context, pitch: i > prev ? 1.15 : 0.92, volume: 0.55, componentEnabled: widget.sound);
    widget.onChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    if (widget.options.isEmpty) return const SizedBox.shrink();
    const slotW = 78.0;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.track,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.line, width: t.stroke * 0.5),
      ),
      child: SizedBox(
        width: slotW * widget.options.length,
        height: 32,
        child: AnimatedBuilder(
          animation: _s,
          builder: (context, _) {
            final pos = (_s['idx'] / 100).clamp(0.0, widget.options.length - 1.0);
            return Stack(
              children: [
                Positioned(
                  left: pos * slotW,
                  top: 0,
                  bottom: 0,
                  width: slotW,
                  child: Container(
                    decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < widget.options.length; i++)
                      SizedBox(
                        width: slotW,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _select(i),
                          child: Center(
                            child: Text(widget.options[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: i == _idx ? t.accentInk : t.line)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* 7. Tag / Chip Input (Free) */
class TagChipInput extends StatefulWidget {
  const TagChipInput({super.key, this.initialTags = const ['motion', 'spring'], this.onChanged, this.sound = true});

  final List<String> initialTags;
  final ValueChanged<List<String>>? onChanged;
  final bool sound;

  @override
  State<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends State<TagChipInput> {
  late final List<String> _tags = List.of(widget.initialTags);
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final clean = raw.trim().toLowerCase();
    if (clean.isEmpty) return;
    if (_tags.contains(clean)) {
      KipluoSound.play(KSound.bonk, at: context, volume: 0.5, componentEnabled: widget.sound);
      return;
    }
    setState(() {
      _tags.add(clean);
      _ctrl.clear();
    });
    KipluoSound.play(KSound.pop, at: context, pitch: 1.15, componentEnabled: widget.sound);
    widget.onChanged?.call(List.unmodifiable(_tags));
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.line, width: t.stroke * 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in _tags)
                Chip(
                  label: Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.accentInk)),
                  backgroundColor: t.accent,
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                    KipluoSound.play(KSound.swish, at: context, volume: 0.4, componentEnabled: widget.sound);
                    widget.onChanged?.call(List.unmodifiable(_tags));
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(hintText: 'Add tag...', isDense: true, border: OutlineInputBorder()),
                  onSubmitted: _add,
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(onPressed: () => _add(_ctrl.text.isEmpty ? 'kipluo' : _ctrl.text), child: const Text('Add')),
            ],
          ),
        ],
      ),
    );
  }
}
