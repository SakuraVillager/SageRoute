import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/credential_storage.dart';
import '../theme/color_schemes.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    this.authService,
    this.credentialStorage,
  });

  final AuthService? authService;

  /// 可选的凭据存储，便于测试注入。
  final CredentialStorage? credentialStorage;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final AuthService _auth;
  late final CredentialStorage _credentials;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _loading = false;
  bool _passwordUpdated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
    _credentials = widget.credentialStorage ?? CredentialStorage();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;
    if (password.length < 6) {
      setState(() => _errorMessage = '密码至少需要 6 位');
      _passwordFocus.requestFocus();
      return;
    }
    if (password != confirmation) {
      setState(() => _errorMessage = '两次输入的密码不一致');
      _confirmPasswordFocus.requestFocus();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await _auth.updatePassword(password);
      if (!mounted) return;
      // 若本设备记住的正是该账号，同步为新密码，
      // 避免 7 天内自动填充一个已失效的旧密码。
      await _syncRememberedPassword(password);
      if (!mounted) return;
      setState(() => _passwordUpdated = true);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '密码更新失败，请重新打开重置邮件后再试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 密码重置成功后更新已记住的密码；失败不影响重置结果。
  Future<void> _syncRememberedPassword(String newPassword) async {
    try {
      final email = _auth.currentUser?.email;
      if (email == null || email.isEmpty) return;
      await _credentials.replacePassword(
        email: email,
        newPassword: newPassword,
      );
    } catch (error) {
      debugPrint('[Auth] sync remembered password failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: _passwordUpdated ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '设置新密码',
          style: TextStyle(
            color: AppColors.sageText,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '请设置一个至少 6 位的新密码。',
          style: TextStyle(color: AppColors.sageMuted, fontSize: 14),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: '新密码',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          obscureText: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: '确认新密码',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => _loading ? null : _updatePassword(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.sageText, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _updatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageDeep,
              foregroundColor: Colors.white,
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('更新密码'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 52, color: AppColors.sageAccent),
        SizedBox(height: 20),
        Text(
          '密码已更新',
          style: TextStyle(
            color: AppColors.sageText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '你现在可以使用新密码登录。',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.sageMuted, fontSize: 14),
        ),
      ],
    );
  }
}
