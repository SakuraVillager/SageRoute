import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/map_initialization.dart';
import 'navigation/web_app.dart';
import 'navigation/app_navigation.dart';
import 'navigation/platform_url.dart';
import 'components/adaptive_content.dart';
import 'components/web/web_workspace.dart';

import 'theme.dart';
import 'components/bottom_nav.dart';
import 'data/user_route_repository.dart';
import 'models/saved_route.dart';
import 'pages/celebrity_selection/celebrity_selection_page.dart';
import 'views/landing_page.dart';
import 'views/home_page.dart';
import 'views/figures_list_page.dart';
import 'views/create_route_wizard/create_route_wizard.dart';
import 'views/discovery/discovery_page.dart';
import 'views/profile_page.dart';
import 'services/database_service.dart';
import 'services/guest_session.dart';
import 'services/native_share_links.dart';
import 'services/route_changes.dart';
import 'auth/auth_gate.dart';
import 'auth/login_page.dart';

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
  configureUrlStrategy();
  debugPrint('[SageRoute] app starting...');

  // 高德 SDK 隐私合规声明需在调用任何地图接口前设置。
  prepareMapPrivacy();

  // 不要在此处 await 任何耗时操作——先渲染 UI，再异步初始化。
  // 调试模式下 JIT + 网络初始化若阻塞 runApp，会触发 Android ANR。
  runApp(const SageRouteApp());
  debugPrint('[SageRoute] runApp called, first frame should appear shortly');
}

class SageRouteApp extends StatefulWidget {
  const SageRouteApp({super.key});

  @override
  State<SageRouteApp> createState() => _SageRouteAppState();
}

