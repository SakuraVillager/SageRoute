import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';

class DetailContentSection extends StatelessWidget {
  const DetailContentSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionText,
    this.headerGap = 16,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? actionText;
  final double headerGap;

  static const _titleColor = AppColors.sageAccent;
  static const _dividerColor = AppColors.brandLight;
  static const _mutedColor = AppColors.sageMuted;
  static const _actionColor = AppColors.sageAccent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '—',
                  style: TextStyle(fontSize: 14, color: _dividerColor),
                ),
                const SizedBox(width: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: _mutedColor),
                ),
              ],
            ),
            if (actionText != null)
              Text(
                actionText!,
                style: const TextStyle(
                  fontSize: 13,
                  color: _actionColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        SizedBox(height: headerGap),
        child,
      ],
    );
  }
}

class DetailStatDivider extends StatelessWidget {
  const DetailStatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: AppColors.brandLight);
  }
}
