import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/theme/app_theme.dart';
import 'package:sageroute/views/create_route_wizard/create_route_wizard.dart';
import 'package:sageroute/components/route_date_range_picker.dart';

void main() {
  testWidgets('first step renders the form and accepts title and date input', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const CreateRouteWizard()),
    );

    expect(find.text('行程名称'), findsOneWidget);
    expect(find.text('出行日期'), findsOneWidget);
    final now = DateTime.now();
    expect(find.text('${now.year}年 ${now.month}月'), findsOneWidget);

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
    final picker = tester.widget<RouteDateRangePicker>(
      find.byType(RouteDateRangePicker),
    );
    expect(picker.startDate, DateTime(now.year, now.month, 12));
    expect(picker.endDate, DateTime(now.year, now.month, 14));
  });

  testWidgets('planner retains a full range when selecting across months', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const CreateRouteWizard()),
    );
    final start = find.byKey(
      ValueKey('calendar-day-${now.year}-${now.month}-27'),
    );
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.tap(find.byTooltip('下个月'));
    await tester.pumpAndSettle();
    final end = find.byKey(
      ValueKey('calendar-day-${next.year}-${next.month}-2'),
    );
    await tester.ensureVisible(end);
    await tester.tap(end);
    await tester.pumpAndSettle();
    final picker = tester.widget<RouteDateRangePicker>(
      find.byType(RouteDateRangePicker),
    );
    expect(picker.startDate, DateTime(now.year, now.month, 27));
    expect(picker.endDate, DateTime(next.year, next.month, 2));
  });
}
