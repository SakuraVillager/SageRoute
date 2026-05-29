import 'package:flutter/material.dart';

import '../models/figure.dart';

/// 人物详情页，精确匹配 Web 版 FigureDetail.tsx 视觉风格。
///
/// 沉浸式头部图片 + 渐变遮罩、人物信息、统计卡片、Tab 导航、操作按钮。
/// 接受 [Figure] 对象作为参数。
class FigureDetailPage extends StatefulWidget {
  const FigureDetailPage({super.key, required this.figure, this.onBack});

  final Figure figure;

  /// 返回按钮回调，不传则隐藏返回按钮。
  final VoidCallback? onBack;

  @override
  State<FigureDetailPage> createState() => _FigureDetailPageState();
}

class _FigureDetailPageState extends State<FigureDetailPage> {
  int _selectedTab = 0;

  static const List<String> _tabs = ['生平', '遗址', '名言', '地图', '作品'];

  // Page-specific colors (from Web FigureDetail.tsx)
  static const Color _pageBg = Color(0xFFFDFBF7);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE8E2D9);
  static const Color _textPrimary = Color(0xFF2D2825);
  static const Color _textSecondary = Color(0xFF857F75);
  static const Color _roleBg = Color(0xFFF0EBE4);
  static const Color _roleText = Color(0xFF6B655A);
  static const Color _primaryBtnBg = Color(0xFF1C1A1A);
  static const Color _primaryBtnText = Color(0xFFF3EFE9);
  static const Color _dividerColor = Color(0xFFE8E2D9);
  static const Color _tabActive = Color(0xFFC37153);
  static const Color _tabInactive = Color(0xFF857F75);
  static const Color _navBtnBg = Color(0x33FFFFFF);
  static const Color _starColor = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final figure = widget.figure;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        children: [
          // ── Scrollable content ──
          SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero image + gradient + figure info ──
                SizedBox(
                  height: screenHeight * 0.48,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      Image.network(
                        figure.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: _cardBorder,
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 64,
                              color: Color(0xFFB0A89A),
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay:
                      // top: black/40 (nav readability)
                      // middle: transparent (image visible)
                      // bottom: #FDFBF7 (blend into page bg)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black54,
                                  Colors.transparent,
                                  _pageBg,
                                ],
                                stops: [0.0, 0.35, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Figure info overlaid at bottom of hero
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Text(
                                figure.name,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Pinyin name
                              Text(
                                figure.pinyinName,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w300,
                                  color: _textPrimary,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Dynasty + short description
                              Text(
                                '${figure.dynasty} · ${figure.shortDesc}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Role tags (small capsules)
                              if (figure.role.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: figure.role.map((r) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _roleBg,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Text(
                                        r,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _roleText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content area below hero ──
                const SizedBox(height: 8),

                // Stats grid
                _buildStatsGrid(figure),
                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(),
                const SizedBox(height: 32),

                // Tab bar
                _buildTabBar(),
                const SizedBox(height: 4),
                // Tab underline
                Container(
                  height: 2,
                  color: _dividerColor,
                  width: double.infinity,
                ),
                const SizedBox(height: 24),

                // Tab content
                _buildTabContent(figure),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // ── Top navigation bar (Positioned) ──
          // Web: 三段布局 — 左侧返回 / 中间 "Sage _ Route" 品牌字 / 右侧收藏+分享
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left: Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: widget.onBack != null
                        ? _buildNavButton(Icons.arrow_back, widget.onBack!)
                        : const SizedBox.shrink(),
                  ),
                  // Center: Brand title "Sage _ Route"
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 3,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '_',
                        style: TextStyle(
                          color: Color(0x80FFFFFF), // text-white/50
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Route',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  // Right: Bookmark + Share buttons
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNavButton(Icons.bookmark_border, () {}),
                        const SizedBox(width: 8),
                        _buildNavButton(Icons.ios_share, () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top navigation icon button ──
  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: _navBtnBg, shape: BoxShape.circle),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ),
    );
  }

  // ── Stats grid (4 columns: locations, routes, poems, rating) ──
  Widget _buildStatsGrid(Figure figure) {
    final stats = [
      _StatItem(figure.locationsCount.toString(), '遗址'),
      _StatItem(figure.routesCount.toString(), '旅程'),
      _StatItem(figure.poemsCount.toString(), '诗篇'),
      _StatItem(figure.rating.toStringAsFixed(1), '评分', isRating: true),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: stats.map((stat) {
            return Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stat.label,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      if (stat.isRating)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.star, size: 18, color: _starColor),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Action buttons row ──
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Primary: "规划路线"
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBtnBg,
                  foregroundColor: _primaryBtnText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.route, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '规划路线',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Secondary: "地图"
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: _textPrimary,
                side: const BorderSide(color: _cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.map_outlined, size: 18),
                  SizedBox(width: 6),
                  Text(
                    '地图',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar (horizontally scrollable) ──
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isActive = index == _selectedTab;
            return Padding(
              padding: const EdgeInsets.only(right: 28),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tabs[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive ? _tabActive : _tabInactive,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Active indicator underline
                    Container(
                      height: 3,
                      width: 20,
                      decoration: BoxDecoration(
                        color: isActive ? _tabActive : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Tab content ──
  Widget _buildTabContent(Figure figure) {
    switch (_selectedTab) {
      case 0:
        return _buildBiographyContent(figure);
      case 1:
        return _buildPlaceholderTab('遗址', Icons.place);
      case 2:
        return _buildPlaceholderTab('名言', Icons.format_quote);
      case 3:
        return _buildPlaceholderTab('地图', Icons.map);
      case 4:
        return _buildPlaceholderTab('作品', Icons.menu_book);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Biography tab: show description in paragraphs ──
  Widget _buildBiographyContent(Figure figure) {
    // Split description by double newlines to form paragraphs
    final paragraphs = figure.description
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          '暂无详细资料',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.map((paragraph) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              paragraph.trim(),
              style: const TextStyle(
                fontSize: 15,
                color: _textPrimary,
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Placeholder tab for non-biography tabs ──
  Widget _buildPlaceholderTab(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: _textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                '$label内容即将上线',
                style: const TextStyle(
                  fontSize: 15,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal data class for stats items.
class _StatItem {
  final String label;
  final String value;
  final bool isRating;

  const _StatItem(this.label, this.value, {this.isRating = false});
}
