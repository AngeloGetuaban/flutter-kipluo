import 'dart:async';

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';

/* 18. Reaction Picker Bar (Free) */
class ReactionPickerBar extends StatefulWidget {
  const ReactionPickerBar({super.key, this.onReact, this.sound = true});

  final ValueChanged<String>? onReact;
  final bool sound;

  @override
  State<ReactionPickerBar> createState() => _ReactionPickerBarState();
}

class _ReactionPickerBarState extends State<ReactionPickerBar> {
  final Map<String, int> _counts = {'love': 3, 'fire': 2, 'clap': 1, 'spark': 4};
  String? _picked = 'spark';

  static const _items = [
    ('love', Icons.favorite_rounded),
    ('fire', Icons.local_fire_department_rounded),
    ('clap', Icons.thumb_up_rounded),
    ('spark', Icons.auto_awesome_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: t.line, width: t.stroke * 0.55)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _items.length; i++)
            GestureDetector(
              onTap: () {
                final id = _items[i].$1;
                final active = _picked == id;
                setState(() {
                  _picked = active ? null : id;
                  _counts[id] = (_counts[id] ?? 0) + (active ? -1 : 1);
                });
                KipluoSound.play(active ? KSound.boopLow : KSound.pop, at: context, pitch: notePitch(i), componentEnabled: widget.sound);
                widget.onReact?.call(id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _picked == _items[i].$1 ? t.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_items[i].$2, size: 15, color: _picked == _items[i].$1 ? t.accentInk : t.line),
                    const SizedBox(width: 4),
                    Text('${_counts[_items[i].$1]}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _picked == _items[i].$1 ? t.accentInk : t.line)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* 19. Inline Status Pill (Free) */
class InlineStatusPill extends StatefulWidget {
  const InlineStatusPill({super.key, this.sound = true});
  final bool sound;

  @override
  State<InlineStatusPill> createState() => _InlineStatusPillState();
}

class _InlineStatusPillState extends State<InlineStatusPill> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final states = [
      ('All systems online', t.ok),
      ('Syncing changes...', t.accent),
      ('High latency', Colors.amber),
      ('Connection lost', t.bad),
    ];
    final cur = states[_idx];
    return GestureDetector(
      onTap: () {
        final next = (_idx + 1) % states.length;
        setState(() => _idx = next);
        KipluoSound.play(next >= 2 ? KSound.bonk : KSound.drop, at: context, volume: 0.5, componentEnabled: widget.sound);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: t.line, width: t.stroke * 0.55)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: cur.$2, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(cur.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.line)),
          ],
        ),
      ),
    );
  }
}
