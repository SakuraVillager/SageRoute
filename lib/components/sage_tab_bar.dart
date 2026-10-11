import 'package:flutter/material.dart';
import '../theme/color_schemes.dart';

/// A horizontal tab bar with an underline indicator, matching the Web
/// version's `border-b border-[#E8E2D9]` + active `border-b-2 border-[#C37153]` pattern.
///
/// Used by SavedRoutes, FigureDetail, LocationDetail, etc.
///
/// Usage:
/// ```dart
/// SageTabBar(
///   tabs: ['保存的路线 (2)', '历史人物', '地点'],
///   selectedIndex: _selectedTab,
///   onChanged: (i) => setState(() => _selectedTab = i),
/// )
/// ```
class SageTabBar extends StatelessWidget {
  const SageTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.horizontalPadding = 24,
    this.expand = true,
    this.activeColor = AppColors.sageAccent,
    this.inactiveColor = AppColors.sageMuted,
    this.dividerColor = AppColors.sageBorder,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Horizontal padding around the tab row.
  final double horizontalPadding;

  /// If true, tabs are equally distributed (Expanded). If false, tabs
  /// size to content and align left (for scrolling/many-tab usage).
  final bool expand;

  final Color activeColor;
  final Color inactiveColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final children = List<Widget>.generate(tabs.length, (index) {
      final tab = _buildTab(index);
      return expand ? Expanded(child: tab) : tab;
    });

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Stack(
        children: [
          // Bottom divider line (full width)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 1, color: dividerColor),
          ),
          // Tabs row
          Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    final isActive = index == selectedIndex;
    return GestureDetector(
      onTap: () => onChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: expand ? 4 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
            // Active indicator (2px line)
            Container(
              height: 2,
              width: expand ? double.infinity : 40,
              color: isActive ? activeColor : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
