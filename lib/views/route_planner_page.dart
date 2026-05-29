import 'package:flutter/material.dart';

import '../data/mock_figures.dart' as mock;
import '../theme/color_schemes.dart';

/// Route planner page matching Web RoutePlanner.tsx.
///
/// Sections:
/// - Header with back + Sage_Route title + preview button
/// - Subtitle "行程规划" with figure dynasty/name badge
/// - Date & duration cards (2-column)
/// - Pace selection grid (3-column)
/// - Transportation mode pills
/// - Daily schedule tabs (placeholder)
/// - Bottom CTA "生成智能路线"
///
/// Navigation is handled via optional callbacks — no real date picking
/// or route generation logic.
class RoutePlannerPage extends StatefulWidget {
  /// The figure ID to plan routes for. Defaults to 白居易 if null.
  final String? figureId;

  /// Callback when back is tapped.
  final VoidCallback? onBack;

  /// Callback when the preview button is tapped.
  final VoidCallback? onPreview;

  const RoutePlannerPage({
    super.key,
    this.figureId,
    this.onBack,
    this.onPreview,
  });

  @override
  State<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends State<RoutePlannerPage> {
  int _selectedPace = 1; // 0=悠闲, 1=适中, 2=紧凑
  int _selectedTransport = 0; // 0=步行
  int _selectedDay = 1; // 第1天

  static const _paces = ['悠闲', '适中', '紧凑'];
  static const _paceEmojis = ['🍃', '⚖️', '⚡'];
  static const _paceDescriptions = ['每天2-3处', '每天3-4处', '每天5处以上'];

  static const _transports = [
    _TransportOption('步行', '\u{1F9B6}', AppColors.sageText),
    _TransportOption('骑行', '\u{1F6B2}', AppColors.sageGreen),
    _TransportOption('公交', '\u{1F68C}', Color(0xFF6B8E9B)),
    _TransportOption('自驾', '\u{1F697}', AppColors.sageGold),
    _TransportOption('游船', '\u{26F5}', Color(0xFFA65B40)),
  ];

  mock.MockFigure get _figure {
    final found = mock.findFigureById(widget.figureId ?? '');
    return found ?? mock.baiJuyi;
  }

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
              const SizedBox(height: 8),
              _buildTitleSection(),
              const SizedBox(height: 24),
              _buildDateSection(),
              const SizedBox(height: 28),
              _buildPaceSection(),
              const SizedBox(height: 28),
              _buildTransportSection(),
              const SizedBox(height: 28),
              _buildDailyScheduleSection(),
              const SizedBox(height: 16),
              _buildBottomButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section icon decoration (shared helper) ──

  Widget _sectionIcon(IconData icon, Color bgColor) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  // ── Header ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEBE5DA),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFDCD6C8)),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.sageText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Vertical divider
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFDCD6C8),
          ),
          const SizedBox(width: 12),
          // Title
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Sage ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sageText,
                  ),
                ),
                TextSpan(
                  text: '_',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight.withValues(alpha: 0.7),
                  ),
                ),
                const TextSpan(
                  text: ' Route',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sageText,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Preview button
          GestureDetector(
            onTap: widget.onPreview,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.sageDeep,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: const Color(0xFFF3EFE9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '预览',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF3EFE9),
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

  // ── Title Section ──

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '行程规划',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.sageText,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '逐步构建您的旅途',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFFA8A195),
                ),
              ),
              const Spacer(),
              // Figure badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0DED3),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${_figure.dynasty} ${_figure.name} ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA65B40),
                        ),
                      ),
                      TextSpan(
                        text: _figure.years,
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFFA65B40).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Date & Duration Section ──

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              _sectionIcon(Icons.calendar_today_outlined, AppColors.primaryLight),
              const SizedBox(width: 12),
              Text(
                '日期与行程天数',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Date cards (2-column)
          Row(
            children: [
              Expanded(child: _dateCard('出发日期', '10月12日', '2025', AppColors.primaryLight, Icons.calendar_today_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _dateCard('返程日期', '10月15日', '2025', AppColors.sageGreen, Icons.calendar_today_outlined)),
            ],
          ),
          const SizedBox(height: 14),
          // Metadata pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _metaPill('4天3夜', Icons.nightlight_round, AppColors.sageDeep, AppColors.sageGold, Colors.white),
                const SizedBox(width: 10),
                _metaPill('6处景点', Icons.location_on_outlined, const Color(0xFFEBE5DA), AppColors.primaryLight, AppColors.sageText),
                const SizedBox(width: 10),
                _metaPill('12.4 公里', Icons.route_outlined, const Color(0xFFEBE5DA), AppColors.sageGreen, AppColors.sageText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateCard(String label, String date, String year, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sageBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFFA8A195),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageText,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                year,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFFA8A195),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaPill(String label, IconData icon, Color bgColor, Color iconColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: bgColor == AppColors.sageDeep
            ? null
            : Border.all(color: const Color(0xFFDCD6C8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pace Section ──

  Widget _buildPaceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.tune_outlined, AppColors.sageGreen),
              const SizedBox(width: 12),
              Text(
                '游览节奏',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 3-column grid
          Row(
            children: List.generate(3, (i) {
              final selected = _selectedPace == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 6,
                    right: i == 2 ? 0 : 6,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPace = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF0DED3)
                            : AppColors.sageCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryLight.withValues(alpha: 0.4)
                              : AppColors.sageBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _paceEmojis[i],
                            style: TextStyle(
                              fontSize: selected ? 28 : 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _paces[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? const Color(0xFFA65B40)
                                  : AppColors.sageText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _paceDescriptions[i],
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? const Color(0xFFA65B40).withValues(alpha: 0.7)
                                  : const Color(0xFFA8A195),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Transport Section ──

  Widget _buildTransportSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.directions_car_outlined, const Color(0xFF6B8E9B)),
              const SizedBox(width: 12),
              Text(
                '出行方式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_transports.length, (i) {
              final t = _transports[i];
              final selected = _selectedTransport == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedTransport = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.sageDeep : AppColors.sageCard,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.sageBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.emoji,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : t.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Daily Schedule Section ──

  Widget _buildDailyScheduleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              _sectionIcon(Icons.list_outlined, AppColors.sageGold),
              const SizedBox(width: 12),
              Text(
                '每日行程安排',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Day tabs
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDay = i + 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(
                          color: _selectedDay == i + 1
                              ? AppColors.sageDeep
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: _selectedDay == i + 1
                                ? Colors.transparent
                                : AppColors.sageBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '第${i + 1}天',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _selectedDay == i + 1
                                ? Colors.white
                                : const Color(0xFF8A8376),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Add day button
                Container(
                  width: 42,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sageCard,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Daily itinerary placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.sageCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.sageBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 32,
                  color: AppColors.sageMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  '第$_selectedDay天行程',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sageText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '点击下方按钮开始规划',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.sageMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPlaceholderStat(Icons.location_on_outlined, '3 处景点', AppColors.primaryLight),
                    const SizedBox(width: 24),
                    _buildPlaceholderStat(Icons.directions_walk_outlined, '2.4 公里', AppColors.sageGreen),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Bottom action row
          Row(
            children: [
              // Save button
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE5DA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCD6C8)),
                ),
                child: IconButton(
                  icon: Icon(Icons.save_outlined, size: 22, color: AppColors.sageText),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              // Smart optimize button
              Expanded(
                child: GestureDetector(
                  onTap: widget.onPreview,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.sageDeep,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '✨ 智能优化 · 预览',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sageGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppColors.sageGold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.sageMuted,
          ),
        ),
      ],
    );
  }

  // ── Bottom CTA Button ──

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: widget.onPreview,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.sageDeep,
            foregroundColor: const Color(0xFFF3EFE9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            '生成智能路线',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal data class for transport mode options.
class _TransportOption {
  final String label;
  final String emoji;
  final Color color;

  const _TransportOption(this.label, this.emoji, this.color);
}
