import 'package:flutter/material.dart';
import '../theme/color_schemes.dart';
import '../data/mock_figures.dart';
import '../models/figure.dart';
import 'figure_detail_page.dart';

/// Historical figures list page matching the Web version's FiguresList.tsx.
///
/// Layout (top to bottom):
/// 1. Brand header (Sage —— Route + bell + avatar)
/// 2. Title section (small "历史人物" + big title + description)
/// 3. Search bar (white rounded with search icon)
/// 4. Dynasty filter capsules (horizontal scroll, active dark fill)
/// 5. Theme filter capsules (horizontal scroll, with emoji icons)
/// 6. Featured figure card (image + gradient + bottom info)
/// 7. "全部人物" section header
/// 8. 2-column figure grid (image + dynasty tag + bookmark + name + stats)
/// 9. "加载更多" button
///
/// All filters are static UI — no real filtering logic.
class FiguresListPage extends StatelessWidget {
  const FiguresListPage({super.key, this.onNavigateAway, this.onNavigateBack});

  /// Called before navigating away from this page (e.g. to detail page).
  final VoidCallback? onNavigateAway;

  /// Called when returning to this page from a detail page.
  final VoidCallback? onNavigateBack;

  static const List<String> _dynasties = ['全部', '唐朝', '宋朝', '汉朝', '周朝', '明朝'];

