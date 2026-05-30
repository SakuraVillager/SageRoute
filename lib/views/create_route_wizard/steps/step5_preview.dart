import 'package:flutter/material.dart';

import '../../../data/mock_figures.dart';

/// Step 5: Route preview + save, matching Web CreateRouteWizard.tsx Step5Preview.
///
/// Displays:
/// - Hero card with gradient overlay, route name, day/location tags
/// - Optimization info card (green icon + title + description)
/// - Timeline overview (numbered circles + vertical line + location info)
/// - "保存行程" button triggering SnackBar feedback
class Step5Preview extends StatefulWidget {
  const Step5Preview({super.key, this.figure, this.onSave});

  /// The currently selected figure (for route naming).
  final MockFigure? figure;

  /// Called when the user taps the save button.
  final VoidCallback? onSave;

  @override
  State<Step5Preview> createState() => _Step5PreviewState();
}

class _Step5PreviewState extends State<Step5Preview> {
  // ── Page-specific colors (from Web Step5Preview) ──
  static const Color _accentColor = Color(0xFFC37153);
  static const Color _greenColor = Color(0xFF84A98C);
  static const Color _deepBg = Color(0xFF1C1A1A);
  static const Color _warmBg = Color(0xFFEBE5DA);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE8E2D9);
  static const Color _textPrimary = Color(0xFF2D2825);
  static const Color _textSecondary = Color(0xFF8A8376);
  static const Color _mutedText = Color(0xFFA8A195);

  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1543335759-33eb91f5a5e3?auto=format&fit=crop&q=80&w=800';

  // ── Static mock timeline data ──
  static const List<_TimelineItem> _timelineItems = [
    _TimelineItem(
      number: 1,
      name: '西湖白堤',
      time: '09:00',
      duration: '游览2小时',
      isPrimary: true,
    ),
    _TimelineItem(
      number: 2,
      name: '孤山放鹤亭',
      time: '11:30',
      duration: '游览1.5小时',
      isPrimary: false,
    ),
  ];

  MockFigure get _figure => widget.figure ?? mockFigures[0];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildHeroCard(),
          const SizedBox(height: 24),
          _buildOptimizationInfo(),
          const SizedBox(height: 24),
          _buildTimelineSection(),
          const SizedBox(height: 32),
          _buildSaveButton(),
          // Bottom spacing for safe area
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Hero Card
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: double.infinity,
        height: 200,
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
                  child: Icon(Icons.image, size: 48, color: Color(0xFFB0A89A)),
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
            // Content at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_figure.name}的杭州之旅',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Days badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            '4天',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Locations badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Text(
                            '9处景点',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Optimization Info
  // ═══════════════════════════════════════════════════════════

  Widget _buildOptimizationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _warmBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _greenColor.withValues(alpha: 0.3)),
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
              child: Icon(Icons.check_circle, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '路线已智能优化',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '景点顺序已根据您的主题与倾向重新排列，全程交通时间显著减少。',
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Timeline Section
  // ═══════════════════════════════════════════════════════════

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
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
          const Text(
            '行程概览 (第1天)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Stack(
        children: [
          // Vertical gradient line
          Positioned(
            left: 9,
            top: 12,
            bottom: 12,
            child: Container(width: 2, color: _cardBorder),
          ),
          // Timeline items
          Column(
            children: List.generate(_timelineItems.length, (index) {
              final item = _timelineItems[index];
              final isLast = index == _timelineItems.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Numbered circle
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: item.isPrimary ? _accentColor : _greenColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (item.isPrimary ? _accentColor : _greenColor)
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${item.number}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Location info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 12,
                                color: _mutedText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.time} (${item.duration})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _mutedText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Save Button
  // ═══════════════════════════════════════════════════════════

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _deepBg,
          foregroundColor: Colors.white,
          elevation: 8,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 16),
            SizedBox(width: 8),
            Text(
              '保存行程',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    widget.onSave?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('行程已保存'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Internal data class
// ═══════════════════════════════════════════════════════════════

/// Static timeline item for route preview.
class _TimelineItem {
  final int number;
  final String name;
  final String time;
  final String duration;
  final bool isPrimary;

  const _TimelineItem({
    required this.number,
    required this.name,
    required this.time,
    required this.duration,
    required this.isPrimary,
  });
}
