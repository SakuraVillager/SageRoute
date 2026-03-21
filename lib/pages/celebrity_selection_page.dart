import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/celebrity_repository.dart';
import '../data/supabase_table_repository.dart';
import '../data/topic_repository.dart';
import '../models/celebrity_profile.dart';
import '../models/topic_record.dart';

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
  final TopicRepository _topicRepository = const TopicRepository();
  late final Future<List<CelebrityProfile>> _celebritiesFuture;
  Future<List<TopicRecord>>? _topicsFuture;

  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _showTopicStage = false;
  String? _topicsCelebrityName;
  String? _selectedTopicName;
  bool _databaseDumped = false;

  @override
  void initState() {
    super.initState();
    _celebritiesFuture = _repository.fetchCelebrities();
  }

  bool get _isForward => _currentIndex >= _previousIndex;

  static const Duration _stageAnimDuration = Duration(milliseconds: 360);

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
            !_showTopicStage ||
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

        if (table == 'Topic') {
          final topicRows = rows;
          final topicCelebrities =
              topicRows
                  .map((row) => (row['celebrity'] ?? '').toString())
                  .where((name) => name.trim().isNotEmpty)
                  .toSet()
                  .toList(growable: false)
                ..sort();
          final matched = topicRows
              .where(
                (row) =>
                    (row['celebrity'] ?? '').toString().contains(celebrityName),
              )
              .toList(growable: false);

          debugPrint(
            'DB调试 Topic.celebrity distinct=${topicCelebrities.length}',
          );
          for (final name in topicCelebrities.take(50)) {
            debugPrint('DB调试 Topic.celebrity -> $name');
          }
          debugPrint(
            'DB调试 Topic contains[$celebrityName] rows=${matched.length}',
          );
          for (final row in matched.take(20)) {
            debugPrint(
              'DB调试 Topic命中 celebrity=${row['celebrity']} name=${row['name']}',
            );
          }
        }
      } catch (error) {
        debugPrint('DB调试 table=$table error=$error');
      }
    }
  }

  void _onContinuePressed(String celebrityName) {
    if (_showTopicStage) {
      widget.onContinue();
      return;
    }

    setState(() {
      _showTopicStage = true;
      _loadTopicsForCelebrity(celebrityName);
    });
  }

  void _onBackStepPressed() {
    if (!_showTopicStage) {
      return;
    }
    setState(() {
      _showTopicStage = false;
    });
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
        final progress = animation.value;
        final offsetX = beginOffsetX * (1 - progress);
        final opacity = isEntering
            ? _splitFadeIn(progress)
            : _splitFadeOut(progress);
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

    return Material(
      color: colorScheme.surface,
      child: FutureBuilder<List<CelebrityProfile>>(
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

          final celebrities = snapshot.data ?? const <CelebrityProfile>[];
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
          final selectedId = selected.id;
          final selectedName = selected.name;
          final selectedDynasty = selected.dynasty;
          final selectedBioShort = selected.bioShort;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) =>
                _onHorizontalDragEnd(details, celebrities),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final titleStyle = Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    );
                final lineHeight =
                    (titleStyle?.fontSize ?? 24) * (titleStyle?.height ?? 1.2);

                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: _stageAnimDuration,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              final currentTitleKey = ValueKey<bool>(
                                _showTopicStage,
                              );
                              final isIncoming = child.key == currentTitleKey;

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
                                      ? lineHeight * (1 - animation.value)
                                      : -lineHeight * (1 - animation.value);
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
                              _showTopicStage ? '选择想体验的主题' : '选择您的同行者',
                              key: ValueKey<bool>(_showTopicStage),
                              style: titleStyle,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            flex: 2,
                            child: AnimatedSlide(
                              duration: _stageAnimDuration,
                              curve: Curves.easeInOutCubic,
                              offset: _showTopicStage
                                  ? Offset.zero
                                  : const Offset(0.8, 0),
                              child: AnimatedOpacity(
                                duration: _stageAnimDuration,
                                curve: _showTopicStage
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
                                opacity: _showTopicStage ? 1 : 0,
                                child: IgnorePointer(
                                  ignoring: !_showTopicStage,
                                  child: FutureBuilder<List<TopicRecord>>(
                                    future: _topicsFuture,
                                    builder: (context, topicSnapshot) {
                                      if (_topicsFuture == null) {
                                        return const SizedBox.shrink();
                                      }

                                      if (topicSnapshot.connectionState !=
                                          ConnectionState.done) {
                                        return const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                            ),
                                          ),
                                        );
                                      }

                                      if (topicSnapshot.hasError) {
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
                                          topicSnapshot.data ??
                                          const <TopicRecord>[];
                                      final topicNames = topics
                                          .map((topic) => topic.name)
                                          .where((name) => name.isNotEmpty)
                                          .toSet()
                                          .toList(growable: false);

                                      if (topicNames.isEmpty) {
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
                                              .toList(growable: false),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: LayoutBuilder(
                              builder: (context, stageConstraints) {
                                final stageHeight = stageConstraints.maxHeight;
                                final hasDynasty = selectedDynasty
                                    .trim()
                                    .isNotEmpty;
                                final nameStyle = Theme.of(
                                  context,
                                ).textTheme.headlineMedium;
                                final nameLineHeight =
                                    (nameStyle?.fontSize ?? 28) *
                                    (nameStyle?.height ?? 1.2);
                                return TweenAnimationBuilder<double>(
                                  duration: _stageAnimDuration,
                                  curve: Curves.easeInOutCubic,
                                  tween: Tween<double>(
                                    begin: 0,
                                    end: _showTopicStage ? 1 : 0,
                                  ),
                                  builder: (context, t, child) {
                                    final avatarTop = stageHeight * 0.06;
                                    final nameTop =
                                        stageHeight * (0.64 + (-0.46 * t));
                                    final stageOneArrowTop = stageHeight * 0.30;
                                    final stageTwoArrowTop =
                                        stageHeight * 0.18 +
                                        (nameLineHeight - 48) / 2;
                                    final arrowTop =
                                        stageOneArrowTop +
                                        (stageTwoArrowTop - stageOneArrowTop) *
                                            t;

                                    return Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          top: avatarTop,
                                          child: Opacity(
                                            opacity: _splitFadeOut(t),
                                            child: IgnorePointer(
                                              ignoring: _showTopicStage,
                                              child: Center(
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 260,
                                                  ),
                                                  transitionBuilder:
                                                      (child, animation) {
                                                        return _buildEdgeSlideFadeTransition(
                                                          child: child,
                                                          animation: animation,
                                                          isForward: _isForward,
                                                          selectedId:
                                                              selectedId,
                                                        );
                                                      },
                                                  child: Container(
                                                    key: ValueKey<int>(
                                                      selectedId,
                                                    ),
                                                    width: 160,
                                                    height: 160,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: colorScheme
                                                          .primaryContainer,
                                                      border: Border.all(
                                                        color:
                                                            colorScheme.primary,
                                                        width: 4,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 80,
                                                      color: colorScheme
                                                          .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          top: nameTop,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 260,
                                            ),
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
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            colorScheme.primary,
                                                      ),
                                                ),
                                                if (hasDynasty) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    selectedDynasty,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          top: arrowTop,
                                          child: SizedBox(
                                            width: 44,
                                            child: _currentIndex > 0
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
                                                    celebrities.length - 1
                                                ? IconButton(
                                                    onPressed: () =>
                                                        _goNext(celebrities),
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
                                );
                              },
                            ),
                          ),
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
                            child: Text(
                              key: ValueKey<int>(selectedId),
                              selectedBioShort,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          SizedBox(height: actionBarHeight + bottomInset + 20),
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
                              final totalWidth = actionConstraints.maxWidth;
                              final backWidth = _showTopicStage
                                  ? (totalWidth * 0.34).clamp(96.0, 180.0)
                                  : 0.0;
                              final gapWidth = _showTopicStage ? 12.0 : 0.0;
                              final continueWidth =
                                  totalWidth - backWidth - gapWidth;

                              return Row(
                                children: [
                                  AnimatedContainer(
                                    duration: _stageAnimDuration,
                                    curve: Curves.easeInOutCubic,
                                    width: backWidth,
                                    child: AnimatedOpacity(
                                      duration: _stageAnimDuration,
                                      curve: _showTopicStage
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
                                      opacity: _showTopicStage ? 1 : 0,
                                      child: IgnorePointer(
                                        ignoring: !_showTopicStage,
                                        child: OutlinedButton(
                                          onPressed: _onBackStepPressed,
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(
                                              0,
                                              actionBarHeight,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: const Text('上一步'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: _stageAnimDuration,
                                    curve: Curves.easeInOutCubic,
                                    width: gapWidth,
                                  ),
                                  AnimatedContainer(
                                    duration: _stageAnimDuration,
                                    curve: Curves.easeInOutCubic,
                                    width: continueWidth,
                                    child: FilledButton(
                                      onPressed: () =>
                                          _onContinuePressed(selectedName),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size(
                                          0,
                                          actionBarHeight,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _showTopicStage ? '完成' : '继续',
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
