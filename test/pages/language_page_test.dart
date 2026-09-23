import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/pages/language_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/page_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('lists supported and upcoming languages', (tester) async {
    useLargeSurface(tester);
    await pumpPushedPage(tester, const LanguagePage());

    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('繁體中文'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('即将上线'), findsNWidgets(2));
  });

  testWidgets('tapping the current language keeps it selected', (tester) async {
    useLargeSurface(tester);
    await pumpPushedPage(tester, const LanguagePage());

    await tester.tap(find.byKey(const Key('language-option-zh-Hans')));
    await tester.pumpAndSettle();

    expect(find.text('当前已是简体中文'), findsOneWidget);
  });
}
