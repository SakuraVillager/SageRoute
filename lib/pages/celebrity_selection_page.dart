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
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showTopicStage ? '选择想体验的主题' : '选择您的同行者',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 28),
                          if (_showTopicStage)
                            FutureBuilder<List<TopicRecord>>(
                              future: _topicsFuture,
                              builder: (context, topicSnapshot) {
                                if (topicSnapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const Padding(
                                    padding: EdgeInsets.only(bottom: 20),
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
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Text(
                                      '主题加载失败',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
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
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Text(
                                      '暂无可选主题',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  );
                                }

                                final selectedTopic =
                                    topicNames.contains(_selectedTopicName)
                                    ? _selectedTopicName
                                    : topicNames.first;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: topicNames
                                        .map(
                                          (topicName) => ChoiceChip(
                                            label: Text(topicName),
                                            selected:
                                                selectedTopic == topicName,
                                            onSelected: (_) {
                                              setState(() {
                                                _selectedTopicName = topicName;
                                              });
                                            },
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                );
                              },
                            ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: _showTopicStage
                                ? const SizedBox.shrink()
                                : Row(
                                    key: ValueKey<String>('avatar-$selectedId'),
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        child: _currentIndex > 0
                                            ? IconButton(
                                                onPressed: () =>
                                                    _goPrevious(celebrities),
                                                icon: const Icon(
                                                  Icons.chevron_left_rounded,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                      Expanded(
                                        child: Center(
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
                                            child: Container(
                                              key: ValueKey<int>(selectedId),
                                              width: 160,
                                              height: 160,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: colorScheme
                                                    .primaryContainer,
                                                border: Border.all(
                                                  color: colorScheme.primary,
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
                                      SizedBox(
                                        width: 44,
                                        child:
                                            _currentIndex <
                                                celebrities.length - 1
                                            ? IconButton(
                                                onPressed: () =>
                                                    _goNext(celebrities),
                                                icon: const Icon(
                                                  Icons.chevron_right_rounded,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
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
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      child:
                                          _showTopicStage && _currentIndex > 0
                                          ? IconButton(
                                              onPressed: () =>
                                                  _goPrevious(celebrities),
                                              icon: const Icon(
                                                Icons.chevron_left_rounded,
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    Expanded(
                                      child: Text(
                                        selectedName,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 44,
                                      child:
                                          _showTopicStage &&
                                              _currentIndex <
                                                  celebrities.length - 1
                                          ? IconButton(
                                              onPressed: () =>
                                                  _goNext(celebrities),
                                              icon: const Icon(
                                                Icons.chevron_right_rounded,
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  selectedDynasty,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  selectedBioShort,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 56),
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
                                  onPressed: () =>
                                      _onContinuePressed(selectedName),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(_showTopicStage ? '完成' : '继续'),
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
        },
      ),
    );
  }
}
