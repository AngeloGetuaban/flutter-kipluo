import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Item entry for [ElasticAccordion].
class AccordionItem {
  const AccordionItem({required this.title, required this.body});
  final String title;
  final Widget body;
}

/// Accordion panels that open on a slightly under-damped spring with a rotating chevron.
class ElasticAccordion extends StatefulWidget {
  const ElasticAccordion({
    super.key,
    required this.items,
    this.multiple = false,
    this.initialOpen = const {},
    this.sound = true,
  });

  final List<AccordionItem> items;
  final bool multiple;
  final Set<int> initialOpen;
  final bool sound;

  @override
  State<ElasticAccordion> createState() => _ElasticAccordionState();
}

class _ElasticAccordionState extends State<ElasticAccordion> {
  late Set<int> _open = Set.of(widget.initialOpen);

  void _toggle(int i) {
    final willOpen = !_open.contains(i);
    setState(() {
      if (widget.multiple) {
        if (willOpen) {
          _open.add(i);
        } else {
          _open.remove(i);
        }
      } else {
        _open = willOpen ? {i} : {};
      }
    });
    KipluoSound.play(willOpen ? KSound.boop : KSound.boopLow, at: context, volume: 0.55, componentEnabled: widget.sound);
  }

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.items.length; i++)
          _AccordionPanel(
            item: widget.items[i],
            isOpen: _open.contains(i),
            tokens: t,
            onToggle: () => _toggle(i),
          ),
      ],
    );
  }
}

class _AccordionPanel extends StatefulWidget {
  const _AccordionPanel({required this.item, required this.isOpen, required this.tokens, required this.onToggle});
  final AccordionItem item;
  final bool isOpen;
  final KipluoTokens tokens;
  final VoidCallback onToggle;

  @override
  State<_AccordionPanel> createState() => _AccordionPanelState();
}

class _AccordionPanelState extends State<_AccordionPanel> with SingleTickerProviderStateMixin {
  late final KSprings _s = KSprings(
    vsync: this,
    initial: {'open': widget.isOpen ? 100 : 0},
    config: const SpringConfig(stiffness: 240, damping: 16),
  );

  @override
  void didUpdateWidget(_AccordionPanel old) {
    super.didUpdateWidget(old);
    if (old.isOpen != widget.isOpen) {
      _s.reducedMotion = kipluoReducedMotion(context);
      _s.animateTo({'open': widget.isOpen ? 100 : 0});
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.line, width: t.stroke * 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: widget.isOpen,
            label: widget.item.title,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(widget.item.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                    AnimatedBuilder(
                      animation: _s,
                      builder: (context, _) => Transform.rotate(
                        angle: (_s['open'] / 100).clamp(0.0, 1.15) * math.pi,
                        child: Icon(Icons.expand_more_rounded, color: t.line),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _s,
            builder: (context, child) {
              final v = (_s['open'] / 100).clamp(0.0, 1.08);
              if (v <= 0.005 && !widget.isOpen) return const SizedBox.shrink();
              return ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  heightFactor: v.clamp(0.0, 1.0),
                  child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.item.body,
            ),
          ),
        ],
      ),
    );
  }
}
