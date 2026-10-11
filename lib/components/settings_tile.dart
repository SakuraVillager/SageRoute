import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';

/// 设置列表中的单行：图标 + 标题（+ 副标题 / 尾随内容）+ 箭头。
///
/// 必须放在 [Material] 容器内（例如 [SettingsCard]），否则水波纹会被
/// 卡片的不透明背景盖住。相比原来的 [GestureDetector]，这里自带
/// Material 水波纹、48dp 最小触控区域与按钮语义。
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.showDivider = true,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: IconTheme(
            data: const IconThemeData(color: AppColors.sageMuted),
            child: leading,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.sageText,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.sageMuted,
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (trailing != null) ...<Widget>[
                trailing!,
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.sageBorder,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.sageBorder),
      ],
    );
  }
}
