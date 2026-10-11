import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';

/// 圆形头像占位：品牌色底 + 首字，带装饰环与投影。
///
/// 与「我的」页原头像视觉一致，供个人页与账号信息页复用。
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.letter,
    this.size = 96,
    this.borderWidth = 4,
  });

  /// 头像中央展示的文字，通常取昵称首字。
  final String letter;

  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brandLight, width: borderWidth),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
        color: AppColors.sageAccent,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.375,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
