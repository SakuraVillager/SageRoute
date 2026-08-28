import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_service.dart';

typedef PasswordResetSender =
    Future<void> Function({required String email, required String redirectTo});

typedef PasswordUpdater = Future<void> Function(String password);

typedef PasswordSignIn =
    Future<AuthResponse> Function({
      required String email,
      required String password,
    });

/// 封装 Supabase Auth 的常用操作。
///
/// 负责：注册、登录、退出、会话状态监听。
/// 其他业务代码应通过这一层调用，不必直接操作 SupabaseClient.auth。
class AuthService {
  AuthService({
    SupabaseClient? client,
    PasswordResetSender? passwordResetSender,
    PasswordUpdater? passwordUpdater,
    PasswordSignIn? passwordSignIn,
  }) : _client = client,
       _passwordResetSender = passwordResetSender,
       _passwordUpdater = passwordUpdater,
       _passwordSignIn = passwordSignIn;

  final SupabaseClient? _client;
  final PasswordResetSender? _passwordResetSender;
  final PasswordUpdater? _passwordUpdater;
  final PasswordSignIn? _passwordSignIn;

  static const passwordResetRedirectTo = 'sageroute://login-callback/';

  SupabaseClient get _supabaseClient => _client ?? DatabaseService.client;

  /// 当前已登录的用户，未登录时为 null。
  User? get currentUser => _supabaseClient.auth.currentUser;

  /// 当前会话，未登录时为 null。
  Session? get currentSession => _supabaseClient.auth.currentSession;

  /// 认证状态变化流，可用于监听登录 / 退出 / 会话恢复。
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  /// 使用邮箱密码注册新用户。
  ///
  /// [nickname] 会写入用户的 metadata，供 profiles 表触发器读取。
  /// 邮箱验证回调地址为 sageroute://login-callback/ 。
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _supabaseClient.auth.signUp(
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
    final signInOverride = _passwordSignIn;
    if (signInOverride != null) {
      return signInOverride(email: email, password: password);
    }
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final session = response.session;
    if (session != null) await DatabaseService.persistAuthSession(session);
    return response;
  }

  /// 退出登录。
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
    await DatabaseService.clearPersistedAuthSession();
  }

  /// 发送密码重置邮件，链接会将用户带回 App 的恢复密码流程。
  Future<void> requestPasswordReset(String email) async {
    final normalizedEmail = email.trim();
    final sender = _passwordResetSender;
    if (sender != null) {
      return sender(
        email: normalizedEmail,
        redirectTo: passwordResetRedirectTo,
      );
    }
    await _supabaseClient.auth.resetPasswordForEmail(
      normalizedEmail,
      redirectTo: passwordResetRedirectTo,
    );
  }

  /// 在 Supabase 通过密码恢复链接创建的临时会话中更新密码。
  Future<void> updatePassword(String password) async {
    final updater = _passwordUpdater;
    if (updater != null) return updater(password);
    await _supabaseClient.auth.updateUser(UserAttributes(password: password));
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
