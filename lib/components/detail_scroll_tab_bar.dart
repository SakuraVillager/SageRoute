import 'package:flutter/material.dart';

class DetailScrollTabBar extends StatelessWidget {
  const DetailScrollTabBar({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.scrollController,
    required this.onTabTap,
    this.itemRightPadding = 28,
  });

  final List<String> tabs;
  final int activeTab;
  final ScrollController scrollController;
  final ValueChanged<int> onTabTap;
  final double itemRightPadding;

  static const _background = Color(0xFFFAF7F2);
  static const _activeText = Color(0xFF111111);
  static const _inactiveText = Color(0xFF8E8A82);
  static const _indicator = Color(0xFFCD6642);
  static const _bottomBorder = Color(0xFFEFEBE4);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: Column(
        children: [
          SizedBox(
            height: 49,
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: tabs.length,
              itemBuilder: (_, index) {
                final isActive = index == activeTab;
                return GestureDetector(
                  onTap: () => onTabTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.only(right: itemRightPadding),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive ? _activeText : _inactiveText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2.5,
                          width: isActive ? 20 : 0,
                          decoration: BoxDecoration(
                            color: isActive ? _indicator : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: _bottomBorder),
        ],
      ),
    );
  }
}
