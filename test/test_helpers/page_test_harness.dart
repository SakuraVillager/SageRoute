import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 放大测试窗口，保证 ListView 一次性构建全部子项，
/// 避免懒加载导致 `find.byKey` 找不到视口外的控件。
void useLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 从宿主页面 push 目标页，便于测试依赖 `Navigator.pop` 的行为
/// （直接以目标页作为 home 时，pop 初始路由会得到空导航栈）。
Future<void> pumpPushedPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (context) => page)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
