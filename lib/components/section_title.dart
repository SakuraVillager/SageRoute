import 'package:flutter/material.dart';
import '../theme/color_schemes.dart';

/// Section title with a colored left border accent, matching the Web
/// version's `border-l-4` + `pl-3` pattern used across Home, FiguresList,
/// RoutePreview, etc.
///
/// Usage:
/// ```dart
/// SageSectionTitle('为你推荐的路线', accentColor: AppColors.sageAccent)
/// SageSectionTitle('时下流行人物', accentColor: AppColors.sageGreen, trailing: ...)
/// ```
class SageSectionTitle extends StatelessWidget {
  const SageSectionTitle(
    this.title, {
    super.key,
    this.accentColor = AppColors.sageAccent,
    this.trailing,
  });

  final String title;
  final Color accentColor;

  /// Optional trailing widget (e.g. "全部 →" link).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.sageText,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
