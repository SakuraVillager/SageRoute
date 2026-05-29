import 'package:flutter/material.dart';

import '../data/mock_figures.dart';
import '../models/figure.dart';

/// 名人详情页，匹配 HTML mockup 设计。
///
/// 沉浸式渐变头部 + 朝代标签、个人信息区（左名右标签）、
/// 统计卡片（带图标）、操作按钮、Tab 导航、内容区。
class FigureDetailPage extends StatefulWidget {
  const FigureDetailPage({super.key, required this.figure});

  final Figure figure;

  @override
  State<FigureDetailPage> createState() => _FigureDetailPageState();
}

class _FigureDetailPageState extends State<FigureDetailPage> {
  int _selectedTab = 0;

  static const List<String> _tabs = ['生平', '遗址', '名言', '地图', '作品'];

  // ── Colors ──
  static const Color _pageBg = Color(0xFFFAF7F2);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFEFEBE4);
  static const Color _textPrimary = Color(0xFF222222);
  static const Color _textSecondary = Color(0xFF8E8A82);
  static const Color _accent = Color(0xFFCD6642);
  static const Color _green = Color(0xFF629A7A);
  static const Color _gold = Color(0xFFC09A67);
  static const Color _star = Color(0xFFD4AF37);
  static const Color _tagPoet = Color(0xFFE2EFE7);
  static const Color _tagPoetText = Color(0xFF629A7A);
  static const Color _tagOfficial = Color(0xFFF7EFE2);
  static const Color _tagOfficialText = Color(0xFFC09A67);
  static const Color _tagPhilosopher = Color(0xFFF7EAE6);
  static const Color _tagPhilosopherText = Color(0xFFC28274);
  static const Color _navBtnBg = Color(0x40000000);
  static const Color _tabInactive = Color(0xFF8E8A82);
  static const Color _divider = Color(0xFFEFEBE4);

  static const List<Color> _tagColors = [
    _tagPoet,
    _tagOfficial,
    _tagPhilosopher,
  ];
  static const List<Color> _tagTextColors = [
    _tagPoetText,
    _tagOfficialText,
    _tagPhilosopherText,
  ];

  @override
  Widget build(BuildContext context) {
    final figure = widget.figure;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        children: [
          // ── Scrollable content ──
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient header (mimics ink-wash mountain fog)
                _buildHeader(),
                // Profile section
                _buildProfile(figure),
                const SizedBox(height: 20),
                // Stats card
                _buildStatsCard(figure),
                // Action buttons
                _buildActionButtons(),
                const SizedBox(height: 24),
                // Tab bar
                _buildTabBar(),
                // Divider
                Container(height: 1, color: _divider),
                const SizedBox(height: 24),
                // Tab content
                _buildTabContent(figure),
                const SizedBox(height: 40),
              ],
            ),
          ),
          // ── Top nav ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _buildNavBtn(Icons.arrow_back, () => Navigator.of(context).pop()),
                  // Brand title
                  const Text(
                    'Sage _ Route',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Georgia',
                      letterSpacing: 1,
                      shadows: [
                        Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  // Right buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavBtn(Icons.bookmark_border, () {}),
                      const SizedBox(width: 10),
                      _buildNavBtn(Icons.ios_share, () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: _navBtnBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ── Gradient header ──
  Widget _buildHeader() {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFdcd5c7),
            Color(0xFFe8e2d5),
            _pageBg,
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle fog decoration
          Positioned(
            right: 0,
            bottom: 20,
            child: Container(
              width: 240,
              height: 180,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.0,
                  colors: [
                    const Color(0xFF5A5446).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Dynasty badge
          Positioned(
            left: 20,
            top: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.figure.dynasty,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile section: name + pinyin + lifespan + role tags ──
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
                Text(
                  figure.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  figure.pinyinName.isNotEmpty ? figure.pinyinName : '',
                  style: const TextStyle(
                    fontSize: 32,
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                    color: _textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${figure.years} · ${figure.shortDesc}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Tags on the right
          if (figure.role.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (figure.role.length >= 2)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRoleTag(figure.role[0], 0),
                        const SizedBox(width: 6),
                        _buildRoleTag(figure.role[1], 1),
                      ],
                    ),
                  if (figure.role.length >= 2) const SizedBox(height: 6),
                  if (figure.role.length >= 3)
                    _buildRoleTag(figure.role[2], 2),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleTag(String label, int colorIndex) {
    final bg = colorIndex < _tagColors.length ? _tagColors[colorIndex] : _tagPoet;
    final fg = colorIndex < _tagTextColors.length ? _tagTextColors[colorIndex] : _tagPoetText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  // ── Stats card ──
  Widget _buildStatsCard(Figure figure) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C826E).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStat(
            icon: Icons.location_on_outlined,
            iconColor: _accent,
            value: figure.locationsCount.toString(),
            label: '遗址',
          ),
          _buildStatDivider(),
          _buildStat(
            icon: Icons.directions_walk,
            iconColor: _green,
            value: figure.routesCount.toString(),
            label: '旅程',
          ),
          _buildStatDivider(),
          _buildStat(
            icon: Icons.auto_stories_outlined,
            iconColor: _gold,
            value: figure.poemsCount > 1000
                ? '${(figure.poemsCount / 1000).toStringAsFixed(0)}000+'
                : figure.poemsCount.toString(),
            label: '诗编',
          ),
          _buildStatDivider(),
          _buildStat(
            icon: Icons.star,
            iconColor: _star,
            value: figure.rating.toStringAsFixed(1),
            label: '评分',
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFECE7DF),
    );
  }

  // ── Action buttons ──
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF171717),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_fix_high, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '规划路线',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textPrimary,
                  side: const BorderSide(color: _cardBorder),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 18, color: _green),
                    SizedBox(width: 6),
                    Text(
                      '地图',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ──
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
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? _textPrimary : _tabInactive,
                    ),
                  ),
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
        return _buildBiography(figure);
      case 1:
        return _buildPlaceholder('遗址', Icons.place);
      case 2:
        return _buildPlaceholder('名言', Icons.format_quote);
      case 3:
        return _buildPlaceholder('地图', Icons.map);
      case 4:
        return _buildPlaceholder('作品', Icons.menu_book);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBiography(Figure figure) {
    // Try to get richer description from mock data
    final mock = _findMockFigure(figure.id);
    final description = mock?.description ?? figure.description;

    final paragraphs = description
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text('暂无详细资料', style: TextStyle(color: _textSecondary, fontSize: 14)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const Row(
            children: [
              Text('生平', style: TextStyle(fontSize: 14, color: _accent)),
              SizedBox(width: 6),
              Text('—', style: TextStyle(fontSize: 14, color: _divider)),
              SizedBox(width: 6),
              Text('人物简介', style: TextStyle(fontSize: 14, color: _textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          ...paragraphs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  p.trim(),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4A4A4A),
                    height: 1.75,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  MockFigure? _findMockFigure(String id) {
    try {
      return mockFigures.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Widget _buildPlaceholder(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: _textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('$label内容即将上线',
                  style: const TextStyle(fontSize: 15, color: _textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
