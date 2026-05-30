import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/celebrity_repository.dart';
import '../../data/mock_figures.dart' as mock;
import '../../data/topic_repository.dart';
import '../../models/celebrity_profile.dart';
import '../../models/figure.dart';
import '../../models/topic_record.dart';
import '../../views/figure_detail_page.dart';

part 'celebrity_overlay_animation.dart';
part 'celebrity_overlay_painter.dart';
part 'celebrity_carousel_widgets.dart';

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
  bool _isFinishing = false;
  String? _topicsCelebrityName;
  String? _selectedTopicName;
  late final AnimationController _backgroundEntryController;
  late final AnimationController _pageEntryController;
  late final AnimationController _finishExitController;
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
    _finishExitController = AnimationController(
      vsync: this,
      duration: _stageAnimDuration,
    );

    _backgroundEntryController.addListener(_onBackgroundEntryTick);

    _backgroundEntryController.forward();

    _celebritiesFuture = _repository.fetchCelebrities();
  }

  void _onBackgroundEntryTick() {
    if (!_showPageReveal && _backgroundEntryController.value >= 0.8) {
      setState(() {
        _showPageReveal = true;
      });
      _pageEntryController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _backgroundEntryController.removeListener(_onBackgroundEntryTick);
    _backgroundEntryController.dispose();
    _pageEntryController.dispose();
    _finishExitController.dispose();
    super.dispose();
  }

  bool get _showTopicStage => _phase != _OverlayPhase.character;

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

  void _onContinuePressed(String celebrityName) {
    if (_phase == _OverlayPhase.reveal) {
      if (_isFinishing) {
        return;
      }
      setState(() {
        _isFinishing = true;
      });
      _finishExitController.forward(from: 0).whenComplete(() {
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

          return RepaintBoundary(
            child: AnimatedBuilder(
              animation: _backgroundEntryController,
              builder: (context, _) {
                final backgroundRevealT = Curves.easeOutCubic.transform(
                  _backgroundEntryController.value,
                );
                final backgroundRevealRadius =
                    revealStartRadius +
                    (farthestCornerDistance * backgroundRevealT);

                return Stack(
                  children: [
                    // Background circle reveal layer
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
                    // Page body layer — independently animated
                    if (_showPageReveal)
                      FutureBuilder<List<CelebrityProfile>>(
                        future: _celebritiesFuture,
                        builder: (context, snapshot) {
                          final isLoading =
                              snapshot.connectionState !=
                              ConnectionState.done;

                          if (isLoading) {
                            return RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _pageEntryController,
                                builder: (context, _) {
                                  final pageRevealT =
                                      Curves.easeOutCubic.transform(
                                        _pageEntryController.value,
                                      );
                                  final pageRevealRadius =
                                      revealStartRadius +
                                      (farthestCornerDistance * pageRevealT);
                                  final loadingOpacity =
                                      (1 - pageRevealT).clamp(0.0, 1.0);

                                  final loadingBody = Container(
                                    color: colorScheme.surface,
                                    child: Center(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerLowest,
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          border: Border.all(
                                            color:
                                                colorScheme.outlineVariant,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x14000000),
                                              blurRadius: 18,
                                              offset: Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                            horizontal: 18,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: colorScheme
                                                          .primary,
                                                    ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '加载人物中...',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurface,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  return Stack(
                                    children: [
                                      if (!_pageEntryController
                                          .isCompleted)
                                        Positioned.fill(
                                          child: ClipPath(
                                            clipper:
                                                _BottomCircleRevealClipper(
                                              center: revealCenter,
                                              radius: pageRevealRadius,
                                            ),
                                            child: loadingBody,
                                          ),
                                        )
                                      else
                                        Positioned.fill(
                                            child: loadingBody),
                                      if (_showPageReveal &&
                                          !_pageEntryController
                                              .isCompleted)
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: bottomInset + 28,
                                          child: IgnorePointer(
                                            child: Opacity(
                                              opacity: loadingOpacity,
                                              child: Center(
                                                child: Container(
                                                  width:
                                                      revealStartRadius *
                                                          2,
                                                  height:
                                                      revealStartRadius *
                                                          2,
                                                  decoration:
                                                      BoxDecoration(
                                                    shape:
                                                        BoxShape.circle,
                                                    color: colorScheme
                                                        .surfaceContainerHighest,
                                                  ),
                                                  child: Center(
                                                    child: SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        color: colorScheme
                                                            .primary,
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
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '人物数据加载失败',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: colorScheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            );
                          } else {
                            final celebrities =
                                snapshot.data ??
                                const <CelebrityProfile>[];
                            if (celebrities.isEmpty) {
                              return Center(
                                child: Text(
                                  '暂无人物数据',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              );
                            }

                            return RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _pageEntryController,
                                builder: (context, _) {
                                  final pageRevealT =
                                      Curves.easeOutCubic.transform(
                                        _pageEntryController.value,
                                      );
                                  final pageRevealRadius =
                                      revealStartRadius +
                                      (farthestCornerDistance * pageRevealT);

                                  final content = RepaintBoundary(
                                    child: AnimatedBuilder(
                                      animation: _finishExitController,
                                      builder: (context, _) {
                                        final finishExitT =
                                            Curves.easeOutCubic.transform(
                                          _finishExitController.value,
                                        );
                                        return _CelebrityCarouselContent(
                                          celebrities: celebrities,
                                          currentIndex: _currentIndex,
                                          previousIndex: _previousIndex,
                                          phase: _phase,
                                          isFinishing: _isFinishing,
                                          finishExitT: finishExitT,
                                          selectedTopicName:
                                              _selectedTopicName,
                                          topicsFuture: _topicsFuture,
                                          stageAnimDuration:
                                              _stageAnimDuration,
                                          showActionButtons:
                                              widget.showActionButtons,
                                          colorScheme: colorScheme,
                                          onSkip: skipHandler,
                                          onGoToIndex: (nextIndex) =>
                                              _goToIndex(
                                            nextIndex,
                                            celebrities,
                                          ),
                                          onHorizontalDragEnd: (details) =>
                                              _onHorizontalDragEnd(
                                            details,
                                            celebrities,
                                          ),
                                          onContinue: _onContinuePressed,
                                          onBackStep: _onBackStepPressed,
                                          onTopicSelected: (name) =>
                                              setState(() {
                                            _selectedTopicName = name;
                                          }),
                                        );
                                      },
                                    ),
                                  );

                                  if (!_pageEntryController.isCompleted) {
                                    return ClipPath(
                                      clipper: _BottomCircleRevealClipper(
                                        center: revealCenter,
                                        radius: pageRevealRadius,
                                      ),
                                      child: content,
                                    );
                                  }
                                  return content;
                                },
                              ),
                            );
                          }
                        },
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
