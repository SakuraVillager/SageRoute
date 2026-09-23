import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/components/bottom_nav.dart';
import 'package:sageroute/theme/color_schemes.dart';

/// 机型样例：覆盖小屏、全面屏、手势条 / 虚拟按键高度差异、横屏刘海。
const _devices = <({String name, Size size, EdgeInsets padding})>[
  (
    name: '小屏无手势条 320x568',
    size: Size(320, 568),
    padding: EdgeInsets.only(top: 20),
  ),
  (
    name: '虚拟按键 360x800',
    size: Size(360, 800),
    padding: EdgeInsets.only(top: 24, bottom: 48),
  ),
  (
    name: '矮手势条 390x844',
    size: Size(390, 844),
    padding: EdgeInsets.only(top: 47, bottom: 24),
  ),
  (
    name: '高手势条 430x932',
    size: Size(430, 932),
    padding: EdgeInsets.only(top: 59, bottom: 34),
  ),
  (
    name: '横屏刘海 844x390',
    size: Size(844, 390),
    padding: EdgeInsets.fromLTRB(44, 0, 44, 21),
  ),
];

Future<void> _pumpBottomNav(
  WidgetTester tester, {
  required Size screen,
  required EdgeInsets padding,
  ValueChanged<int>? onTap,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: screen,
          padding: padding,
          viewPadding: padding,
        ),
        child: child!,
      ),
      // 复刻 MainScreen 的摆放方式：页面铺满整屏并延伸到屏幕底边
      //（Scaffold extendBody），导航栏用 Positioned 贴在 Stack 最底部。
      home: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.sageBg)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SageRouteBottomNav(currentIndex: 0, onTap: onTap ?? (_) {}),
          ),
        ],
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('底部导航栏贴合屏幕底边', () {
    for (final device in _devices) {
      testWidgets(device.name, (tester) async {
        await _pumpBottomNav(
          tester,
          screen: device.size,
          padding: device.padding,
        );

        // find.byType 拿到的是导航栏最外层的方框，也就是画背景的那一层。
        final bar = tester.getRect(find.byType(SageRouteBottomNav));
        final content = tester.getRect(
          find.byKey(const Key('bottom-nav-content')),
        );

        // 背景一直铺到物理底边 —— 导航栏下方不再露出页面底色。
        expect(bar.bottom, device.size.height);
        expect(
          bar.height,
          SageRouteBottomNav.barHeight + device.padding.bottom,
        );
        // 上方不能多出状态栏内边距，否则导航栏顶部会浮起来。
        expect(bar.top, content.top);
        // 内容区域让开手势条 / 虚拟按键，且左右避开刘海。
        expect(content.height, SageRouteBottomNav.barHeight);
        expect(content.bottom, device.size.height - device.padding.bottom);
        expect(content.left, device.padding.left);
        expect(content.right, device.size.width - device.padding.right);
      });
    }

    testWidgets('没有安全区时导航栏高度仍是标准值', (tester) async {
      await _pumpBottomNav(
        tester,
        screen: const Size(390, 844),
        padding: EdgeInsets.zero,
      );

      final bar = tester.getRect(find.byType(SageRouteBottomNav));
      expect(bar.bottom, 844);
      expect(bar.height, SageRouteBottomNav.barHeight);
    });
  });

  testWidgets('重构后五个 tab 仍可点击', (tester) async {
    final taps = <int>[];
    await _pumpBottomNav(
      tester,
      screen: const Size(430, 932),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      onTap: taps.add,
    );

    for (final label in <String>['首页', '人物', '收藏', '我的', '规划']) {
      await tester.tap(find.text(label));
    }
    await tester.pump();

    expect(taps, <int>[0, 1, 3, 4, 2]);
  });
}
