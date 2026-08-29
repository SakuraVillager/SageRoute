import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';

class DetailCircleButton extends StatelessWidget {
  const DetailCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  const DetailCircleButton.back({super.key, required this.onTap})
    : icon = Icons.arrow_back;

  final IconData icon;
  final VoidCallback onTap;

  static const _background = AppColors.sageBg;
  static const _border = AppColors.brandLight;
  static const _foreground = AppColors.sageText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _background,
          shape: BoxShape.circle,
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 18, color: _foreground),
      ),
    );
  }
}
