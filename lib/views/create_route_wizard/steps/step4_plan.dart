import 'package:flutter/material.dart';
import '../../../models/figure.dart';
import '../../../theme/color_schemes.dart';

/// Step 4: 行程规划 — Person badge, date display, and pace preference.
///
/// Matches the Web version's Step4Plan from CreateRouteWizard.tsx.
/// Manages selection state for three pace options: 悠闲 / 适中 / 紧凑.
class Step4Plan extends StatefulWidget {
  final Figure? figure;

  const Step4Plan({super.key, this.figure});

  @override
  State<Step4Plan> createState() => _Step4PlanState();
}

class _Step4PlanState extends State<Step4Plan> {
  int _selectedPace = 1;

  static const Color _badgeBg = Color(0xFFF0DED3);
  static const Color _badgeText = Color(0xFFA65B40);
  static const Color _mutedLabel = Color(0xFFA8A195);

  static const List<_PaceOption> _paceOptions = [
    _PaceOption(icon: '🍃', label: '悠闲'),
    _PaceOption(icon: '⚖️', label: '适中'),
    _PaceOption(icon: '⚡', label: '紧凑'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPersonBadge(),
          const SizedBox(height: 24),
          _buildSectionTitle(Icons.calendar_month_outlined, '日期与行程天数'),
          const SizedBox(height: 12),
          _buildDateCards(),
          const SizedBox(height: 32),
          _buildSectionTitle(Icons.explore_outlined, '游览节奏'),
          const SizedBox(height: 12),
          _buildPaceGrid(),
        ],
      ),
    );
  }

  // ── Person badge: dynasty + name ──

  Widget _buildPersonBadge() {
    final figure = widget.figure;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _badgeBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '${figure?.dynasty ?? ''} ${figure?.name ?? ''}'.trim(),
        style: const TextStyle(
          color: _badgeText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Section title with icon ──

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.sageText,
          ),
        ),
      ],
    );
  }

  // ── Date cards: departure date + days ──

  Widget _buildDateCards() {
    return Row(
      children: [
        Expanded(child: _buildDateCard('出发日期', '10月12日')),
        const SizedBox(width: 16),
        Expanded(child: _buildDateCard('天数', '4天3夜')),
      ],
    );
  }

  Widget _buildDateCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageCard,
        border: Border.all(color: AppColors.sageBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _mutedLabel,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.sageText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pace grid: 3 cards in a row ──

  Widget _buildPaceGrid() {
    return Row(
      children: List.generate(_paceOptions.length, (index) {
        final isFirst = index == 0;
        final isLast = index == _paceOptions.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: isFirst ? 0 : 6,
              right: isLast ? 0 : 6,
            ),
            child: _buildPaceCard(index),
          ),
        );
      }),
    );
  }

  Widget _buildPaceCard(int index) {
    final isSelected = _selectedPace == index;
    final option = _paceOptions[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedPace = index),
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? _badgeBg : AppColors.sageCard,
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryLight.withValues(alpha: 0.4)
                  : AppColors.sageBorder,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
                blurRadius: isSelected ? 8 : 4,
                offset: Offset(0, isSelected ? 2 : 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(option.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                option.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _badgeText : AppColors.sageText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal model for a pace option (icon + label).
class _PaceOption {
  final String icon;
  final String label;

  const _PaceOption({required this.icon, required this.label});
}
