import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_service.dart';
import 'login_page.dart';

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
  AuthGate({
    super.key,
    required this.authenticatedBuilder,
    SupabaseClient? client,
  }) : _client = client ?? DatabaseService.client;

  final Widget Function(BuildContext context) authenticatedBuilder;
  final SupabaseClient _client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 优先用 stream 中的 session，其次用当前已有的 session
        final session = snapshot.data?.session ?? _client.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return authenticatedBuilder(context);
      },
    );
  }
}
