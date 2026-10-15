import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/color_schemes.dart';

/// A contrasting browser back control without a hover tooltip.
class WebBackButton extends StatefulWidget {
  const WebBackButton({
    super.key,
    required this.onPressed,
    this.mobileChild,
    this.size = 40,
  });

  final VoidCallback onPressed;
  final Widget? mobileChild;
  final double size;

  @override
  State<WebBackButton> createState() => _WebBackButtonState();
}

class _WebBackButtonState extends State<WebBackButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return widget.mobileChild ??
          IconButton(
            onPressed: widget.onPressed,
            icon: const Icon(Icons.arrow_back),
          );
    }
    final active = _hovered || _focused;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        label: MaterialLocalizations.of(context).backButtonTooltip,
        button: true,
        child: AnimatedContainer(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _pressed
                  ? [
                      AppColors.brandDark,
                      AppColors.brandDeeper,
                      AppColors.brandDeeper,
                    ]
                  : active
                  ? [
                      AppColors.brandMedium,
                      AppColors.brandDark,
                      AppColors.brandDeeper,
                    ]
                  : [AppColors.brand, AppColors.brand, AppColors.brandDark],
              stops: const [0, 0.35, 1],
            ),
            border: Border.all(
              color: _focused ? AppColors.brandInk : AppColors.brandPale,
              width: _focused ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandDeeper.withValues(
                  alpha: active ? 0.28 : 0.12,
                ),
                blurRadius: active ? 12 : 4,
                offset: Offset(0, active ? 4 : 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              onHover: (value) => setState(() => _hovered = value),
              onFocusChange: (value) => setState(() => _focused = value),
              onHighlightChanged: (value) => setState(() => _pressed = value),
              customBorder: const CircleBorder(),
              mouseCursor: SystemMouseCursors.click,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
