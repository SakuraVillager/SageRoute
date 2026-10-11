import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsHandle;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../auth/forgot_password_page.dart';
import '../auth/reset_password_page.dart';
import '../components/adaptive_content.dart';
import '../components/web/web_auth_layout.dart';
import '../views/web_welcome_page.dart';
import '../components/draft_exit_guard.dart';
import '../data/article_repository.dart';
import '../data/celebrity_repository.dart';
import '../data/location_repository.dart';
import '../data/user_route_repository.dart';
import '../data/mock_figures.dart';
import '../data/mock_locations.dart';
import '../main.dart' show MainScreen;
import '../models/figure.dart';
import '../models/location.dart';
import '../pages/settings_page.dart';
import '../pages/account_info_page.dart';
import '../pages/travel_preferences_page.dart';
import '../pages/language_page.dart';
import '../services/database_service.dart';
import '../services/browser_session.dart';
import '../services/auth_service.dart';
import '../services/credential_storage.dart';
import '../theme.dart';
import '../theme/web_theme.dart';
import '../views/article_detail_page.dart';
import '../views/landing_page.dart';
import '../views/figure_detail_page.dart';
import '../views/location_detail_page.dart';
import '../views/create_route_wizard/create_route_wizard.dart';
import '../views/route_preview/route_preview_page.dart';
import '../views/route_preview/route_edit_page.dart';
import 'app_navigation.dart';
import 'map_overlay_observer.dart';

const _tabs = {'/home': 0, '/figures': 1, '/saved': 3, '/profile': 4};

class WebSageRouteApp extends StatefulWidget {
  const WebSageRouteApp({
    super.key,
    required this.initialization,
    this.initialLocation,
  });
  final Future<Object?> initialization;
  final String? initialLocation;
  @override
  State<WebSageRouteApp> createState() => _WebSageRouteAppState();
}

class _WebSageRouteAppState extends State<WebSageRouteApp> {
  GoRouter? _router;
  final _authRefresh = ValueNotifier<int>(0);
  StreamSubscription<dynamic>? _auth;
  Object? _error;
  bool _hasSeenOnboarding = false;
  final _rootMapObserver = MapOverlayObserver();
  final _shellMapObserver = MapOverlayObserver();
  late final SemanticsHandle _semantics;

