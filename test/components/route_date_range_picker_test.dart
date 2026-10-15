import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/components/route_date_range_picker.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    DateTime? today,
    DateTime? start,
    DateTime? end,
    ValueChanged<DateTime>? onSelect,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 288,
            child: RouteDateRangePicker(
              currentDate: today,
              startDate: start,
              endDate: end,
              onSelect: onSelect ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'defaults to the current month and lays out leap February correctly',
    (tester) async {
      await mount(tester, today: DateTime(2028, 2, 15));
      expect(find.text('2028年 2月'), findsOneWidget);
      expect(find.text('29'), findsOneWidget);
      expect(find.text('30'), findsNothing);
      final first = tester.getRect(
        find.byKey(const ValueKey('calendar-day-2028-2-1')),
      );
      final monday = tester.getRect(find.text('一'));
      // 1 February 2028 is Tuesday, so Monday's first cell must be empty.
      expect(first.left, greaterThan(monday.center.dx));
      DateTime? selected;
      await mount(
        tester,
        today: DateTime(2028, 2, 15),
        onSelect: (date) => selected = date,
      );
      await tester.tap(find.text('29'));
      expect(selected, DateTime(2028, 2, 29));
    },
  );

  testWidgets(
    'month arrows cross the year and returning to this month does not select a date',
    (tester) async {
      var calls = 0;
      await mount(
        tester,
        today: DateTime(2026, 12, 15),
        onSelect: (_) => calls++,
      );
      await tester.tap(find.byTooltip('下个月'));
      await tester.pumpAndSettle();
      expect(find.text('2027年 1月'), findsOneWidget);
      await tester.tap(find.byTooltip('上个月'));
      await tester.pumpAndSettle();
      expect(find.text('2026年 12月'), findsOneWidget);
      await tester.tap(find.byTooltip('上个月'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('回到本月'));
      await tester.pumpAndSettle();
      expect(find.text('2026年 12月'), findsOneWidget);
      expect(calls, 0);
    },
  );

  testWidgets(
    'direct year and month selection validates year and can be cancelled',
    (tester) async {
      await mount(tester, today: DateTime(2026, 10, 15));
      await tester.tap(find.byKey(const ValueKey('calendar-choose-month')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('calendar-year-field')),
        '0',
      );
      await tester.tap(find.text('确定年月'));
      await tester.pumpAndSettle();
      expect(find.text('请输入 1–9999 的年份'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('calendar-year-field')),
        '2028',
      );
      await tester.tap(find.byKey(const ValueKey('calendar-month-2')));
      await tester.tap(find.text('确定年月'));
      await tester.pumpAndSettle();
      expect(find.text('2028年 2月'), findsOneWidget);
      expect(find.text('29'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-choose-month')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('calendar-year-field')),
        '2030',
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('2028年 2月'), findsOneWidget);
    },
  );

  testWidgets(
    'reopening a saved range shows its departure month and retains full dates',
    (tester) async {
      await mount(
        tester,
        today: DateTime(2026, 10, 15),
        start: DateTime(2027, 12, 30),
        end: DateTime(2028, 1, 2),
      );
      expect(find.text('2027年 12月'), findsOneWidget);
      await tester.tap(find.byTooltip('下个月'));
      await tester.pumpAndSettle();
      expect(find.text('2028年 1月'), findsOneWidget);
      final semantics = tester.getSemantics(
        find.byKey(const ValueKey('calendar-day-2028-1-2')),
      );
      expect(semantics.label, contains('返程日期'));
      expect(tester.takeException(), isNull);
    },
  );
}
