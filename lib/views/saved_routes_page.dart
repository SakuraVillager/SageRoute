import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/ticket_card.dart';
import '../components/sage_tab_bar.dart';
import '../data/mock_routes.dart' as routes;
import '../data/mock_figures.dart' as figures;
import '../models/new_route_draft.dart';
import '../theme/color_schemes.dart';

/// 收藏页，匹配 Web 版 SavedRoutes.tsx 视觉风格。
///
/// 功能：
/// - Tab 导航：保存的路线 / 历史人物 / 地点
/// - 路线卡片：图片头部 + 渐变遮罩 + 收藏图标 + 路线名称 + 统计信息
/// - 卡片底部：人物头像 + "+X" 计数 + "查看行程" 按钮
class SavedRoutesPage extends StatefulWidget {
  const SavedRoutesPage({
    super.key,
    this.onRouteTap,
    this.createdRoutesListenable,
  });

  /// Callback when a route card is tapped.
  final void Function(String routeId)? onRouteTap;
  final ValueListenable<List<NewRouteDraft>>? createdRoutesListenable;

  @override
  State<SavedRoutesPage> createState() => _SavedRoutesPageState();
}

class _SavedRoutesPageState extends State<SavedRoutesPage> {
  int _selectedTab = 0;

  static const List<String> _tabs = ['保存的路线', '历史人物', '地点'];

  // Mock saved route IDs for demonstration (2 routes saved)
  static const _savedRouteIds = {'bai-juyi-hangzhou', 'su-dongpo-chibi'};

  List<routes.MockRoute> get _savedRoutes =>
      routes.mockRoutes.where((r) => _savedRouteIds.contains(r.id)).toList();

  @override
  Widget build(BuildContext context) {
    final listenable = widget.createdRoutesListenable;
    if (listenable == null) {
      return _buildScaffold(const <NewRouteDraft>[]);
    }

    return ValueListenableBuilder<List<NewRouteDraft>>(
      valueListenable: listenable,
      builder: (context, createdRoutes, _) => _buildScaffold(createdRoutes),
    );
  }

  Widget _buildScaffold(List<NewRouteDraft> createdRoutes) {
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTabBar(createdRoutes),
              const SizedBox(height: 24),
              _buildTabContent(createdRoutes),
              // Bottom nav spacing
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '我的收藏',
            style: TextStyle(
              fontSize: 30, // Web: text-3xl
              fontWeight: FontWeight.bold,
              color: AppColors.sageText,
              letterSpacing: 1.5, // Web: tracking-wide
            ),
          ),
          SizedBox(height: 8),
          Text(
            '保存的路线与历史遗迹',
            style: TextStyle(fontSize: 14, color: AppColors.sageMuted),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ──

  Widget _buildTabBar(List<NewRouteDraft> createdRoutes) {
    final tabLabels = _tabs.asMap().entries.map((e) {
      final showCount = e.key == 0;
      final count = _savedRoutes.length + createdRoutes.length;
      return showCount ? '${e.value} ($count)' : e.value;
    }).toList();

    return SageTabBar(
      tabs: tabLabels,
      selectedIndex: _selectedTab,
      onChanged: (i) => setState(() => _selectedTab = i),
      expand: false,
    );
  }

  // ── Tab Content ──

  Widget _buildTabContent(List<NewRouteDraft> createdRoutes) {
    switch (_selectedTab) {
      case 0:
        return _buildSavedRoutes(createdRoutes);
      case 1:
        return _buildPlaceholderTab(Icons.people_outline, '历史人物');
      case 2:
        return _buildPlaceholderTab(Icons.place_outlined, '地点');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholderTab(IconData icon, String label) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.sageMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '$label内容即将上线',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.sageMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Saved Routes List ──

  Widget _buildSavedRoutes(List<NewRouteDraft> createdRoutes) {
    final savedRoutes = _savedRoutes;
    if (createdRoutes.isEmpty && savedRoutes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 48,
                  color: AppColors.sageMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  '还没有收藏的路线',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.sageMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          for (final route in createdRoutes)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TicketCard(
                title: route.title,
                dateRange: route.dateRange,
                memberText: '全新规划的旅程',
                duration: route.duration,
                distance: route.distance,
              ),
            ),
          for (final route in savedRoutes)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _RouteCard(
                route: route,
                onTap: () => widget.onRouteTap?.call(route.id),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Route Card Widget
// ─────────────────────────────────────────────────────────────

/// Renders a single saved route card matching the Web SavedRoutes.tsx layout:
///
/// - Image header with gradient overlay, bookmark icon, date badge + route name
/// - Stats row (days, locations, distance, places)
/// - Bottom section with figure avatar, "+X" count, and "查看行程" button
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, this.onTap});

  final routes.MockRoute route;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final figure = figures.findFigureById(route.figureId);
    final imageUrl =
        figure?.imageUrl ??
        'https://images.unsplash.com/photo-1543335759-33eb91f5a5e3?auto=format&fit=crop&q=80&w=800';

    // Collect unique location names (up to 3)
    final locationNames = <String>{};
    for (final loc in route.locations) {
      if (locationNames.length >= 3) break;
      locationNames.add(loc.name);
    }
    final locationsSummary = locationNames.join(', ');

    // Format start date
    final startDateLabel = _formatStartDate(route.startDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.sageBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Header ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: 128,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 600,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.sageBorder),
                    ),
                    // Gradient overlay (dark at bottom for text readability)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                            stops: [0.3, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Bookmark icon (top-right, glassmorphism)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.bookmark,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Bottom-left: date badge + route name
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (startDateLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                startDateLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (startDateLabel != null) const SizedBox(height: 4),
                          Text(
                            route.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats Section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Left column: days + locations
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatRow(
                              Icons.calendar_month,
                              AppColors.sageGreen,
                              '${route.days}天${route.days - 1}夜',
                            ),
                            const SizedBox(height: 6),
                            _StatRow(
                              Icons.location_on_outlined,
                              AppColors.primaryLight,
                              '${route.locationsCount} 处景点',
                            ),
                          ],
                        ),
                      ),
                      // Vertical divider
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.sageBorder,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      // Right column: distance + location names
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatRow(
                              Icons.route,
                              const Color(0xFFA38D64),
                              route.totalDistance,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              locationsSummary,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.sageMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: AppColors.sageBorder),
                ],
              ),
            ),

            // ── Bottom Section: avatar + count + button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar group (overlapping)
                  Row(
                    children: [
                      // Figure avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: figure != null
                              ? DecorationImage(
                                  image: NetworkImage(figure.imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: AppColors.sageBorder,
                        ),
                      ),
                      // "+X" badge (overlaps avatar by 8px via negative offset)
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEBE5DA),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '+8',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sageMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // "查看行程" button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sageBg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '查看行程',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.sageText,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppColors.sageText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Parse and format startDate string like "2024-04-01" → "4月1日 出发".
  /// Returns null if the date cannot be parsed.
  static String? _formatStartDate(String? startDate) {
    if (startDate == null || startDate.length < 10) return null;
    try {
      final date = DateTime.parse(startDate);
      return '${date.month}月${date.day}日 出发';
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Stat Row Helper
// ─────────────────────────────────────────────────────────────

/// A small row with an icon and text, used for route statistics.
class _StatRow extends StatelessWidget {
  const _StatRow(this.icon, this.color, this.text);

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.sageMuted),
        ),
      ],
    );
  }
}
