import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/credential_storage.dart';
import '../theme/color_schemes.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

/// 登录页，匹配 SageRoute 文人风格设计语言。
///
/// 功能：
/// - 邮箱密码登录
/// - 跳转注册页
/// - 错误提示（邮箱格式、密码错误、网络异常等）
/// - 加载状态
/// - 7 天内登录过则自动填充邮箱与密码（记住密码）
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authService, this.credentialStorage});

  final AuthService? authService;

  /// 可选的凭据存储，便于测试注入。
  final CredentialStorage? credentialStorage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthService _auth;
  late final CredentialStorage _credentials;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  // ── Page-specific colors ──
  static const _pageBg = AppColors.sageBg;
  static const _textColor = AppColors.sageText;
  static const _mutedColor = AppColors.sageMuted;
  static const _borderColor = AppColors.sageBorder;
  static const _accentColor = AppColors.sageAccent;
  static const _buttonBg = AppColors.sageDeep;
  static const _buttonText = Colors.white;
  static const _errorColor = AppColors.sageText;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
    _credentials = widget.credentialStorage ?? CredentialStorage();
    _restoreSavedCredentials();
  }

  /// 同一设备 7 天内登录过 -> 自动填充邮箱与密码。
  Future<void> _restoreSavedCredentials() async {
    final saved = await _credentials.load();
    if (saved == null || !mounted) return;
    _emailController.text = saved.email;
    _passwordController.text = saved.password;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    // 密码不做本地 trim 校验，但 AuthService 提交前会 trim；
    // 记住的密码也按提交值（trim 后）保存。
    final password = _passwordController.text;

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

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await _auth.signIn(email: email, password: password);
      if (!mounted) return;

      // Do not rely solely on AuthGate's stream timing here. A successful
      // password grant already contains the session, so navigate explicitly
      // and remove the login/onboarding pages from the back stack.
      if (response.session == null || response.user == null) {
        setState(() => _errorMessage = '登录成功但未获取到有效会话，请重试');
        return;
      }
      // 登录成功后记住账号密码，供 7 天内自动填充。
      // 保存的是 AuthService 实际提交的凭据（两侧均已 trim）。
      await _rememberCredentials(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (_) => false);
    } on AuthException catch (e) {
      debugPrint(
        '[Auth] signIn failed: code=${e.code}, status=${e.statusCode}, '
        'message=${e.message}',
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(e.message, e.code);
      });
    } catch (e, stackTrace) {
      debugPrint('[Auth] unexpected signIn error: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = '登录失败：$e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String message, String? code) {
    switch (code) {
      case 'invalid_credentials':
      case 'invalid_grant':
        return '邮箱或密码错误，请重试';
      case 'email_not_confirmed':
        return '请先验证您的邮箱';
      case 'user_not_found':
        return '该邮箱尚未注册';
      case 'over_email_send_rate_limit':
        return '操作过于频繁，请稍后再试';
      default:
        if (message.toLowerCase().contains('invalid')) {
          return '邮箱或密码错误，请重试';
        }
        return message.isEmpty ? '登录失败，请重试' : message;
    }
  }

  /// 持久化记住的凭据；存储失败不影响登录结果。
  Future<void> _rememberCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _credentials.save(email: email, password: password.trim());
    } catch (error) {
      debugPrint('[Auth] persist credentials failed: $error');
    }
  }

  void _goToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RegisterPage(authService: _auth)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildBrandSection(),
              const SizedBox(height: 48),
              _buildWelcomeSection(),
              const SizedBox(height: 32),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorText(),
              ],
              const SizedBox(height: 8),
              _buildForgotPassword(),
              const SizedBox(height: 24),
              _buildLoginButton(),
              const SizedBox(height: 40),
              _buildSignUpPrompt(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Brand: "Sage — Route" + tagline ──

  Widget _buildBrandSection() {
    return Center(
      child: Column(
        children: [
          const _BrandTitle(),
          const SizedBox(height: 12),
          Text(
            '穿越历史的旅程',
            style: TextStyle(
              color: _mutedColor,
              fontSize: 13,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome text ──

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '欢迎回来',
          style: TextStyle(
            color: _textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '登录以继续您的旅程',
          style: TextStyle(
            color: _mutedColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
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
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontSize: 15, color: _textColor),
      decoration: InputDecoration(
        hintText: '密码',
        prefixIcon: Icon(Icons.lock_outlined, size: 20, color: _mutedColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: _mutedColor,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      onSubmitted: (_) => _handleLogin(),
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

  // ── Forgot password ──

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ForgotPasswordPage(authService: _auth),
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: _mutedColor,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('忘记密码？'),
      ),
    );
  }

  // ── Login button ──

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _handleLogin,
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
                '登 录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  // ── Sign up prompt ──

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('还没有账号？', style: TextStyle(color: _mutedColor, fontSize: 14)),
        TextButton(
          onPressed: _goToRegister,
          style: TextButton.styleFrom(
            foregroundColor: _accentColor,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('立即注册'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// "Sage — Route" brand title
// ─────────────────────────────────────────────────────────────

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.sageText,
      fontSize: 36,
      height: 1.0,
      fontWeight: FontWeight.w700,
    );

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Sage', style: style),
        SizedBox(width: 12),
        SizedBox(
          width: 28,
          height: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.sageText),
          ),
        ),
        SizedBox(width: 12),
        Text('Route', style: style),
      ],
    );
  }
}
