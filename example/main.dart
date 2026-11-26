import 'package:flutter/material.dart';
import 'package:kipluo/kipluo.dart';

void main() => runApp(const KipluoExample());

class KipluoExample extends StatefulWidget {
  const KipluoExample({super.key});

  @override
  State<KipluoExample> createState() => _KipluoExampleState();
}

class _KipluoExampleState extends State<KipluoExample> {
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kipluo',
      home: Scaffold(
        body: Center(
          child: KipluoTheme(
            style: KipluoStyle.playful,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                SpringToggle(
                  value: notifications,
                  label: 'Notifications',
                  onChanged: (v) => setState(() => notifications = v),
                ),
                KipluoIcon.bySlug('user-icon'),
                const KHeartIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
