import 'package:flutter/material.dart';

import '../../../data/celebrity_repository.dart';
import '../../../models/celebrity_profile.dart';
import '../../../models/figure.dart';
import '../../../theme/color_schemes.dart';
import '../../../utils/slide_route.dart';
import '../../figure_detail_page.dart';

/// Step 2 of CreateRouteWizard — historical figure selection.
///
/// Loads real celebrity data from the database; falls back to mock data
/// when the database is unreachable.
class Step1Figure extends StatefulWidget {
  const Step1Figure({
    super.key,
    required this.selectedFigureId,
    required this.onSelect,
  });

  final String? selectedFigureId;
  final void Function(String id, CelebrityProfile profile) onSelect;

  @override
  State<Step1Figure> createState() => _Step1FigureState();
}

class _Step1FigureState extends State<Step1Figure> {
  late final Future<List<CelebrityProfile>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadFigures();
  }

  Future<List<CelebrityProfile>> _loadFigures() async {
    return const CelebrityRepository().fetchCelebrities();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CelebrityProfile>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '加载人物失败: ${snapshot.error}',
              style: const TextStyle(color: AppColors.sageMuted),
            ),
          );
        }
        final figures = snapshot.data ?? const [];
        if (figures.isEmpty) {
          return const Center(
            child: Text(
              '暂无人物数据',
              style: TextStyle(color: AppColors.sageMuted),
            ),
          );
        }
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
                itemCount: figures.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.sageBorder),
                itemBuilder: (context, index) {
                  final figure = figures[index];
                  final isSelected =
                      figure.id.toString() == widget.selectedFigureId;
                  return _FigureListTile(
                    figure: figure,
                    isSelected: isSelected,
                    onTap: () => widget.onSelect(
                      figure.id.toString(),
                      figure,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FigureListTile extends StatelessWidget {
  const _FigureListTile({
    required this.figure,
    required this.isSelected,
    required this.onTap,
  });

  final CelebrityProfile figure;
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
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  isSelected ? AppColors.primaryLight : AppColors.sageBorder,
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
                    '${figure.dynasty} · ${figure.bioShort}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.sageMuted,
                    ),
                  ),
                ],
              ),
            ),
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
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  slideFromRightRoute(
                    FigureDetailPage(
                      figure: Figure(
                        id: figure.id.toString(),
                        name: figure.name,
                        dynasty: figure.dynasty,
                        role: figure.topic,
                        shortDesc: figure.bioShort,
                        description: figure.bioFull,
                        imageUrl: figure.avatarUrl,
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
