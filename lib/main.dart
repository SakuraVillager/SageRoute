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

  // 启动时先初始化 Supabase，确保后续页面可以直接请求数据库。
  await DatabaseService.initialize();
  final resolvedAmapKey = await _resolveAmapKey();
  runApp(SageRouteApp(resolvedAmapKey: resolvedAmapKey));
}

class SageRouteApp extends StatelessWidget {
  final ResolvedAmapKey resolvedAmapKey;

  const SageRouteApp({required this.resolvedAmapKey, super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint(
      resolvedAmapKey.key.isEmpty
          ? 'AMap Android Key 未注入：请使用 --dart-define，或在 assets/env.env / dart_define.json 配置 AMAP_ANDROID_KEY。'
          : 'AMap Android Key 已注入，来源=${resolvedAmapKey.source}，长度=${resolvedAmapKey.key.length}',
    );

    AMapInitializer.init(
      context,
      apiKey: resolvedAmapKey.key.isEmpty
          ? null
          : AMapApiKey(androidKey: resolvedAmapKey.key),
    );

    return MaterialApp(
      title: 'SageRoute',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routes: {'/main': (context) => const MainScreen()},
      home: const AppLaunchDecider(),
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
  bool _hideBottomNav = false;
  bool _showCelebrityOverlay = false;

  void _onItemTapped(int index) {
    if (_showCelebrityOverlay) return;
    setState(() {
      _selectedIndex = index;
      _hideBottomNav = index == 2;
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

  void _setBottomNavVisible(bool visible) {
    setState(() => _hideBottomNav = !visible);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Body — always full-screen; nav bar is an overlay, not inside Scaffold.
        Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              const HomePage(),
              FiguresListPage(
                onNavigateAway: () => _setBottomNavVisible(false),
                onNavigateBack: () => _setBottomNavVisible(true),
              ),
              CreateRouteWizard(
                onExit: () => setState(() {
                  _selectedIndex = 0;
                  _hideBottomNav = false;
                }),
              ),
              const SavedRoutesPage(),
              const ProfilePage(),
            ],
          ),
        ),
        // Bottom nav — overlaid on top so it can slide away without reserving layout space.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSlide(
            offset: _hideBottomNav ? const Offset(0, 1) : Offset.zero,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            child: SageRouteBottomNav(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
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
