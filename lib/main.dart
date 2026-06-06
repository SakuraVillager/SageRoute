import 'dart:convert';

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_amap_base/x_amap_base.dart';

import 'theme.dart';
import 'components/bottom_nav.dart';
import 'pages/celebrity_selection/celebrity_selection_page.dart';
import 'views/landing_page.dart';
import 'views/home_page.dart';
import 'views/figures_list_page.dart';
import 'views/create_route_wizard/create_route_wizard.dart';
import 'views/saved_routes_page.dart';
import 'views/profile_page.dart';
import 'services/database_service.dart';
import 'utils/slide_route.dart';

/// 高德地图 Android Key，通过 --dart-define 或 --dart-define-from-file 注入。
const String _amapAndroidKeyFromDefine = String.fromEnvironment(
  'AMAP_ANDROID_KEY',
);

class ResolvedAmapKey {
  final String key;
  final String source;

  const ResolvedAmapKey({required this.key, required this.source});
}

Future<ResolvedAmapKey> _resolveAmapKey() async {
  final defineKey = _amapAndroidKeyFromDefine.trim();
  if (defineKey.isNotEmpty) {
    return ResolvedAmapKey(key: defineKey, source: 'dart-define');
  }

  final dotenvKey = (dotenv.env['AMAP_ANDROID_KEY'] ?? '').trim();
  if (dotenvKey.isNotEmpty) {
    return ResolvedAmapKey(key: dotenvKey, source: 'assets/env.env');
  }

  try {
    final raw = await rootBundle.loadString('dart_define.json');
    final parsed = jsonDecode(raw);
    if (parsed is Map<String, dynamic>) {
      final fileKey = (parsed['AMAP_ANDROID_KEY'] ?? '').toString().trim();
      if (fileKey.isNotEmpty) {
        return ResolvedAmapKey(key: fileKey, source: 'asset:dart_define.json');
      }
    }
  } catch (_) {
    // ignore: fallback chain continues
  }

  return const ResolvedAmapKey(key: '', source: 'missing');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 高德 SDK 隐私合规声明需在调用任何地图接口前设置。
  AMapInitializer.updatePrivacyAgree(
    const AMapPrivacyStatement(
      hasContains: true,
      hasShow: true,
      hasAgree: true,
    ),
  );

  // 不要在此处 await 任何耗时操作——先渲染 UI，再异步初始化。
  // 调试模式下 JIT + 网络初始化若阻塞 runApp，会触发 Android ANR。
  runApp(const SageRouteApp());
}

class SageRouteApp extends StatefulWidget {
  const SageRouteApp({super.key});

  @override
  State<SageRouteApp> createState() => _SageRouteAppState();
}

class _SageRouteAppState extends State<SageRouteApp> {
  late final Future<ResolvedAmapKey> _initFuture;
  bool _amapInitialized = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<ResolvedAmapKey> _initialize() async {
    await DatabaseService.initialize();
    return _resolveAmapKey();
  }

  void _onInitDone(ResolvedAmapKey key) {
    if (_amapInitialized) return;
    _amapInitialized = true;
    debugPrint(
      key.key.isEmpty
          ? 'AMap Android Key 未注入：请使用 --dart-define，或在 assets/env.env / dart_define.json 配置 AMAP_ANDROID_KEY。'
          : 'AMap Android Key 已注入，来源=${key.source}，长度=${key.key.length}',
    );
    // 延迟到首帧之后再初始化 AMap，避免在 build 阶段做原生调用。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AMapInitializer.init(
        context,
        apiKey: key.key.isEmpty
            ? null
            : AMapApiKey(androidKey: key.key),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SageRoute',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routes: {'/main': (context) => const MainScreen()},
      home: FutureBuilder<ResolvedAmapKey>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            _onInitDone(snapshot.data!);
          }

          return const AppLaunchDecider();
        },
      ),
    );
  }
}

class AppLaunchDecider extends StatefulWidget {
  const AppLaunchDecider({super.key});

  @override
  State<AppLaunchDecider> createState() => _AppLaunchDeciderState();
}

class _AppLaunchDeciderState extends State<AppLaunchDecider> {
  late final Future<bool> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _hasSeenOnboarding();
  }

  Future<bool> _hasSeenOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('hasSeenOnboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final hasSeenOnboarding = snapshot.data ?? false;
        if (hasSeenOnboarding) {
          return const MainScreen();
        }

        return LandingPage(
          onStartJourney: () async {
            final preferences = await SharedPreferences.getInstance();
            await preferences.setBool('hasSeenOnboarding', true);
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _showCelebrityOverlay = false;

  // 惰性 tab 构建：只有访问过的 tab 才会被构建，避免首次进入时
  // IndexedStack 同时构建全部 4 个页面导致主线程过载 (ANR)。
  // 索引: 0=首页, 1=人物, 2=收藏, 3=我的（规划通过 push 独立页面进入）
  late final List<Widget> _tabs;
  final Set<int> _builtTabs = {0}; // 首页立即构建

  /// 底部导航栏 index → _tabs index 的映射。
  /// 导航栏中间的"规划"按钮（navIndex=2）不对应 tab，而是 push 新页面。
  static const _navToTab = {0: 0, 1: 1, 3: 2, 4: 3};

  @override
  void initState() {
    super.initState();
    _tabs = [
      const HomePage(),
      const FiguresListPage(),
      const SavedRoutesPage(),
      ProfilePage(onDebugRouteTap: _pushCreateRouteWizard),
    ];
  }

  void _pushCreateRouteWizard() {
    Navigator.of(context).push(
      slideFromRightRoute(
        CreateRouteWizard(
          onExit: () => Navigator.of(context).pop(),
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _onItemTapped(int navIndex) {
    if (_showCelebrityOverlay) return;
    // "规划"按钮暂时不做任何事情
    if (navIndex == 2) return;
    final tabIndex = _navToTab[navIndex]!;
    setState(() {
      _selectedIndex = navIndex;
      _builtTabs.add(tabIndex);
    });
  }

  // ignore: unused_element — kept for future CelebritySelection overlay access.
  void _openCelebrityOverlay() {
    setState(() => _showCelebrityOverlay = true);
  }

  void _closeCelebrityOverlay() {
    if (!_showCelebrityOverlay) return;
    setState(() => _showCelebrityOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Body — always full-screen; nav bar is an overlay, not inside Scaffold.
        Scaffold(
          extendBody: true,
          body: Stack(
            fit: StackFit.expand,
            children: List.generate(_tabs.length, (index) {
              // 只有访问过的 tab 才构建，其余用空 Container 占位。
              if (!_builtTabs.contains(index)) {
                return const SizedBox.shrink();
              }
              final tabIndex = _navToTab[_selectedIndex] ?? 0;
              return Offstage(
                offstage: tabIndex != index,
                child: _tabs[index],
              );
            }),
          ),
        ),
        // Bottom nav — 始终显示。
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SageRouteBottomNav(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ),
        if (_showCelebrityOverlay)
          Positioned.fill(
            child: CelebritySelectionPage(
              onContinue: _closeCelebrityOverlay,
              onSkip: _closeCelebrityOverlay,
            ),
          ),
      ],
    );
  }
}
