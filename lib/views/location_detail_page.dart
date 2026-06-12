import 'package:flutter/material.dart';

import '../components/detail_content_section.dart';
import '../components/detail_circle_button.dart';
import '../components/detail_scroll_tab_bar.dart';
import '../models/location.dart';
import '../utils/detail_scroll_spy_controller.dart';

/// 景点详情页，与人物详情页统一风格。
class LocationDetailPage extends StatefulWidget {
  const LocationDetailPage({
    super.key,
    required this.location,
    this.figureName,
    this.onBack,
    this.onAddToRoute,
  });

  final Location location;
  final String? figureName;
  final VoidCallback? onBack;
  final VoidCallback? onAddToRoute;

  @override
  State<LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends State<LocationDetailPage> {
  final _scrollSpy = DetailScrollSpyController(sectionCount: 5);

  int _activeTab = 0;

  static const _tabs = ['故事', '背景', '意义', '图像', '旅行'];

  // ── Colors ──
  static const _bg = Color(0xFFFAF7F2);
  static const _accent = Color(0xFFCD6642);
  static const _green = Color(0xFF5A6B54);
  static const _teal = Color(0xFF547278);
  static const _warm = Color(0xFFA2804E);
  static const _rose = Color(0xFFB85C48);
  static const _text1 = Color(0xFF1A1A1A);
  static const _text2 = Color(0xFF4A4A4A);
  static const _star = Color(0xFFD4AF37);
  static const _muted = Color(0xFF8E8A82);

  // Tag color presets
  static const _tagStyles = [
    (Color(0xFFEAECE6), Color(0xFF5A6B54)), // landmark
    (Color(0xFFF9ECE8), Color(0xFFB85C48)), // associated
    (Color(0xFFF6EFE0), Color(0xFFA2804E)), // heritage
    (Color(0xFFE9EFF0), Color(0xFF547278)), // free
  ];

  @override
  void initState() {
    super.initState();
    _scrollSpy.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollSpy.updateSectionOffsets(),
    );
  }

  @override
  void dispose() {
    _scrollSpy.scrollController.removeListener(_onScroll);
    _scrollSpy.dispose();
    super.dispose();
  }

  double get _pinnedOffset {
    final topPad = MediaQuery.of(context).padding.top;
    return topPad + kToolbarHeight + 50;
  }

  void _onScroll() {
    final newActive = _scrollSpy.activeSectionIndex(
      pinnedOffset: _pinnedOffset,
      currentIndex: _activeTab,
    );
    if (newActive != _activeTab) {
      setState(() => _activeTab = newActive);
      _scrollSpy.scrollTabIntoView(newActive);
    }
  }

