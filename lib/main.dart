import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'onboarding_screen.dart';
import 'pages/settings_page.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 启动时先初始化 Supabase，确保后续页面可以直接请求数据库。
  await DatabaseService.initialize();
  runApp(const SageRouteApp());
}

class SageRouteApp extends StatelessWidget {
  const SageRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
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
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _bodyForIndex(int index) {
    switch (index) {
      case 1:
        return const Center(
          child: Text(
            '导览',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      case 2:
        return const SettingsPage();
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
