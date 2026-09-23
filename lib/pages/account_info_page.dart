import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/profile_avatar.dart';
import '../components/settings_card.dart';
import '../services/auth_service.dart';
import '../services/profile_preferences.dart';
import '../theme/color_schemes.dart';

/// 账号信息页：展示绑定邮箱，编辑昵称 / 简介（本地保存），并提供密码重置入口。
///
/// 云端资料写入属于 Phase 2（见 `docs/supabase_profile_schema.md`），
/// 因此本页会明确提示“暂存本机”。
class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({
    super.key,
    this.email = '',
    this.initialNickname = '',
    this.authService,
    this.preferences,
  });

  /// 登录账号的邮箱；为空时尝试从 [AuthService] 读取。
  final String email;

  /// 本地昵称缺失时用于预填的账号昵称。
  final String initialNickname;

  final AuthService? authService;
  final ProfilePreferences? preferences;

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  static const int _nicknameMaxLength = 20;
  static const int _bioMaxLength = 60;

  late final AuthService _auth;
  late final ProfilePreferences _preferences;
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _sendingResetEmail = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
    _preferences = widget.preferences ?? ProfilePreferences();
    _loadLocalProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalProfile() async {
    final state = await _preferences.load();
    if (!mounted) return;
    final nickname = state.nickname?.trim();
    setState(() {
      _nicknameController.text = (nickname == null || nickname.isEmpty)
          ? widget.initialNickname
          : nickname;
      _bioController.text = state.bio ?? '';
      _loading = false;
    });
  }

  String get _email {
    final provided = widget.email.trim();
    if (provided.isNotEmpty) return provided;
    try {
      return _auth.currentUser?.email ?? '';
    } catch (_) {
      // Supabase 未初始化（测试 / 离线）时按未绑定邮箱处理。
      return '';
    }
  }

  String get _avatarLetter {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return '旅';
    return nickname[0];
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    final bio = _bioController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _errorMessage = '昵称不能为空');
      return;
    }
    if (nickname.length > _nicknameMaxLength) {
      setState(() => _errorMessage = '昵称不能超过 $_nicknameMaxLength 个字');
      return;
    }
    if (bio.length > _bioMaxLength) {
      setState(() => _errorMessage = '简介不能超过 $_bioMaxLength 个字');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await _preferences.saveNickname(nickname);
      await _preferences.saveBio(bio);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('账号信息已保存')));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '保存失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendResetEmail() async {
    final email = _email;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('当前账号没有可用的邮箱地址')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: Text('将向 $email 发送密码重置邮件，是否继续？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('发送'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sendingResetEmail = true);
    try {
      await _auth.requestPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('重置邮件已发送，请查收')));
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('发送失败，请检查网络后重试')));
    } finally {
      if (mounted) setState(() => _sendingResetEmail = false);
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
        title: const Text('账号信息'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: <Widget>[
                  Center(child: ProfileAvatar(letter: _avatarLetter, size: 88)),
                  const SizedBox(height: 24),
                  _buildLocalOnlyBanner('昵称与简介暂存于本机，云端同步将在后续版本提供。'),
                  const SizedBox(height: 20),
                  TextField(
                    key: const Key('account-nickname-field'),
                    controller: _nicknameController,
                    maxLength: _nicknameMaxLength,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '昵称',
                      hintText: '请输入昵称',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      } else {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('account-bio-field'),
                    controller: _bioController,
                    maxLength: _bioMaxLength,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '个人简介',
                      hintText: '用一句话介绍自己',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SettingsCard(
                    children: <Widget>[
                      ListTile(
                        key: const Key('account-email'),
                        leading: const Icon(
                          Icons.mail_outline,
                          color: AppColors.sageMuted,
                        ),
                        title: const Text(
                          '邮箱',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.sageText,
                          ),
                        ),
                        subtitle: Text(
                          _email.isEmpty ? '未绑定邮箱' : _email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.sageMuted,
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.sageBorder,
                      ),
                      ListTile(
                        key: const Key('account-change-password'),
                        onTap: _sendingResetEmail ? null : _sendResetEmail,
                        leading: const Icon(
                          Icons.lock_outline,
                          color: AppColors.sageMuted,
                        ),
                        title: const Text(
                          '修改密码',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.sageText,
                          ),
                        ),
                        subtitle: const Text(
                          '向绑定邮箱发送密码重置邮件',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.sageMuted,
                          ),
                        ),
                        trailing: _sendingResetEmail
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.sageAccent,
                                ),
                              )
                            : const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.sageBorder,
                              ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.sageText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('account-save-button'),
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sageDeep,
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('保存修改'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLocalOnlyBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandWash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandLight),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline, size: 16, color: AppColors.sageAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.sageMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
