import 'package:flutter/material.dart';

import '../../../data/celebrity_repository.dart';
import '../../../models/celebrity_profile.dart';
import '../../../models/figure.dart';
import '../../../theme/color_schemes.dart';
import '../../../utils/slide_route.dart';
import '../../figure_detail_page.dart';

/// Step 2 of CreateRouteWizard — historical figure selection.
///
/// Uses a compact, searchable card grid so users can compare figures without
/// scrolling through a long single-column list.
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
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = const CelebrityRepository().fetchCelebrities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CelebrityProfile> _filterFigures(List<CelebrityProfile> figures) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return figures;
    return figures.where((figure) {
      return figure.name.toLowerCase().contains(query) ||
          figure.dynasty.toLowerCase().contains(query) ||
          figure.bioShort.toLowerCase().contains(query) ||
          figure.topic.any((topic) => topic.toLowerCase().contains(query));
    }).toList(growable: false);
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

        final figures = snapshot.data ?? const <CelebrityProfile>[];
        if (figures.isEmpty) {
          return const Center(
            child: Text('暂无人物数据', style: TextStyle(color: AppColors.sageMuted)),
          );
        }

        final visibleFigures = _filterFigures(figures);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '选择一位同行人物',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sageText,
                      ),
                    ),
                  ),
                  Text(
                    '${visibleFigures.length} 位',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.sageMuted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '搜索人物、朝代或主题',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.sageBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.sageBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                ),
              ),
            ),
            Expanded(
              child: visibleFigures.isEmpty
                  ? const Center(
                      child: Text(
                        '没有找到匹配人物',
                        style: TextStyle(color: AppColors.sageMuted),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 360 ? 2 : 1;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemCount: visibleFigures.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: columns == 2 ? 190 : 142,
                          ),
                          itemBuilder: (context, index) {
                            final figure = visibleFigures[index];
                            return _FigureCard(
                              figure: figure,
                              horizontal: columns == 1,
                              isSelected:
                                  figure.id.toString() == widget.selectedFigureId,
                              onTap: () => widget.onSelect(
                                figure.id.toString(),
                                figure,
                              ),
                            );
                          },
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

class _FigureCard extends StatelessWidget {
  const _FigureCard({
    required this.figure,
    required this.horizontal,
    required this.isSelected,
    required this.onTap,
  });

  final CelebrityProfile figure;
  final bool horizontal;
  final bool isSelected;
  final VoidCallback onTap;

  void _openDetails(BuildContext context) {
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
  }

  @override
  Widget build(BuildContext context) {
    final content = horizontal
        ? Row(
            children: [
              _FigureAvatar(figure: figure, isSelected: isSelected, size: 62),
              const SizedBox(width: 14),
              Expanded(child: _FigureCardText(figure: figure, isSelected: isSelected)),
              IconButton(
                onPressed: () => _openDetails(context),
                icon: const Icon(Icons.info_outline, size: 19),
                color: AppColors.sageMuted,
                tooltip: '查看详情',
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FigureAvatar(figure: figure, isSelected: isSelected, size: 54),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    onPressed: () => _openDetails(context),
                    icon: const Icon(Icons.info_outline, size: 18),
                    color: AppColors.sageMuted,
                    tooltip: '查看详情',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: _FigureCardText(figure: figure, isSelected: isSelected)),
            ],
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : AppColors.sageBorder,
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D2B2724),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(child: content),
              if (isSelected)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.check_circle,
                    size: 22,
                    color: AppColors.primaryLight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FigureAvatar extends StatelessWidget {
  const _FigureAvatar({
    required this.figure,
    required this.isSelected,
    required this.size,
  });

  final CelebrityProfile figure;
  final bool isSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: isSelected ? AppColors.primaryLight : AppColors.sageBorder,
      alignment: Alignment.center,
      child: Text(
        figure.name.isEmpty ? '?' : figure.name.characters.first,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppColors.sageText,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size,
        child: figure.avatarUrl.trim().isEmpty
            ? fallback
            : Image.network(
                figure.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

class _FigureCardText extends StatelessWidget {
  const _FigureCardText({required this.figure, required this.isSelected});

  final CelebrityProfile figure;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          figure.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.primaryLight : AppColors.sageText,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.sageBorder.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            figure.dynasty.isEmpty ? '历史人物' : figure.dynasty,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.sageMuted),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          figure.bioShort.isEmpty ? '点击选择并查看相关文化路线' : figure.bioShort,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.35,
            color: AppColors.sageMuted,
          ),
        ),
      ],
    );
  }
}
