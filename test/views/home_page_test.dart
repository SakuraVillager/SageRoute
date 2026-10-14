import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/saved_route.dart';
import 'package:sageroute/views/home_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('白居易的江南遗迹'));
    await tester.pump();

    expect(find.text('仅占位示例行程，暂不可查看'), findsOneWidget);
  });

  testWidgets('delete confirms before removing a saved route', (tester) async {
    final routes = ValueNotifier<List<SavedRoute>>([_route('one', '历史行程一')]);
    addTearDown(routes.dispose);
    var deleteCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          createdRoutesListenable: routes,
          onDeleteRoute: (id) async {
            deleteCalls++;
            routes.value = routes.value
                .where((route) => route.id != id)
                .toList();
          },
        ),
      ),
    );

    expect(find.byIcon(Icons.delete_outline), findsNothing);
    await tester.longPress(find.text('历史行程一'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除行程'));
    await tester.pumpAndSettle();
    expect(find.textContaining('无法恢复'), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('取消')),
    );
    await tester.pumpAndSettle();
    expect(deleteCalls, 0);
    expect(find.text('历史行程一'), findsOneWidget);

    await tester.longPress(find.text('历史行程一'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除行程'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(deleteCalls, 1);
    expect(find.text('历史行程一'), findsNothing);
    expect(find.text('行程已删除'), findsOneWidget);
  });

  testWidgets('failed deletion keeps the route on the home page', (
    tester,
  ) async {
    final routes = ValueNotifier<List<SavedRoute>>([_route('one', '历史行程一')]);
    addTearDown(routes.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          createdRoutesListenable: routes,
          onDeleteRoute: (_) async => throw StateError('数据库拒绝删除'),
        ),
      ),
    );

    await tester.longPress(find.text('历史行程一'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除行程'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.text('历史行程一'), findsOneWidget);
    expect(find.textContaining('删除失败'), findsOneWidget);
  });

  testWidgets('batch delete removes only selected saved routes', (
    tester,
  ) async {
    final routes = ValueNotifier<List<SavedRoute>>([
      _route('one', '历史行程一'),
      _route('two', '历史行程二'),
      _route('three', '历史行程三'),
    ]);
    addTearDown(routes.dispose);
    final deleted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          createdRoutesListenable: routes,
          onDeleteRoute: (id) async {
            deleted.add(id);
            routes.value = routes.value
                .where((route) => route.id != id)
                .toList();
          },
        ),
      ),
    );

    await tester.tap(find.text('批量删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('历史行程一'));
    await tester.ensureVisible(find.text('历史行程三'));
    await tester.tap(find.text('历史行程三'));
    await tester.pumpAndSettle();
    expect(find.text('已选择 2 项'), findsOneWidget);

    await tester.ensureVisible(find.text('删除(2)'));
    await tester.tap(find.text('删除(2)'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('取消')),
    );
    await tester.pumpAndSettle();
    expect(deleted, isEmpty);

    await tester.tap(find.text('删除(2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(deleted, ['one', 'three']);
    expect(find.text('历史行程一'), findsNothing);
    expect(find.text('历史行程二'), findsOneWidget);
    expect(find.text('历史行程三'), findsNothing);
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
