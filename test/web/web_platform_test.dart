@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:convert';
import 'package:sageroute/components/web/web_brand_panel.dart';
import 'package:sageroute/components/web/web_auth_layout.dart';
import 'package:sageroute/components/web/web_workspace.dart';
import 'package:sageroute/views/web_welcome_page.dart';
import 'package:sageroute/views/create_route_wizard/create_route_wizard.dart';
import 'package:sageroute/views/create_route_wizard/steps/step1_figure.dart';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sageroute/components/map/sage_map.dart';
import 'package:sageroute/models/saved_route.dart';
import 'package:sageroute/navigation/map_overlay_observer.dart';
import 'package:sageroute/route_planning/models/amap_route_types.dart';
import 'package:sageroute/route_planning/models/route_place.dart';
import 'package:sageroute/route_planning/models/transport_type.dart';
import 'package:sageroute/services/amap_navigation.dart';
import 'package:sageroute/services/browser_session.dart';
import 'package:sageroute/services/credential_storage.dart';
import 'package:sageroute/services/location_service.dart';
import 'package:sageroute/services/route_draft_storage.dart';
import 'package:sageroute/services/route_gateway_web.dart';
import 'package:sageroute/services/auth_service.dart';
import 'package:sageroute/components/draft_exit_guard.dart';
import 'package:sageroute/navigation/web_app.dart';
import 'package:sageroute/auth/login_page.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sageroute/main.dart' show MainScreen;
import 'package:sageroute/views/home_page.dart';
import 'package:sageroute/views/route_invitation_page.dart';
import 'package:sageroute/views/discovery/discovery_page.dart';
import 'package:sageroute/services/guest_session.dart';
import 'package:sageroute/data/user_route_repository.dart';
import 'package:sageroute/views/route_preview/route_preview_page.dart';
import 'package:sageroute/views/route_preview/route_edit_page.dart';
import 'package:sageroute/views/create_route_wizard/steps/step3_map.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://sageroute-test.invalid',
      publishableKey: 'test-public-key',
      httpClient: MockClient(
        (request) async => http.Response(
          request.url.path.endsWith('/Celebrity')
              ? jsonEncode([
                  {
                    'id': 1,
                    'name': '苏轼',
                    'dynasty': '宋',
                    'bio_short': '诗与远方',
                    'avatar_url': '',
                    'topic': [],
                  },
                ])
              : '[]',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
          request: request,
        ),
      ),
      authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets('public invitations retain their path without forcing a login', (
    tester,
  ) async {
    final token = 'a' * 64;
    await tester.pumpWidget(
      WebSageRouteApp(
        initialization: Future<Object?>.value(),
        initialLocation: '/invite/$token',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RouteInvitationPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    final router = GoRouter.of(
      tester.element(find.byType(RouteInvitationPage)),
    );
    expect(router.routeInformationProvider.value.uri.path, '/invite/$token');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('legacy saved URL opens public discovery', (tester) async {
    await tester.pumpWidget(
      WebSageRouteApp(
        initialization: Future<Object?>.value(),
        initialLocation: '/saved',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DiscoveryPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  late List<Map<dynamic, dynamic>> updates;
  late List<int> destroyed;
  late List<bool> blocked;
  late Map<dynamic, dynamic>? routeRequest;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clearRouteDrafts();
    updates = [];
    destroyed = [];
    blocked = [];
    routeRequest = null;
    globalContext.setProperty(
      'sageMaps'.toJS,
      {
        'create': ((JSAny host, JSAny options, JSFunction tap) => Future.value(
          1.toJS,
        ).toJS).toJS,
        'update': ((JSNumber id, JSAny data) {
          updates.add(data.dartify()! as Map);
        }).toJS,
        'camera': ((JSNumber id, JSAny data) {}).toJS,
        'destroy': ((JSNumber id) {
          destroyed.add(id.toDartInt);
        }).toJS,
        'block': ((JSBoolean value) {
          blocked.add(value.toDart);
        }).toJS,
        'route': ((JSAny options) {
          routeRequest = options.dartify()! as Map;
          return Future<JSAny?>.value(
            {
              'distance': 100,
              'duration': 80,
              'polyline': [
                [30.1, 120.1],
                [30.2, 120.2],
              ],
            }.jsify(),
          ).toJS;
        }).toJS,
        'locate': ((JSAny options) => JSPromise<JSAny?>(
          ((JSFunction resolve, JSFunction reject) {
            final error = (globalContext['Error'] as JSFunction)
                .callAsConstructor<JSObject>('PERMISSION_DENIED'.toJS);
            reject.callAsFunction(null, error);
          }).toJS,
        )).toJS,
      }.jsify()!,
    );
  });

  test('Web uses the current HTTPS/localhost origin for email callbacks', () {
    final callback = Uri.parse(AuthService.passwordResetRedirectTo);
    expect(callback.origin, Uri.base.origin);
    expect(callback.path, '/auth/callback');
    expect(callback.fragment, isEmpty);
  });

  test('tab drafts are partitioned by user and cleared on sign out', () {
    const first = RouteDraftStorage(userId: 'first', draftId: 'new');
    const second = RouteDraftStorage(userId: 'second', draftId: 'new');
    first.save({'title': '杭州路线', 'step': 3});
    expect(first.load()?['title'], '杭州路线');
    expect(second.load(), isNull);
    writeSessionValue(second.key, '{broken');
    expect(second.load(), isNull);
    expect(readSessionValue(second.key), isNull);
    clearRouteDrafts();
    expect(first.load(), isNull);
  });

  test('Web credential storage never retains a password by default', () async {
    final storage = CredentialStorage();
    await storage.save(email: 'a@example.com', password: 'password');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(CredentialStorage.passwordKey), isNull);
    expect((await storage.load())?.password, isEmpty);
  });

  test(
    'JS routing uses longitude-first input and preserves policy and units',
    () async {
      const origin = RoutePlace(
        id: 1,
        name: 'A',
        latitude: 30.1,
        longitude: 120.1,
        averageVisitDurationMin: null,
        topic: null,
        categories: null,
      );
      const destination = RoutePlace(
        id: 2,
        name: 'B',
        latitude: 30.2,
        longitude: 120.2,
        averageVisitDurationMin: null,
        topic: null,
        categories: null,
      );
      final result = await const WebAmapGateway().fetchRoute(
        const AmapRouteDraftRequest(
          origin: origin,
          destination: destination,
          waypoints: [],
          transportType: TransportType.driving,
          optimizeOrder: false,
          preferenceKey: 'shortest',
        ),
      );
      expect(routeRequest?['origin'], [120.1, 30.1]);
      expect(routeRequest?['preference'], 'shortest');
      expect(result.polyline.first, [30.1, 120.1]);
      expect(result.travelDuration.inSeconds, 80);
    },
  );

  test('denied location returns an actionable result', () async {
    final result = await LocationService.locate();
    expect(result.status, LocationStatus.denied);
    expect(result.coordinate, isNull);
    expect(result.message, contains('浏览器'));
  });

  test('navigation opens an HTTPS page with GCJ-02 coordinates', () {
    final uri = buildAmapNavigationUri(
      const RouteWaypoint(name: '钟楼', latitude: 34.26, longitude: 108.95),
    );
    expect(uri.scheme, 'https');
    expect(uri.host, 'uri.amap.com');
    expect(uri.queryParameters['coordinate'], 'gaode');
  });

  testWidgets('map overlays update and DOM map is released on exit', (
    tester,
  ) async {
    final registry = _TestHtmlViewRegistry(tester);
    ui_web.debugOverridePlatformViewRegistry(registry);
    addTearDown(() {
      ui_web.debugOverridePlatformViewRegistry(null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        null,
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SageMap(
            initialCameraPosition: const MapCameraPosition(
              target: MapCoordinate(30, 120),
            ),
            markers: {
              MapMarkerData(
                position: const MapCoordinate(30, 120),
                infoWindow: const MapInfoWindow(title: '景点'),
              ),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(updates, isNotEmpty);
    expect((updates.last['markers'] as List).first['position'], [120, 30]);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(destroyed, [1]);
  });

  testWidgets(
    'popup barrier blocks DOM map pointers and restores them on close',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [MapOverlayObserver()],
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(blocked.last, isTrue);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      expect(blocked.last, isFalse);
    },
  );

  testWidgets(
    'protected detail URL retains its target through the login redirect',
    (tester) async {
      await tester.pumpWidget(
        WebSageRouteApp(
          initialization: Future.value(),
          initialLocation: '/articles/42',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(LoginPage)));
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(
        router.routeInformationProvider.value.uri.queryParameters['from'],
        '/articles/42',
      );
      await tester.ensureVisible(find.text('忘记密码？'));
      await tester.tap(find.text('忘记密码？'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationParser
            .restoreRouteInformation(
              router.routerDelegate.currentConfiguration,
            )!
            .uri
            .path,
        '/forgot-password',
      );
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationParser
            .restoreRouteInformation(
              router.routerDelegate.currentConfiguration,
            )!
            .uri
            .path,
        '/login',
      );
      router.go('/register');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/register');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'invalid callback exposes resend actions without entering the main app',
    (tester) async {
      await tester.pumpWidget(
        WebSageRouteApp(
          initialization: Future.value(),
          initialLocation: '/auth/callback',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('验证链接无效或已过期，请重新发送邮件'), findsOneWidget);
      await tester.tap(find.text('重新发送注册验证邮件'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('router exit keeps the draft until the user confirms discard', (
    tester,
  ) async {
    var discarded = false;
    final router = GoRouter(
      initialLocation: '/edit',
      overridePlatformDefaultLocation: true,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('首页')),
        ),
        GoRoute(
          path: '/edit',
          onExit: (_, _) => DraftExitGuard.confirmExit(),
          builder: (context, _) => DraftExitGuard(
            dirty: true,
            onDiscard: () => discarded = true,
            child: Scaffold(
              body: TextButton(
                onPressed: () => context.go('/'),
                child: const Text('离开'),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('离开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(discarded, isFalse);
    expect(find.text('离开'), findsOneWidget);
    await tester.tap(find.text('离开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃修改'));
    await tester.pumpAndSettle();
    expect(discarded, isTrue);
    expect(find.text('首页'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });

  testWidgets(
    'desktop navigation preserves the mounted home state when resized',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();
      final home = tester.state(find.byType(HomePage));
      expect(find.byType(NavigationRail), findsNothing);
      tester.view.physicalSize = const Size(1366, 900);
      await tester.pumpAndSettle();
      expect(find.byType(WebWorkspace), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.state(find.byType(HomePage)), same(home));
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(HomePage)), same(home));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('auth switches to two columns without losing typed email', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(home: WebAuthLayout(child: LoginPage())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WebBrandPanel), findsOneWidget);
    expect(find.text('Sage — Route'), findsOneWidget);
    expect(
      tester.getRect(find.byType(WebBrandPanel)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(TextField).first).top),
    );
    await tester.enterText(find.byType(TextField).first, 'layout@example.com');
    tester.view.physicalSize = const Size(1366, 900);
    await tester.pumpAndSettle();
    expect(find.byType(WebBrandPanel), findsOneWidget);
    expect(find.text('layout@example.com'), findsOneWidget);
    expect(
      tester.getRect(find.byType(WebBrandPanel)).right,
      lessThan(tester.getRect(find.byType(TextField).first).left),
    );
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField).last);
    await tester.pumpAndSettle();
    expect(find.text('layout@example.com'), findsOneWidget);
    expect(find.text('Sage — Route'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('welcome uses a landscape and working browser CTAs', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var started = false;
    var loggedIn = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WebWelcomePage(
          onStart: () => started = true,
          onLogin: () => loggedIn = true,
        ),
      ),
    );
    await tester.tap(find.text('开启旅程  →'));
    await tester.tap(find.text('登录'));
    expect(started && loggedIn, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'mobile welcome uses the same supplied artwork with readable separate actions',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: WebWelcomePage(onStart: () {}, onLogin: () {}),
        ),
      );
      await tester.pumpAndSettle();
      final artwork = tester.widget<Image>(find.byType(Image));
      expect(artwork.image, isA<AssetImage>());
      expect(
        (artwork.image as AssetImage).assetName,
        'assets/images/auth/landscape.png',
      );
      final copy = tester.getRect(find.text('山水之间\n与历史同行'));
      final action = tester.getRect(find.text('让故事成为旅程'));
      expect(copy.bottom, lessThan(action.top));
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('开启旅程  →'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('planner stays inside the browser shell and dates stay compact', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(initialIndex: 2, workspaceChild: CreateRouteWizard()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WebWorkspace), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.byType(Step1Figure), findsOneWidget);
    expect(find.text('苏轼'), findsOneWidget);
    expect(find.byKey(const ValueKey('web-date-popover')), findsNothing);
    expect(
      tester.getRect(find.byKey(const ValueKey('route-title-field'))).right,
      lessThan(tester.getRect(find.byType(Step1Figure)).left),
    );
    await tester.tap(find.byKey(const ValueKey('web-date-field')));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(find.text('${now.year}年 ${now.month}月'), findsOneWidget);
    final rect = tester.getRect(find.byKey(const ValueKey('web-date-popover')));
    expect(rect.width, 320);
    expect(rect.height, lessThan(480));
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('确定日期'));
    await tester.pumpAndSettle();
    final month = '${now.year}.${now.month.toString().padLeft(2, '0')}';
    expect(find.text('$month.03 - $month.05'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('browser dates cross the year and survive restoring the draft', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await GuestSession.enter();
    addTearDown(GuestSession.leave);
    await tester.pumpWidget(const MaterialApp(home: CreateRouteWizard()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-date-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-choose-month')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('calendar-year-field')),
      '2028',
    );
    await tester.tap(find.byKey(const ValueKey('calendar-month-12')));
    await tester.tap(find.text('确定年月'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-day-2028-12-31')));
    await tester.tap(find.byTooltip('下个月'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-day-2029-1-2')));
    await tester.tap(find.text('确定日期'));
    await tester.pumpAndSettle();
    expect(find.text('2028.12.31 - 2029.01.02'), findsOneWidget);
    expect(find.text('3天2晚'), findsOneWidget);
    const draft = RouteDraftStorage(
      userId: GuestSession.draftUserId,
      draftId: 'new',
    );
    expect(draft.load()?['startDate'], startsWith('2028-12-31'));
    expect(draft.load()?['endDate'], startsWith('2029-01-02'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: CreateRouteWizard()));
    await tester.pumpAndSettle();
    expect(find.text('2028.12.31 - 2029.01.02'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('web-date-field')));
    await tester.pumpAndSettle();
    expect(find.text('2028年 12月'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('old fixed-month drafts preserve their original dates', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await GuestSession.enter();
    addTearDown(GuestSession.leave);
    const draft = RouteDraftStorage(
      userId: GuestSession.draftUserId,
      draftId: 'new',
    );
    draft.save({'title': '旧行程', 'startDay': 28, 'endDay': 30});
    await tester.pumpWidget(const MaterialApp(home: CreateRouteWizard()));
    await tester.pumpAndSettle();
    expect(find.text('2026.06.28 - 2026.06.30'), findsOneWidget);
    expect(find.text('3天2晚'), findsOneWidget);
    expect(draft.load()?['startDate'], startsWith('2026-06-28'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'route preview and editing reserve toolbar space above the desktop itinerary',
    (tester) async {
      final registry = _TestHtmlViewRegistry(tester);
      ui_web.debugOverridePlatformViewRegistry(registry);
      addTearDown(() => ui_web.debugOverridePlatformViewRegistry(null));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const route = SavedRoute(
        id: 'test-route',
        title: '跟着东坡游西湖',
        dateRange: '',
        duration: '一天',
        distance: '2km',
        waypoints: [
          RouteWaypoint(name: '苏堤', latitude: 30.25, longitude: 120.14),
          RouteWaypoint(name: '虎跑泉', latitude: 30.21, longitude: 120.13),
        ],
      );
      for (final width in [1024.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 900);
        for (final edit in [false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey('$width-$edit'),
              home: WebWorkspace(
                selectedIndex: 2,
                onSelected: (_) {},
                child: edit
                    ? const RouteEditPage(route: route)
                    : RoutePreviewPage(
                        routeId: route.id,
                        initialRoute: route,
                        repository: const _PreviewRouteRepository(route),
                      ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final toolbar = tester.getRect(
            find.byKey(
              ValueKey(edit ? 'route-edit-toolbar' : 'route-preview-toolbar'),
            ),
          );
          final itinerary = tester.getRect(find.byType(Step3Map));
          expect(toolbar.bottom, lessThanOrEqualTo(itinerary.top));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
  testWidgets(
    'narrow desktop profile keeps achievements and preferences visible',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 768);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        const MaterialApp(home: MainScreen(initialIndex: 4)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WebWorkspace), findsOneWidget);
      expect(find.text('偏好设置'), findsOneWidget);
      expect(find.byType(Wrap), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _PreviewRouteRepository extends UserRouteRepository {
  const _PreviewRouteRepository(this.route);
  final SavedRoute route;
  @override
  Future<SavedRoute?> fetchRouteById(String routeId) async => route;
}

/// Flutter's widget binding mocks platform channels; this fixture creates real
/// DOM elements while keeping the SDK bridge deterministic and network-free.
class _TestHtmlViewRegistry implements ui_web.PlatformViewRegistry {
  _TestHtmlViewRegistry(WidgetTester tester) {
    for (final type in [
      ui_web.PlatformViewRegistry.defaultVisibleViewType,
      ui_web.PlatformViewRegistry.defaultInvisibleViewType,
    ]) {
      registerViewFactory(
        type,
        (int id, {Object? params}) =>
            web.document.createElement((params as Map)['tagName'] as String),
      );
    }
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async {
        if (call.method == 'create') {
          final args = call.arguments as Map;
          final factory =
              _factories[args['viewType']]!
                  as ui_web.ParameterizedPlatformViewFactory;
          _views[args['id'] as int] = factory(
            args['id'] as int,
            params: args['params'],
          );
        } else if (call.method == 'dispose') {
          _views.remove(call.arguments);
        }
        return null;
      },
    );
  }
  final Map<String, Function> _factories = {};
  final Map<int, Object> _views = {};
  @override
  bool registerViewFactory(
    String viewType,
    Function viewFactory, {
    bool isVisible = true,
  }) {
    if (_factories.containsKey(viewType)) return false;
    _factories[viewType] = viewFactory;
    return true;
  }

  @override
  Object getViewById(int viewId) => _views[viewId]!;
}
