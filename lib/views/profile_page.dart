import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/profile_avatar.dart';
import '../components/settings_card.dart';
import '../components/settings_tile.dart';
import '../data/local_achievement_repository.dart';
import '../data/mock_achievements.dart';
import '../data/mock_user.dart';
import '../models/achievement.dart';
import '../pages/account_info_page.dart';
import '../pages/achievement_detail_page.dart';
import '../pages/language_page.dart';
import '../pages/settings_page.dart';
import '../pages/travel_preferences_page.dart';
import '../services/auth_service.dart';
import '../services/profile_preferences.dart';
import '../theme/color_schemes.dart';
import '../utils/achievement_icons.dart';

/// 「我的」页可点击的设置项。
enum ProfileSettingItem { account, travelPreference, language }

/// Profile / personal page matching the Web version's Profile.tsx layout.
///
/// 页面上的按钮与入口全部接通：
/// - 右上角齿轮 → [SettingsPage]（可通过 [onSettingsTap] 覆盖）
/// - 账号信息 / 旅行偏好 / 语言设置 → 对应子页面
///   （可通过 [onSettingItemTap] 覆盖）
/// - 成就卡片 → 成就详情页（可通过 [onAchievementTap] 覆盖）
/// - 退出登录 → 二次确认后调用 [AuthService.signOut]
///   （可通过 [onLogout] 覆盖）
///
/// 昵称、简介、语言与旅行偏好当前保存在本机（[ProfilePreferences]），
/// 云端表结构见 `docs/supabase_profile_schema.md`。
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.onSettingsTap,
    this.onAchievementTap,
    this.onSettingItemTap,
    this.onLogout,
    this.onDebugRouteTap,
    this.authService,
    this.preferences,
    this.achievementRepository,
    this.authStateChanges,
  });

  /// 覆盖设置齿轮的默认行为（默认 push [SettingsPage]）。
  final VoidCallback? onSettingsTap;

  /// 覆盖成就卡片的默认行为（默认打开成就详情页）。
  final void Function(String achievementId)? onAchievementTap;

  /// 覆盖设置列表项的默认导航。
  final void Function(ProfileSettingItem item)? onSettingItemTap;

  /// 覆盖退出登录的默认行为；不传时调用 [AuthService.signOut]。
  final VoidCallback? onLogout;

  /// 点击 Debug 行（仅 debug 构建且提供该回调时展示）。
  final VoidCallback? onDebugRouteTap;

  /// 可选的 AuthService 实例，便于测试注入。
  final AuthService? authService;

  /// 可选的本地偏好存储，便于测试注入。
  final ProfilePreferences? preferences;

  /// 可选的本地成就仓库，便于测试注入。
  final LocalAchievementRepository? achievementRepository;

  /// 可选的登录态流，便于测试注入；为空时读取 [AuthService.authStateChanges]。
  final Stream<AuthState>? authStateChanges;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ── Page-specific colors (from Web Profile.tsx) ──

  static const Color _pageBg = AppColors.sageBg;
  static const Color _sectionTitle = AppColors.sageAccent;
  static const Color _statAchieve = AppColors.sageAccent;
  static const Color _statExplore = AppColors.sageMuted;
  static const Color _statRoute = AppColors.sageMuted;
  static const Color _logoutText = AppColors.sageAccent;
  static const Color _iconBg1 = AppColors.sageBorder;
  static const Color _iconFg1 = AppColors.sageAccent;
  static const Color _iconBg2 = AppColors.brandLight;
  static const Color _iconFg2 = AppColors.sageAccent;
  static const Color _iconBgLocked = Colors.white;
  static const Color _iconFgLocked = AppColors.sageBorder;

  late final AuthService _auth;
  late final ProfilePreferences _preferences;
  late final LocalAchievementRepository _achievementRepository;
  late final Stream<AuthState> _authStateChanges;

  String? _nickname;
  String? _bio;
  String _language = ProfilePreferences.defaultLanguage;
  List<Achievement> _achievements = mockAchievements;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
    _preferences = widget.preferences ?? ProfilePreferences();
    _achievementRepository =
        widget.achievementRepository ?? const LocalAchievementRepository();
    _authStateChanges = widget.authStateChanges ?? _readAuthStateChanges();
    _loadLocalProfile();
    _loadAchievements();
  }

  /// Supabase 未初始化（测试 / 离线）时退化为空流，页面仍能展示本地数据。
  Stream<AuthState> _readAuthStateChanges() {
    try {
      return _auth.authStateChanges;
    } catch (_) {
      return const Stream<AuthState>.empty();
    }
  }

  User? _readCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadLocalProfile() async {
    final state = await _preferences.load();
    if (!mounted) return;
    setState(() {
      _nickname = state.nickname;
      _bio = state.bio;
      _language = state.language;
    });
  }

  Future<void> _loadAchievements() async {
    final achievements = await _achievementRepository.fetchAchievements();
    if (!mounted) return;
    setState(() => _achievements = achievements);
  }

  String _resolvedDisplayName(User? user) {
    final nickname = _nickname?.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;
    return AuthService.displayNameOf(user);
  }

  String _resolvedSubtitle(String email) {
    final bio = _bio?.trim() ?? '';
    if (bio.isNotEmpty) return bio;
    if (email.isNotEmpty) return email;
    return mockUser.bio;
  }

  // ── Navigation handlers ──

  Future<void> _openSettings() async {
    final override = widget.onSettingsTap;
    if (override != null) {
      override();
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const SettingsPage()));
    if (!mounted) return;
    await _loadLocalProfile();
  }

  Future<void> _handleSettingItem(ProfileSettingItem item) async {
    final override = widget.onSettingItemTap;
    if (override != null) {
      override(item);
      return;
    }

    final user = _readCurrentUser();
    final Widget page;
    switch (item) {
      case ProfileSettingItem.account:
        page = AccountInfoPage(
          email: user?.email ?? '',
          initialNickname: _resolvedDisplayName(user),
        );
      case ProfileSettingItem.travelPreference:
        page = const TravelPreferencesPage();
      case ProfileSettingItem.language:
        page = const LanguagePage();
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => page));
    if (!mounted) return;
    await _loadLocalProfile();
  }

  Future<void> _handleAchievementTap(Achievement achievement) async {
    final override = widget.onAchievementTap;
    if (override != null) {
      override(achievement.id);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AchievementDetailPage(achievement: achievement),
      ),
    );
    if (!mounted) return;
    await _loadAchievements();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('退出后需要重新登录才能继续同步行程，确定要退出吗？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final override = widget.onLogout;
    if (override != null) {
      override();
      return;
    }

    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('退出失败，请稍后重试')));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data?.session?.user ?? _readCurrentUser();
        final displayName = _resolvedDisplayName(user);
        final email = user?.email ?? '';
        // 用昵称首字作为头像占位（没有头像 URL 时）
        final avatarLetter = displayName.isNotEmpty ? displayName[0] : '旅';

        return Scaffold(
          backgroundColor: _pageBg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  _buildHeader(displayName, email, avatarLetter),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
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
      },
    );
  }

  // ── Header ──

  Widget _buildHeader(String displayName, String email, String avatarLetter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.sageCard,
        border: const Border(bottom: BorderSide(color: AppColors.sageBorder)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 28),
              ProfileAvatar(letter: avatarLetter),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sageText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _resolvedSubtitle(email),
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
              key: const Key('profile-settings-button'),
              icon: const Icon(Icons.settings, size: 22),
              color: AppColors.sageMuted,
              tooltip: '设置',
              onPressed: _openSettings,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──

  Widget _buildStatsRow() {
    // 与成就列表保持一致：这里统计的是“已解锁”的成就数量。
    final unlockedAchievements = _achievements
        .where((achievement) => achievement.isUnlocked)
        .length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildStatColumn(
          '$unlockedAchievements',
          '解锁成就',
          _statAchieve,
          valueKey: const Key('profile-stat-achievements'),
        ),
        Container(width: 1, height: 40, color: AppColors.sageBorder),
        _buildStatColumn('${mockUser.exploredLocations}', '探索地点', _statExplore),
        Container(width: 1, height: 40, color: AppColors.sageBorder),
        _buildStatColumn('${mockUser.completedRoutes}', '完成路线', _statRoute),
      ],
    );
  }

  Widget _buildStatColumn(
    String value,
    String label,
    Color valueColor, {
    Key? valueKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.sageMuted),
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
        children: <Widget>[
          for (final entry in _achievements.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildAchievementCard(entry.value, entry.key),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, int index) {
    final unlocked = achievement.isUnlocked;
    final iconColor = unlocked
        ? (index % 2 == 0 ? _iconFg1 : _iconFg2)
        : _iconFgLocked;
    final iconBgColor = unlocked
        ? (index % 2 == 0 ? _iconBg1 : _iconBg2)
        : _iconBgLocked;

    final card = Semantics(
      button: true,
      label: '${achievement.name}，${unlocked ? '已解锁' : '未解锁'}',
      child: Material(
        color: AppColors.sageCard,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.sageBorder),
        ),
        child: InkWell(
          key: Key('achievement-card-${achievement.id}'),
          onTap: () => _handleAchievementTap(achievement),
          child: SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Icon circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievementIconFor(achievement.icon),
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
                    unlocked ? achievement.description : '未解锁',
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
          ),
        ),
      ),
    );

    if (!unlocked) {
      return Opacity(opacity: 0.5, child: card);
    }
    return card;
  }

  // ── Settings List ──

  Widget _buildSettingsList() {
    final showDebugEntry = kDebugMode && widget.onDebugRouteTap != null;

    return SettingsCard(
      children: <Widget>[
        SettingsTile(
          key: const Key('profile-setting-account'),
          leading: const Icon(Icons.person_outline, size: 18),
          title: '账号信息',
          onTap: () => _handleSettingItem(ProfileSettingItem.account),
        ),
        SettingsTile(
          key: const Key('profile-setting-travel'),
          leading: const Icon(Icons.explore, size: 18),
          title: '旅行偏好',
          onTap: () => _handleSettingItem(ProfileSettingItem.travelPreference),
        ),
        SettingsTile(
          key: const Key('profile-setting-language'),
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
          title: '语言设置',
          trailing: Text(
            ProfilePreferences.labelForLanguage(_language),
            style: const TextStyle(fontSize: 12, color: AppColors.sageMuted),
          ),
          showDivider: showDebugEntry,
          onTap: () => _handleSettingItem(ProfileSettingItem.language),
        ),
        if (showDebugEntry)
          SettingsTile(
            key: const Key('profile-setting-debug'),
            leading: const Icon(Icons.bug_report_outlined, size: 18),
            title: 'Debug',
            showDivider: false,
            onTap: widget.onDebugRouteTap!,
          ),
      ],
    );
  }

  // ── Logout Button ──

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: const Key('profile-logout-button'),
        onPressed: _signingOut ? null : _confirmLogout,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.sageCard,
          foregroundColor: _logoutText,
          side: const BorderSide(color: AppColors.sageBorder),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _signingOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _logoutText,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
