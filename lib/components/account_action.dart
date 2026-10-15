import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/login_page.dart';
import '../data/social_gateway.dart';

Future<bool> requireAccountForAction(BuildContext context) async {
  if (const SocialGateway().userId != null) return true;
  if (kIsWeb) {
    final from = GoRouterState.of(context).uri.toString();
    await context.push<void>(
      Uri(path: '/login', queryParameters: {'from': from}).toString(),
    );
    return false;
  }
  return await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (loginContext) => LoginPage(
            onAuthenticated: () => Navigator.pop(loginContext, true),
          ),
        ),
      ) ??
      false;
}
