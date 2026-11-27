import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/theme.dart';

/* 31. Spring Banner (Free) */

class BannerAnnouncement extends StatefulWidget {
  const BannerAnnouncement({super.key, this.message = 'Kipluo 2.0 · 2,100+ live icons', this.sound = true});
  final String message;
  final bool sound;

  @override
  State<BannerAnnouncement> createState() => _BannerAnnouncementState();
}

class _BannerAnnouncementState extends State<BannerAnnouncement> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final t = KipluoTheme.tokensOf(context);
    return SizedBox(
      width: 248,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (_visible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.line, width: t.stroke),
              ),
              child: Row(
                children: [
                  Expanded(child: Text('✦ ${widget.message}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.line))),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() => _visible = false);
                      KipluoSound.play(KSound.swish, at: context, volume: 0.42, componentEnabled: widget.sound);
                    },
                    child: Icon(Icons.close_rounded, size: 16, color: t.line),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () {
                setState(() {
                  _visible = true;
                });
                KipluoSound.play(KSound.whoosh, at: context, volume: 0.45, componentEnabled: widget.sound);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(99), border: Border.all(color: t.line, width: 1.5)),
                child: Text('Restore banner ✦', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.accentInk)),
              ),
            ),
        ],
      ),
    );
  }
}
