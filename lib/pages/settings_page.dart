import 'package:flutter/material.dart';

import '../components/settings_card.dart';
import '../components/settings_tile.dart';
import '../services/profile_preferences.dart';
import '../theme/color_schemes.dart';
import 'account_info_page.dart';
import 'celebrity_selection/celebrity_selection_page.dart';
import 'language_page.dart';
import 'travel_preferences_page.dart';

/// 设置中心：账号信息、旅行偏好、语言设置与切换同行人物。
///
/// 由「我的」页右上角齿轮进入，原先只包含“切换人物”的占位页面已补齐为
/// 可用的功能入口。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onSwitchCelebrity, this.preferences});

  /// 覆盖“切换人物”的默认行为（默认 push [CelebritySelectionPage]）。
  final VoidCallback? onSwitchCelebrity;

  /// 可注入的本地偏好存储，便于测试。
  final ProfilePreferences? preferences;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final ProfilePreferences _preferences;
  String _languageLabel = ProfilePreferences.simplifiedChineseLabel;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences ?? ProfilePreferences();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final state = await _preferences.load();
    if (!mounted) return;
    setState(
      () =>
          _languageLabel = ProfilePreferences.labelForLanguage(state.language),
    );
  }

  /// push 子页面并在返回后刷新语言等展示信息。
  Future<void> _push(Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => page));
    if (!mounted) return;
    await _loadLanguage();
  }

  void _openCelebritySelection() {
    final override = widget.onSwitchCelebrity;
    if (override != null) {
      override();
      return;
    }
    _push(
      CelebritySelectionPage(
        onContinue: () => Navigator.of(context).pop(),
        onSkip: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      appBar: AppBar(
        backgroundColor: AppColors.sageBg,
        foregroundColor: AppColors.sageText,
        elevation: 0,
        title: const Text('设置'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: <Widget>[
            _buildSectionTitle('账号'),
            const SizedBox(height: 12),
            SettingsCard(
              children: <Widget>[
                SettingsTile(
                  key: const Key('settings-account-info'),
                  leading: const Icon(Icons.person_outline, size: 18),
                  title: '账号信息',
                  subtitle: '昵称、简介与密码',
                  showDivider: false,
                  onTap: () => _push(const AccountInfoPage()),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('偏好'),
            const SizedBox(height: 12),
            SettingsCard(
              children: <Widget>[
                SettingsTile(
                  key: const Key('settings-travel-preferences'),
                  leading: const Icon(Icons.explore, size: 18),
                  title: '旅行偏好',
                  subtitle: '偏好朝代、主题、节奏与交通方式',
                  onTap: () => _push(const TravelPreferencesPage()),
                ),
                SettingsTile(
                  key: const Key('settings-language'),
                  leading: const SizedBox(
                    width: 18,
                    height: 18,
                    child: Center(
                      child: Text(
                        '文',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sageMuted,
                        ),
                      ),
                    ),
                  ),
                  title: '语言设置',
                  trailing: Text(
                    _languageLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.sageMuted,
                    ),
                  ),
                  showDivider: false,
                  onTap: () => _push(const LanguagePage()),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('同行人物'),
            const SizedBox(height: 12),
            SettingsCard(
              children: <Widget>[
                SettingsTile(
                  key: const Key('settings-switch-celebrity'),
                  leading: const Icon(Icons.person, size: 18),
                  title: '切换人物',
                  subtitle: '从角色库中挑选新的同行者',
                  showDivider: false,
                  onTap: _openCelebritySelection,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.sageAccent,
      ),
    );
  }
}
