import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/celebrity_repository.dart';
import '../data/supabase_table_repository.dart';
import '../data/topic_repository.dart';
import '../models/celebrity_profile.dart';
import '../models/topic_record.dart';

enum _OverlayPhase { character, reveal }

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

class _CelebritySelectionPageState extends State<CelebritySelectionPage>
    with TickerProviderStateMixin {
  final CelebrityRepository _repository = const CelebrityRepository();
  final TopicRepository _topicRepository = const TopicRepository();

  late final Future<List<CelebrityProfile>> _celebritiesFuture;
  Future<List<TopicRecord>>? _topicsFuture;

  int _currentIndex = 0;
  int _previousIndex = 0;
  _OverlayPhase _phase = _OverlayPhase.character;
  bool _overlayVisible = true;
  String? _topicsCelebrityName;
  String? _selectedTopicName;
  bool _databaseDumped = false;
  late final AnimationController _backgroundEntryController;
  late final AnimationController _pageEntryController;
  bool _showPageReveal = false;

  static const Duration _stageAnimDuration = Duration(milliseconds: 360);
  static const Duration _backgroundEntryDuration = Duration(milliseconds: 420);
  static const Duration _pageEntryDuration = Duration(milliseconds: 420);

  @override
  void initState() {
    super.initState();
    _backgroundEntryController = AnimationController(
      vsync: this,
      duration: _backgroundEntryDuration,
    );
    _pageEntryController = AnimationController(
      vsync: this,
      duration: _pageEntryDuration,
    );

    _backgroundEntryController.addListener(() {
      if (!_showPageReveal && _backgroundEntryController.value >= 0.8) {
        setState(() {
          _showPageReveal = true;
        });
        _pageEntryController.forward(from: 0);
      }
    });

    _backgroundEntryController.forward();

    _celebritiesFuture = Future<List<CelebrityProfile>>.delayed(
      Duration.zero,
      _repository.fetchCelebrities,
    );
  }

  @override
  void dispose() {
    _backgroundEntryController.dispose();
    _pageEntryController.dispose();
    super.dispose();
  }

  bool get _isForward => _currentIndex >= _previousIndex;
  bool get _showTopicStage => _phase != _OverlayPhase.character;
  bool get _showMapCutout => _phase == _OverlayPhase.reveal;

  static double _splitFadeIn(double t) => ((t - 0.5) * 2).clamp(0.0, 1.0);
  static double _splitFadeOut(double t) => (1 - 2 * t).clamp(0.0, 1.0);

  void _goToIndex(int nextIndex, List<CelebrityProfile> celebrities) {
    final maxCount = celebrities.length;
    if (nextIndex < 0 || nextIndex >= maxCount || nextIndex == _currentIndex) {
      return;
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = nextIndex;
      if (_showTopicStage) {
        _loadTopicsForCelebrity(celebrities[nextIndex].name);
      }
    });
  }

  void _goPrevious(List<CelebrityProfile> celebrities) =>
      _goToIndex(_currentIndex - 1, celebrities);

  void _goNext(List<CelebrityProfile> celebrities) =>
      _goToIndex(_currentIndex + 1, celebrities);

  void _onHorizontalDragEnd(
    DragEndDetails details,
    List<CelebrityProfile> celebrities,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) {
      return;
    }
    if (velocity < 0) {
      _goNext(celebrities);
    } else {
      _goPrevious(celebrities);
    }
  }

  void _loadTopicsForCelebrity(String celebrityName) {
    _topicsCelebrityName = celebrityName;
    _selectedTopicName = null;
    _topicsFuture = _topicRepository.fetchTopicsByCelebrity(celebrityName).then(
      (topics) {
        debugPrint('Topic匹配: celebrity=$celebrityName, count=${topics.length}');
        if (kDebugMode && topics.isEmpty) {
          _dumpDatabaseForDebug(celebrityName);
        }

        if (!mounted ||
            _phase == _OverlayPhase.character ||
            _topicsCelebrityName != celebrityName) {
          return topics;
        }

        final topicNames = topics
            .map((topic) => topic.name)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList(growable: false);
        if (topicNames.isNotEmpty && _selectedTopicName == null) {
          setState(() {
            _selectedTopicName = topicNames.first;
          });
        }
        return topics;
      },
    );
  }

  Future<void> _dumpDatabaseForDebug(String celebrityName) async {
    if (_databaseDumped) {
      return;
    }
    _databaseDumped = true;

    const tables = <String>[
      'Celebrity',
      'Topic',
      'Location',
      'poi_celebrity_relatian',
    ];

    for (final table in tables) {
      try {
        final rows = await SupabaseTableRepository(
          tableName: table,
        ).fetchAllRaw(limit: 5000);
        debugPrint('DB调试 table=$table, count=${rows.length}');
      } catch (error) {
        debugPrint('DB调试 table=$table error=$error');
      }
    }
  }

  void _onContinuePressed(String celebrityName) {
    if (_phase == _OverlayPhase.reveal) {
      if (!_overlayVisible) {
        return;
      }
      setState(() {
        _overlayVisible = false;
      });
      Future<void>.delayed(_stageAnimDuration, () {
        if (!mounted) {
          return;
        }
        widget.onContinue();
      });
      return;
    }

    setState(() {
      _phase = _OverlayPhase.reveal;
      _loadTopicsForCelebrity(celebrityName);
    });
  }

  void _onBackStepPressed() {
    if (_phase == _OverlayPhase.character) {
      return;
    }
    setState(() {
      _phase = _OverlayPhase.character;
    });
  }

  Widget _buildEdgeSlideFadeTransition({
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final skipHandler = widget.onSkip ?? () => Navigator.of(context).pop();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const actionBarHeight = 52.0;
    const revealStartRadius = 36.0;

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, rootConstraints) {
          final revealCenter = Offset(
            rootConstraints.maxWidth / 2,
            rootConstraints.maxHeight - bottomInset - 28 - actionBarHeight / 2,
          );
          final farthestCornerDistance = <double>[
            (revealCenter - const Offset(0, 0)).distance,
            (revealCenter - Offset(rootConstraints.maxWidth, 0)).distance,
            (revealCenter - Offset(0, rootConstraints.maxHeight)).distance,
            (revealCenter -
                    Offset(rootConstraints.maxWidth, rootConstraints.maxHeight))
                .distance,
          ].reduce((a, b) => a > b ? a : b);

          return AnimatedBuilder(
            animation: Listenable.merge([
              _backgroundEntryController,
              _pageEntryController,
            ]),
            builder: (context, _) {
              final backgroundRevealT = Curves.easeOutCubic.transform(
                _backgroundEntryController.value,
              );
              final pageRevealT = Curves.easeOutCubic.transform(
                _pageEntryController.value,
              );
              final backgroundRevealRadius =
                  revealStartRadius +
                  (farthestCornerDistance * backgroundRevealT);
              final pageRevealRadius =
                  revealStartRadius + (farthestCornerDistance * pageRevealT);

              return FutureBuilder<List<CelebrityProfile>>(
                future: _celebritiesFuture,
                builder: (context, snapshot) {
                  final isLoading =
                      snapshot.connectionState != ConnectionState.done;
                  final loadingOpacity = (1 - pageRevealT).clamp(0.0, 1.0);

                  Widget pageBody;
                  if (isLoading) {
                    pageBody = Container(
                      color: colorScheme.surface,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '加载人物中...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    pageBody = Center(
                      child: Text(
                        '人物数据加载失败',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  } else {
                    final celebrities =
                        snapshot.data ?? const <CelebrityProfile>[];
                    if (celebrities.isEmpty) {
                      pageBody = Center(
                        child: Text(
                          '暂无人物数据',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    } else {
                      final safeIndex = _currentIndex.clamp(
                        0,
                        celebrities.length - 1,
                      );
                      if (safeIndex != _currentIndex) {
                        _currentIndex = safeIndex;
                      }

                      final selected = celebrities[_currentIndex];
                      final selectedId = selected.id;
                      final selectedName = selected.name;
                      final selectedDynasty = selected.dynasty;
                      final selectedBioShort = selected.bioShort;

                      pageBody = GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragEnd: (details) =>
                            _onHorizontalDragEnd(details, celebrities),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final titleStyle = Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                );
                            final lineHeight =
                                (titleStyle?.fontSize ?? 24) *
                                (titleStyle?.height ?? 1.2);

                            return TweenAnimationBuilder<double>(
                              duration: _stageAnimDuration,
                              curve: Curves.easeInOutCubic,
                              tween: Tween<double>(
                                begin: 0,
                                end: _showMapCutout ? 1 : 0,
                              ),
                              builder: (context, cutoutT, child) {
                                final reserveT = cutoutT.clamp(0.0, 1.0);
                                final holeT = ((cutoutT - 0.5) * 2).clamp(
                                  0.0,
                                  1.0,
                                );

                                final endHoleWidth =
                                    ((constraints.maxWidth - 52) *
                                            (0.58 + 0.32 * 1.0))
                                        .clamp(
                                          180.0,
                                          constraints.maxWidth - 24,
                                        );
                                final endHoleHeight = (96 + 150 * 1.0).clamp(
                                  96.0,
                                  constraints.maxHeight * 0.45,
                                );
                                final maxReservedHeight =
                                    (endHoleHeight - 160.0)
                                        .clamp(0.0, constraints.maxHeight)
                                        .toDouble();

                                final holeWidth =
                                    ((constraints.maxWidth - 52) *
                                            (0.58 + 0.32 * holeT))
                                        .clamp(
                                          180.0,
                                          constraints.maxWidth - 24,
                                        );
                                final holeHeight = (96 + 150 * holeT).clamp(
                                  96.0,
                                  constraints.maxHeight * 0.45,
                                );
                                final holeTop =
                                    constraints.maxHeight *
                                    (0.36 - 0.08 * holeT);
                                final holeLeft =
                                    (constraints.maxWidth - holeWidth) / 2;

                                final hasHole = holeT > 0.001;
                                final hole = hasHole
                                    ? RRect.fromRectAndRadius(
                                        Rect.fromLTWH(
                                          holeLeft,
                                          holeTop,
                                          holeWidth,
                                          holeHeight,
                                        ),
                                        Radius.circular(24 + 12 * holeT),
                                      )
                                    : null;

                                final reservedWidth = endHoleWidth * reserveT;
                                final reservedHeight =
                                    maxReservedHeight * reserveT;

                                return AnimatedOpacity(
                                  duration: _stageAnimDuration,
                                  curve: Curves.easeInOutCubic,
                                  opacity: _overlayVisible ? 1 : 0,
                                  child: IgnorePointer(
                                    ignoring: !_overlayVisible,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: _OverlayMaskPainter(
                                              overlayColor: colorScheme.surface,
                                              hole: hole,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            24,
                                            112,
                                            24,
                                            24,
                                          ),
                                          child: Column(
                                            children: [
                                              AnimatedSwitcher(
                                                duration: _stageAnimDuration,
                                                switchInCurve:
                                                    Curves.easeOutCubic,
                                                switchOutCurve:
                                                    Curves.easeInCubic,
                                                transitionBuilder: (child, animation) {
                                                  final currentTitleKey =
                                                      ValueKey<bool>(
                                                        _showTopicStage,
                                                      );
                                                  final isIncoming =
                                                      child.key ==
                                                      currentTitleKey;

                                                  return AnimatedBuilder(
                                                    animation: animation,
                                                    child: child,
                                                    builder: (context, animatedChild) {
                                                      final progress =
                                                          isIncoming
                                                          ? animation.value
                                                          : 1 - animation.value;
                                                      final opacity = isIncoming
                                                          ? _splitFadeIn(
                                                              progress,
                                                            )
                                                          : _splitFadeOut(
                                                              progress,
                                                            );
                                                      final dy = isIncoming
                                                          ? lineHeight *
                                                                (1 -
                                                                    animation
                                                                        .value)
                                                          : -lineHeight *
                                                                (1 -
                                                                    animation
                                                                        .value);
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
                                                  _showTopicStage
                                                      ? '选择想体验的主题'
                                                      : '选择您的同行者',
                                                  key: ValueKey<bool>(
                                                    _showTopicStage,
                                                  ),
                                                  style: titleStyle,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                height: 44,
                                                alignment: Alignment.center,
                                                child: AnimatedSlide(
                                                  duration: _stageAnimDuration,
                                                  curve: Curves.easeInOutCubic,
                                                  offset: _showTopicStage
                                                      ? Offset.zero
                                                      : const Offset(0.8, 0),
                                                  child: AnimatedOpacity(
                                                    duration:
                                                        _stageAnimDuration,
                                                    curve: _showTopicStage
                                                        ? const Interval(
                                                            0.5,
                                                            1,
                                                            curve: Curves
                                                                .easeOutCubic,
                                                          )
                                                        : const Interval(
                                                            0,
                                                            0.5,
                                                            curve: Curves
                                                                .easeInCubic,
                                                          ),
                                                    opacity: _showTopicStage
                                                        ? 1
                                                        : 0,
                                                    child: IgnorePointer(
                                                      ignoring:
                                                          !_showTopicStage,
                                                      child: FutureBuilder<List<TopicRecord>>(
                                                        future: _topicsFuture,
                                                        builder: (context, topicSnapshot) {
                                                          if (_topicsFuture ==
                                                              null) {
                                                            return const SizedBox.shrink();
                                                          }

                                                          if (topicSnapshot
                                                                  .connectionState !=
                                                              ConnectionState
                                                                  .done) {
                                                            return const Center(
                                                              child: SizedBox(
                                                                width: 24,
                                                                height: 24,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2.2,
                                                                    ),
                                                              ),
                                                            );
                                                          }

                                                          if (topicSnapshot
                                                              .hasError) {
                                                            return Center(
                                                              child: Text(
                                                                '主题加载失败',
                                                                style: Theme.of(
                                                                  context,
                                                                ).textTheme.bodyMedium,
                                                              ),
                                                            );
                                                          }

                                                          final topics =
                                                              topicSnapshot
                                                                  .data ??
                                                              const <
                                                                TopicRecord
                                                              >[];
                                                          final topicNames = topics
                                                              .map(
                                                                (topic) =>
                                                                    topic.name,
                                                              )
                                                              .where(
                                                                (name) => name
                                                                    .isNotEmpty,
                                                              )
                                                              .toSet()
                                                              .toList(
                                                                growable: false,
                                                              );

                                                          if (topicNames
                                                              .isEmpty) {
                                                            return Center(
                                                              child: Text(
                                                                '暂无可选主题',
                                                                style: Theme.of(
                                                                  context,
                                                                ).textTheme.bodyMedium,
                                                              ),
                                                            );
                                                          }

                                                          final selectedTopic =
                                                              topicNames.contains(
                                                                _selectedTopicName,
                                                              )
                                                              ? _selectedTopicName
                                                              : topicNames
                                                                    .first;

                                                          return Align(
                                                            alignment: Alignment
                                                                .topCenter,
                                                            child: Wrap(
                                                              alignment:
                                                                  WrapAlignment
                                                                      .center,
                                                              spacing: 10,
                                                              runSpacing: 10,
                                                              children: topicNames
                                                                  .map(
                                                                    (
                                                                      topicName,
                                                                    ) => ChoiceChip(
                                                                      label: Text(
                                                                        topicName,
                                                                      ),
                                                                      selected:
                                                                          selectedTopic ==
                                                                          topicName,
                                                                      onSelected: (_) {
                                                                        setState(() {
                                                                          _selectedTopicName =
                                                                              topicName;
                                                                        });
                                                                      },
                                                                    ),
                                                                  )
                                                                  .toList(
                                                                    growable:
                                                                        false,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topCenter,
                                                child: SizedBox(
                                                  width: reservedWidth,
                                                  height: reservedHeight,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 6,
                                                child: TweenAnimationBuilder<double>(
                                                  duration: _stageAnimDuration,
                                                  curve: Curves.easeInOutCubic,
                                                  tween: Tween<double>(
                                                    begin: 0,
                                                    end: _showTopicStage
                                                        ? 1
                                                        : 0,
                                                  ),
                                                  builder: (context, t, child) {
                                                    final hasDynasty =
                                                        selectedDynasty
                                                            .trim()
                                                            .isNotEmpty;
                                                    const nameOffsetY = 0.0;
                                                    final nameStyle = Theme.of(
                                                      context,
                                                    ).textTheme.headlineMedium;
                                                    final nameLineHeight =
                                                        (nameStyle?.fontSize ??
                                                            28) *
                                                        (nameStyle?.height ??
                                                            1.2);

                                                    const avatarTop = 8.0;
                                                    const avatarSize = 160.0;
                                                    const avatarNameGap = 20.0;
                                                    final nameTop =
                                                        avatarTop +
                                                        avatarSize +
                                                        avatarNameGap +
                                                        nameOffsetY;

                                                    final stageOneArrowCenter =
                                                        (avatarTop +
                                                            (nameTop +
                                                                nameLineHeight)) /
                                                        2;
                                                    final stageTwoArrowCenter =
                                                        nameTop +
                                                        nameLineHeight / 2;
                                                    final arrowCenter =
                                                        stageOneArrowCenter +
                                                        (stageTwoArrowCenter -
                                                                stageOneArrowCenter) *
                                                            t;
                                                    final arrowTop =
                                                        arrowCenter - 24;

                                                    return Stack(
                                                      children: [
                                                        Column(
                                                          children: [
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Opacity(
                                                              opacity:
                                                                  _splitFadeOut(
                                                                    t,
                                                                  ),
                                                              child: IgnorePointer(
                                                                ignoring:
                                                                    _showTopicStage,
                                                                child: Center(
                                                                  child: AnimatedSwitcher(
                                                                    duration: const Duration(
                                                                      milliseconds:
                                                                          260,
                                                                    ),
                                                                    transitionBuilder:
                                                                        (
                                                                          child,
                                                                          animation,
                                                                        ) {
                                                                          return _buildEdgeSlideFadeTransition(
                                                                            child:
                                                                                child,
                                                                            animation:
                                                                                animation,
                                                                            isForward:
                                                                                _isForward,
                                                                            selectedId:
                                                                                selectedId,
                                                                          );
                                                                        },
                                                                    child: Container(
                                                                      key:
                                                                          ValueKey<
                                                                            int
                                                                          >(
                                                                            selectedId,
                                                                          ),
                                                                      width:
                                                                          160,
                                                                      height:
                                                                          160,
                                                                      decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: colorScheme
                                                                            .primaryContainer,
                                                                        border: Border.all(
                                                                          color:
                                                                              colorScheme.primary,
                                                                          width:
                                                                              4,
                                                                        ),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .person,
                                                                        size:
                                                                            80,
                                                                        color: colorScheme
                                                                            .onPrimaryContainer,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 20,
                                                            ),
                                                            Transform.translate(
                                                              offset: Offset(
                                                                0,
                                                                nameOffsetY,
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  const SizedBox(
                                                                    width: 44,
                                                                  ),
                                                                  Expanded(
                                                                    child: AnimatedSwitcher(
                                                                      duration: const Duration(
                                                                        milliseconds:
                                                                            260,
                                                                      ),
                                                                      transitionBuilder:
                                                                          (
                                                                            child,
                                                                            animation,
                                                                          ) {
                                                                            return _buildEdgeSlideFadeTransition(
                                                                              child: child,
                                                                              animation: animation,
                                                                              isForward: _isForward,
                                                                              selectedId: selectedId,
                                                                            );
                                                                          },
                                                                      child: Column(
                                                                        key:
                                                                            ValueKey<
                                                                              int
                                                                            >(
                                                                              selectedId,
                                                                            ),
                                                                        children: [
                                                                          Text(
                                                                            selectedName,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style:
                                                                                Theme.of(
                                                                                  context,
                                                                                ).textTheme.headlineMedium?.copyWith(
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: colorScheme.primary,
                                                                                ),
                                                                          ),
                                                                          if (hasDynasty) ...[
                                                                            const SizedBox(
                                                                              height: 8,
                                                                            ),
                                                                            Text(
                                                                              selectedDynasty,
                                                                              style:
                                                                                  Theme.of(
                                                                                    context,
                                                                                  ).textTheme.bodySmall?.copyWith(
                                                                                    color: colorScheme.onSurfaceVariant,
                                                                                  ),
                                                                            ),
                                                                          ],
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 44,
                                                                  ),
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
                                                            child:
                                                                _currentIndex >
                                                                    0
                                                                ? IconButton(
                                                                    onPressed: () =>
                                                                        _goPrevious(
                                                                          celebrities,
                                                                        ),
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .chevron_left_rounded,
                                                                    ),
                                                                  )
                                                                : const SizedBox.shrink(),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          right: 0,
                                                          top: arrowTop,
                                                          child: SizedBox(
                                                            width: 44,
                                                            child:
                                                                _currentIndex <
                                                                    celebrities
                                                                            .length -
                                                                        1
                                                                ? IconButton(
                                                                    onPressed: () =>
                                                                        _goNext(
                                                                          celebrities,
                                                                        ),
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .chevron_right_rounded,
                                                                    ),
                                                                  )
                                                                : const SizedBox.shrink(),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                              AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 260,
                                                ),
                                                transitionBuilder:
                                                    (child, animation) {
                                                      return _buildEdgeSlideFadeTransition(
                                                        child: child,
                                                        animation: animation,
                                                        isForward: _isForward,
                                                        selectedId: selectedId,
                                                      );
                                                    },
                                                child: Text(
                                                  key: ValueKey<int>(
                                                    selectedId,
                                                  ),
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
                                                height:
                                                    actionBarHeight +
                                                    bottomInset +
                                                    8,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.showActionButtons)
                                          Positioned(
                                            left: 24,
                                            right: 24,
                                            bottom: 28 + bottomInset,
                                            child: SizedBox(
                                              height: actionBarHeight,
                                              child: LayoutBuilder(
                                                builder: (context, actionConstraints) {
                                                  final totalWidth =
                                                      actionConstraints
                                                          .maxWidth;
                                                  final backWidth =
                                                      _showTopicStage
                                                      ? (totalWidth * 0.34)
                                                            .clamp(96.0, 180.0)
                                                      : 0.0;
                                                  final gapWidth =
                                                      _showTopicStage
                                                      ? 12.0
                                                      : 0.0;
                                                  final continueWidth =
                                                      totalWidth -
                                                      backWidth -
                                                      gapWidth;

                                                  return Row(
                                                    children: [
                                                      AnimatedContainer(
                                                        duration:
                                                            _stageAnimDuration,
                                                        curve: Curves
                                                            .easeInOutCubic,
                                                        width: backWidth,
                                                        child: AnimatedOpacity(
                                                          duration:
                                                              _stageAnimDuration,
                                                          curve: _showTopicStage
                                                              ? const Interval(
                                                                  0.5,
                                                                  1,
                                                                  curve: Curves
                                                                      .easeOutCubic,
                                                                )
                                                              : const Interval(
                                                                  0,
                                                                  0.5,
                                                                  curve: Curves
                                                                      .easeInCubic,
                                                                ),
                                                          opacity:
                                                              _showTopicStage
                                                              ? 1
                                                              : 0,
                                                          child: IgnorePointer(
                                                            ignoring:
                                                                !_showTopicStage,
                                                            child: OutlinedButton(
                                                              onPressed:
                                                                  _onBackStepPressed,
                                                              style: OutlinedButton.styleFrom(
                                                                minimumSize:
                                                                    const Size(
                                                                      0,
                                                                      actionBarHeight,
                                                                    ),
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          20,
                                                                    ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        30,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                '上一步',
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      AnimatedContainer(
                                                        duration:
                                                            _stageAnimDuration,
                                                        curve: Curves
                                                            .easeInOutCubic,
                                                        width: gapWidth,
                                                      ),
                                                      AnimatedContainer(
                                                        duration:
                                                            _stageAnimDuration,
                                                        curve: Curves
                                                            .easeInOutCubic,
                                                        width: continueWidth,
                                                        child: FilledButton(
                                                          onPressed: () =>
                                                              _onContinuePressed(
                                                                selectedName,
                                                              ),
                                                          style: FilledButton.styleFrom(
                                                            minimumSize:
                                                                const Size(
                                                                  0,
                                                                  actionBarHeight,
                                                                ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      32,
                                                                ),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    30,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            _phase ==
                                                                    _OverlayPhase
                                                                        .reveal
                                                                ? '完成'
                                                                : '继续',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        if (widget.showActionButtons)
                                          Positioned(
                                            top: 22,
                                            right: 10,
                                            child: TextButton(
                                              onPressed: skipHandler,
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
                                );
                              },
                            );
                          },
                        ),
                      );
                    }
                  }

                  return Stack(
                    children: [
                      if (!_pageEntryController.isCompleted)
                        Positioned.fill(
                          child: ClipPath(
                            clipper: _BottomCircleRevealClipper(
                              center: revealCenter,
                              radius: backgroundRevealRadius,
                            ),
                            child: ColoredBox(color: colorScheme.primary),
                          ),
                        ),
                      if (_showPageReveal)
                        Positioned.fill(
                          child: _pageEntryController.isCompleted
                              ? pageBody
                              : ClipPath(
                                  clipper: _BottomCircleRevealClipper(
                                    center: revealCenter,
                                    radius: pageRevealRadius,
                                  ),
                                  child: pageBody,
                                ),
                        ),
                      if (isLoading &&
                          _showPageReveal &&
                          !_pageEntryController.isCompleted)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: bottomInset + 28,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: loadingOpacity,
                              child: Center(
                                child: Container(
                                  width: revealStartRadius * 2,
                                  height: revealStartRadius * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.surfaceContainerHighest,
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BottomCircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const _BottomCircleRevealClipper({
    required this.center,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _BottomCircleRevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

class _OverlayMaskPainter extends CustomPainter {
  final Color overlayColor;
  final RRect? hole;

  const _OverlayMaskPainter({required this.overlayColor, required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()..addRect(Offset.zero & size);
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (hole == null) {
      canvas.drawPath(overlayPath, paint);
      return;
    }

    final holePath = Path()..addRRect(hole!);
    final maskedPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      holePath,
    );
    canvas.drawPath(maskedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayMaskPainter oldDelegate) {
    return oldDelegate.overlayColor != overlayColor || oldDelegate.hole != hole;
  }
}
