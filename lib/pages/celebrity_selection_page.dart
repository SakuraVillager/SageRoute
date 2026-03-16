import 'package:flutter/material.dart';

import '../data/celebrity_repository.dart';

class CelebritySelectionPage extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback? onSkip;
  final bool showActionButtons;

  const CelebritySelectionPage({
    super.key,
    required this.onContinue,
    this.onSkip,
    this.showActionButtons = true,
  });

  @override
  State<CelebritySelectionPage> createState() => _CelebritySelectionPageState();
}

class _CelebritySelectionPageState extends State<CelebritySelectionPage> {
  // 该页面通过 CelebrityRepository 从 Supabase 的 Celebrity 表获取人物列表。
  final CelebrityRepository _repository = const CelebrityRepository();
  late final Future<List<Map<String, dynamic>>> _celebritiesFuture;

  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _celebritiesFuture = _repository.fetchCelebrities();
  }

  bool get _isForward => _currentIndex >= _previousIndex;

  void _goToIndex(int nextIndex, int maxCount) {
    if (nextIndex < 0 || nextIndex >= maxCount || nextIndex == _currentIndex) {
      return;
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = nextIndex;
    });
  }

  void _goPrevious(int maxCount) => _goToIndex(_currentIndex - 1, maxCount);

  void _goNext(int maxCount) => _goToIndex(_currentIndex + 1, maxCount);

  void _onHorizontalDragEnd(DragEndDetails details, int maxCount) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) {
      return;
    }
    if (velocity < 0) {
      _goNext(maxCount);
    } else {
      _goPrevious(maxCount);
    }
  }

  Widget _buildEdgeSlideFadeTransition({
    required Widget child,
    required Animation<double> animation,
    required bool isForward,
    required int selectedId,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bool isEntering = child.key == ValueKey<int>(selectedId);

    double beginOffsetX;
    if (isForward) {
      beginOffsetX = isEntering ? screenWidth : -screenWidth;
    } else {
      beginOffsetX = isEntering ? -screenWidth : screenWidth;
    }

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, animatedChild) {
        final offsetX = beginOffsetX * (1 - animation.value);
        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: FadeTransition(opacity: animation, child: animatedChild),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final skipHandler = widget.onSkip ?? () => Navigator.of(context).pop();

    return ColoredBox(
      color: colorScheme.surface,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _celebritiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '人物数据加载失败',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final celebrities = snapshot.data ?? const <Map<String, dynamic>>[];
          if (celebrities.isEmpty) {
            return Center(
              child: Text(
                '暂无人物数据',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final safeIndex = _currentIndex.clamp(0, celebrities.length - 1);
          if (safeIndex != _currentIndex) {
            _currentIndex = safeIndex;
          }
          final selected = celebrities[_currentIndex];
          final selectedId = (selected['id'] as num?)?.toInt() ?? _currentIndex;
          final selectedName = (selected['name'] ?? '').toString();
          final selectedDynasty = (selected['dynasty'] ?? '').toString();
          final selectedBioShort = (selected['bio_short'] ?? '').toString();

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) =>
                _onHorizontalDragEnd(details, celebrities.length),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '选择您的同行者',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 60),
                    Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: _currentIndex > 0
                              ? IconButton(
                                  onPressed: () =>
                                      _goPrevious(celebrities.length),
                                  icon: const Icon(Icons.chevron_left_rounded),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Expanded(
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              transitionBuilder: (child, animation) {
                                return _buildEdgeSlideFadeTransition(
                                  child: child,
                                  animation: animation,
                                  isForward: _isForward,
                                  selectedId: selectedId,
                                );
                              },
                              child: Container(
                                key: ValueKey<int>(selectedId),
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primaryContainer,
                                  border: Border.all(
                                    color: colorScheme.primary,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: _currentIndex < celebrities.length - 1
                              ? IconButton(
                                  onPressed: () => _goNext(celebrities.length),
                                  icon: const Icon(Icons.chevron_right_rounded),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, animation) {
                        return _buildEdgeSlideFadeTransition(
                          child: child,
                          animation: animation,
                          isForward: _isForward,
                          selectedId: selectedId,
                        );
                      },
                      child: Column(
                        key: ValueKey<int>(selectedId),
                        children: [
                          Text(
                            selectedName,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedDynasty,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedBioShort,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                    if (widget.showActionButtons)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: skipHandler,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('跳过'),
                          ),
                          FilledButton(
                            onPressed: widget.onContinue,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('继续'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
