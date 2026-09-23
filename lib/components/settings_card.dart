import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';

/// 设置类列表的白色圆角卡片容器。
///
/// 使用 [Material] 而不是 [Container]，这样内部 [ListTile] / [InkWell]
/// 的水波纹才会绘制在卡片背景之上，而不是被不透明背景盖住。
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sageCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.sageBorder),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