  // Web 版主题: 全部主题 / 诗词 / 哲学 / 帝王 / 军事
  static const List<Map<String, String>> _themes = [
    {'emoji': '', 'label': '全部主题'},
    {'emoji': '🍁', 'label': '诗词'},
    {'emoji': '📜', 'label': '哲学'},
    {'emoji': '👑', 'label': '帝王'},
    {'emoji': '⚔️', 'label': '军事'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTitleSection(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildDynastyFilters(),
              const SizedBox(height: 16),
              _buildThemeFilters(),
              const SizedBox(height: 28),
              _buildFeaturedCardHeader(),
              const SizedBox(height: 12),
              _buildFeaturedCard(context, mockFigures[0]),
              const SizedBox(height: 24),
              // Optional: 3 horizontal route recommendations (skip if mock not available, screenshot shows route chips below featured card)
              _buildFeaturedRoutes(),
              const SizedBox(height: 32),
              _buildAllFiguresHeader(),
              const SizedBox(height: 16),
              _buildFigureGrid(context),
              const SizedBox(height: 24),
              _buildLoadMoreButton(),
              // Bottom padding for BottomNav bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: "Sage —— Route" + bell icon + avatar ──
  // Web: bell bg-[#EBE5DA] rounded-full, avatar ring-2 ring-[#EBE5DA]
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _BrandTitle(),
          Row(
            children: [
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
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEBE5DA), width: 2),
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/150?img=47'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Title section: small subtitle + big title + description ──
  // Web: small "历史人物" with sage-accent color + 1px line, large "历史名人" h2.
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '历史人物',
                style: TextStyle(
                  color: AppColors.sageAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 24, height: 1, color: AppColors.sageAccent),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '历史名人',
            style: TextStyle(
              color: AppColors.sageText,
              fontSize: 30, // Web: text-3xl
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '探索历朝历代的学者、诗人与帝王',
            style: TextStyle(
              color: AppColors.sageMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar: pill-shaped with sage-card bg + Filter trailing ──
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sageCard, // #FAF7F2
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.sageBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: AppColors.sageMuted),
            const SizedBox(width: 12),
            const Expanded(
              child: TextField(
                style: TextStyle(fontSize: 14, color: AppColors.sageText),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none,
                  hintText: '搜索人物、朝代...',
                  hintStyle: TextStyle(
                    color: AppColors.sageMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            // Filter button (dark pill)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.sageText,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(Icons.tune, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dynasty filter capsules ──

  Widget _buildDynastyFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '朝代',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.sageMuted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _dynasties.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isActive = index == 0;
              return _FilterChip(label: _dynasties[index], isActive: isActive);
            },
          ),
        ),
      ],
    );
  }

  // ── Theme filter capsules (with emoji) ──
  Widget _buildThemeFilters() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _themes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = _themes[index];
          final isActive = index == 0;
          final emoji = filter['emoji']!;
          return _ThemeFilterChip(
            // "全部主题" uses layout_grid icon if emoji is empty
            emoji: emoji,
            label: filter['label']!,
            isActive: isActive,
          );
        },
      ),
    );
  }

  // ── "精选人物" Header ──
  Widget _buildFeaturedCardHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '精选人物',
            style: TextStyle(
              color: AppColors.sageMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(true),
              const SizedBox(width: 4),
              _buildDot(false),
              const SizedBox(width: 4),
              _buildDot(false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: active
            ? AppColors.sageAccent.withValues(alpha: 0.6)
            : AppColors.sageBorder.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }

  // ── "Featured routes" horizontal chips ──
  Widget _buildFeaturedRoutes() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFeaturedRouteChip('庐山隐居', '3天·5处遗址'),
          const SizedBox(width: 12),
          _buildFeaturedRouteChip('浔阳贬谪', '2天·4处遗址'),
          const SizedBox(width: 12),
          _buildFeaturedRouteChip('长安岁月', '4天·7处遗址'),
        ],
      ),
    );
  }

  Widget _buildFeaturedRouteChip(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sageBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.sageCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_outlined,
              size: 14,
              color: AppColors.sageAccent,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.sageText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.sageMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Navigate to figure detail page ──
  void _openFigure(BuildContext context, MockFigure mf) {
    onNavigateAway?.call();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FigureDetailPage(
          figure: Figure(
            id: mf.id,
            name: mf.name,
            pinyinName: mf.pinyinName,
            dynasty: mf.dynasty,
            role: mf.role,
            years: mf.years,
            shortDesc: mf.shortDesc,
            description: mf.description,
            imageUrl: mf.imageUrl,
            locationsCount: mf.locationsCount,
            routesCount: mf.routesCount,
            poemsCount: mf.poemsCount,
            rating: mf.rating,
          ),
        ),
      ),
    ).then((_) => onNavigateBack?.call());
  }

  // ── Featured figure card (full-width, 24px radius, image + gradient + info) ──
  // Web: aspect-[4/3], dynasty tag bg-[#C37153], role tag bg-black/30 backdrop-blur,
  //      bookmark button bottom-right, stats with MapPin + Route icons
  Widget _buildFeaturedCard(BuildContext context, MockFigure figure) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _openFigure(context, figure),
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  figure.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.sageBorder.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.sageMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.68),
                      ],
                      stops: const [0.0, 0.46, 0.76, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sageAccent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    figure.dynasty,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.bookmark_border,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      figure.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${figure.years} · ${figure.shortDesc}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    if (figure.role.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: figure.role.take(2).map((role) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _FeaturedStat(
                          icon: Icons.location_on_outlined,
                          iconColor: Colors.white,
                          text: '${figure.locationsCount} 处遗址',
                        ),
                        const SizedBox(width: 16),
                        _FeaturedStat(
                          icon: Icons.route_outlined,
                          iconColor: Colors.white,
                          text: '${figure.routesCount} 条路线',
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

  Widget _buildAllFiguresHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '全部人物',
                style: TextStyle(
                  color: AppColors.sageText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '共 48 位历史名人',
                style: TextStyle(color: AppColors.sageMuted, fontSize: 13),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.sageCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.sageBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: AppColors.sageText,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.view_list_rounded,
                    size: 16,
                    color: AppColors.sageMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2-column figure grid ──

  Widget _buildFigureGrid(BuildContext context) {
    // Use all 3 mock figures + repeats for visual fill (6 cards = 3 rows)
    final gridFigures = <MockFigure>[
      mockFigures[1], // 苏东坡
      mockFigures[2], // 李白
      mockFigures[0], // 白居易
      mockFigures[1], // 苏东坡 (repeat)
      mockFigures[2], // 李白 (repeat)
      mockFigures[0], // 白居易 (repeat)
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (int i = 0; i < gridFigures.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(child: _FigureCard(figure: gridFigures[i], onTap: () => _openFigure(context, gridFigures[i]))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: i + 1 < gridFigures.length
                        ? _FigureCard(figure: gridFigures[i + 1], onTap: () => _openFigure(context, gridFigures[i + 1]))
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── "加载更多" button ──
  // Web: border border-[#DCD6C8] rounded-xl
  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.sageText,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: Color(0xFFDCD6C8)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '加载更多人物',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Private helper widgets
// ═══════════════════════════════════════════════════════════

/// "Sage —— Route" brand title with a sage-accent decorative line.
/// Web: <span class="text-sage-accent mx-2 ... bg-sage-accent">
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.sageText,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Sage', style: style),
        SizedBox(width: 8),
        SizedBox(
          width: 16,
          height: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.sageAccent),
          ),
        ),
        SizedBox(width: 8),
        Text('Route', style: style),
      ],
    );
  }
}

/// A single dynasty filter chip (rounded-full pill).
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.sageText : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? null : Border.all(color: AppColors.sageBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : AppColors.sageText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// A theme filter chip with emoji icon (🍁 📜 👑).
/// Web 版激活态色: bg-[#C37153] text-white (sageAccent)
class _ThemeFilterChip extends StatelessWidget {
  const _ThemeFilterChip({
    required this.emoji,
    required this.label,
    required this.isActive,
  });

  final String emoji;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.sageAccent : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: isActive ? null : Border.all(color: AppColors.sageBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji.isEmpty)
            Icon(
              Icons.grid_view_rounded,
              size: 14,
              color: isActive ? Colors.white : AppColors.sageText,
            )
          else ...[
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
          ],
          if (emoji.isEmpty) const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.sageText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single figure card in the 2-column grid.
///
/// Layout: image (with dynasty tag + bookmark overlay) → name → years →
/// role tags → bottom stats row with "查看" button.
/// Web: dynasty tag bg-[#84A98C] rounded-full, bookmark text-[#C37153],
///      role tags bg-[#FAF7F2], bottom stats with MapPin + "查看" button.
class _FigureCard extends StatelessWidget {
  const _FigureCard({required this.figure, this.onTap});

  final MockFigure figure;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Image area with overlays ──
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      figure.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.sageBorder.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                // Dynasty tag — top-left (green, rounded-full)
                Positioned(
                  top: 18,
                  left: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sageGreen,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      figure.dynasty,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Bookmark icon — top-right (accent color)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bookmark_border,
                      size: 14,
                      color: AppColors.sageAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Content area ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Text(
                  figure.name,
                  style: const TextStyle(
                    color: AppColors.sageText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Years
                Text(
                  figure.years,
                  style: const TextStyle(
                    color: AppColors.sageMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Role tags
                if (figure.role.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: figure.role.take(2).map((r) {
                      final isFirst = r == figure.role.first;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? AppColors
                                    .sageCard // Let's use light brown/orange bg for first?
                              : AppColors.sageCard,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            color: isFirst
                                ? AppColors.sageAccent
                                : AppColors.sageMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 10),
                // Bottom stats row with divider + "查看" button
                const Divider(height: 1, color: AppColors.sageBorder),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 10,
                          color: AppColors.sageMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${figure.locationsCount} 处',
                          style: const TextStyle(
                            color: AppColors.sageMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sageCard,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '查看',
                            style: TextStyle(
                              color: AppColors.sageText,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward,
                            size: 10,
                            color: AppColors.sageText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Stat item used in the featured figure card (light text on dark image).
/// Web: text-white/70 with colored icons.
class _FeaturedStat extends StatelessWidget {
  const _FeaturedStat({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
