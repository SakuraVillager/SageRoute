import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/saved_route.dart';
import 'package:sageroute/views/home_page.dart';

void main() {
  testWidgets('startup sync displays every historical route', (tester) async {
    final routes = ValueNotifier<List<SavedRoute>>([]);
    addTearDown(routes.dispose);

    await tester.pumpWidget(
      MaterialApp(home: HomePage(createdRoutesListenable: routes)),
    );

    routes.value = [
      _route('one', '历史行程一'),
      _route('two', '历史行程二'),
      _route('three', '历史行程三'),
    ];
    await tester.pumpAndSettle();

    expect(find.text('历史行程一'), findsOneWidget);
    expect(find.text('历史行程二'), findsOneWidget);
    expect(find.text('历史行程三'), findsOneWidget);
  });

  testWidgets('example route explains that it is a placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('白居易的江南遗迹'));
    await tester.pump();

    expect(find.text('仅占位示例行程，暂不可查看'), findsOneWidget);
  });
}

SavedRoute _route(String id, String title) => SavedRoute(
  id: id,
  title: title,
  dateRange: '2026.09.23',
  duration: '1天',
  distance: '1 km',
  waypoints: const [],
);
