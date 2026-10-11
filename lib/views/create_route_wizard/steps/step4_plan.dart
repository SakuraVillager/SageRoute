import 'package:flutter/material.dart';

import '../../../models/figure.dart';
import '../../../theme/color_schemes.dart';

/// Step 3: 行程规划 — 日期、游览节奏。
class Step4Plan extends StatefulWidget {
  final Figure? figure;

  const Step4Plan({super.key, this.figure});

  @override
  State<Step4Plan> createState() => _Step4PlanState();
}

class _Step4PlanState extends State<Step4Plan> {
  int _selectedPace = 0;

  // ── Colors (HTML design) ──
  static const _cardBg = Color(0xFFFFFFFF);
  static const _textMain = AppColors.sageText;
  static const _textSecondary = AppColors.sageMuted;
  static const _accent = AppColors.sageAccent;
  static const _accentBg = AppColors.brandLight;
  static const _border = AppColors.brandLight;
  static const _greenIcon = AppColors.brandDeeper;
  static const _brownRedIcon = AppColors.sageMuted;

  static const _paces = ['悠闲', '适中', '紧凑'];
  static const _paceDescriptions = ['每天2-3处', '每天3-4处', '每天5处以上'];
  static const _paceIcons = [
    Icons.eco_outlined,
    Icons.balance_outlined,
    Icons.bolt_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('日期与行程天数', Icons.calendar_month, isRedIcon: true),
          const SizedBox(height: 16),
          _buildDateCards(),
          const SizedBox(height: 32),
          _buildSectionTitle('游览节奏', Icons.speed),
          const SizedBox(height: 16),
          _buildPaceCards(),
        ],
      ),
    );
  }

  // ── Section Title ──

  Widget _buildSectionTitle(
    String title,
    IconData icon, {
    bool isRedIcon = false,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isRedIcon ? _brownRedIcon : _greenIcon,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _textMain,
          ),
        ),
      ],
    );
  }

  // ── Date Cards ──

  Widget _buildDateCards() {
    return Row(
      children: [
        Expanded(child: _buildDateCard('出发日期', '10月12日', '2025', _accent)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateCard('返程日期', '10月15日', '2025', AppColors.sageMuted),
        ),
      ],
    );
  }

  Widget _buildDateCard(
    String label,
    String date,
    String year,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textMain,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  year,
                  style: const TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pace Cards ──

  Widget _buildPaceCards() {
    return Row(
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? _accentBg : _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? _accent : _border),
                ),
                child: Column(
                  children: [
                    Icon(
                      _paceIcons[i],
                      size: 20,
                      color: selected ? _accent : AppColors.sageMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _paces[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? _accent : _textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _paceDescriptions[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: selected
                            ? _accent.withValues(alpha: 0.7)
                            : _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
