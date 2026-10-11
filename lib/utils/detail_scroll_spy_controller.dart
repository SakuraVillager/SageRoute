import 'package:flutter/material.dart';

class DetailScrollSpyController {
  DetailScrollSpyController({required int sectionCount, this.tabStride = 90})
    : scrollController = ScrollController(),
      tabScrollController = ScrollController(),
      sectionKeys = List<GlobalKey>.generate(sectionCount, (_) => GlobalKey()),
      _sectionScrollOffsets = List<double?>.filled(sectionCount, null);

  final ScrollController scrollController;
  final ScrollController tabScrollController;
  final List<GlobalKey> sectionKeys;
  final double tabStride;

  final List<double?> _sectionScrollOffsets;
  bool _isProgrammaticScroll = false;

  void dispose() {
    scrollController.dispose();
    tabScrollController.dispose();
  }

  void updateSectionOffsets() {
    final scrollOffset = scrollController.hasClients
        ? scrollController.offset
        : 0.0;

    for (var i = 0; i < sectionKeys.length; i++) {
      final sectionContext = sectionKeys[i].currentContext;
      final renderObject = sectionContext?.findRenderObject();
      if (renderObject is RenderBox) {
        _sectionScrollOffsets[i] =
            renderObject.localToGlobal(Offset.zero).dy + scrollOffset;
      }
    }
  }

  int activeSectionIndex({
    required double pinnedOffset,
    required int currentIndex,
  }) {
    if (_isProgrammaticScroll || !scrollController.hasClients) {
      return currentIndex;
    }

    final scrollOffset = scrollController.offset;
    for (var i = _sectionScrollOffsets.length - 1; i >= 0; i--) {
      final sectionOffset = _sectionScrollOffsets[i];
      if (sectionOffset == null) {
        continue;
      }

      if (sectionOffset - scrollOffset <= pinnedOffset) {
        return i;
      }
    }

    return 0;
  }

  void scrollTabIntoView(
    int index, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeOut,
  }) {
    if (!tabScrollController.hasClients) {
      return;
    }

    final targetOffset = index * tabStride;
    final clampedOffset = targetOffset.clamp(
      0.0,
      tabScrollController.position.maxScrollExtent,
    );

    tabScrollController.animateTo(
      clampedOffset,
      duration: duration,
      curve: curve,
    );
  }

  Future<void> scrollToSection({
    required int index,
    required BuildContext context,
    required double pinnedOffset,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (index < 0 || index >= sectionKeys.length) {
      return;
    }

    final sectionContext = sectionKeys[index].currentContext;
    if (sectionContext == null) {
      return;
    }

    _isProgrammaticScroll = true;
    try {
      await Scrollable.ensureVisible(
        sectionContext,
        duration: duration,
        curve: curve,
        alignment: pinnedOffset / MediaQuery.sizeOf(context).height,
      );
    } finally {
      _isProgrammaticScroll = false;
      updateSectionOffsets();
    }
  }
}
