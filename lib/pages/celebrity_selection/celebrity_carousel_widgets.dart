part of 'celebrity_selection_page.dart';

/// Celebrity avatar, name, dynasty, and navigation arrows section.
class _CelebrityInfoSection extends StatelessWidget {
  const _CelebrityInfoSection({
    required this.displayIndex,
    required this.selected,
    required this.showTopicStage,
    required this.isForward,
    required this.stageAnimDuration,
    required this.colorScheme,
    required this.celebrityCount,
    required this.onGoToIndex,
  });

  final int displayIndex;
  final CelebrityProfile selected;
  final bool showTopicStage;
  final bool isForward;
  final Duration stageAnimDuration;
  final ColorScheme colorScheme;
  final int celebrityCount;
  final ValueChanged<int> onGoToIndex;

  @override
  Widget build(BuildContext context) {
    final selectedDynasty = selected.dynasty;
    final selectedId = selected.id;
    final hasDynasty = selectedDynasty.trim().isNotEmpty;
    const nameOffsetY = 12.0;
    final nameStyle = Theme.of(context).textTheme.headlineMedium;
    final nameLineHeight =
        (nameStyle?.fontSize ?? 28) * (nameStyle?.height ?? 1.2);

    const avatarTop = 8.0;
    const avatarSize = 252.0;
    const avatarNameGap = 24.0;

    return TweenAnimationBuilder<double>(
      duration: stageAnimDuration,
      curve: Curves.easeInOutCubic,
      tween: Tween<double>(begin: 0, end: showTopicStage ? 1 : 0),
      builder: (context, t, child) {
        const nameTop = avatarTop + avatarSize + avatarNameGap + nameOffsetY;

        final stageOneArrowCenter =
            (avatarTop + (nameTop + nameLineHeight)) / 2;
        final stageTwoArrowCenter = nameTop + nameLineHeight / 2;
        final arrowCenter =
            stageOneArrowCenter +
            (stageTwoArrowCenter - stageOneArrowCenter) * t;
        final arrowTop = arrowCenter - 24;

        return Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                Opacity(
                  opacity: _splitFadeOut(t),
                  child: IgnorePointer(
                    ignoring: showTopicStage,
                    child: Center(
                      child: RepaintBoundary(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) {
                            return _buildEdgeSlideFadeTransition(
                              context: context,
                              child: child,
                              animation: animation,
                              isForward: isForward,
                              selectedId: selectedId,
                            );
                          },
                          child: SizedBox(
                            key: ValueKey<int>(selectedId),
                            width: 252,
                            height: 252,
                            child: _buildAvatar(selected),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Transform.translate(
                  offset: const Offset(0, nameOffsetY),
                  child: Row(
                    children: [
                      const SizedBox(width: 44),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) {
                            return _buildEdgeSlideFadeTransition(
                              context: context,
                              child: child,
                              animation: animation,
                              isForward: isForward,
                              selectedId: selectedId,
                            );
                          },
                          child: Column(
                            key: ValueKey<int>(selectedId),
                            children: [
                              Text(
                                selected.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                              ),
                              if (hasDynasty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  selectedDynasty,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ViewDetailButton(
                          selected: selected,
                          colorScheme: colorScheme,
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
            Positioned(
              left: 0,
              top: arrowTop,
              child: SizedBox(
                width: 44,
                child: displayIndex > 0
                    ? IconButton(
                        onPressed: () => onGoToIndex(displayIndex - 1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Positioned(
              right: 0,
              top: arrowTop,
              child: SizedBox(
                width: 44,
                child: displayIndex < celebrityCount - 1
                    ? IconButton(
                        onPressed: () => onGoToIndex(displayIndex + 1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bottom action bar with back and continue buttons.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.selectedName,
    required this.showTopicStage,
    required this.stageAnimDuration,
    required this.phase,
    required this.colorScheme,
    required this.onBackStep,
    required this.onContinue,
  });

  final String selectedName;
  final bool showTopicStage;
  final Duration stageAnimDuration;
  final _OverlayPhase phase;
  final ColorScheme colorScheme;
  final VoidCallback onBackStep;
  final ValueChanged<String> onContinue;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const actionBarHeight = 52.0;

    return Positioned(
      left: 24,
      right: 24,
      bottom: 28 + bottomInset,
      child: SizedBox(
        height: actionBarHeight,
        child: LayoutBuilder(
          builder: (context, actionConstraints) {
            final totalWidth = actionConstraints.maxWidth;
            final backWidth = showTopicStage
                ? (totalWidth * 0.34).clamp(96.0, 180.0)
                : 0.0;
            final gapWidth = showTopicStage ? 12.0 : 0.0;
            final continueWidth = totalWidth - backWidth - gapWidth;

            return Row(
              children: [
                AnimatedContainer(
                  duration: stageAnimDuration,
                  curve: Curves.easeInOutCubic,
                  width: backWidth,
                  child: AnimatedOpacity(
                    duration: stageAnimDuration,
                    curve: showTopicStage
                        ? const Interval(0.5, 1, curve: Curves.easeOutCubic)
                        : const Interval(0, 0.5, curve: Curves.easeInCubic),
                    opacity: showTopicStage ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !showTopicStage,
                      child: OutlinedButton(
                        onPressed: onBackStep,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, actionBarHeight),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          foregroundColor: colorScheme.primary,
                          backgroundColor: colorScheme.surface.withValues(
                            alpha: 0.92,
                          ),
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.24),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('上一步'),
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: stageAnimDuration,
                  curve: Curves.easeInOutCubic,
                  width: gapWidth,
                ),
                AnimatedContainer(
                  duration: stageAnimDuration,
                  curve: Curves.easeInOutCubic,
                  width: continueWidth,
                  child: FilledButton(
                    onPressed: () => onContinue(selectedName),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, actionBarHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(phase == _OverlayPhase.reveal ? '完成' : '继续'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "查看详情" button that navigates to FigureDetailPage.
class _ViewDetailButton extends StatelessWidget {
  const _ViewDetailButton({
    required this.selected,
    required this.colorScheme,
  });

  final CelebrityProfile selected;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        final mockFigure = mock.mockFigures.cast<mock.MockFigure?>().firstWhere(
              (f) => f!.name == selected.name,
              orElse: () => null,
            );
        final figure = mockFigure != null
            ? Figure(
                id: mockFigure.id,
                name: mockFigure.name,
                pinyinName: mockFigure.pinyinName,
                dynasty: mockFigure.dynasty,
                role: mockFigure.role,
                years: mockFigure.years,
                shortDesc: mockFigure.shortDesc,
                description: mockFigure.description,
                imageUrl: mockFigure.imageUrl,
                locationsCount: mockFigure.locationsCount,
                routesCount: mockFigure.routesCount,
                poemsCount: mockFigure.poemsCount,
                rating: mockFigure.rating,
              )
            : Figure(
                id: selected.id.toString(),
                name: selected.name,
                dynasty: selected.dynasty,
                description: selected.bioFull,
                imageUrl: selected.avatarUrl,
              );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FigureDetailPage(figure: figure),
          ),
        );
      },
      icon: Icon(Icons.visibility_outlined, size: 16, color: colorScheme.primary),
      label: Text(
        '查看详情',
        style: TextStyle(fontSize: 13, color: colorScheme.primary),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
