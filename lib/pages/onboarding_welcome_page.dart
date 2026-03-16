import 'package:flutter/material.dart';

import 'onboarding_info_layout.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingInfoLayout(
      title: '欢迎来到 SageRoute',
      description: '[简介]',
      icon: Icons.map_outlined,
    );
  }
}
