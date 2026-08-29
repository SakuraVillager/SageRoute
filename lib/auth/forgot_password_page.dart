import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/color_schemes.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final AuthService _auth;
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _loading = false;
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = '请输入有效的邮箱地址');
      _emailFocus.requestFocus();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await _auth.requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _emailSent = true);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '暂时无法发送邮件，请检查网络后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      appBar: AppBar(
        backgroundColor: AppColors.sageBg,
        foregroundColor: AppColors.sageText,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: _emailSent ? _buildEmailSent() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '找回密码',
          style: TextStyle(
            color: AppColors.sageText,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '输入注册邮箱，我们将发送密码重置链接。',
          style: TextStyle(color: AppColors.sageMuted, fontSize: 14),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: '邮箱地址',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          onSubmitted: (_) => _loading ? null : _sendResetEmail(),
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
            onPressed: _loading ? null : _sendResetEmail,
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
                : const Text('发送重置邮件'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 48,
          color: AppColors.sageAccent,
        ),
        const SizedBox(height: 20),
        const Text(
          '重置邮件已发送',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.sageText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '请在邮箱中打开链接并返回 SageRoute 设置新密码。',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.sageMuted, fontSize: 14),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sageDeep,
            foregroundColor: Colors.white,
          ),
          child: const Text('返回登录'),
        ),
      ],
    );
  }
}
