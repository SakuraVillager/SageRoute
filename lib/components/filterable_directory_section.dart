import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';

const _directoryInset = EdgeInsets.symmetric(horizontal: 15);

/// A titled, independently filterable directory with stable-item transitions.
class FilterableDirectorySection<T> extends StatelessWidget {
  const FilterableDirectorySection({
    super.key,
    required this.title,
    required this.filterLabel,
    required this.options,
    required this.selectedOption,
    required this.emptyLabel,
    required this.items,
    required this.totalCount,
    required this.expanded,
    required this.onOptionChanged,
    required this.onExpansionChanged,
    required this.filterKeyPrefix,
    required this.itemId,
    required this.itemBuilder,
  });

  final String title;
  final String filterLabel;
  final List<String> options;
  final String selectedOption;
  final String emptyLabel;
  final List<T> items;
  final int totalCount;
  final bool expanded;
  final ValueChanged<String> onOptionChanged;
  final VoidCallback onExpansionChanged;
  final String filterKeyPrefix;
  final String Function(T item) itemId;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _directoryInset,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.brandInk,
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _DirectoryFilterRow(
          title: filterLabel,
          options: options,
          selectedOption: selectedOption,
          onSelected: onOptionChanged,
          keyPrefix: filterKeyPrefix,
        ),
        const SizedBox(height: 8),
        _AnimatedDirectoryResults<T>(
          key: Key('$filterKeyPrefix-directory-animated'),
          items: items,
          itemId: itemId,
          emptyLabel: emptyLabel,
          itemBuilder: itemBuilder,
        ),
        if (totalCount > 7)
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 4),
            child: TextButton(
              key: Key('$filterKeyPrefix-expand'),
              onPressed: onExpansionChanged,
              child: Text(expanded ? '收起' : '显示更多'),
            ),
          ),
      ],
    ),
  );
}

class _AnimatedDirectoryResults<T> extends StatefulWidget {
  const _AnimatedDirectoryResults({
    super.key,
    required this.items,
    required this.itemId,
    required this.emptyLabel,
    required this.itemBuilder,
  });

  final List<T> items;
  final String Function(T item) itemId;
  final String emptyLabel;
  final Widget Function(T item) itemBuilder;

  @override
  State<_AnimatedDirectoryResults<T>> createState() =>
      _AnimatedDirectoryResultsState<T>();
}

class _AnimatedDirectoryResultsState<T>
    extends State<_AnimatedDirectoryResults<T>> {
  final _listKey = GlobalKey<AnimatedListState>();
  late final List<T> _items = List<T>.of(widget.items);
  late bool _showEmptyLabel = _items.isEmpty;

  @override
  void didUpdateWidget(covariant _AnimatedDirectoryResults<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final desiredIds = widget.items.map(widget.itemId).toSet();
    _showEmptyLabel = false;

    for (var index = _items.length - 1; index >= 0; index--) {
      final item = _items[index];
      if (!desiredIds.contains(widget.itemId(item))) {
        _items.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _DirectoryExitTransition(
            animation: animation,
            child: widget.itemBuilder(item),
          ),
          duration: const Duration(milliseconds: 260),
        );
      }
    }

    if (_items.isEmpty) {
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted && _items.isEmpty) setState(() => _showEmptyLabel = true);
      });
    }

    final currentIds = _items.map(widget.itemId).toSet();
    for (
      var desiredIndex = 0;
      desiredIndex < widget.items.length;
      desiredIndex++
    ) {
      final item = widget.items[desiredIndex];
      if (currentIds.add(widget.itemId(item))) {
        final insertionIndex = desiredIndex.clamp(0, _items.length);
        _items.insert(insertionIndex, item);
        _listKey.currentState?.insertItem(insertionIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showEmptyLabel) {
      return Padding(
        padding: _directoryInset,
        child: Text(
          widget.emptyLabel,
          style: const TextStyle(color: AppColors.sageMuted),
        ),
      );
    }

    return Padding(
      padding: _directoryInset,
      child: AnimatedList(
        key: _listKey,
        initialItemCount: _items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index, animation) => _DirectoryEnterTransition(
          animation: animation,
          child: KeyedSubtree(
            key: ValueKey<String>(widget.itemId(_items[index])),
            child: widget.itemBuilder(_items[index]),
          ),
        ),
      ),
    );
  }
}

class _DirectoryEnterTransition extends StatelessWidget {
  const _DirectoryEnterTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      child: child,
    ),
  );
}

class _DirectoryExitTransition extends StatelessWidget {
  const _DirectoryExitTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) => Opacity(
      opacity: animation.value,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: (1 - animation.value) * 8,
          sigmaY: (1 - animation.value) * 8,
        ),
        child: Transform.scale(scale: animation.value, child: child),
      ),
    ),
  );
}

class _DirectoryFilterRow extends StatelessWidget {
  const _DirectoryFilterRow({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    required this.keyPrefix,
  });

  final String title;
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onSelected;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        SizedBox(
          key: Key('$keyPrefix-filter-label'),
          width: 46,
          child: Center(
            child: Text(
              title,
              key: Key('$keyPrefix-filter-label-text'),
              style: const TextStyle(color: AppColors.sageMuted, fontSize: 13),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(right: 15),
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 5),
            itemBuilder: (context, index) {
              final option = options[index];
              final selected = option == selectedOption;
              return Semantics(
                key: Key('$keyPrefix-filter-$option'),
                selected: selected,
                button: true,
                label: '$title $option',
                child: ChoiceChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (_) => onSelected(option),
                  showCheckmark: false,
                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -2,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 5),
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.brandInk,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  side: const BorderSide(color: AppColors.sageBorder),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
