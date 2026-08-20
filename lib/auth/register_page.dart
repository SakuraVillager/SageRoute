import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/color_schemes.dart';

/// 注册页，匹配 SageRoute 文人风格设计语言。
///
/// 功能：
/// - 昵称 + 邮箱 + 密码 + 确认密码
/// - 表单校验（邮箱格式、密码长度、两次密码一致）
/// - 注册成功提示
/// - 错误提示
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final AuthService _auth;

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nicknameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMessage;
  bool _emailSent = false;

  // ── Page-specific colors ──
  static const _pageBg = AppColors.sageBg;
  static const _textColor = AppColors.sageText;
  static const _mutedColor = AppColors.sageMuted;
  static const _borderColor = AppColors.sageBorder;
  static const _accentColor = AppColors.sageAccent;
  static const _buttonBg = Color(0xFF1C1700);
  static const _buttonText = Colors.white;
  static const _errorColor = Color(0xFF6F5E00);

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // ── 校验 ──
    if (nickname.isEmpty) {
      setState(() => _errorMessage = '请输入昵称');
      _nicknameFocus.requestFocus();
      return;
    }
    if (nickname.length < 2) {
      setState(() => _errorMessage = '昵称至少需要 2 个字符');
      _nicknameFocus.requestFocus();
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = '请输入有效的邮箱地址');
      _emailFocus.requestFocus();
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = '请输入密码');
      _passwordFocus.requestFocus();
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = '密码至少需要 6 位');
      _passwordFocus.requestFocus();
      return;
    }
    if (confirm.isEmpty) {
      setState(() => _errorMessage = '请再次输入密码');
      _confirmPasswordFocus.requestFocus();
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = '两次输入的密码不一致');
      _confirmPasswordFocus.requestFocus();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        nickname: nickname,
      );

      if (!mounted) return;

      final session = response.session;
      final user = response.user;

      if (session != null) {
        // 邮箱验证关闭的情况下，session 非空 = 直接登录成功
        // AuthGate 会自动跳转到主页
        return;
      }

      if (user != null && user.emailConfirmedAt == null) {
        // 已创建但需要邮箱验证
        setState(() {
          _emailSent = true;
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e.message, e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = '注册失败，请检查网络后重试';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String message, String? code) {
    switch (code) {
      case 'user_already_registered':
      case 'email_already_registered':
        return '该邮箱已被注册，请直接登录';
      case 'weak_password':
        return '密码强度不足，请设置更复杂的密码';
      case 'over_email_send_rate_limit':
        return '操作过于频繁，请稍后再试';
      case 'invalid_email':
        return '邮箱格式不正确';
      default:
        if (message.toLowerCase().contains('already')) {
          return '该邮箱已被注册，请直接登录';
        }
        return message.isEmpty ? '注册失败，请重试' : message;
    }
  }

  void _goToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // 邮箱已发送的确认状态
    if (_emailSent) {
      return _buildEmailSentScreen();
    }

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBackButton(),
              const SizedBox(height: 32),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildNicknameField(),
              const SizedBox(height: 14),
              _buildEmailField(),
              const SizedBox(height: 14),
              _buildPasswordField(),
              const SizedBox(height: 14),
              _buildConfirmPasswordField(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorText(),
              ],
              const SizedBox(height: 24),
              _buildRegisterButton(),
              const SizedBox(height: 24),
              _buildTermsText(),
              const SizedBox(height: 24),
              _buildLoginPrompt(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Back button ──

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: const Color(0xFFF8F7F0),
        shape: CircleBorder(
          side: BorderSide(color: _borderColor),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back, size: 18, color: _textColor),
          ),
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '创建账号',
          style: TextStyle(
            color: _textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '开启您的文化之旅',
          style: TextStyle(
            color: _mutedColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── Nickname field ──

  Widget _buildNicknameField() {
    return TextField(
      controller: _nicknameController,
      focusNode: _nicknameFocus,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 15, color: _textColor),
      decoration: InputDecoration(
        hintText: '昵称',
        prefixIcon: Icon(Icons.person_outlined, size: 20, color: _mutedColor),
      ),
      onSubmitted: (_) => _emailFocus.requestFocus(),
    );
  }

  // ── Email field ──

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 15, color: _textColor),
      decoration: InputDecoration(
        hintText: '邮箱地址',
        prefixIcon: Icon(Icons.email_outlined, size: 20, color: _mutedColor),
      ),
      onSubmitted: (_) => _passwordFocus.requestFocus(),
    );
  }

  // ── Password field ──

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 15, color: _textColor),
      decoration: InputDecoration(
        hintText: '密码（至少 6 位）',
        prefixIcon: Icon(Icons.lock_outlined, size: 20, color: _mutedColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: _mutedColor,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
    );
  }

  // ── Confirm password field ──

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocus,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontSize: 15, color: _textColor),
      decoration: InputDecoration(
        hintText: '确认密码',
        prefixIcon: Icon(Icons.lock_outlined, size: 20, color: _mutedColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: _mutedColor,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      onSubmitted: (_) => _handleRegister(),
    );
  }

  // ── Error text ──

  Widget _buildErrorText() {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 16, color: _errorColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _errorMessage!,
            style: TextStyle(color: _errorColor, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ── Register button ──

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: _buttonBg,
          foregroundColor: _buttonText,
          disabledBackgroundColor: _borderColor,
          disabledForegroundColor: _mutedColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
            : const Text(
                '注 册',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  // ── Terms text ──

  Widget _buildTermsText() {
    return Center(
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: _mutedColor, fontSize: 12, height: 1.5),
          children: [
            const TextSpan(text: '继续即表示您同意我们的'),
            TextSpan(
              text: '使用条款',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: _borderColor,
                decorationThickness: 1,
              ),
            ),
            const TextSpan(text: '与'),
            TextSpan(
              text: '隐私政策',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: _borderColor,
                decorationThickness: 1,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Login prompt ──

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('已有账号？', style: TextStyle(color: _mutedColor, fontSize: 14)),
        TextButton(
          onPressed: _goToLogin,
          style: TextButton.styleFrom(
            foregroundColor: _accentColor,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('立即登录'),
        ),
      ],
    );
  }

  // ── Email sent confirmation screen ──

  Widget _buildEmailSentScreen() {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildBackButton(),
              const Spacer(),
              _buildEmailSentContent(),
              const Spacer(),
              _buildEmailSentActions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailSentContent() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFDCD6B3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.email_outlined, size: 36, color: _accentColor),
        ),
        const SizedBox(height: 24),
        Text(
          '验证邮件已发送',
          style: TextStyle(
            color: _textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '我们已向您的邮箱发送了验证链接，\n请查收并点击链接完成注册。',
          style: TextStyle(color: _mutedColor, fontSize: 14, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _emailController.text.trim(),
          style: TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmailSentActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _goToLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: _textColor,
              side: BorderSide(color: _borderColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('返回登录'),
          ),
        ),
      ],
    );
  }
}
