import 'package:flutter/material.dart';
import '../../theme/color_schemes.dart';
import 'web_brand_panel.dart';

class WebAuthLayout extends StatefulWidget {
  const WebAuthLayout({super.key, required this.child});
  final Widget child;
  @override
  State<WebAuthLayout> createState() => _WebAuthLayoutState();
}

class _WebAuthLayoutState extends State<WebAuthLayout> {
  final _contentKey = GlobalKey();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final content = KeyedSubtree(key: _contentKey, child: widget.child);
      if (constraints.maxWidth < 900) return content;
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            const Expanded(flex: 5, child: WebBrandPanel()),
            Expanded(
              flex: 6,
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        scaffoldBackgroundColor: Colors.white,
                        appBarTheme: const AppBarTheme(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.sageText,
                          elevation: 0,
                        ),
                      ),
                      child: SizedBox(
                        height: constraints.maxHeight > 680
                            ? 680
                            : constraints.maxHeight,
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
