import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';

/// A titled paged content rail for recommendations such as themes or routes.
class ContentCarousel<T> extends StatefulWidget {
  const ContentCarousel({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    required this.pageViewKey,
    this.height = 238,
    this.viewportFraction = 0.78,
    this.backgroundColor = AppColors.neutralDirectory,
    this.showPositionIndicator = false,
    this.positionIndicatorKey,
    this.activeIndicatorColor = AppColors.brand,
    this.inactiveIndicatorColor = AppColors.sageMuted,
  });

  final String title;
  final List<T> items;
  final Widget Function(BuildContext context, T item, double distance)
  itemBuilder;
  final Key pageViewKey;
  final double height;
  final double viewportFraction;
  final Color backgroundColor;
  final bool showPositionIndicator;
  final Key? positionIndicatorKey;
  final Color activeIndicatorColor;
  final Color inactiveIndicatorColor;

  @override
  State<ContentCarousel<T>> createState() => _ContentCarouselState<T>();
}

class _ContentCarouselState<T> extends State<ContentCarousel<T>> {
  late final PageController _controller;
  var _page = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction)
      ..addListener(() => setState(() => _page = _controller.page ?? 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.items.isEmpty
        ? 0
        : _page.round().clamp(0, widget.items.length - 1);
    final showPositionIndicator =
        widget.showPositionIndicator && widget.items.length > 1;

    return Container(
      color: widget.backgroundColor,
      padding: const EdgeInsets.only(top: 15, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.brandInk,
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            key: widget.pageViewKey,
            height: widget.height,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              itemBuilder: (context, index) => widget.itemBuilder(
                context,
                widget.items[index],
                (index - _page).abs().clamp(0.0, 1.0),
              ),
            ),
          ),
          if (showPositionIndicator)
            SizedBox(
              key: widget.positionIndicatorKey,
              height: 30,
              child: Center(
                child: Semantics(
                  label:
                      '${widget.title}，第 ${currentIndex + 1} 项，共 ${widget.items.length} 项',
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List<Widget>.generate(widget.items.length, (
                        index,
                      ) {
                        final active = index == currentIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: active
                                  ? widget.activeIndicatorColor
                                  : widget.inactiveIndicatorColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: SizedBox(width: active ? 25 : 5, height: 5),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
