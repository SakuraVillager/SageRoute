part of 'celebrity_selection_page.dart';

/// Phase of the overlay selection flow.
enum _OverlayPhase { character, reveal }

/// ---------- helper functions ----------

double _splitFadeIn(double t) => ((t - 0.5) * 2).clamp(0.0, 1.0);

double _splitFadeOut(double t) => (1 - 2 * t).clamp(0.0, 1.0);

Widget _buildAvatar(CelebrityProfile profile) {
  final url = profile.avatarUrl;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Image.network(url, fit: BoxFit.cover);
  } else if (url.startsWith('assets/')) {
    return Image.asset(url, fit: BoxFit.cover);
  } else {
    final initial = profile.name.isNotEmpty
        ? profile.name.substring(0, 1)
        : '?';
    return CircleAvatar(
      radius: 126,
      child: Text(initial, style: const TextStyle(fontSize: 64)),
    );
  }
}

Widget _buildEdgeSlideFadeTransition({
  required BuildContext context,
  required Widget child,
  required Animation<double> animation,
  required bool isForward,
  required int selectedId,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isEntering = child.key == ValueKey<int>(selectedId);

  late final double beginOffsetX;
  if (isForward) {
    beginOffsetX = isEntering ? screenWidth : -screenWidth;
  } else {
    beginOffsetX = isEntering ? -screenWidth : screenWidth;
  }

  return AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, animatedChild) {
      final progress = animation.value;
      final offsetX = beginOffsetX * (1 - progress);

      // For AnimatedSwitcher:
      // Entering child: animation.value goes 0.0 -> 1.0
      // Exiting child: animation.value goes 1.0 -> 0.0
      // _splitFadeIn(progress) handles both correctly:
      // - Entering: opacity stays 0 then goes 0->1 (fades in late)
      // - Exiting: opacity goes 1->0 then stays 0 (fades out early)
      final opacity = _splitFadeIn(progress);

      return Transform.translate(
        offset: Offset(offsetX, 0),
        child: Opacity(opacity: opacity, child: animatedChild),
      );
    },
  );
}

/// ---------- carousel content widget ----------

/// Builds the main celebrity carousel UI when celebrities are loaded.
/// Receives all state via constructor parameters (controlled widget).
class _CelebrityCarouselContent extends StatelessWidget {
  const _CelebrityCarouselContent({
    required this.celebrities,
    required this.currentIndex,
    required this.previousIndex,
    required this.phase,
    required this.isFinishing,
    required this.finishExitT,
    required this.selectedTopicName,
    required this.topicsFuture,
    required this.stageAnimDuration,
    required this.showActionButtons,
    required this.colorScheme,
    required this.onGoToIndex,
    required this.onHorizontalDragEnd,
    required this.onContinue,
    required this.onBackStep,
    required this.onTopicSelected,
    this.onSkip,
  });

