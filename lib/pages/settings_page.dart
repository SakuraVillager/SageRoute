import 'package:flutter/material.dart';

import 'celebrity_selection/celebrity_selection_page.dart';
import '../theme/color_schemes.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback? onSwitchCelebrity;

  const SettingsPage({super.key, this.onSwitchCelebrity});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '设置',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.sageText,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.sageBorder),
          ),
          child: ListTile(
            leading: const Icon(Icons.person, color: AppColors.sageMuted),
            title: const Text('切换人物'),
            subtitle: const Text('从角色库中挑选新的同行者'),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.sageBorder,
            ),
            onTap: () {
              if (onSwitchCelebrity != null) {
                onSwitchCelebrity!();
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CelebritySelectionPage(
                    onContinue: () => Navigator.of(context).pop(),
                    onSkip: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
