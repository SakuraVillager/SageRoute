import 'package:flutter/material.dart';

import '../auth/login_page.dart';
import '../navigation/app_navigation.dart';

class GuestAccountNotice extends StatelessWidget {
  const GuestAccountNotice({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 40),
          const SizedBox(height: 12),
          const Text('当前为游客模式'),
          const SizedBox(height: 8),
          const Text('登录后可保存和同步你的行程', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => openAppPage<void>(context, const LoginPage()),
            child: const Text('登录 / 注册'),
          ),
        ],
      ),
    ),
  );
}
