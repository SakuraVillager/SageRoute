@TestOn('browser')
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/components/web/web_back_button.dart';

void main() {
  testWidgets(
    'hover changes the finish without a tooltip and click goes back',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WebBackButton(onPressed: () => calls++)),
        ),
      );
      final control = find.byType(WebBackButton);
      final surface = find.descendant(
        of: control,
        matching: find.byType(AnimatedContainer),
      );
      BoxDecoration decoration() =>
          tester.widget<AnimatedContainer>(surface).decoration!
              as BoxDecoration;
      final resting = decoration();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      await mouse.moveTo(tester.getCenter(control));
      await tester.pumpAndSettle();
      expect(decoration().gradient, isNot(resting.gradient));
      expect(decoration().boxShadow!.single.blurRadius, greaterThan(4));
      expect(find.byType(Tooltip), findsNothing);
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(calls, 1);
      await mouse.moveTo(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(decoration().gradient, resting.gradient);
      await mouse.removePointer();
    },
  );

  testWidgets('keyboard activation and reduced motion remain available', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: WebBackButton(onPressed: () => calls++)),
        ),
      ),
    );
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      Duration.zero,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}
