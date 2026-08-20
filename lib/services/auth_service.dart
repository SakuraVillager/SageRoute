import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_service.dart';

/// 封装 Supabase Auth 的常用操作。
///
/// 负责：注册、登录、退出、会话状态监听。
/// 其他业务代码应通过这一层调用，不必直接操作 SupabaseClient.auth。
class AuthService {
  AuthService([SupabaseClient? client])
    : _client = client ?? DatabaseService.client;

  final SupabaseClient _client;

  /// 当前已登录的用户，未登录时为 null。
  User? get currentUser => _client.auth.currentUser;

  /// 当前会话，未登录时为 null。
  Session? get currentSession => _client.auth.currentSession;

  /// 认证状态变化流，可用于监听登录 / 退出 / 会话恢复。
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// 使用邮箱密码注册新用户。
  ///
  /// [nickname] 会写入用户的 metadata，供 profiles 表触发器读取。
  /// 邮箱验证回调地址为 sageroute://login-callback/ 。
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {'nickname': nickname.trim()},
      emailRedirectTo: 'sageroute://login-callback/',
    );
    final session = response.session;
    if (session != null) await DatabaseService.persistAuthSession(session);
    return response;
  }

  /// 使用邮箱密码登录。
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final session = response.session;
    if (session != null) await DatabaseService.persistAuthSession(session);
    return response;
  }

  /// 退出登录。
  Future<void> signOut() async {
    await _client.auth.signOut();
    await DatabaseService.clearPersistedAuthSession();
  }

  /// 从用户信息中读取昵称。
  ///
  /// 优先从 userMetadata 的 nickname 字段读取，
  /// 没有则回退到邮箱前缀（@ 前的部分），再无则返回"旅行者"。
  static String displayNameOf(User? user) {
    if (user == null) return '旅行者';
    final meta = user.userMetadata;
    if (meta != null && meta['nickname'] is String) {
      final nick = meta['nickname'] as String;
      if (nick.trim().isNotEmpty) return nick.trim();
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) {
      final atIndex = email.indexOf('@');
      if (atIndex > 0) return email.substring(0, atIndex);
    }
    return '旅行者';
  }
}
