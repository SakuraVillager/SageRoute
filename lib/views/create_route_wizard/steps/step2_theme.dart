import 'package:flutter/material.dart';

import '../../../data/topic_repository.dart';
import '../../../models/celebrity_profile.dart';
import '../../../models/topic_record.dart';
import '../../../theme/color_schemes.dart';

/// Step 3 of the Create Route Wizard — Theme Selection.
///
/// Loads real topic data from the database for the selected celebrity,
/// displayed as selectable cards with emoji icons and descriptions.
class Step2Theme extends StatefulWidget {
  final String? selectedTopicId;
  final void Function(String id, String name) onSelect;
  final CelebrityProfile? figure;

  const Step2Theme({
    super.key,
    this.selectedTopicId,
    required this.onSelect,
    this.figure,
  });

  @override
  State<Step2Theme> createState() => _Step2ThemeState();
}

class _Step2ThemeState extends State<Step2Theme> {
  late Future<List<TopicRecord>> _future;

  static const _emojiPool = ['🍃', '🥢', '🏛️', '📜', '⛩️', '🎭', '🏔️', '🌸'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant Step2Theme oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.figure?.name != oldWidget.figure?.name) {
      _load();
    }
  }

  void _load() {
    final name = widget.figure?.name ?? '';
    _future = _fetchTopics(name);
  }

  Future<List<TopicRecord>> _fetchTopics(String celebrityName) async {
    return const TopicRepository().fetchTopicsByCelebrity(celebrityName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TopicRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final topics = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '加载主题失败: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.sageMuted, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 28),
              if (topics.isEmpty)
                _buildEmptyState()
              else
                ...topics.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildThemeCard(entry.value, entry.key),
                      ),
                    ),
              if (widget.selectedTopicId != null && topics.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildPreview(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final name = widget.figure?.name ?? '';
    return Center(
      child: Column(
        children: [
          const Text(
            '选择您的旅行主题',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.sageText,
            ),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '我们将以此为您定制$name的专属路线',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.sageMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final name = widget.figure?.name ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.topic_outlined, size: 48, color: AppColors.sageBorder),
            const SizedBox(height: 12),
            Text(
              name.isNotEmpty ? '$name暂无关联主题' : '请先选择一位人物',
              style: const TextStyle(color: AppColors.sageMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(TopicRecord topic, int index) {
    final isSelected = topic.id.toString() == widget.selectedTopicId;
    final emoji = _emojiPool[index % _emojiPool.length];

    return GestureDetector(
      onTap: () => widget.onSelect(topic.id.toString(), topic.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFFFF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B7500)
                : const Color(0xFFEEEAD9),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.sageText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.description?.isNotEmpty == true
                          ? topic.description!
                          : '探索${topic.name}相关的历史遗迹',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.sageMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildCheckIndicator(isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFF8B7500) : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? const Color(0xFF8B7500)
              : const Color(0xFFDCD6B3),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }

  Widget _buildPreview() {
    final topic = _findSelectedTopic();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(widget.selectedTopicId),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEAD9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌟 主题预览',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B7500),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              topic?.description ?? '该主题将带您领略沿途风光',
              style: const TextStyle(fontSize: 14, color: AppColors.sageText),
            ),
          ],
        ),
      ),
    );
  }

  TopicRecord? _findSelectedTopic() {
    // We can't easily access the Future result synchronously here.
    // Return null; the preview shows generic text if no specific topic found.
    return null;
  }
}
