import 'package:flutter/material.dart';

import '../../theme/color_schemes.dart';

/// Keep the brand copy in the illustration's light sky, above the landscape.
class WebBrandPanel extends StatelessWidget {
  const WebBrandPanel({super.key, this.compactHeader = false});

  final bool compactHeader;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 480 || constraints.maxHeight < 660;
      final inset = compactHeader
          ? 24.0
          : compact
          ? 32.0
          : 48.0;
      return ClipRect(
        child: ColoredBox(
          color: AppColors.brandWash,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/auth/landscape.png',
                fit: BoxFit.cover,
                alignment: compactHeader
                    ? const Alignment(0, -0.65)
                    : Alignment.topCenter,
                excludeFromSemantics: true,
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(inset),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sage — Route',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandInk,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '循着足迹，读懂一座城。',
                          style: TextStyle(
                            color: AppColors.brandDark,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        if (!compactHeader) ...[
                          SizedBox(height: compact ? 16 : 36),
                          Text(
                            '山水之间\n与历史同行',
                            style: TextStyle(
                              fontSize: compact ? 34 : 42,
                              height: 1.22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandInk,
                            ),
                          ),
                        ],
                        SizedBox(height: compact ? 12 : 16),
                        Text(
                          compact ? '让故事，成为你的旅程。' : '从一位人物出发，\n把故事串成你的旅程。',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
