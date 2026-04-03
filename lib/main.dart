import 'dart:convert';

import 'package:amap_map/amap_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_amap_base/x_amap_base.dart';

import 'theme.dart';
import 'onboarding_screen.dart';
import 'pages/celebrity_selection_page.dart';
import 'pages/guide_page.dart';
import 'pages/settings_page.dart';
import 'services/database_service.dart';

/// 高德地图 Android Key，通过 --dart-define 或 --dart-define-from-file 注入。
const String _amapAndroidKeyFromDefine = String.fromEnvironment(
  'AMAP_ANDROID_KEY',
);

class _ResolvedAmapKey {
  final String key;
  final String source;

  const _ResolvedAmapKey({required this.key, required this.source});
}

Future<_ResolvedAmapKey> _resolveAmapKey() async {
  final defineKey = _amapAndroidKeyFromDefine.trim();
  if (defineKey.isNotEmpty) {
    return _ResolvedAmapKey(key: defineKey, source: 'dart-define');
  }

  final dotenvKey = (dotenv.env['AMAP_ANDROID_KEY'] ?? '').trim();
  if (dotenvKey.isNotEmpty) {
    return _ResolvedAmapKey(key: dotenvKey, source: 'assets/env.env');
  }

  try {
    final raw = await rootBundle.loadString('dart_define.json');
    final parsed = jsonDecode(raw);
    if (parsed is Map<String, dynamic>) {
      final fileKey = (parsed['AMAP_ANDROID_KEY'] ?? '').toString().trim();
      if (fileKey.isNotEmpty) {
        return _ResolvedAmapKey(key: fileKey, source: 'asset:dart_define.json');
      }
    }
  } catch (_) {
    // ignore: fallback chain continues
  }

  return const _ResolvedAmapKey(key: '', source: 'missing');
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
  final _ResolvedAmapKey resolvedAmapKey;

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
      themeMode: ThemeMode.system,
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

        return const OnboardingScreen();
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
  static const Duration _guideSwitchDelay = Duration(milliseconds: 120);

  int _selectedIndex = 0;
  bool _showCelebrityOverlay = false;

  void _onItemTapped(int index) {
    if (_showCelebrityOverlay) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openCelebrityOverlay() {
    setState(() {
      _showCelebrityOverlay = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(_guideSwitchDelay, () {
        if (!mounted || !_showCelebrityOverlay || _selectedIndex == 1) {
          return;
        }
        setState(() {
          _selectedIndex = 1;
        });
      });
    });
  }

  void _closeCelebrityOverlay() {
    if (!_showCelebrityOverlay) {
      return;
    }
    setState(() {
      _showCelebrityOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('SageRoute'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          body: _bodyForIndex(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
              BottomNavigationBarItem(icon: Icon(Icons.explore), label: '导览'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
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

  Widget _bodyForIndex(int index) {
    switch (index) {
      case 1:
        return const GuidePage();
      case 2:
        return SettingsPage(onSwitchCelebrity: _openCelebrityOverlay);
      default:
        return const Center(
          child: Text(
            '首页',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
    }
  }
}
