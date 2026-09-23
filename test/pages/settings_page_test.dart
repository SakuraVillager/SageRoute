import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/pages/account_info_page.dart';
import 'package:sageroute/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/page_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows grouped settings entries', (tester) async {
    useLargeSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('账号'), findsOneWidget);
    expect(find.text('偏好'), findsOneWidget);
    expect(find.text('同行人物'), findsOneWidget);
    expect(find.text('账号信息'), findsOneWidget);
    expect(find.text('旅行偏好'), findsOneWidget);
    expect(find.text('语言设置'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('切换人物'), findsOneWidget);
  });

  testWidgets('switch celebrity uses the injected callback', (tester) async {
    useLargeSurface(tester);
    var switched = false;
    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(onSwitchCelebrity: () => switched = true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-switch-celebrity')));
    await tester.pumpAndSettle();

    expect(switched, isTrue);
  });

  testWidgets('account info entry opens AccountInfoPage', (tester) async {
    useLargeSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-account-info')));
    await tester.pumpAndSettle();

    expect(find.byType(AccountInfoPage), findsOneWidget);
  });
}