  @override
  void initState() {
    super.initState();
    GoRouter.optionURLReflectsImperativeAPIs = true;
    _semantics = WidgetsBinding.instance.ensureSemantics();
    widget.initialization.then(
      (_) async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(CredentialStorage.passwordKey);
        if (!mounted) return;
        _hasSeenOnboarding = preferences.getBool('hasSeenOnboarding') ?? false;
        _router = _createRouter();
        _auth = DatabaseService.client.auth.onAuthStateChange.listen((_) {
          _authRefresh.value++;
        }, onError: (Object _) {});
        setState(() {});
      },
      onError: (Object error) {
        if (mounted) setState(() => _error = error);
      },
    );
  }

  GoRouter _createRouter() => GoRouter(
    initialLocation:
        widget.initialLocation ??
        Uri(
          path: Uri.base.path,
          query: Uri.base.hasQuery ? Uri.base.query : null,
        ).toString(),
    overridePlatformDefaultLocation: true,
    observers: [_rootMapObserver],
    refreshListenable: _authRefresh,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/auth/callback') return null;
      if (path == '/') {
        if (DatabaseService.client.auth.currentSession != null) return '/home';
        return _hasSeenOnboarding ? '/login' : '/welcome';
      }
      final public = [
        '/welcome',
        '/login',
        '/register',
        '/forgot-password',
      ].contains(path);
      if (DatabaseService.client.auth.currentSession == null && !public) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      return null;
    },
    errorBuilder: (context, state) => const _UnavailablePage(message: '页面不存在'),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(
        path: '/welcome',
        builder: (context, _) {
          Future<void> begin(String path) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('hasSeenOnboarding', true);
            _hasSeenOnboarding = true;
            if (context.mounted) context.go(path);
          }

          return LayoutBuilder(
            builder: (_, constraints) => constraints.maxWidth >= 900
                ? WebWelcomePage(
                    onStart: () => begin('/register'),
                    onLogin: () => begin('/login'),
                  )
                : LandingPage(
                    onStartJourney: () => begin('/register'),
                    onLogin: () => begin('/login'),
                  ),
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const WebAuthLayout(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const WebAuthLayout(child: RegisterPage()),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const WebAuthLayout(child: ForgotPasswordPage()),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (_, _) => const _AuthCallbackPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, _) => const WebAuthLayout(child: ResetPasswordPage()),
      ),
      ShellRoute(
        observers: [_shellMapObserver],
        builder: (context, state, child) => MainScreen(
          key: const ValueKey('web-main-screen'),
          initialIndex:
              _tabs[state.uri.path] ??
              (state.uri.path.startsWith('/routes')
                  ? 2
                  : state.uri.path.startsWith('/settings')
                  ? 4
                  : 1),
          workspaceChild: _tabs.containsKey(state.uri.path) ? null : child,
          onTabSelected: (index) => context.go(
            index == 2
                ? '/routes/new'
                : _tabs.entries.firstWhere((e) => e.value == index).key,
          ),
        ),
        routes: [
          for (final path in _tabs.keys)
            GoRoute(path: path, builder: (_, _) => const SizedBox.shrink()),
          GoRoute(
            path: '/settings',
            builder: (_, _) =>
                const AdaptiveContent(maxWidth: 800, child: SettingsPage()),
          ),
          GoRoute(
            path: '/settings/account',
            builder: (_, state) => AdaptiveContent(
              maxWidth: 800,
              child: state.extra is AccountInfoPage
                  ? state.extra! as AccountInfoPage
                  : AccountInfoPage(
                      email:
                          DatabaseService.client.auth.currentUser?.email ?? '',
                      initialNickname:
                          DatabaseService
                                  .client
                                  .auth
                                  .currentUser
                                  ?.userMetadata?['nickname']
                              as String? ??
                          '',
                    ),
            ),
          ),
          GoRoute(
            path: '/settings/travel',
            builder: (_, _) => const AdaptiveContent(
              maxWidth: 800,
              child: TravelPreferencesPage(),
            ),
          ),
          GoRoute(
            path: '/settings/language',
            builder: (_, _) =>
                const AdaptiveContent(maxWidth: 800, child: LanguagePage()),
          ),
          GoRoute(
            path: '/routes/new',
            onExit: (_, _) => DraftExitGuard.confirmExit(),
            builder: (_, _) => const CreateRouteWizard(),
          ),
          GoRoute(
            path: '/routes/:id/edit',
            onExit: (_, _) => DraftExitGuard.confirmExit(),
            builder: (_, state) => _RecordPage(
              load: () async {
                final route = await const UserRouteRepository().fetchRouteById(
                  state.pathParameters['id']!,
                );
                return route == null ? null : RouteEditPage(route: route);
              },
            ),
          ),
          GoRoute(
            path: '/routes/:id',
            builder: (_, state) =>
                RoutePreviewPage(routeId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/figures/:id',
            builder: (_, state) => _RecordPage(
              maxWidth: 1200,
              load: () async {
                final id = state.pathParameters['id']!;
                final numeric = int.tryParse(id);
                if (numeric == null) {
                  for (final figure in mockFigures) {
                    if (figure.id == id) {
                      return FigureDetailPage(
                        figure: Figure(
                          id: figure.id,
                          name: figure.name,
                          dynasty: figure.dynasty,
                          pinyinName: figure.pinyinName,
                          role: figure.role,
                          years: figure.years,
                          shortDesc: figure.shortDesc,
                          description: figure.description,
                          imageUrl: figure.imageUrl,
                          locationsCount: figure.locationsCount,
                          routesCount: figure.routesCount,
                          poemsCount: figure.poemsCount,
                          rating: figure.rating,
                        ),
                      );
                    }
                  }
                  return null;
                }
                final profile = await const CelebrityRepository().fetchById(
                  numeric,
                );
                if (profile == null) return null;
                return FigureDetailPage(
                  figure: Figure(
                    id: id,
                    name: profile.name,
                    dynasty: profile.dynasty,
                    shortDesc: profile.bioShort,
                    description: profile.bioFull,
                    imageUrl: profile.avatarUrl,
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/locations/:id',
            builder: (_, state) => _RecordPage(
              maxWidth: 1200,
              load: () async {
                final id = state.pathParameters['id']!;
                final numeric = int.tryParse(id);
                if (numeric == null) {
                  for (final location in mockLocations) {
                    if (location.id == id) {
                      return LocationDetailPage(
                        location: Location(
                          id: location.id,
                          name: location.name,
                          figureId: location.figureId,
                          pinyinName: location.pinyinName,
                          region: location.region,
                          years: location.years,
                          tags: location.tags,
                          distance: location.distance,
                          recommendedTime: location.recommendedTime,
                          relatedPoems: location.relatedPoems,
                          rating: location.rating,
                          imageUrl: location.imageUrl,
                          description: location.description,
                        ),
                      );
                    }
                  }
                  return null;
                }
                final location = await const LocationRepository().fetchById(
                  numeric,
                );
                if (location == null) return null;
                return LocationDetailPage(
                  location: Location(
                    id: id,
                    name: location.nameModern,
                    region: location.address ?? '',
                    description: location.description ?? '',
                    tags: location.categories,
                    recommendedTime: location.averageVisitDurationMin == null
                        ? ''
                        : '${location.averageVisitDurationMin}分钟',
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/articles/:id',
            builder: (_, state) => _RecordPage(
              maxWidth: 800,
              load: () async {
                final id = int.tryParse(state.pathParameters['id']!);
                if (id == null) return null;
                final article = await const ArticleRepository().fetchById(id);
                return article == null
                    ? null
                    : ArticleDetailPage(article: article);
              },
            ),
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _auth?.cancel();
    _router?.dispose();
    _rootMapObserver.release();
    _shellMapObserver.release();
    _authRefresh.dispose();
    _semantics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return MaterialApp(
        theme: browserTheme(AppTheme.lightTheme),
        home: Scaffold(
          body: Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '应用初始化失败，请检查公开客户端配置后刷新。\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      );
    }
    return MaterialApp.router(
      title: 'SageRoute',
      theme: browserTheme(AppTheme.lightTheme),
      darkTheme: browserTheme(AppTheme.darkTheme),
      routerConfig: _router,
    );
  }
}

class _RecordPage extends StatefulWidget {
  const _RecordPage({required this.load, this.maxWidth = double.infinity});
  final Future<Widget?> Function() load;
  final double maxWidth;
  @override
  State<_RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<_RecordPage> {
  late Future<Widget?> _future = widget.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<Widget?>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return _UnavailablePage(
          message: '加载失败，请检查网络后重试',
          retry: () => setState(() => _future = widget.load()),
        );
      }
      if (snapshot.data == null) {
        return const _UnavailablePage(message: '内容不存在、已删除或当前账号无权访问');
      }
      return AdaptiveContent(maxWidth: widget.maxWidth, child: snapshot.data!);
    },
  );
}

class _UnavailablePage extends StatelessWidget {
  const _UnavailablePage({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => finishAppPage(context),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('重试')),
        ],
      ),
    ),
  );
}

class _AuthCallbackPage extends StatefulWidget {
  const _AuthCallbackPage();
  @override
  State<_AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<_AuthCallbackPage> {
  String? _error;
  @override
  void initState() {
    super.initState();
    _handle();
  }

  Future<void> _handle() async {
    try {
      final result = await DatabaseService.client.auth.getSessionFromUrl(
        Uri.base,
      );
      await DatabaseService.persistAuthSession(result.session);
      cleanAuthParameters();
      if (!mounted) return;
      context.go(
        result.redirectType == 'recovery' ||
                result.redirectType == 'passwordRecovery'
            ? '/reset-password'
            : '/home',
      );
    } catch (_) {
      cleanAuthParameters();
      if (mounted) setState(() => _error = '验证链接无效或已过期，请重新发送邮件');
    }
  }

  @override
  Widget build(BuildContext context) => _error == null
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text('重新发送重置邮件'),
                ),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _ResendVerificationDialog(),
                  ),
                  child: const Text('重新发送注册验证邮件'),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('返回登录'),
                ),
              ],
            ),
          ),
        );
}

class _ResendVerificationDialog extends StatefulWidget {
  const _ResendVerificationDialog();
  @override
  State<_ResendVerificationDialog> createState() =>
      _ResendVerificationDialogState();
}

class _ResendVerificationDialogState extends State<_ResendVerificationDialog> {
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _sending = false;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await AuthService().resendVerification(_email.text);
      if (mounted) setState(() => _message = '验证邮件已发送，请检查邮箱');
    } catch (_) {
      if (mounted) setState(() => _message = '发送失败，请检查邮箱地址或稍后重试');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('重新发送注册验证邮件'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: '邮箱地址'),
            validator: (value) =>
                RegExp(
                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                ).hasMatch(value?.trim() ?? '')
                ? null
                : '请输入有效邮箱',
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _sending ? null : () => Navigator.pop(context),
        child: const Text('关闭'),
      ),
      FilledButton(
        onPressed: _sending ? null : _send,
        child: Text(_sending ? '发送中…' : '发送'),
      ),
    ],
  );
}
