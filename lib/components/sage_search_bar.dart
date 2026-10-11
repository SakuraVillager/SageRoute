import 'package:flutter/material.dart';
import '../theme/color_schemes.dart';

/// A pill-shaped search bar matching the Web version's `rounded-full`
/// search input pattern across Home, FiguresList, MapExplorer.
///
/// The widget can render as either a tap-only placeholder (when [onTap]
/// is provided) or as a real [TextField] (when [controller] is provided).
class SageSearchBar extends StatelessWidget {
  const SageSearchBar({
    super.key,
    this.hintText = '搜索...',
    this.controller,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.backgroundColor = Colors.white,
    this.trailing,
  });

  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Color backgroundColor;

  /// Optional trailing widget (e.g. filter icon button) shown on the right,
  /// preceded by a 1-px divider line for visual separation.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hasInput = controller != null || onChanged != null;

    final inner = Row(
      children: [
        const Icon(Icons.search, size: 20, color: AppColors.sageMuted),
        const SizedBox(width: 12),
        Expanded(
          child: hasInput
              ? TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.sageText,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.sageMuted,
                    ),
                  ),
                )
              : Text(
                  hintText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.sageMuted,
                  ),
                ),
        ),
        if (trailing != null) ...[
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.only(left: 8, right: 8),
            color: AppColors.sageBorder,
          ),
          trailing!,
        ],
      ],
    );

    final container = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: inner,
    );

    if (hasInput) return container;
    return GestureDetector(onTap: onTap, child: container);
  }
}
