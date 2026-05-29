import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/mock_figures.dart' as mock;
import '../theme/color_schemes.dart';

/// Home page matching the Web version's Home.tsx layout.
///
/// Sections:
/// - Header: greeting + notification bell + avatar
/// - Search bar (UI placeholder, no real search logic)
/// - Recommended route hero card with gradient overlay, badges, stats
/// - Trending figures horizontal scroll
///
/// Navigation is handled via optional callbacks.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.onRouteTap,
    this.onFigureTap,
    this.onFiguresListTap,
    this.onSearchTap,
  });

  /// Callback when the hero route card is tapped.
  final void Function(String figureId)? onRouteTap;

  /// Callback when a trending figure card is tapped.
  final void Function(String figureId)? onFigureTap;

  /// Callback when the "全部" button in trending section is tapped.
  final VoidCallback? onFiguresListTap;

  /// Callback when the search bar is tapped.
  final VoidCallback? onSearchTap;

  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1574227492706-f65b24c3688a?auto=format&fit=crop&q=80&w=800';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildSearchBar(context),
              const SizedBox(height: 32),
              _buildSectionTitle('为你推荐的路线', AppColors.sageAccent),
              const SizedBox(height: 12),
              _buildHeroCard(context),
              const SizedBox(height: 32),
              _buildTrendingSectionHeader(context),
              const SizedBox(height: 12),
              _buildTrendingFigures(context),
              // Bottom nav spacing
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '你好，旅行者',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.sageMuted,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic, // Web: font-serif italic
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '准备好探索历史了吗？',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sageText,
                    letterSpacing: 1.5, // Web: tracking-wide
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Notification bell
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEBE5DA),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.notifications_outlined, size: 20),
              color: AppColors.sageText,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          // Avatar with accent ring
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sageAccent, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=150',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: onSearchTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
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
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: AppColors.sageMuted),
              const SizedBox(width: 12),
              Text(
                '搜索人物、城市、路线...',
                style: TextStyle(fontSize: 14, color: AppColors.sageMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Title (left border + text) ──

  Widget _buildSectionTitle(String title, Color accentColor) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.sageText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Route Card ──

  Widget _buildHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => onRouteTap?.call('bai-juyi'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.network(_heroImageUrl, fit: BoxFit.cover),
                // Gradient overlay (dark at bottom for text readability)
                // Web: from-black/80 via-black/20 to-black/10 (bottom→top)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.80),
                          Colors.black.withValues(alpha: 0.20),
                          Colors.black.withValues(alpha: 0.10),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                // Foreground content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: badges
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // "唐江南游" badge (accent color, pill shape)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sageAccent,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '唐江南游',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          // "4天3夜" badge (semi-transparent, glassmorphism)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '4天3夜',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Bottom content: title, description, stats
                      Text(
                        '白居易的江南遗迹',
                        style: TextStyle(
                          fontSize: 30, // Web: text-3xl (30px)
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '跟随诗人的脚步，探索杭州与苏州的历史。',
                        style: TextStyle(
                          fontSize: 14, // Web: text-sm
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatItem(
                            Icons.location_on_outlined,
                            AppColors.sageGold,
                            '8 处景点',
                          ),
                          const SizedBox(width: 16),
                          _buildStatItem(
                            Icons.directions_outlined,
                            AppColors.sageGreen,
                            '12 公里',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color iconColor, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  // ── Trending Section Header (green left border + "全部" link) ──

  Widget _buildTrendingSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.sageGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '时下流行人物',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.sageText,
              ),
            ),
          ),
          GestureDetector(
            onTap: onFiguresListTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '全部',
                  style: TextStyle(fontSize: 13, color: AppColors.sageMuted),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: AppColors.sageMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Trending Figures Horizontal Scroll ──

  Widget _buildTrendingFigures(BuildContext context) {
    final trending = mock.mockFigures.take(2).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 4),
      child: Row(
        children: trending.map((figure) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _FigureCard(
              figure: figure,
              onTap: () => onFigureTap?.call(figure.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Private helper: trending figure card
// ─────────────────────────────────────────────────────────────

/// Renders a single trending figure card with image, dynasty badge,
/// name, and short description.
class _FigureCard extends StatelessWidget {
  const _FigureCard({required this.figure, required this.onTap});

  final mock.MockFigure figure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            // Image with dynasty overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Image.network(figure.imageUrl, fit: BoxFit.cover),
                  ),
                  // Dynasty badge (top-left corner)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: BackdropFilter(
                        // Web: backdrop-blur on bg-black/40
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            figure.dynasty,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              figure.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.sageText,
              ),
            ),
            const SizedBox(height: 4),
            // Short description
            Text(
              figure.shortDesc,
              style: TextStyle(fontSize: 10, color: AppColors.sageMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