  void _onTabTap(int index) {
    setState(() => _activeTab = index);
    _scrollSpy.scrollTabIntoView(index);
    _scrollSpy.scrollToSection(
      index: index,
      context: context,
      pinnedOffset: _pinnedOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.location;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        controller: _scrollSpy.scrollController,
        slivers: [
          // ── Hero image AppBar ──
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: _bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 56,
            leading: Center(
              child: DetailCircleButton.back(
                onTap: () =>
                    (widget.onBack ?? () => Navigator.of(context).pop()).call(),
              ),
            ),
            actions: [
              DetailCircleButton(icon: Icons.bookmark_border, onTap: () {}),
              const SizedBox(width: 4),
              DetailCircleButton(icon: Icons.ios_share, onTap: () {}),
              const SizedBox(width: 12),
            ],
            title: const Text(
              'Sage _ Route',
              style: TextStyle(
                color: _text1,
                fontSize: 20,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    l.imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFFE8E2D9)),
                  ),
                  // Gradient fade to bg
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.transparent,
                            Colors.transparent,
                            _bg.withValues(alpha: 0.6),
                            _bg,
                          ],
                          stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Photo count badge
                  Positioned(
                    right: 20,
                    bottom: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '24 张照片',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Breadcrumb
                  if (widget.figureName != null)
                    Positioned(
                      left: 24,
                      bottom: 30,
                      child: Row(
                        children: [
                          Text(
                            widget.figureName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            ' > ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBCB8B0),
                            ),
                          ),
                          const Text(
                            '相关景点',
                            style: TextStyle(
                              fontSize: 12,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            ' > ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBCB8B0),
                            ),
                          ),
                          Text(
                            l.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: DetailScrollTabBar(
                tabs: _tabs,
                activeTab: _activeTab,
                scrollController: _scrollSpy.tabScrollController,
                onTabTap: _onTabTap,
                itemRightPadding: 32,
              ),
            ),
          ),

          // ── Title + rating ──
          SliverToBoxAdapter(child: _buildTitleSection(l)),
          // Tags
          SliverToBoxAdapter(child: _buildTags(l)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // Stats dashboard
          SliverToBoxAdapter(child: _buildStatsCard(l)),
          // Action buttons
          SliverToBoxAdapter(child: _buildActionButtons()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Content sections ──
          SliverToBoxAdapter(
            child: _Section(
              key: _scrollSpy.sectionKeys[0],
              child: _buildStory(l),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              key: _scrollSpy.sectionKeys[1],
              child: _buildBackground(l),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              key: _scrollSpy.sectionKeys[2],
              child: _buildSignificance(l),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              key: _scrollSpy.sectionKeys[3],
              child: _buildImages(),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              key: _scrollSpy.sectionKeys[4],
              child: _buildTravel(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Title section
  // ═══════════════════════════════════════════════════════════

  Widget _buildTitleSection(Location l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _text1,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                if (l.pinyinName.isNotEmpty)
                  Text(
                    l.pinyinName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF222222),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: _muted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l.region,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _muted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Rating card
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE6E1D8),
                    width: 0.4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F8C826E),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: _star),
                    const SizedBox(width: 4),
                    Text(
                      l.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _text1,
                      ),
                    ),
                  ],
                ),
              ),
              if (l.years.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l.years,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBCB8B0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Tags
  // ═══════════════════════════════════════════════════════════

  Widget _buildTags(Location l) {
    if (l.tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: l.tags.asMap().entries.map((e) {
          final style = _tagStyles[e.key % _tagStyles.length];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: style.$1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: style.$2,
                letterSpacing: 0.3,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Stats dashboard
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatsCard(Location l) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E3DA), width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A8C826E),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _DashStat(
            icon: Icons.bar_chart,
            color: _warm,
            value: l.distance,
            label: '全长',
          ),
          const DetailStatDivider(),
          _DashStat(
            icon: Icons.access_time,
            color: _teal,
            value: l.recommendedTime,
            label: '游览时间',
          ),
          const DetailStatDivider(),
          _DashStat(
            icon: Icons.auto_stories_outlined,
            color: _rose,
            value: '${l.relatedPoems}',
            label: '相关诗篇',
          ),
          const DetailStatDivider(),
          const _DashStat(
            icon: Icons.camera_alt_outlined,
            color: _green,
            value: '4.8',
            label: '摄影',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Action buttons
  // ═══════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: widget.onAddToRoute,
                icon: const Icon(Icons.alt_route, size: 18),
                label: const Flexible(
                  child: Text(
                    '加入路线',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF171615),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.navigation, size: 18, color: _green),
                label: const Flexible(
                  child: Text(
                    '导航',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF333333),
                  side: const BorderSide(color: Color(0xFFE6E1D8)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Content sections
  // ═══════════════════════════════════════════════════════════

  Widget _buildStory(Location l) {
    return DetailContentSection(
      title: '故事',
      subtitle: '堤因人传',
      child: Text(
        l.description.isNotEmpty ? l.description : '暂无故事内容',
        style: const TextStyle(fontSize: 15, color: _text2, height: 1.8),
      ),
    );
  }

  Widget _buildBackground(Location l) {
    return const DetailContentSection(
      title: '背景',
      subtitle: '历史溯源',
      child: Text(
        '白堤东起断桥桥堍，西接孤山，全长近1公里。虽然历史上的唐代古沙堤与如今我们所漫步的白堤在地理位置上略有偏移，但它作为西湖三大景观堤之一的核心地位从未动摇。',
        style: TextStyle(fontSize: 15, color: _text2, height: 1.8),
      ),
    );
  }

  Widget _buildSignificance(Location l) {
    return const DetailContentSection(
      title: '意义',
      subtitle: '文化坐标',
      child: Text(
        '白堤不仅仅是一项水利桥梁工程，它更是中国山水美学与文学史交融的结晶。白居易本人一首《钱塘湖春行》中的名句赋予了这条长堤永恒的精神生命。',
        style: TextStyle(fontSize: 15, color: _text2, height: 1.8),
      ),
    );
  }

  Widget _buildImages() {
    const images = [
      'https://images.unsplash.com/photo-1504618223053-559bdef9dd5a?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&w=300&q=80',
    ];
    return DetailContentSection(
      title: '图像',
      subtitle: '画卷捕捉',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (_, i) => Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E3DA), width: 0.5),
            image: DecorationImage(
              image: NetworkImage(images[i]),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTravel() {
    return const DetailContentSection(
      title: '旅行',
      subtitle: '游览游记',
      child: SizedBox(
        height: 100,
        child: Center(
          child: Text('暂无游记内容', style: TextStyle(fontSize: 14, color: _muted)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Section wrapper
// ═══════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  const _Section({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 6),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Tab bar (same pattern as FigureDetailPage)
// ═══════════════════════════════════════════════════════════

class _DashStat extends StatelessWidget {
  const _DashStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFA09B90),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
