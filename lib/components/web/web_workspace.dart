import 'package:flutter/material.dart';
import '../../theme/color_schemes.dart';

/// Browser navigation retains its place while the workspace changes.
class WebWorkspace extends StatelessWidget {
  const WebWorkspace({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.neutralSoft,
    // Paint navigation after the nested Navigator so route semantics do not
    // suppress the sidebar. RTL here affects placement only, not text direction.
    body: Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(child: child),
        Container(
          key: const ValueKey('web-workspace-sidebar'),
          width: 232,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: AppColors.sageBorder)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: InkWell(
                      key: const ValueKey('web-brand-home'),
                      onTap: () => onSelected(0),
                      child: const Text(
                        'Sage — Route',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandInk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '穿越历史的旅程',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppColors.sageMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 12),
                    child: Text(
                      '探索与计划',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.sageMuted,
                      ),
                    ),
                  ),
                  _link(0, Icons.grid_view_outlined, '我的旅程'),
                  _link(1, Icons.auto_stories_outlined, '人物与故事'),
                  _link(2, Icons.route_outlined, '规划行程'),
                  _link(3, Icons.bookmark_border, '我的收藏'),
                  const Spacer(),
                  const Divider(height: 32),
                  _link(4, Icons.person_outline, '个人中心'),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 24, 0, 0),
                    child: Text(
                      'SageRoute · 山水与人文',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.sageMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _link(int index, IconData icon, String label) {
    final active = index == selectedIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextButton(
        key: ValueKey('web-nav-$index'),
        onPressed: () => onSelected(index),
        style: TextButton.styleFrom(
          foregroundColor: active ? AppColors.brandDark : AppColors.sageMuted,
          backgroundColor: active ? AppColors.brandWash : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            Icon(icon, size: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