class _SageRouteAppState extends State<SageRouteApp> {
  late final Future<ResolvedAmapKey> _initFuture;
  bool _amapInitialized = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  NativeShareLinks? _shareLinks;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
    if (!kIsWeb) {
      _shareLinks = NativeShareLinks(_navigatorKey)..start(_initFuture);
    }
  }

  @override
  void dispose() {
    _shareLinks?.dispose();
    super.dispose();
  }

  Future<ResolvedAmapKey> _initialize() async {
    debugPrint('[SageRoute] initializing DatabaseService...');
    try {
      await DatabaseService.initialize();
      debugPrint('[SageRoute] DatabaseService initialized');
    } catch (e) {
      debugPrint('[SageRoute] DatabaseService init failed: $e');
      rethrow;
    }
    await GuestSession.restore();
    final restoredUser = DatabaseService.client.auth.currentUser;
    if (restoredUser != null) {
      await GuestSession.completeSignIn(restoredUser.id);
    }
    if (kIsWeb) return const ResolvedAmapKey(key: '', source: 'web');
    final key = await _resolveAmapKey();
    debugPrint(
      '[SageRoute] AMap key resolved (source=${key.source}, length=${key.key.length})',
    );
    return key;
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
      initializeNativeMap(context, key.key);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return WebSageRouteApp(initialization: _initFuture);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'SageRoute',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routes: {
        '/main': (context) =>
            AuthGate(authenticatedBuilder: (_) => const MainScreen()),
      },
      home: FutureBuilder<ResolvedAmapKey>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            debugPrint('[SageRoute] init error: ${snapshot.error}');
            // 初始化失败也继续进入应用，不阻塞用户
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('初始化失败：${snapshot.error}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            });
            return const AppLaunchDecider();
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
    debugPrint('[SageRoute] checking onboarding status...');
    final preferences = await SharedPreferences.getInstance();
    final hasSeen = preferences.getBool('hasSeenOnboarding') ?? false;
    debugPrint('[SageRoute] onboarding status: hasSeen=$hasSeen');
    return hasSeen;
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

        if (snapshot.hasError) {
          debugPrint('[SageRoute] onboarding check error: ${snapshot.error}');
          // 读取失败时直接进入鉴权入口，避免卡在加载页
          return AuthGate(authenticatedBuilder: (_) => const MainScreen());
        }

        final hasSeenOnboarding = snapshot.data ?? false;
        // Authentication takes precedence over onboarding. A restored local
        // session should always enter the app without asking the user to log in
        // or tap through the landing page again.
        if (DatabaseService.client.auth.currentSession != null ||
            GuestSession.isActive) {
          debugPrint('[SageRoute] restored persisted auth session');
          return AuthGate(authenticatedBuilder: (_) => const MainScreen());
        }
        if (hasSeenOnboarding) {
          debugPrint(
            '[SageRoute] navigating to AuthGate -> MainScreen or Login',
          );
          return AuthGate(authenticatedBuilder: (_) => const MainScreen());
        }

        debugPrint('[SageRoute] showing LandingPage');
        return LandingPage(
          onStartJourney: () async {
            final preferences = await SharedPreferences.getInstance();
            await preferences.setBool('hasSeenOnboarding', true);
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    AuthGate(authenticatedBuilder: (_) => const MainScreen()),
              ),
            );
          },
          onLogin: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.onTabSelected,
    this.workspaceChild,
  });
  final Widget? workspaceChild;
  final int initialIndex;
  final ValueChanged<int>? onTabSelected;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final _contentKey = GlobalKey();
  int _selectedIndex = 0;
  bool _showCelebrityOverlay = false;
  final _savedRoutes = ValueNotifier<List<SavedRoute>>(const <SavedRoute>[]);
  final Set<String> _deletedRouteIds = <String>{};
  int _syncRequestId = 0;

  static const _routeRepository = UserRouteRepository();

  // 惰性 tab 构建：只有访问过的 tab 才会被构建，避免首次进入时
  // IndexedStack 同时构建全部 4 个页面导致主线程过载 (ANR)。
  // 索引: 0=首页, 1=人物, 2=收藏, 3=我的；Web 规划位于工作区子路由。
  late final List<Widget> _tabs;
  final Set<int> _builtTabs = {0}; // 首页立即构建

  /// 底部导航栏 index → _tabs index 的映射。
  /// 规划（navIndex=2）在 Android push 页面，在 Web 切换工作区子路由。
  static const _navToTab = {0: 0, 1: 1, 3: 2, 4: 3};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    routeListChanges.addListener(_loadSavedRoutes);
    _selectedIndex = widget.initialIndex;
    _builtTabs.add(_navToTab[_selectedIndex] ?? 0);
    _tabs = [
      HomePage(
        createdRoutesListenable: _savedRoutes,
        onRefreshRoutes: _loadSavedRoutes,
        onDeleteRoute: _deleteSavedRoute,
      ),
      const FiguresListPage(),
      DiscoveryPage(onRouteCreated: _loadSavedRoutes),
      ProfilePage(onDebugRouteTap: _pushCreateRouteWizard),
    ];
    _loadSavedRoutes();
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceChild != null && widget.workspaceChild == null) {
      _loadSavedRoutes();
    }
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = widget.initialIndex;
      _builtTabs.add(_navToTab[_selectedIndex] ?? 0);
    }
  }

  /// 从 Supabase 拉取当前用户的路线（新→旧）。
  Future<void> _loadSavedRoutes() async {
    final requestId = ++_syncRequestId;
    if (DatabaseService.client.auth.currentUser == null) {
      _savedRoutes.value = const [];
      return;
    }
    final idsAtStart = _savedRoutes.value.map((route) => route.id).toSet();
    try {
      final routes = (await _routeRepository.fetchUserRoutes())
          .where((route) => !_deletedRouteIds.contains(route.id))
          .toList(growable: false);
      if (!mounted || requestId != _syncRequestId) return;
      final remoteIds = routes.map((route) => route.id).toSet();
      final localOnly = _savedRoutes.value.where(
        (route) =>
            !idsAtStart.contains(route.id) && !remoteIds.contains(route.id),
      );
      _savedRoutes.value = [...localOnly, ...routes];
    } catch (error, stackTrace) {
      developer.log(
        'Failed to sync saved routes on app start',
        name: 'SageRoute.MainScreen',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted || requestId != _syncRequestId) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('历史行程同步失败，可在首页下拉重试'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              SageRouteBottomNav.barHeight +
                  MediaQuery.paddingOf(context).bottom +
                  12,
            ),
          ),
        );
    }
  }

  Future<void> _deleteSavedRoute(String routeId) async {
    await _routeRepository.deleteRoute(routeId);
    if (!mounted) return;
    _deletedRouteIds.add(routeId);
    _savedRoutes.value = _savedRoutes.value
        .where((route) => route.id != routeId)
        .toList(growable: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeListChanges.removeListener(_loadSavedRoutes);
    _savedRoutes.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _selectedIndex == 0) {
      _loadSavedRoutes();
    }
  }

  Future<void> _pushCreateRouteWizard() async {
    final saved = await openAppPage<SavedRoute>(
      context,
      const CreateRouteWizard(),
    );
    if (saved == null || !mounted) return;
    widget.onTabSelected?.call(0);
    if (saved.id.isNotEmpty) {
      _savedRoutes.value = [saved, ..._savedRoutes.value];
    } else {
      // 路线 id 未回传时兜底：重新拉取列表。
      await _loadSavedRoutes();
    }
    setState(() {
      _selectedIndex = 0;
      _builtTabs.add(0);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('行程已保存'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            SageRouteBottomNav.barHeight +
                MediaQuery.paddingOf(context).bottom +
                12,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _onItemTapped(int navIndex) {
    if (_showCelebrityOverlay) return;
    if (navIndex == 2 && (!kIsWeb || widget.onTabSelected == null)) {
      _pushCreateRouteWizard();
      return;
    }
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(navIndex);
      return;
    }
    final tabIndex = _navToTab[navIndex]!;
    if (tabIndex == 0) _loadSavedRoutes();
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
    final desktop = kIsWeb && MediaQuery.sizeOf(context).width >= 1024;
    final content = KeyedSubtree(
      key: _contentKey,
      child: Stack(
        children: [
          Scaffold(
            extendBody: true,
            body: Stack(
              fit: StackFit.expand,
              children: List.generate(_tabs.length, (index) {
                if (!_builtTabs.contains(index)) {
                  return const SizedBox.shrink();
                }
                final tabIndex = _navToTab[_selectedIndex] ?? 0;
                return Offstage(
                  offstage: widget.workspaceChild != null || tabIndex != index,
                  child: TickerMode(
                    enabled: widget.workspaceChild == null && tabIndex == index,
                    child: AdaptiveContent(child: _tabs[index]),
                  ),
                );
              }),
            ),
          ),
          if (widget.workspaceChild != null)
            Positioned.fill(child: widget.workspaceChild!),
          if (!desktop && widget.workspaceChild == null)
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
      ),
    );
    if (!desktop) return content;
    return WebWorkspace(
      selectedIndex: _selectedIndex,
      onSelected: _onItemTapped,
      child: content,
    );
  }
}
