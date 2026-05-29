import 'package:flutter/material.dart';
import '../models/location.dart';
import '../theme/color_schemes.dart';

/// 地点详情页，匹配 Web 版 LocationDetail.tsx 的视觉风格。
///
/// 展示沉浸式头部图片、地点信息、标签云、统计数据卡片、
/// 底部操作按钮、标签页和详细描述。
class LocationDetailPage extends StatelessWidget {
  const LocationDetailPage({
    super.key,
    required this.location,
    this.figureName,
    this.onBack,
    this.onAddToRoute,
    this.onFigureTap,
    this.onBookmark,
    this.onShare,
  });

  /// 要展示的地点。
  final Location location;

  /// 关联人物名称（用于面包屑导航）。
  final String? figureName;

  /// 返回上一页或切换到人物详情。
  final VoidCallback? onBack;

  /// 加入路线。
  final VoidCallback? onAddToRoute;

  /// 点击人物名称时触发（跳转到人物详情）。
  final VoidCallback? onFigureTap;

  /// 收藏/书签。
  final VoidCallback? onBookmark;

  /// 分享。
  final VoidCallback? onShare;

  // Web 标签页列表（仅第一个标签 "故事" 有内容）。
  static const List<String> _tabs = ['故事', '背景', '意义', '图像', '旅行'];

