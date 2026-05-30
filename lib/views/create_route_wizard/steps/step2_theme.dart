import 'package:flutter/material.dart';

import '../../../theme/color_schemes.dart';

/// Step 2 of the Create Route Wizard — Theme Selection.
///
/// Matches the Web version's [Step2Theme] in CreateRouteWizard.tsx.
/// Displays 3 travel themes (poetry, food, history) as selectable cards
/// with emoji icons, descriptions, and a circular selection indicator.
/// When a theme is selected, a preview section with images appears.
class Step2Theme extends StatelessWidget {
  final String? selectedThemeId;
  final ValueChanged<String> onSelect;
  final String figureName;

  const Step2Theme({
    super.key,
    this.selectedThemeId,
    required this.onSelect,
    this.figureName = '',
  });

  static const _themes = [
    _ThemeOption(
      id: 'poetry',
      icon: '🍃',
      title: '诗词足迹',
      desc: '沿着诗篇流传的地点前行',
    ),
    _ThemeOption(
      id: 'food',
      icon: '🥢',
      title: '地方美食',
      desc: '品尝当地传统风味佳肴',
    ),
    _ThemeOption(
      id: 'history',
      icon: '🏛️',
      title: '名胜古迹',
      desc: '探索古建筑与历史遗址',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          ..._themes.map(
            (theme) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildThemeCard(theme),
            ),
          ),
          if (selectedThemeId != null) ...[
            const SizedBox(height: 8),
            _buildPreview(),
          ],
        ],
      ),
    );
  }

  // ── Title + subtitle ──

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          const Text(
            '选择您的旅行主题',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.sageText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '我们将以此为您定制$figureName的专属路线',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.sageMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Theme card (emoji + text + check indicator) ──

  Widget _buildThemeCard(_ThemeOption theme) {
    final isSelected = selectedThemeId == theme.id;

    return GestureDetector(
      onTap: () => onSelect(theme.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFCFAF8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC37153)
                : const Color(0xFFE8E2D9),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Emoji icon
              Text(theme.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.sageText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.sageMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Selection indicator (circle with optional check)
              _buildCheckIndicator(isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFFC37153) : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? const Color(0xFFC37153)
              : const Color(0xFFDCD6C8),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }

  // ── Preview section (visible after theme selected) ──

  Widget _buildPreview() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(selectedThemeId),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E2D9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌟 主题预览',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8A8376),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPreviewImage(
                    'https://images.unsplash.com/photo-1543335759-33eb91f5a5e3?auto=format&fit=crop&q=80&w=300',
                    '西湖夜游',
                  ),
                  const SizedBox(width: 12),
                  _buildPreviewImage(
                    'https://images.unsplash.com/photo-1577626992523-886ec5cfb881?auto=format&fit=crop&q=80&w=300',
                    '孤山放鹤亭',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewImage(String url, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 128,
        height: 96,
        child: Stack(
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              cacheWidth: 256,
              width: 128,
              height: 96,
            ),
            // Dark gradient overlay from bottom
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Text label at bottom-left
            Positioned(
              left: 8,
              bottom: 8,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal model for a theme option.
class _ThemeOption {
  final String id;
  final String icon;
  final String title;
  final String desc;

  const _ThemeOption({
    required this.id,
    required this.icon,
    required this.title,
    required this.desc,
  });
}