  final List<CelebrityProfile> celebrities;
  final int currentIndex;
  final int previousIndex;
  final _OverlayPhase phase;
  final bool isFinishing;
  final double finishExitT;
  final String? selectedTopicName;
  final Future<List<TopicRecord>>? topicsFuture;
  final Duration stageAnimDuration;
  final bool showActionButtons;
  final ColorScheme colorScheme;
  final VoidCallback? onSkip;
  final ValueChanged<int> onGoToIndex;
  final ValueChanged<DragEndDetails> onHorizontalDragEnd;
  final ValueChanged<String> onContinue;
  final VoidCallback onBackStep;
  final ValueChanged<String> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    final displayIndex = currentIndex.clamp(0, celebrities.length - 1);
    final selected = celebrities[displayIndex];
    final selectedId = selected.id;
    final selectedName = selected.name;
    final selectedBioShort = selected.bioShort;
    final showTopicStage = phase != _OverlayPhase.character;
    final showMapCutout = phase == _OverlayPhase.reveal;
    final isForward = currentIndex >= previousIndex;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const actionBarHeight = 52.0;

    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    );
    final lineHeight =
        (titleStyle?.fontSize ?? 24) * (titleStyle?.height ?? 1.2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TweenAnimationBuilder<double>(
            duration: stageAnimDuration,
            curve: Curves.easeInOutCubic,
            tween: Tween<double>(
              begin: 0,
              end: showMapCutout ? 1 : 0,
            ),
            builder: (context, cutoutT, child) {
              final reserveT = cutoutT.clamp(0.0, 1.0);
              final holeT = ((cutoutT - 0.5) * 2).clamp(0.0, 1.0);

              final endHoleWidth =
                  ((constraints.maxWidth - 52) * (0.58 + 0.32 * 1.0))
                      .clamp(180.0, constraints.maxWidth - 24);
              final endHoleHeight = (96 + 150 * 1.0).clamp(
                96.0,
                constraints.maxHeight * 0.45,
              );
              final maxReservedHeight =
                  (endHoleHeight - 160.0).clamp(0.0, constraints.maxHeight);

              final holeWidth =
                  ((constraints.maxWidth - 52) * (0.66 + 0.38 * holeT))
                      .clamp(220.0, constraints.maxWidth - 8);
              final holeHeight = (136 + 200 * holeT).clamp(
                136.0,
                constraints.maxHeight * 0.58,
              );
              final holeTop = constraints.maxHeight * (0.335 - 0.055 * holeT);
              final holeLeft = (constraints.maxWidth - holeWidth) / 2;

              final hasHole = holeT > 0.001;
              final hole = hasHole
                  ? RRect.fromRectAndRadius(
                      Rect.fromLTWH(
                        holeLeft,
                        holeTop,
                        holeWidth,
                        holeHeight,
                      ),
                      Radius.circular(32 + 16 * holeT),
                    )
                  : null;
              final holeCenter = Offset(
                holeLeft + holeWidth / 2,
                holeTop + holeHeight / 2,
              );
              final startCircleRadius =
                  0.5 * math.sqrt(holeWidth * holeWidth + holeHeight * holeHeight);
              final endCircleRadius = <double>[
                (holeCenter - const Offset(0, 0)).distance,
                (holeCenter - Offset(constraints.maxWidth, 0)).distance,
                (holeCenter - Offset(0, constraints.maxHeight)).distance,
                (holeCenter -
                        Offset(constraints.maxWidth, constraints.maxHeight))
                    .distance,
              ].reduce((a, b) => a > b ? a : b);
              final finishCircleRadius = startCircleRadius +
                  (endCircleRadius - startCircleRadius) * finishExitT;
              final holePath = isFinishing && hasHole
                  ? (Path()
                    ..addOval(
                      Rect.fromCircle(
                        center: holeCenter,
                        radius: finishCircleRadius,
                      ),
                    ))
                  : (hole == null
                      ? null
                      : (Path()..addRRect(hole)));

              final reservedWidth = endHoleWidth * reserveT;
              final reservedHeight = maxReservedHeight * reserveT;

              return IgnorePointer(
                ignoring: isFinishing,
                child: Stack(
                  children: [
                    // Overlay mask
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OverlayMaskPainter(
                          overlayColor: colorScheme.surface,
                          holePath: holePath,
                        ),
                      ),
                    ),
                    // Hole content
                    Positioned.fill(
                      child: ClipPath(
                        clipper: _HoleClipper(holePath: holePath),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 112, 24, 24),
                              child: Column(
                                children: [
                                  // Title
                                  AnimatedSwitcher(
                                    duration: stageAnimDuration,
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder:
                                        (child, animation) {
                                      final currentTitleKey =
                                          ValueKey<bool>(showTopicStage);
                                      final isIncoming =
                                          child.key == currentTitleKey;

                                      return AnimatedBuilder(
                                        animation: animation,
                                        child: child,
                                        builder: (context, animatedChild) {
                                          final progress = isIncoming
                                              ? animation.value
                                              : 1 - animation.value;
                                          final opacity = isIncoming
                                              ? _splitFadeIn(progress)
                                              : _splitFadeOut(progress);
                                          final dy = isIncoming
                                              ? lineHeight *
                                                  (1 - animation.value)
                                              : -lineHeight *
                                                  (1 - animation.value);
                                          return Transform.translate(
                                            offset: Offset(0, dy),
                                            child: Opacity(
                                              opacity: opacity,
                                              child: animatedChild,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Text(
                                      showTopicStage
                                          ? '选择想体验的主题'
                                          : '选择您的同行者',
                                      key: ValueKey<bool>(showTopicStage),
                                      style: titleStyle,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Topic chips
                                  Container(
                                    height: 44,
                                    alignment: Alignment.center,
                                    child: AnimatedSlide(
                                      duration: stageAnimDuration,
                                      curve: Curves.easeInOutCubic,
                                      offset: showTopicStage
                                          ? Offset.zero
                                          : const Offset(0.8, 0),
                                      child: AnimatedOpacity(
                                        duration: stageAnimDuration,
                                        curve: showTopicStage
                                            ? const Interval(
                                                0.5,
                                                1,
                                                curve: Curves.easeOutCubic,
                                              )
                                            : const Interval(
                                                0,
                                                0.5,
                                                curve: Curves.easeInCubic,
                                              ),
                                        opacity: showTopicStage ? 1 : 0,
                                        child: IgnorePointer(
                                          ignoring: !showTopicStage,
                                          child: _buildTopicsChips(
                                            context,
                                            showTopicStage,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Reserved space
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: SizedBox(
                                      width: reservedWidth,
                                      height: reservedHeight,
                                    ),
                                  ),
                                  // Celebrity info
                                  Expanded(
                                    flex: 6,
                                    child: _CelebrityInfoSection(
                                      displayIndex: displayIndex,
                                      selected: selected,
                                      showTopicStage: showTopicStage,
                                      isForward: isForward,
                                      stageAnimDuration: stageAnimDuration,
                                      colorScheme: colorScheme,
                                      celebrityCount: celebrities.length,
                                      onGoToIndex: onGoToIndex,
                                    ),
                                  ),
                                  // Bio
                                  AnimatedSwitcher(
                                    duration: const Duration(
                                      milliseconds: 260,
                                    ),
                                    transitionBuilder: (child, animation) {
                                      return _buildEdgeSlideFadeTransition(
                                        context: context,
                                        child: child,
                                        animation: animation,
                                        isForward: isForward,
                                        selectedId: selectedId,
                                      );
                                    },
                                    child: Text(
                                      key: ValueKey<int>(selectedId),
                                      selectedBioShort,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: actionBarHeight + bottomInset + 8,
                                  ),
                                ],
                              ),
                            ),
                            // Action buttons
                            if (showActionButtons)
                              _ActionBar(
                                selectedName: selectedName,
                                showTopicStage: showTopicStage,
                                stageAnimDuration: stageAnimDuration,
                                phase: phase,
                                onBackStep: onBackStep,
                                onContinue: onContinue,
                              ),
                            // Skip button
                            if (showActionButtons)
                              Positioned(
                                top: 22,
                                right: 10,
                                child: TextButton(
                                  onPressed: onSkip ?? (() => Navigator.of(context).pop()),
                                  child: Text(
                                    '跳过',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopicsChips(BuildContext context, bool showTopicStage) {
    return FutureBuilder<List<TopicRecord>>(
      future: topicsFuture,
      builder: (context, topicSnapshot) {
        if (topicsFuture == null) {
          return const SizedBox.shrink();
        }

        if (topicSnapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        }

        if (topicSnapshot.hasError) {
          return Center(
            child: Text(
              '主题加载失败',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final topics =
            topicSnapshot.data ?? const <TopicRecord>[];
        final topicNames = topics
            .map((topic) => topic.name)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList(growable: false);

        if (topicNames.isEmpty) {
          return Center(
            child: Text(
              '暂无可选主题',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final selectedTopic = topicNames.contains(selectedTopicName)
            ? selectedTopicName
            : topicNames.first;

        return Align(
          alignment: Alignment.topCenter,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: topicNames
                .map(
                  (topicName) => ChoiceChip(
                    label: Text(topicName),
                    selected: selectedTopic == topicName,
                    onSelected: (_) {
                      onTopicSelected(topicName);
                    },
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
  }


}
