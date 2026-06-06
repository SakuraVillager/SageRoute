import 'package:flutter/material.dart';

import '../data/mock_user.dart';
import '../theme/color_schemes.dart';

/// Profile / personal page matching the Web version's Profile.tsx layout.
///
/// Sections:
/// - Header: settings icon + avatar (circular with decorative ring) + name + bio
/// - Stats row: unlocked achievements / explored locations / completed routes
/// - Achievement cards: horizontal scroll with icon + name + description
/// - Settings list: account info, travel preferences, language (card + chevron)
/// - Logout button: sage card background + terracotta text
///
/// Navigation is handled via optional callbacks. No real settings functionality.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.onSettingsTap,
    this.onAchievementTap,
    this.onSettingItemTap,
    this.onLogout,
    this.onDebugRouteTap,
  });

  /// Callback when the settings icon is tapped.
  final VoidCallback? onSettingsTap;

  /// Callback when an achievement card is tapped.
  final void Function(String achievementId)? onAchievementTap;

  /// Callback when a settings list item is tapped.
  final void Function(int index)? onSettingItemTap;

  /// Callback when the logout button is tapped.
  final VoidCallback? onLogout;

  /// Callback when the debug route item is tapped.
  final VoidCallback? onDebugRouteTap;

  // ── Page-specific colors (from Web Profile.tsx) ──

  static const Color _pageBg = Color(0xFFFDFBF7);
  static const Color _avatarRing = Color(0xFFEBE5DA);
  static const Color _sectionTitle = Color(0xFF8A8376);
  static const Color _statAchieve = Color(0xFFC37153);
  static const Color _statExplore = Color(0xFF84A98C);
  static const Color _statRoute = Color(0xFFA38D64);
  static const Color _logoutText = Color(0xFFC37153);
  static const Color _chevronColor = Color(0xFFDCD6C8);
  static const Color _iconBg1 = Color(0xFFF0DED3);
  static const Color _iconFg1 = Color(0xFFA65B40);
  static const Color _iconBg2 = Color(0xFFEBE5DA);
  static const Color _iconFg2 = Color(0xFF8A8376);
  static const Color _iconBgLocked = Colors.white;
  static const Color _iconFgLocked = Color(0xFFDCD6C8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildSectionTitle('我的文史成就'),
                    const SizedBox(height: 12),
                    _buildAchievementsRow(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('偏好设置'),
                    const SizedBox(height: 12),
                    _buildSettingsList(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                    // Bottom clearance for BottomNav
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
         border: const Border(bottom: BorderSide(color: AppColors.sageBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 28),
              _buildAvatar(),
              const SizedBox(height: 16),
              Text(
                mockUser.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sageText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mockUser.bio,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.sageMuted,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatsRow(),
            ],
          ),
          // Settings icon (top-right)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.settings, size: 22),
              color: AppColors.sageMuted,
              onPressed: onSettingsTap,
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar with decorative ring ──

  Widget _buildAvatar() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _avatarRing, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(mockUser.avatarUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ── Stats Row ──

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatColumn(
          '${mockUser.achievementsCount}',
          '解锁成就',
          _statAchieve,
        ),
        Container(width: 1, height: 40, color: AppColors.sageBorder),
        _buildStatColumn(
          '${mockUser.exploredLocations}',
          '探索地点',
          _statExplore,
        ),
        Container(width: 1, height: 40, color: AppColors.sageBorder),
        _buildStatColumn(
          '${mockUser.completedRoutes}',
          '完成路线',
          _statRoute,
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.sageMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title ──

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: _sectionTitle,
      ),
    );
  }

  // ── Achievements Horizontal Scroll ──

  Widget _buildAchievementsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: mockAchievements.map((achievement) {
          final index = mockAchievements.indexOf(achievement);
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildAchievementCard(achievement, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementCard(MockAchievement achievement, int index) {
    final iconColor = achievement.unlocked
        ? (index % 2 == 0 ? _iconFg1 : _iconFg2)
        : _iconFgLocked;
    final iconBgColor = achievement.unlocked
        ? (index % 2 == 0 ? _iconBg1 : _iconBg2)
        : _iconBgLocked;

    final card = GestureDetector(
      onTap: achievement.unlocked
          ? () => onAchievementTap?.call(achievement.id)
          : null,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sageCard,
          border: Border.all(color: AppColors.sageBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _mapIcon(achievement.iconName),
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.sageText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              achievement.unlocked ? achievement.description : '未解锁',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.sageMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (!achievement.unlocked) {
      return Opacity(opacity: 0.5, child: card);
    }
    return card;
  }

  /// Maps the mock icon name to a Material icon.
  static IconData _mapIcon(String? iconName) {
    switch (iconName) {
      case 'book':
        return Icons.menu_book;
      case 'compass':
        return Icons.explore;
      case 'crown':
        return Icons.workspace_premium;
      case 'star':
        return Icons.star;
      case 'camera':
        return Icons.camera_alt;
      case 'quote':
        return Icons.format_quote;
      default:
        return Icons.emoji_events;
    }
  }

  // ── Settings List ──

  Widget _buildSettingsList() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.sageBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            leading: const Icon(Icons.person_outline, size: 18),
            label: '账号信息',
            onTap: () => onSettingItemTap?.call(0),
          ),
          _buildSettingItem(
            leading: const Icon(Icons.explore, size: 18),
            label: '旅行偏好',
            onTap: () => onSettingItemTap?.call(1),
          ),
          _buildSettingItem(
            leading: const SizedBox(
              width: 18,
              height: 18,
              child: Center(
                child: Text(
                  '文',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sageMuted,
                  ),
                ),
              ),
            ),
            label: '语言设置',
            trailing: const Text(
              '简体中文',
              style: TextStyle(fontSize: 12, color: AppColors.sageMuted),
            ),
            onTap: () => onSettingItemTap?.call(2),
          ),
          _buildSettingItem(
            leading: const Icon(Icons.bug_report_outlined, size: 18),
            label: 'Debug',
            onTap: () => onDebugRouteTap?.call(),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required Widget leading,
    required String label,
    required VoidCallback onTap,
    bool showDivider = true,
    Widget? trailing,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                IconTheme(
                  data: const IconThemeData(color: AppColors.sageMuted),
                  child: leading,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.sageText,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right, size: 18, color: _chevronColor),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(height: 1, color: AppColors.sageBorder),
      ],
    );
  }

  // ── Logout Button ──

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onLogout,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.sageCard,
          foregroundColor: _logoutText,
          side: const BorderSide(color: AppColors.sageBorder),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 16, color: _logoutText),
            SizedBox(width: 8),
            Text(
              '退出登录',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
