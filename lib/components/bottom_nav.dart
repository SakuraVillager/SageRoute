import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';

/// 自定义 5-tab 底部导航栏，匹配 Web 版与用户要求：
/// a. 规划按钮完全展示
/// b. 导航栏中间“挖洞”
/// c. 导航栏整体变窄（居中浮动）
class SageRouteBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SageRouteBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _bgColor = AppColors.brandLight;
  static const Color _borderColor = AppColors.sageBorder;
  static const Color _activeBg = AppColors.brandLight;
  static const Color _inactiveColor = AppColors.sageMuted;
  static const Color _activeColor = AppColors.sageText;
  static const Color _specialBg = AppColors.sageAccent;
  static const Color _specialBorder = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: _bgColor.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: _borderColor)),
        ),
        child: Row(
          children: [
            _buildTab(0, Icons.home, '首页'),
            _buildTab(1, Icons.people, '人物'),
            _buildCenterTab(),
            _buildTab(3, Icons.bookmark, '收藏'),
            _buildTab(4, Icons.person, '我的'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? _activeBg : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? _activeColor : _inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? _activeColor : _inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterTab() {
    final isActive = currentIndex == 2;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _specialBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.white : _specialBorder,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              '规划',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? _activeColor : _inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
