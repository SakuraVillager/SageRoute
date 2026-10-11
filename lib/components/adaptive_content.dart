import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({super.key, required this.child, this.maxWidth = 1200});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox.expand(child: SelectionArea(child: child)),
        ),
      ),
    );
  }
}
