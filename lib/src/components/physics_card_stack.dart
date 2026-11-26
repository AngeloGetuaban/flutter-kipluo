import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

enum ThrowDirection { left, right }

/// A ready-made card face in the Kipluo look, for demos and quick starts.
class KipluoCard extends StatelessWidget {
  const KipluoCard({super.key, required this.title, required this.meta, this.tone = KipluoColors.gumball});

  final String title;
  final String meta;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line, width: 1.5),
        boxShadow: [BoxShadow(color: t.line, offset: const Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(width: 40, height: 8, decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(8))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 4),
            Text(meta, style: TextStyle(color: t.line.withValues(alpha: 0.6))),
          ]),
        ],
      ),
    );
  }
}
