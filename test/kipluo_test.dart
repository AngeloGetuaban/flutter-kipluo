import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kipluo/kipluo.dart';

void main() {
  setUp(() => KipluoSound.enabled.value = false);

  testWidgets('SpringToggle flips and reports the new value', (tester) async {
    var value = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SpringToggle(
            value: value,
            label: 'Notifications',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  test('the icon pack only contains free icons', () {
    expect(kipluoIconPack, isNotEmpty);
    expect(kipluoIconPack.every((s) => s.tier == KIconTier.free), isTrue);
  });

  test('paid icons are not available by slug', () {
    expect(kipluoIconBySlug.containsKey('user-icon'), isTrue);
    expect(kipluoIconBySlug.containsKey('factory-icon'), isFalse);
  });

  testWidgets('free icons render', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: KipluoIcon.bySlug('user-icon')))));
    expect(find.byType(KipluoIcon), findsOneWidget);
  });
}
