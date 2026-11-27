import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/* 21. Spring Combobox (Free) */

class SpringCombobox extends StatefulWidget {
  const SpringCombobox({super.key, this.options = const ['React 19', 'Next.js 16', 'Flutter 3', 'Tailwind v4'], this.sound = true});
  final List<String> options;
  final bool sound;

  @override
  State<SpringCombobox> createState() => _SpringComboboxState();
}

class _SpringComboboxState extends State<SpringCombobox> {
  String _query = '';
  String _picked = 'React 19';

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    final matches = widget.options.where((o) => o.toLowerCase().contains(_query.toLowerCase())).toList();
    return SizedBox(
      width: 236,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.line),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Selected: $_picked',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: t.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.line, width: t.stroke)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.line, width: 1.5)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: matches.map((opt) {
                final on = opt == _picked;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _picked = opt;
                    });
                    KipluoSound.play(KSound.pop, at: context, volume: 0.45, componentEnabled: widget.sound);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: on ? t.accent : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Text(opt, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: on ? t.accentInk : t.line)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/* 22. Tactile Radio Cards (Free) */

class TactileRadioCards extends StatefulWidget {
  const TactileRadioCards({super.key, this.initialValue = 'pro', this.sound = true});
  final String initialValue;
  final bool sound;

  @override
  State<TactileRadioCards> createState() => _TactileRadioCardsState();
}

class _TactileRadioCardsState extends State<TactileRadioCards> {
  static const _plans = [('free', 'Free', '58 widgets'), ('pro', 'Pro', 'All 131 + 2.1k icons'), ('team', 'Team', '10 seats')];
  late String _val = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return SizedBox(
      width: 236,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _plans.map((p) {
          final on = _val == p.$1;
          return GestureDetector(
            onTap: () {
              setState(() {
                _val = p.$1;
              });
              KipluoSound.play(KSound.boop, at: context, volume: 0.48, componentEnabled: widget.sound);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: on ? t.accent.withValues(alpha: 0.25) : t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: on ? t.line : t.line.withValues(alpha: 0.45), width: 2.0),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: t.line)),
                            Text(p.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: t.line.withValues(alpha: 0.72))),
                          ],
                        ),
                      ),
                      Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: t.surface, border: Border.all(color: t.line, width: 2)),
                        child: AnimatedScale(
                          scale: on ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutBack,
                          child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
