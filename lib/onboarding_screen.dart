import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/celebrity_selection_page.dart';
import 'pages/onboarding_highlight_one_page.dart';
import 'pages/onboarding_highlight_two_page.dart';
import 'pages/onboarding_welcome_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onSkipToCelebritySelect() {
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _markOnboardingAsSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('hasSeenOnboarding', true);
  }

  Future<void> _onFinish() async {
    await _markOnboardingAsSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const OnboardingWelcomePage(),
      const OnboardingHighlightOnePage(),
      const OnboardingHighlightTwoPage(),
      CelebritySelectionPage(onContinue: _onFinish, onSkip: _onFinish),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: pages,
            ),

            if (_currentPageIndex < 3)
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: _onSkipToCelebritySelect,
                  child: Text(
                    '跳过',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            if (_currentPageIndex < 3)
              Positioned(
                bottom: 100,
                left: 40,
                right: 40,
                child: FilledButton(
                  onPressed: _onNextPage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('继续'),
                ),
              ),

            if (_currentPageIndex < 3)
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => _buildDotIndicator(index == _currentPageIndex),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
