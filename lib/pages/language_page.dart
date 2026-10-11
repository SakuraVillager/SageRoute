import 'package:flutter/material.dart';

import '../components/settings_card.dart';
import '../services/profile_preferences.dart';
import '../theme/color_schemes.dart';

/// 语言设置页。
///
/// 应用界面目前只提供简体中文；其余语言先展示为“即将上线”，
/// 等 `flutter_localizations` + ARB 文案接入后再启用。
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key, this.preferences});

  final ProfilePreferences? preferences;

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late final ProfilePreferences _preferences;
  String _selected = ProfilePreferences.defaultLanguage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences ?? ProfilePreferences();
    _load();
  }

  Future<void> _load() async {
    final state = await _preferences.load();
    if (!mounted) return;
    setState(() {
      _selected = state.language;
      _loading = false;
    });
  }

  Future<void> _select(String code) async {
    if (!ProfilePreferences.supportedLanguages.containsKey(code)) return;
    if (code == _selected) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('当前已是${ProfilePreferences.labelForLanguage(code)}'),
          ),
        );
      return;
    }
    await _preferences.saveLanguage(code);
    if (!mounted) return;
    setState(() => _selected = code);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('已切换为${ProfilePreferences.labelForLanguage(code)}'),
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
        title: const Text('语言设置'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: <Widget>[
                  _buildNotice(),
                  const SizedBox(height: 20),
                  SettingsCard(
                    children: <Widget>[
                      for (final entry
                          in ProfilePreferences.supportedLanguages.entries)
                        _buildOption(
                          code: entry.key,
                          label: entry.value,
                          enabled: true,
                          selected: _selected == entry.key,
                          showDivider:
                              ProfilePreferences.upcomingLanguages.isNotEmpty,
                        ),
                      for (final entry
                          in ProfilePreferences.upcomingLanguages.entries)
                        _buildOption(
                          code: entry.key,
                          label: entry.value,
                          enabled: false,
                          selected: false,
                          showDivider:
                              entry.key !=
                              ProfilePreferences.upcomingLanguages.keys.last,
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOption({
    required String code,
    required String label,
    required bool enabled,
    required bool selected,
    required bool showDivider,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          key: Key('language-option-$code'),
          enabled: enabled,
          onTap: enabled ? () => _select(code) : null,
          leading: Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 20,
            color: enabled ? AppColors.sageAccent : AppColors.sageBorder,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: enabled ? AppColors.sageText : AppColors.sageMuted,
            ),
          ),
          subtitle: enabled
              ? null
              : const Text(
                  '即将上线',
                  style: TextStyle(fontSize: 12, color: AppColors.sageMuted),
                ),
          trailing: selected
              ? const Icon(Icons.check, size: 18, color: AppColors.sageAccent)
              : null,
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.sageBorder),
      ],
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandWash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandLight),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: AppColors.sageAccent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '应用界面目前仅提供简体中文，多语言支持将在后续版本上线。',
              style: TextStyle(
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
