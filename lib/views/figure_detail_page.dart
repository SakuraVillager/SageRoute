import 'package:flutter/material.dart';

import '../data/mock_figures.dart';
import '../data/mock_locations.dart';
import '../models/figure.dart';
import '../models/location.dart';
import '../utils/slide_route.dart';
import 'location_detail_page.dart';

class FigureDetailPage extends StatefulWidget {
  const FigureDetailPage({super.key, required this.figure});
  final Figure figure;

  @override
  State<FigureDetailPage> createState() => _FigureDetailPageState();
}

class _FigureDetailPageState extends State<FigureDetailPage> {
  final _scrollController = ScrollController();
  final _tabScrollController = ScrollController();

  // Section keys for scroll spy
  final _sectionKeys = List.generate(5, (_) => GlobalKey());

  int _activeTab = 0;
  bool _isProgrammaticScroll = false;

  // Cached scroll-space offsets for each section.
  // Screen position = _sectionScrollOffsets[i] - scrollOffset.
  final List<double?> _sectionScrollOffsets = List.filled(5, null);

  // ── Colors ──
  static const _bg = Color(0xFFFAF7F2);
  static const _accent = Color(0xFFCD6642);
  static const _green = Color(0xFF528265);
  static const _gold = Color(0xFFB08550);
  static const _star = Color(0xFFD4AF37);
  static const _text1 = Color(0xFF1A1A1A);
  static const _text2 = Color(0xFF4A4A4A);
  static const _muted = Color(0xFF8E8A82);
  static const _tagPoet = Color(0xFFE6F3EB);
  static const _tagPoetText = Color(0xFF4A8260);
  static const _tagOfficial = Color(0xFFF9F1E6);
  static const _tagOfficialText = Color(0xFFB08550);
  static const _tagPhilosopher = Color(0xFFFBF0ED);
  static const _tagPhilosopherText = Color(0xFFB36B5C);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSectionOffsets());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  static const double _tabBarH = 50;
  // The pinned offset when scrolled: collapsed bar height + tab bar
  // SliverAppBar collapsed height = kToolbarHeight (~56) + top padding
  double get _pinnedOffset {
    final topPad = MediaQuery.of(context).padding.top;
    return topPad + kToolbarHeight + _tabBarH;
  }

  void _updateSectionOffsets() {
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    for (int i = 0; i < _sectionKeys.length; i++) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) {
          final screenY = box.localToGlobal(Offset.zero).dy;
          // Convert screen position to scroll-space offset.
          _sectionScrollOffsets[i] = screenY + scrollOffset;
        }
      }
    }
  }

  void _onScroll() {
    if (_isProgrammaticScroll) return;

    final scrollOffset = _scrollController.offset;
    final threshold = _pinnedOffset;
    int newActive = 0;
    for (int i = _sectionScrollOffsets.length - 1; i >= 0; i--) {
      if (_sectionScrollOffsets[i] != null) {
        // screenY = scrollSpaceOffset - currentScrollOffset
        final screenY = _sectionScrollOffsets[i]! - scrollOffset;
        if (screenY <= threshold) {
          newActive = i;
          break;
        }
      }
    }

    if (newActive != _activeTab) {
      setState(() => _activeTab = newActive);
      _scrollTabIntoView(newActive);
    }
  }

  void _scrollTabIntoView(int index) {
    // Approximate tab position for horizontal scroll
    final approxOffset = index * 90.0;
    _tabScrollController.animateTo(
      approxOffset.clamp(0.0, _tabScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onTabTap(int index) {
    setState(() => _activeTab = index);
    _scrollTabIntoView(index);

    final ctx = _sectionKeys[index].currentContext;
    if (ctx != null) {
      _isProgrammaticScroll = true;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        // Align so the section top sits just below the pinned header
        alignment: _pinnedOffset / MediaQuery.sizeOf(context).height,
      ).then((_) {
        _isProgrammaticScroll = false;
        _updateSectionOffsets();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final figure = widget.figure;
    final mock = _findMockFigure(figure.id);

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Collapsing header with nav bar ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 56,
            leading: Center(
              child: _BackBtn(onTap: () => Navigator.of(context).pop()),
            ),
            actions: [
              _ActionBtn(Icons.bookmark_border, () {}),
              const SizedBox(width: 4),
              _ActionBtn(Icons.ios_share, () {}),
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
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFd6cebf), Color(0xFFe8e2d5), _bg],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0, bottom: 20,
                      child: Container(
                        width: 240, height: 180,
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.bottomRight, radius: 1.0,
                            colors: [Color(0x1F5A5446), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tab bar pinned at the bottom of the AppBar
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(_tabBarH),
              child: _TabBar(
                activeTab: _activeTab,
                tabScrollController: _tabScrollController,
                onTabTap: _onTabTap,
              ),
            ),
          ),

          // ── Profile ──
          SliverToBoxAdapter(child: _buildProfile(figure)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Stats card
          SliverToBoxAdapter(child: _buildStatsCard(figure)),
          // Action buttons
          SliverToBoxAdapter(child: _buildActionButtons()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Content sections ──
          SliverToBoxAdapter(
            child: _Section(key: _sectionKeys[0], child: _buildBiography(figure, mock)),
          ),
          SliverToBoxAdapter(
            child: _Section(key: _sectionKeys[1], child: _buildSites()),
          ),
          SliverToBoxAdapter(
            child: _Section(key: _sectionKeys[2], child: _buildQuotes()),
          ),
          SliverToBoxAdapter(
            child: _Section(key: _sectionKeys[3], child: _buildRouteMap()),
          ),
          SliverToBoxAdapter(
            child: _Section(key: _sectionKeys[4], child: _buildWorks()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  MockFigure? _cachedMockFigure;
  String? _cachedMockFigureId;

  MockFigure? _findMockFigure(String id) {
    if (_cachedMockFigureId == id) return _cachedMockFigure;
    _cachedMockFigureId = id;
    try {
      _cachedMockFigure = mockFigures.firstWhere((f) => f.id == id);
    } catch (_) {
      _cachedMockFigure = null;
    }
    return _cachedMockFigure;
  }

  // ═══════════════════════════════════════════════════════════
  // Profile
  // ═══════════════════════════════════════════════════════════

  Widget _buildProfile(Figure figure) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(figure.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: _text1, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                if (figure.pinyinName.isNotEmpty)
                  Text(figure.pinyinName, style: const TextStyle(fontSize: 32, fontFamily: 'Georgia', fontStyle: FontStyle.italic, color: _text1)),
                const SizedBox(height: 8),
                Text('${figure.years} · ${figure.shortDesc}', style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (figure.role.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (figure.role.length >= 2)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      _RoleTag(figure.role[0], _tagPoet, _tagPoetText),
                      const SizedBox(width: 6),
                      _RoleTag(figure.role[1], _tagOfficial, _tagOfficialText),
                    ]),
                  if (figure.role.length >= 3) ...[
                    const SizedBox(height: 6),
                    _RoleTag(figure.role[2], _tagPhilosopher, _tagPhilosopherText),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Stats card
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatsCard(Figure figure) {
    final poemsText = figure.poemsCount > 1000
        ? '${(figure.poemsCount / 1000).toStringAsFixed(0)}000+'
        : figure.poemsCount.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E1D8), width: 0.5),
        boxShadow: const [BoxShadow(color: Color(0x0D8C826E), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          _StatItem(icon: Icons.location_on_outlined, color: _accent, value: figure.locationsCount.toString(), label: '遗址'),
          _StatDivider(),
          _StatItem(icon: Icons.directions_walk, color: _green, value: figure.routesCount.toString(), label: '旅程'),
          _StatDivider(),
          _StatItem(icon: Icons.auto_stories_outlined, color: _gold, value: poemsText, label: '诗编'),
          _StatDivider(),
          _StatItem(icon: Icons.star, color: _star, value: figure.rating.toStringAsFixed(1), label: '评分'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Action buttons (flex-based, no overflow)
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
                onPressed: () {},
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Flexible(child: Text('规划路线', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF171717),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.map_outlined, size: 18, color: _green),
                label: const Flexible(child: Text('地图', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _text1,
                  side: const BorderSide(color: Color(0xFFE6E1D8)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Section: Biography
  // ═══════════════════════════════════════════════════════════

  static final _paragraphSeparator = RegExp(r'\n\s*\n');
  List<Widget>? _cachedBioParagraphs;
  String? _cachedBioSource;

  Widget _buildBiography(Figure figure, MockFigure? mock) {
    final description = mock?.description ?? figure.description;

    // Cache the expensive split/map operation.
    if (_cachedBioSource != description) {
      _cachedBioSource = description;
      _cachedBioParagraphs = description.trim().isEmpty
          ? null
          : description
              .split(_paragraphSeparator)
              .where((p) => p.trim().isNotEmpty)
              .map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(p.trim(),
                        style: const TextStyle(
                            fontSize: 15, color: _text2, height: 1.8)),
                  ))
              .toList();
    }

    return _ContentSection(
      title: '生平',
      subtitle: '人物简介',
      child: _cachedBioParagraphs == null
          ? const Text('暂无详细资料',
              style: TextStyle(color: _muted, fontSize: 14))
          : Column(children: _cachedBioParagraphs!),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Section: Sites (遗址)
  // ═══════════════════════════════════════════════════════════

  List<MockLocation>? _cachedSites;

  List<MockLocation> get _displaySites {
    _cachedSites ??= () {
      final sites = mockLocations.where((l) => l.figureId == widget.figure.id).toList();
      return sites.isNotEmpty ? sites : mockLocations;
    }();
    return _cachedSites!;
  }

  Widget _buildSites() {

    return _ContentSection(
      title: '遗址',
      subtitle: '相关遗址',
      actionText: '查看全部',
      child: Column(children: _displaySites.map((loc) => _SiteCard(
        location: loc,
        onTap: () => Navigator.of(context).push(
          slideFromRightRoute(
            LocationDetailPage(
              location: Location(
                id: loc.id,
                name: loc.name,
                pinyinName: loc.pinyinName,
                region: loc.region,
                years: loc.years,
                tags: loc.tags,
                distance: loc.distance,
                recommendedTime: loc.recommendedTime,
                relatedPoems: loc.relatedPoems,
                rating: loc.rating,
                imageUrl: loc.imageUrl,
                description: loc.description,
              ),
              figureName: widget.figure.name,
            ),
          ),
        ),
      )).toList()),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Section: Quotes (名言)
  // ═══════════════════════════════════════════════════════════

  Widget _buildQuotes() {
    const quotes = [
      ('"同是天涯沦落人，相逢何必曾相识。"', '——《琵琶行》'),
      ('"野火烧不尽，春风吹又生。"', '——《赋得古原草送别》'),
      ('"日出江花红胜火，春来江水绿如蓝。"', '——《忆江南》'),
    ];

    return _ContentSection(
      title: '名言',
      subtitle: '千古佳句',
      child: Column(children: quotes.map((q) => _QuoteBox(text: q.$1, source: q.$2)).toList()),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Section: Route map (地图)
  // ═══════════════════════════════════════════════════════════

  Widget _buildRouteMap() {
    return _ContentSection(
      title: '地图',
      subtitle: '行迹路线',
      child: SizedBox(
        height: 180,
        child: LayoutBuilder(
          builder: (_, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE6E1D6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6CFC1), width: 0.5),
              ),
              child: Stack(
                children: [
                  // Dashed route line
                  Positioned(
                    left: 40, right: 40, top: h * 0.5,
                    child: const _DashedLine(),
                  ),
                  _MapDot(label: '长安', x: w * 0.15, y: h * 0.35),
                  _MapDot(label: '九江', x: w * 0.40, y: h * 0.55),
                  _MapDot(label: '杭州', x: w * 0.65, y: h * 0.30),
                  _MapDot(label: '洛阳', x: w * 0.85, y: h * 0.45),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Section: Works (作品)
  // ═══════════════════════════════════════════════════════════

  Widget _buildWorks() {
    const works = [
      ('《长恨歌》', '叙事长诗'),
      ('《琵琶行》', '叙事长诗'),
      ('《卖炭翁》', '新乐府诗'),
      ('《钱塘湖春行》', '律诗'),
    ];

    return _ContentSection(
      title: '作品',
      subtitle: '诗歌总集',
      child: Column(children: works.map((w) => _WorkItem(name: w.$1, type: w.$2)).toList()),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Content section wrapper
// ═══════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  const _Section({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
      child: child,
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionText,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF946E4A), letterSpacing: 0.5)),
              const SizedBox(width: 6),
              const Text('—', style: TextStyle(fontSize: 14, color: _detailPageDivider)),
              const SizedBox(width: 6),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: _detailPageMuted)),
            ]),
            if (actionText != null)
              Text(actionText!, style: const TextStyle(fontSize: 13, color: Color(0xFFA07855), fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }

  static const _detailPageDivider = Color(0xFFECE7DF);
  static const _detailPageMuted = Color(0xFF8E8A82);
}

// ═══════════════════════════════════════════════════════════
// Tab bar (used as SliverAppBar.bottom)
// ═══════════════════════════════════════════════════════════

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.activeTab,
    required this.tabScrollController,
    required this.onTabTap,
  });

  final int activeTab;
  final ScrollController tabScrollController;
  final ValueChanged<int> onTabTap;

  static const _tabs = ['生平', '遗址', '名言', '地图', '作品'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF7F2),
      child: Column(
        children: [
          SizedBox(
            height: 49,
            child: ListView.builder(
              controller: tabScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _tabs.length,
              itemBuilder: (_, i) {
                final isActive = i == activeTab;
                return GestureDetector(
                  onTap: () => onTabTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.only(right: 28),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_tabs[i], style: TextStyle(
                          fontSize: 15,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? const Color(0xFF111111) : const Color(0xFF8E8A82),
                        )),
                        const SizedBox(height: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2.5,
                          width: isActive ? 20 : 0,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFCD6642) : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: const Color(0xFFEFEBE4)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Back button (matches wizard style)
// ═══════════════════════════════════════════════════════════

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8E2D9)),
        ),
        child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF2D2825)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Action button (bookmark / share)
// ═══════════════════════════════════════════════════════════

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8E2D9)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF2D2825)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Role tag
// ═══════════════════════════════════════════════════════════

class _RoleTag extends StatelessWidget {
  const _RoleTag(this.label, this.bg, this.fg);
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Stat item
// ═══════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF2A2A2A))),
        ]),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFA09B90), fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: const Color(0xFFECE7DF));
  }
}

// ═══════════════════════════════════════════════════════════
// Site card
// ═══════════════════════════════════════════════════════════

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.location, required this.onTap});
  final MockLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E3DA), width: 0.5),
          boxShadow: const [BoxShadow(color: Color(0x088C826E), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFFEFEBE4), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(location.name.characters.first, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6E6659)))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(location.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(location.region, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8A82)), overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: 10),
            if (location.tags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEAE6DF), borderRadius: BorderRadius.circular(8)),
                child: Text(location.tags.first, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF7A756C))),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Quote box
// ═══════════════════════════════════════════════════════════

class _QuoteBox extends StatelessWidget {
  const _QuoteBox({required this.text, required this.source});
  final String text;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4EFE6),
        borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
        border: Border(left: BorderSide(color: Color(0xFFCD6642), width: 3.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F), height: 1.5, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(source, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8A82), fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Dashed line (route map)
// ═══════════════════════════════════════════════════════════

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(),
      size: const Size(double.infinity, 2),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = const Color(0xFF938B7C)
      ..strokeWidth = 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════
// Map dot
// ═══════════════════════════════════════════════════════════

class _MapDot extends StatelessWidget {
  const _MapDot({required this.label, required this.x, required this.y});
  final String label;
  final double x;
  final double y;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - 20,
      top: y - 10,
      child: Column(children: [
        Container(
          width: 9, height: 9,
          decoration: BoxDecoration(
            color: const Color(0xFFCD6642),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4A463F), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Work item
// ═══════════════════════════════════════════════════════════

class _WorkItem extends StatelessWidget {
  const _WorkItem({required this.name, required this.type});
  final String name;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE6E1D8), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 15, color: Color(0xFF2C2C2C), fontWeight: FontWeight.w600)),
          Text(type, style: const TextStyle(fontSize: 13, color: Color(0xFF528265), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
