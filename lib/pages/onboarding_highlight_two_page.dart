import 'package:flutter/material.dart';

import 'onboarding_info_layout.dart';

class OnboardingHighlightTwoPage extends StatelessWidget {
  const OnboardingHighlightTwoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingInfoLayout(
      title: '亮点二',
      description: '沉浸式文化故事，让旅途既有经略也有诗意。',
      icon: Icons.lightbulb_outline,
    );
  }
}
