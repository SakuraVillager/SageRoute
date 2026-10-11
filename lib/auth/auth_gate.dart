import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_service.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

/// 鉴权入口 Widget。
///
/// 监听 Supabase Auth 状态变化：
/// - 已登录（有 session）→ 显示 [authenticatedBuilder] 返回的页面
/// - 未登录（无 session）→ 显示 [LoginPage]
///
/// 使用方式：
/// ```dart
/// AuthGate(
///   authenticatedBuilder: (_) => const MainScreen(),
/// )
/// ```
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authenticatedBuilder,
    SupabaseClient? client,
    Stream<AuthState>? authStateChanges,
  }) : _client = client,
       _authStateChanges = authStateChanges;

  final Widget Function(BuildContext context) authenticatedBuilder;
  final SupabaseClient? _client;
  final Stream<AuthState>? _authStateChanges;

  SupabaseClient get _supabaseClient => _client ?? DatabaseService.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateChanges ?? _supabaseClient.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final authState = snapshot.data;
        if (authState?.event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordPage();
        }
        if (authState == null && _authStateChanges != null) {
          return const LoginPage();
        }
        // 优先用 stream 中的 session，其次用当前已有的 session
        final session =
            authState?.session ?? _supabaseClient.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return authenticatedBuilder(context);
      },
    );
  }
}
