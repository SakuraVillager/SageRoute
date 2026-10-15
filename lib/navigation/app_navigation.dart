import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/dongpo_catalog_page.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../auth/forgot_password_page.dart';
import '../pages/settings_page.dart';
import '../pages/account_info_page.dart';
import '../pages/travel_preferences_page.dart';
import '../pages/language_page.dart';
import '../views/article_detail_page.dart';
import '../views/figure_detail_page.dart';
import '../views/location_detail_page.dart';
import '../views/create_route_wizard/create_route_wizard.dart';
import '../views/route_preview/route_preview_page.dart';
import '../views/route_preview/route_edit_page.dart';
import '../utils/slide_route.dart';
import '../services/guest_session.dart';

String? pageLocation(Widget page) => switch (page) {
  DongpoCatalogPage() => '/dongpo',
  LoginPage() => '/login',
  RegisterPage() => '/register',
  ForgotPasswordPage() => '/forgot-password',
  SettingsPage() => '/settings',
  AccountInfoPage() => '/settings/account',
  TravelPreferencesPage() => '/settings/travel',
  LanguagePage() => '/settings/language',
  ArticleDetailPage(:final article) =>
    '/articles/${Uri.encodeComponent(article.id.toString())}',
  FigureDetailPage(:final figure) =>
    '/figures/${Uri.encodeComponent(figure.id)}',
  LocationDetailPage(:final location) =>
    '/locations/${Uri.encodeComponent(location.id)}',
  CreateRouteWizard() => '/routes/new',
  RoutePreviewPage(:final routeId) => '/routes/${Uri.encodeComponent(routeId)}',
  RouteEditPage(:final route) =>
    '/routes/${Uri.encodeComponent(route.id)}/edit',
  _ => null,
};

Future<T?> openAppPage<T>(BuildContext context, Widget page) {
  final path = pageLocation(page);
  if (kIsWeb && path != null) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final target = from != null && (path == '/login' || path == '/register')
        ? Uri(
            path: path,
            queryParameters: {'from': safeReturnLocation(from)},
          ).toString()
        : path;
    return context.push<T>(target, extra: page);
  }
  return Navigator.of(context).push<T>(slideFromRightRoute<T>(page));
}

void finishAppPage<T>(BuildContext context, [T? result]) {
  if (kIsWeb) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.go(parentLocationFor(GoRouterState.of(context).uri.path));
    }
  } else {
    Navigator.of(context).pop(result);
  }
}

String parentLocationFor(String path) {
  final parts = Uri.parse(path).pathSegments;
  if (parts.isEmpty) return '/home';
  if (parts.first == 'settings') {
    return parts.length > 1 ? '/settings' : '/profile';
  }
  if (parts.first == 'figures' ||
      parts.first == 'articles' ||
      parts.first == 'locations') {
    return '/figures';
  }
  if (parts.first == 'routes' && parts.length == 3 && parts.last == 'edit') {
    return '/routes/${Uri.encodeComponent(parts[1])}';
  }
  if (parts.first == 'register' || parts.first == 'forgot-password') {
    return '/login';
  }
  return '/home';
}

void completeLogin(BuildContext context) {
  if (kIsWeb) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    context.go(safeReturnLocation(from));
  } else {
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (_) => false);
  }
}

void completeGuestEntry(BuildContext context) {
  if (kIsWeb) {
    final from = safeReturnLocation(
      GoRouterState.of(context).uri.queryParameters['from'],
    );
    context.go(guestCanVisit(Uri.parse(from).path) ? from : '/home');
  } else {
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (_) => false);
  }
}

String safeReturnLocation(String? from) {
  if (from == null ||
      !from.startsWith('/') ||
      from.startsWith('//') ||
      from.startsWith('/login') ||
      from.startsWith('/auth') ||
      from.startsWith('/register') ||
      from.startsWith('/forgot')) {
    return '/home';
  }
  return from;
}
