import 'package:flutter/material.dart';

import '../../../data/mock_figures.dart';
import '../../../models/figure.dart';
import '../../../theme/color_schemes.dart';
import '../../figure_detail_page.dart';

/// Step 1 of CreateRouteWizard — historical figure selection.
///
/// Displays a contact-list style layout: avatar (first character) + name.
class Step1Figure extends StatelessWidget {
  const Step1Figure({
    super.key,
    required this.selectedFigureId,
    required this.onSelect,
  });

  final String? selectedFigureId;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            '您想追随哪位名人的足迹？',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.sageText,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: mockFigures.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.sageBorder,
            ),
            itemBuilder: (context, index) {
              final figure = mockFigures[index];
              final isSelected = figure.id == selectedFigureId;
              return _FigureListTile(
                figure: figure,
                isSelected: isSelected,
                onTap: () => onSelect(figure.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FigureListTile extends StatelessWidget {
  const _FigureListTile({
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar — first character of name
            CircleAvatar(
              radius: 24,
              backgroundColor: isSelected
                  ? AppColors.primaryLight
                  : AppColors.sageBorder,
              child: Text(
                figure.name.characters.first,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.sageText,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Name + dynasty
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    figure.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.sageText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${figure.dynasty} · ${figure.shortDesc}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.sageMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            // View detail button
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FigureDetailPage(
                      figure: Figure(
                        id: figure.id,
                        name: figure.name,
                        pinyinName: figure.pinyinName,
                        dynasty: figure.dynasty,
                        role: figure.role,
                        years: figure.years,
                        shortDesc: figure.shortDesc,
                        description: figure.description,
                        imageUrl: figure.imageUrl,
                        locationsCount: figure.locationsCount,
                        routesCount: figure.routesCount,
                        poemsCount: figure.poemsCount,
                        rating: figure.rating,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.sageMuted,
              ),
              tooltip: '查看详情',
            ),
          ],
        ),
      ),
    );
  }
}
