import 'package:flutter/material.dart';
import '../components/web/web_brand_panel.dart';
import '../components/guest_entry_button.dart';
import '../theme/color_schemes.dart';

class WebWelcomePage extends StatelessWidget {
  const WebWelcomePage({
    super.key,
    required this.onStart,
    required this.onLogin,
  });
  final VoidCallback onStart;
  final VoidCallback onLogin;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 900) {
          return Stack(
            children: [
              const Positioned.fill(child: WebBrandPanel()),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 270, 24, 24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .97),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.sageBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '让故事成为旅程',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandInk,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: onStart,
                              child: const Text('开启旅程  →'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '已有账号？',
                                style: TextStyle(color: AppColors.sageMuted),
                              ),
                              TextButton(
                                onPressed: onLogin,
                                child: const Text('登录'),
                              ),
                            ],
                          ),
                          const GuestEntryButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            const Expanded(flex: 6, child: WebBrandPanel()),
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '让故事成为旅程',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.brand,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '沿着历史的足迹，\n发现下一段风景。',
                          style: TextStyle(
                            fontSize: 36,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '认识一位人物，探索相关地点，规划属于自己的路线。'
                          '让每一次出发，都有故事相伴。',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.9,
                            color: AppColors.sageMuted,
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onStart,
                            child: const Text('开启旅程  →'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              '已有账号？',
                              style: TextStyle(color: AppColors.sageMuted),
                            ),
                            TextButton(
                              onPressed: onLogin,
                              child: const Text('登录'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const GuestEntryButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
