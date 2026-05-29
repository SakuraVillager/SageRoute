import 'package:flutter/material.dart';

import '../../../data/mock_figures.dart';
import '../../../theme/color_schemes.dart';

/// Step 1 of CreateRouteWizard — historical figure selection.
///
/// Displays a 2-column grid of figure cards matching the Web
/// [Step1Figure] in `CreateRouteWizard.tsx`. Selected state shows
/// terracotta border, shadow, check icon, and full opacity. Unselected
/// shows light border, reduced opacity, and slight scale-down.
class Step1Figure extends StatelessWidget {
  const Step1Figure({
    super.key,
    required this.selectedFigureId,
    required this.onSelect,
  });

  /// The currently selected figure ID, or null if none selected.
  final String? selectedFigureId;

  /// Called when a figure card is tapped. Passes the figure's [id].
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            '您想追随哪位名人的足迹？',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.sageText,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: mockFigures.map((figure) {
              return _FigureCard(
                figure: figure,
                isSelected: figure.id == selectedFigureId,
                onTap: () => onSelect(figure.id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// A single figure card with image, name, dynasty, and selection state.
///
/// Wraps the card content in [AnimatedScale], [AnimatedOpacity], and
/// [AnimatedContainer] for smooth selection transitions.
class _FigureCard extends StatelessWidget {
  const _FigureCard({
    required this.figure,
    required this.isSelected,
    required this.onTap,
  });

  final MockFigure figure;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.98,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: isSelected ? 1.0 : 0.7,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryLight
                    : AppColors.sageBorder,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Square image with loading/error states
                    AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        figure.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.sageBorder,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: AppColors.sageMuted,
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom text section: name + dynasty
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            figure.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sageText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            figure.dynasty,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.sageMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Selection check badge (top-right)
                if (isSelected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: _CheckBadge(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small circular check icon badge shown on selected cards.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}
