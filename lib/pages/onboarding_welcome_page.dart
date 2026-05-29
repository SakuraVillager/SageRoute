import 'package:flutter/material.dart';

import 'onboarding_info_layout.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingInfoLayout(
      title: '欢迎来到 SageRoute',
      description: '跟随古人脚步，走一段有温度的文化之旅',
      icon: Icons.map_outlined,
    );
  }
}
