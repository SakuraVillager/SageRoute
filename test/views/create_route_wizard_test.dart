import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/theme/app_theme.dart';
import 'package:sageroute/views/create_route_wizard/create_route_wizard.dart';

void main() {
  testWidgets('first step renders the form and accepts title and date input', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const CreateRouteWizard()),
    );

    expect(find.text('行程名称'), findsOneWidget);
    expect(find.text('出行日期'), findsOneWidget);
    expect(find.text('2026年 6月'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('route-title-field')),
      '苏轼的杭州三日行',
    );
    await tester.pumpAndSettle();

    expect(find.text('苏轼的杭州三日行'), findsWidgets);

    await tester.tap(find.text('12'));
    await tester.pump();
    await tester.tap(find.text('14'));
    await tester.pump();
  });
}