  // Tag 背景色（对应 Web i===1 / i===2 / default）。
  static const List<Color> _tagBgColors = [
    Color(0xFFF0DED3), // i === 1
    Color(0xFFEAE4D8), // i === 2
    Color(0xFFEBE5DA), // default
  ];
  static const List<Color> _tagTextColors = [
    Color(0xFFC37153), // i === 1
    Color(0xFFA38D64), // i === 2
    Color(0xFF8A8376), // default
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // ── Scrollable body ──
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderImage(context, screenHeight),
                _buildContent(context),
              ],
            ),
          ),

          // ── Fixed top bar overlay ──
          _buildTopBar(context),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Header image
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeaderImage(BuildContext context, double screenHeight) {
    final cs = Theme.of(context).colorScheme;
    final l = location;

    return SizedBox(
      height: screenHeight * 0.45,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.network(
            l.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Gradient mask: black/40 at top → transparent → surface at bottom
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      cs.surface,
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Dynasty badge (top-left on the image)
          Positioned(
            top: 100,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                '唐代',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Photo count pill (bottom-right on the image)
          Positioned(
            bottom: 48,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 14, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    '24 张照片',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Top bar (back, title, bookmark, share)
  // ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              // Back button (primary bg — matches Web)
              _buildCircleButton(
                onPressed: onBack,
                bgColor: cs.primary,
                child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
              ),

              const Spacer(),

              // "Sage _ Route" title
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 4,
                  ),
                  children: [
                    const TextSpan(text: 'Sage '),
                    TextSpan(
                      text: '_',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    const TextSpan(text: ' Route'),
                  ],
                ),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),

              const Spacer(),

              // Bookmark & Share
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircleButton(
                    onPressed: onBookmark,
                    bgColor: Colors.black.withValues(alpha: 0.2),
                    child: const Icon(Icons.bookmark_border, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  _buildCircleButton(
                    onPressed: onShare,
                    bgColor: Colors.black.withValues(alpha: 0.2),
                    child: const Icon(Icons.share_outlined, size: 18, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Content below header
  // ─────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = location;

    return Transform.translate(
      offset: const Offset(0, -32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Breadcrumb ──
            _buildBreadcrumb(context),
            const SizedBox(height: 16),

            // ── Title + rating row ──
            _buildTitleRow(context),
            const SizedBox(height: 4),

            // ── Pinyin name ──
            Text(
              l.pinyinName,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 20,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),

            // ── Region with map pin ──
            Row(
              children: [
                Icon(Icons.pin_drop_outlined, size: 14, color: cs.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 6),
                Text(
                  l.region,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Tags ──
            _buildTags(),
            const SizedBox(height: 24),

            // ── Stats card ──
            _buildStatsCard(context),
            const SizedBox(height: 24),

            // ── Action buttons ──
            _buildActionButtons(context),
            const SizedBox(height: 32),

            // ── Tabs ──
            _buildTabs(context),
            const SizedBox(height: 24),

            // ── Description ──
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                l.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: cs.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Breadcrumb: figureName > 相关景点 > location.name ──
  Widget _buildBreadcrumb(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (figureName != null) ...[
          GestureDetector(
            onTap: onFigureTap,
            child: Text(
              figureName!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '>',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
        Text(
          '相关景点',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '>',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.25),
            ),
          ),
        ),
        Text(
          location.name,
          style: TextStyle(
            fontSize: 12,
            color: cs.primary,
          ),
        ),
      ],
    );
  }

  // ── Title + rating badge + years ──
  Widget _buildTitleRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = location;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            l.name,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Rating badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: cs.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.sageGold),
                  const SizedBox(width: 4),
                  Text(
                    l.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.years,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Tag cloud ──
  Widget _buildTags() {
    final l = location;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: l.tags.asMap().entries.map((entry) {
        final i = entry.key;
        final tag = entry.value;
        // Web 索引规则: 1 -> 暖色, 2 -> 金色, 其余 -> 中性
        final bgIndex = i == 1 ? 0 : (i == 2 ? 1 : 2);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _tagBgColors[bgIndex],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              color: _tagTextColors[bgIndex],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Stats card ──
  Widget _buildStatsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = location;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Distance
          _buildStatItem(
            icon: _buildBarsIcon(cs.primary),
            value: l.distance,
            label: '全长',
            color: cs.primary,
          ),
          _buildDivider(cs),
          // Recommended time
          _buildStatItem(
            icon: Icon(Icons.access_time, size: 16, color: cs.tertiary),
            value: l.recommendedTime,
            label: '游览时间',
            color: cs.tertiary,
          ),
          _buildDivider(cs),
          // Related poems
          _buildStatItem(
            icon: const Text('🍃', style: TextStyle(fontSize: 16)),
            value: '${l.relatedPoems}',
            label: '相关诗篇',
            color: const Color(0xFFA38D64),
          ),
          _buildDivider(cs),
          // Photo score
          _buildStatItem(
            icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF6B8E9B)),
            value: '4.8',
            label: '摄影',
            color: const Color(0xFF6B8E9B),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ──
  Widget _buildActionButtons(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        // "加入路线" — dark background matching Web CTA style
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onAddToRoute,
            icon: const Icon(Icons.alt_route, size: 18),
            label: const Text('加入路线'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: cs.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // "导航" — white bg, outline border
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.pin_drop_outlined, size: 18, color: Color(0xFF6B8E9B)),
            label: const Text('导航', style: TextStyle(color: Color(0xFF6B8E9B))),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B8E9B),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: cs.outline),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ── Tabs (only first tab "故事" is active) ──
  Widget _buildTabs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: _tabs.map((tab) {
        final isActive = tab == _tabs.first;
        return Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? cs.primary : cs.primary.withValues(alpha: 0.3),
                    width: isActive ? 2 : 1,
                  ),
                ),
              ),
              child: Text(
                tab,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Shared helpers
  // ─────────────────────────────────────────────────────────────

  /// Circular icon button for the top bar.
  Widget _buildCircleButton({
    required Widget child,
    VoidCallback? onPressed,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  /// Single stat item inside the stats card.
  Widget _buildStatItem({
    required Widget icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.sageMuted,
          ),
        ),
      ],
    );
  }

  /// Vertical divider for stats card.
  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 32,
      color: colorScheme.outline,
    );
  }

  /// 3-bar icon mimicking Web's distance decorative bars.
  Widget _buildBarsIcon(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 3,
          height: 4.0 + i * 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
