import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/user_route_repository.dart';
import 'package:sageroute/models/saved_route.dart';
import 'package:sageroute/route_planning/models/transport_type.dart';
import 'package:sageroute/views/route_preview/route_edit_page.dart';
import 'package:sageroute/views/route_preview/route_preview_page.dart';

void main() {
  const channel = MethodChannel('com.sageroute/route_planning');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = call.arguments as Map;
          return {
            'distance': 1200,
            'duration': 600,
            'polyline': [
              [args['originLat'], args['originLon']],
              [args['destLat'], args['destLon']],
            ],
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'preview page renders read-only route with edit entry',
    (tester) async {
      Uri? openedNavigationUri;
      tester.view.physicalSize = const Size(430, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: RoutePreviewPage(
            routeId: 'route-1',
            initialRoute: _route(),
            repository: _FailingRouteRepository(),
            openNavigationUrl: (uri) async {
              openedNavigationUri = uri;
              return true;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // 顶部标题与编辑入口。
      expect(find.text('白居易的杭州之旅'), findsOneWidget);
      expect(find.byTooltip('编辑路线'), findsOneWidget);

      // 只读预览：地点按途经点顺序渲染，且无编辑操作入口。
      final map = tester.widget<AMapWidget>(find.byType(AMapWidget));
      expect(map.markers.map((m) => m.infoWindow.title), ['1. 白堤', '2. 苏堤']);
      expect(find.byTooltip('添加地点'), findsNothing);
      expect(find.byTooltip('清空地点'), findsNothing);
      expect(find.text('步行'), findsOneWidget);

      // footer 主按钮为「开始导航」。
      expect(find.text('保存行程'), findsNothing);
      expect(find.text('开始导航'), findsOneWidget);

      await tester.tap(find.text('开始导航'));
      await tester.pump();
      expect(openedNavigationUri?.scheme, 'amapuri');
      expect(openedNavigationUri?.host, 'route');
      expect(openedNavigationUri?.path, '/plan/');
      expect(openedNavigationUri?.queryParameters['sname'], '我的位置');
      expect(openedNavigationUri?.queryParameters['dlat'], '30.258');
      expect(openedNavigationUri?.queryParameters['dlon'], '120.147');
      expect(openedNavigationUri?.queryParameters['dname'], '白堤');

      // 点编辑进入编辑页。
      await tester.tap(find.byTooltip('编辑路线'));
      await tester.pumpAndSettle();
      expect(find.byType(RouteEditPage), findsOneWidget);
      expect(find.text('编辑路线'), findsOneWidget);

      // 返回后回到预览页。
      await tester.tap(find.byTooltip('返回').last);
      await tester.pumpAndSettle();
      expect(find.byType(RouteEditPage), findsNothing);
      expect(find.byType(RoutePreviewPage), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}

class _FailingRouteRepository extends UserRouteRepository {
  @override
  Future<SavedRoute?> fetchRouteById(String routeId) =>
      throw StateError('initial route should render without refetching');
}

SavedRoute _route() {
  return const SavedRoute(
    id: 'route-1',
    title: '白居易的杭州之旅',
    dateRange: '2026.06.15 — 2026.06.18',
    duration: '4天3晚',
    distance: '12.5km',
    figureId: 5,
    figureName: '白居易',
    waypoints: [
      RouteWaypoint(
        name: '白堤',
        latitude: 30.258,
        longitude: 120.147,
        transportToNext: TransportType.walking,
      ),
      RouteWaypoint(name: '苏堤', latitude: 30.21, longitude: 120.13),
    ],
  );
}
