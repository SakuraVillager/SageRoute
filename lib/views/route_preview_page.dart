import 'package:flutter/material.dart';

import '../data/mock_routes.dart';


/// 路线预览页，精确匹配 Web 版 RoutePreview.tsx 视觉风格。
///
/// 功能：Hero 卡、统计概览、优化信息、每日行程 Tab、时间线行程、
/// 景点卡片、底部操作按钮。使用静态占位数据模拟真实数据。
class RoutePreviewPage extends StatefulWidget {
  const RoutePreviewPage({
    super.key,
    required this.route,
    this.onBack,
    this.onEdit,
    this.onSave,
  });

  final MockRoute route;

  /// 返回按钮回调，不传则隐藏返回按钮。
  final VoidCallback? onBack;

  /// 编辑按钮回调。
  final VoidCallback? onEdit;

  /// 保存按钮回调。
  final VoidCallback? onSave;

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> {

  // ── Page-specific colors (from Web RoutePreview.tsx) ──
  static const Color _pageBg = Color(0xFFF5EFEB);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBg2 = Color(0xFFFAF7F2);
  static const Color _cardBorder = Color(0xFFE8E2D9);
  static const Color _textPrimary = Color(0xFF2D2825);
  static const Color _textSecondary = Color(0xFF857F75);
  static const Color _mutedText = Color(0xFFA8A195);
  static const Color _accentColor = Color(0xFFC37153);
  static const Color _goldColor = Color(0xFFD4AF37);
  static const Color _greenColor = Color(0xFF84A98C);
  static const Color _blueMuted = Color(0xFF6B8E9B);
  static const Color _deepBg = Color(0xFF1C1A1A);
  static const Color _warmBg = Color(0xFFEBE5DA);
  static const Color _warmBorder = Color(0xFFDCD6C8);
  static const Color _tagBg = Color(0xFFF0DED3);
  static const Color _tagText = Color(0xFFA65B40);


  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1543335759-33eb91f5a5e3?auto=format&fit=crop&q=80&w=800';

  // ── Static placeholder display data for locations ──
  static const Map<String, _LocationDisplay> _displayMap = {
    '白堤': _LocationDisplay(
      pinyin: 'Bái Dī',
      tags: ['历史名堤', '西湖十景'],
      time: '9:00',
      transitDistance: '2.5',
      transitMinutes: '30',
      savedMinutes: '-25',
    ),
    '西湖': _LocationDisplay(
      pinyin: 'Xī Hú',
      tags: ['世界遗产', '湖光山色'],
      time: '10:00',
      transitDistance: '3.2',
      transitMinutes: '38',
      savedMinutes: '-40',
    ),
    '黄州': _LocationDisplay(
      pinyin: 'Huáng Zhōu',
      tags: ['古城', '赤壁'],
      time: '9:00',
      transitDistance: '2.0',
      transitMinutes: '25',
      savedMinutes: '-20',
    ),
    '庐山': _LocationDisplay(
      pinyin: 'Lú Shān',
      tags: ['名山', '云雾'],
      time: '8:30',
      transitDistance: '4.0',
      transitMinutes: '45',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final route = widget.route;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        children: [
          // ── Scrollable content ──
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spacer for fixed top bar
                const SizedBox(height: 120),

                // ── Hero Card ──
                _buildHeroCard(route),
                const SizedBox(height: 24),

                // ── Overview Stats ──
                _buildStatsOverview(route),
                const SizedBox(height: 24),

                // ── Optimization Info ──
                _buildOptimizationInfo(),
                const SizedBox(height: 32),

                // ── Daily Itinerary Header ──
                _buildDailyHeader(),
                const SizedBox(height: 16),

                // ── Day Tabs + Timeline (self-contained state) ──
                _DayItinerarySection(route: route),
                const SizedBox(height: 24),

                // ── Bottom Actions ──
                _buildBottomActions(),
              ],
            ),
          ),

          // ── Fixed header overlay ──
          _buildFixedHeader(route),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════════

  Widget _buildFixedHeader(MockRoute route) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_pageBg, _pageBg, Colors.transparent],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: back button + title + bookmark
                SizedBox(
                  height: 48,
                  child: Stack(
                    children: [
                      // Left side: back + title
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Back button
                            if (widget.onBack != null)
                              GestureDetector(
                                onTap: widget.onBack,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _warmBg,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: _warmBorder),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.arrow_back,
                                      size: 20,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.onBack != null) const SizedBox(width: 16),
                            // Title
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                                children: [
                                  TextSpan(text: 'Sage '),
                                  TextSpan(
                                    text: '_',
                                    style: TextStyle(
                                      color: _accentColor,
                                    ),
                                  ),
                                  TextSpan(text: ' Route'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right side: bookmark button
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _deepBg,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_border,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '收藏',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // AI badge (overlapping right side)
                      Positioned(
                        right: 0,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _tagBg,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '✨',
                                style: TextStyle(fontSize: 12),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'AI 智能优化',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _tagText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle row
                const Text(
                  '行程预览',
                  style: TextStyle(
                    
                    fontSize: 30,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '已优化 · 准备出发',
                  style: TextStyle(
                    fontSize: 13,
                    color: _mutedText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Hero Card
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroCard(MockRoute route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: double.infinity,
          height: 240,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(
                _heroImageUrl,
                fit: BoxFit.cover,
                cacheWidth: 800,
                errorBuilder: (_, __, ___) => Container(
                  color: _cardBorder,
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: Color(0xFFB0A89A),
                    ),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black87,
                          Colors.black38,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Foreground content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${route.figureName}的${route.name.contains(route.figureName) ? '' : ''}${_getRouteShortName(route)}',
                              style: const TextStyle(
                                
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${route.figureName}·${_getRouteShortName(route)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rating badge
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: _goldColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '4.9',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _goldColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRouteShortName(MockRoute route) {
    // Extract the short route name after figure name
    final name = route.name;
    final figureName = route.figureName;
    if (name.startsWith(figureName)) {
      final short = name.substring(figureName.length);
      return short.isEmpty ? '之旅' : short;
    }
    // Fallback: extract last meaningful part
    if (name.contains('的')) {
      final parts = name.split('的');
      return parts.last;
    }
    return '杭州之旅';
  }

  // ═══════════════════════════════════════════════════════════
  // Overview Stats (4 columns)
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatsOverview(MockRoute route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Days
            Expanded(
              child: _buildStatColumn(
                icon: const Icon(
                  Icons.nightlight_round,
                  size: 16,
                  color: _goldColor,
                ),
                value: '${route.days}',
                label: '天',
                color: _goldColor,
              ),
            ),
            _buildStatDivider(),
            // Locations
            Expanded(
              child: _buildStatColumn(
                icon: const Icon(
                  Icons.location_on,
                  size: 16,
                  color: _accentColor,
                ),
                value: '${route.locationsCount}',
                label: '景点',
                color: _accentColor,
              ),
            ),
            _buildStatDivider(),
            // Distance
            Expanded(
              child: _buildStatColumn(
                icon: const Icon(
                  Icons.alt_route,
                  size: 16,
                  color: _greenColor,
                ),
                value: route.totalDistance.replaceAll('km', ''),
                label: '公里',
                color: _greenColor,
              ),
            ),
            _buildStatDivider(),
            // Estimated fare
            Expanded(
              child: _buildStatColumn(
                icon: const Text(
                  '¥',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _blueMuted,
                  ),
                ),
                value: '80',
                label: '预估票价',
                color: _blueMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required Widget icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
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
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: _cardBorder,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Optimization Info
  // ═══════════════════════════════════════════════════════════

  Widget _buildOptimizationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _warmBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _greenColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _greenColor,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '路线已优化',
                    style: TextStyle(
                      
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '景点顺序已重新排列以减少交通时间，全称节省约1.5小时。晨间景点优先安排，气候凉爽更宜游览。',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      height: 1.5,
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

  // ═══════════════════════════════════════════════════════════
  // Daily Itinerary Header
  // ═══════════════════════════════════════════════════════════

  Widget _buildDailyHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _deepBg,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: const Center(
              child: Icon(
                Icons.calendar_today,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '每日行程',
              style: TextStyle(
                
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _tagBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 12, color: _accentColor),
                  SizedBox(width: 4),
                  Text(
                    '全部编辑',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _accentColor,
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

  // Bottom Actions
  // ═══════════════════════════════════════════════════════════

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Edit button
          GestureDetector(
            onTap: widget.onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: _warmBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _warmBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 18, color: _textPrimary),
                  SizedBox(width: 8),
                  Text(
                    '编辑',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Save button
          Expanded(
            child: GestureDetector(
              onTap: widget.onSave,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _deepBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '保存行程',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: Colors.white,
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
}

// ═══════════════════════════════════════════════════════════════
// Internal data classes
// ═══════════════════════════════════════════════════════════════

/// Static placeholder display data for a location card.
class _LocationDisplay {
  final String pinyin;
  final List<String> tags;
  final String time;
  final String transitDistance;
  final String transitMinutes;
  final String savedMinutes;

  const _LocationDisplay({
    required this.pinyin,
    required this.tags,
    required this.time,
    this.transitDistance = '3.0',
    this.transitMinutes = '35',
    this.savedMinutes = '-30',
  });
}

/// Static metadata for a day in the itinerary.
class _DayMeta {
  final String subtitle;
  final String duration;

  const _DayMeta({
    required this.subtitle,
    required this.duration,
  });
}

// ═══════════════════════════════════════════════════════════
// Day Itinerary Section (self-contained state for day selection)
// ═══════════════════════════════════════════════════════════

class _DayItinerarySection extends StatefulWidget {
  const _DayItinerarySection({required this.route});
  final MockRoute route;

  @override
  State<_DayItinerarySection> createState() => _DayItinerarySectionState();
}

class _DayItinerarySectionState extends State<_DayItinerarySection> {
  int _selectedDay = 0;

  // Colors duplicated from parent (same file private access doesn't work for static const).
  static const _deepBg = Color(0xFF1C1A1A);
  static const _cardBg = Color(0xFFF9F5F0);
  static const _cardBg2 = Color(0xFFF0ECE6);
  static const _cardBorder = Color(0xFFE6E0D6);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF7A7368);
  static const _accentColor = Color(0xFFCD6642);
  static const _warmBg = Color(0xFFF6EFE0);
  static const _warmBorder = Color(0xFFE0D5C0);
  static const _mutedText = Color(0xFF8A8376);
  static const _greenColor = Color(0xFF5A8B6E);

  static const _dayMetas = [
    _DayMeta(subtitle: '西湖北线游览', duration: '约5.5小时'),
    _DayMeta(subtitle: '湖心岛探访', duration: '约4.0小时'),
    _DayMeta(subtitle: '南山路漫步', duration: '约3.5小时'),
    _DayMeta(subtitle: '灵隐寺祈福', duration: '约4.5小时'),
  ];

  static const _locationImageUrl =
      'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=400&q=80';

  static const _displayMap = _RoutePreviewPageState._displayMap;

  _DayMeta _getDayMeta(int day) {
    if (day < _dayMetas.length) return _dayMetas[day];
    return const _DayMeta(subtitle: '', duration: '约5小时');
  }

  String _formatDayDate(int dayIndex) {
    final startDate = widget.route.startDate;
    if (startDate != null && startDate.isNotEmpty) {
      try {
        final parts = startDate.split('-');
        if (parts.length >= 3) {
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return '$month月${day + dayIndex}日';
        }
      } catch (_) {}
    }
    final dates = ['10月12日', '10月13日', '10月14日', '10月15日'];
    if (dayIndex < dates.length) return dates[dayIndex];
    return '第${dayIndex + 1}天';
  }

  _LocationDisplay _getDisplay(String name) {
    return _displayMap[name] ?? const _LocationDisplay(
      pinyin: '',
      tags: <String>[],
      time: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    return Column(
      children: [
        _buildDayTabs(route),
        const SizedBox(height: 20),
        _buildDayTimeline(route),
      ],
    );
  }

  Widget _buildDayTabs(MockRoute route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(route.days, (index) {
            final isActive = index == _selectedDay;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? _deepBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isActive ? _deepBg : _cardBorder,
                    ),
                  ),
                  child: Text(
                    '第${index + 1}天',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : _textSecondary,
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

  Widget _buildDayTimeline(MockRoute route) {
    final itinerary = route.itineraryByDay;
    final dayLocations = itinerary[_selectedDay + 1];

    if (dayLocations == null || dayLocations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Text('暂无行程数据', style: TextStyle(color: _textSecondary)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDayHeader(dayLocations),
            const SizedBox(height: 24),
            Stack(
              children: [
                Positioned(
                  left: 34, top: 24, bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_accentColor, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: List.generate(dayLocations.length, (index) {
                    final loc = dayLocations[index];
                    final display = _getDisplay(loc.name);
                    return Column(
                      children: [
                        if (index > 0) ...[
                          _buildTransitRow(display),
                          const SizedBox(height: 16),
                        ],
                        _buildLocationCard(index, loc.name, display),
                        if (index < dayLocations.length - 1)
                          const SizedBox(height: 20),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeader(List<MockRouteLocation> dayLocations) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: _accentColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '第${_selectedDay + 1}天 · ${_formatDayDate(_selectedDay)}',
          style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: _textPrimary),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _warmBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _warmBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, size: 12, color: _textSecondary),
              const SizedBox(width: 4),
              Text(
                _getDayMeta(_selectedDay).duration,
                style: const TextStyle(fontSize: 11, color: _textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransitRow(_LocationDisplay display) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _cardBg2,
              shape: BoxShape.circle,
              border: Border.all(color: _cardBorder),
            ),
            child: const Icon(Icons.directions_walk, size: 14, color: _accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _cardBg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '步行: ${display.transitDistance}公里 · 约${display.transitMinutes}分钟交通',
                      style: const TextStyle(fontSize: 11, color: _mutedText),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _greenColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '↓ ${display.savedMinutes}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _greenColor),
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

  Widget _buildLocationCard(int index, String name, _LocationDisplay display) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 96, height: 96,
                    child: Image.network(
                      _locationImageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 192,
                      errorBuilder: (_, __, ___) => Container(
                        color: _cardBorder,
                        child: const Center(child: Icon(Icons.image, size: 24, color: Color(0xFFB0A89A))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary, height: 1.2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
