import 'package:flutter/material.dart';

import 'onboarding_info_layout.dart';

class OnboardingHighlightOnePage extends StatelessWidget {
  const OnboardingHighlightOnePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingInfoLayout(
      title: '亮点一',
      description: '智能路径伴侣，随时为你规划最优路线并贴心提醒沿途风景。',
      icon: Icons.star_border,
    );
  }
}
