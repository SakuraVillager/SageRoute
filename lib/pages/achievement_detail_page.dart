import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../theme/color_schemes.dart';
import '../utils/achievement_icons.dart';

/// 成就详情页：成就说明、获取方法、进度与获得时间。
///
/// 数据全部来自本地（`LocalAchievementRepository`），不依赖网络。
class AchievementDetailPage extends StatelessWidget {
  const AchievementDetailPage({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;

    return Scaffold(
      key: Key('achievement-detail-${achievement.id}'),
      backgroundColor: AppColors.sageBg,
      appBar: AppBar(
        backgroundColor: AppColors.sageBg,
        foregroundColor: AppColors.sageText,
        elevation: 0,
        title: const Text('成就详情'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: <Widget>[
            _buildHeader(unlocked),
            const SizedBox(height: 28),
            _buildProgressCard(),
            const SizedBox(height: 20),
            _buildInfoCard(
              title: '成就说明',
              icon: Icons.menu_book_outlined,
              content: achievement.description,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: '获取方法',
              icon: Icons.lightbulb_outline,
              content: achievement.howToUnlock,
            ),
            const SizedBox(height: 16),
            _buildUnlockTimeCard(unlocked),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool unlocked) {
    return Column(
      children: <Widget>[
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: unlocked ? AppColors.brandLight : AppColors.sageCard,
            shape: BoxShape.circle,
            border: Border.all(
              color: unlocked ? AppColors.brandLight : AppColors.sageBorder,
              width: 4,
            ),
          ),
          child: Icon(
            achievementIconFor(achievement.icon),
            size: 44,
            color: unlocked ? AppColors.sageAccent : AppColors.sageBorder,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          achievement.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.sageText,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatusChip(unlocked),
      ],
    );
  }

  Widget _buildStatusChip(bool unlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.brandWash : AppColors.sageCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: unlocked ? AppColors.brandLight : AppColors.sageBorder,
        ),
      ),
      child: Text(
        unlocked ? '已解锁' : '未解锁',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: unlocked ? AppColors.sageAccent : AppColors.sageMuted,
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final remaining = achievement.target - achievement.progress;
    final percent = (achievement.progressRatio * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageCard,
        border: Border.all(color: AppColors.sageBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                '当前进度',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageText,
                ),
              ),
              Text(
                '${achievement.progress} / ${achievement.target}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: achievement.progressRatio,
              minHeight: 8,
              backgroundColor: AppColors.sageBg,
              color: AppColors.sageAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.isCompleted
                ? '已完成全部条件（$percent%）'
                : '还差 $remaining 次达成目标（$percent%）',
            style: const TextStyle(fontSize: 12, color: AppColors.sageMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageCard,
        border: Border.all(color: AppColors.sageBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: AppColors.sageAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.sageText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockTimeCard(bool unlocked) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.brandWash : AppColors.sageCard,
        border: Border.all(
          color: unlocked ? AppColors.brandLight : AppColors.sageBorder,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            unlocked ? Icons.verified_outlined : Icons.lock_outline,
            size: 20,
            color: unlocked ? AppColors.sageAccent : AppColors.sageMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  unlocked ? '获得时间' : '尚未获得',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sageText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unlocked
                      ? _formatTime(achievement.unlockedAt!)
                      : '达成上述条件后会自动解锁，进度会保存在本机。',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.sageMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}
