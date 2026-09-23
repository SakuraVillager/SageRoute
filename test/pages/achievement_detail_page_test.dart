import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/achievement.dart';
import 'package:sageroute/pages/achievement_detail_page.dart';

import '../test_helpers/page_test_harness.dart';

void main() {
  Achievement buildAchievement({DateTime? unlockedAt}) {
    return Achievement(
      id: 'poem-reciter',
      name: '诗词背诵者',
      description: '背诵 10 首景点相关古诗词',
      icon: 'quote',
      howToUnlock: '在景点详情页完成 10 首古诗词的背诵打卡。',
      progress: unlockedAt == null ? 6 : 10,
      target: 10,
      unlockedAt: unlockedAt,
    );
  }

  testWidgets('unlocked achievement shows how to unlock and the unlock time', (
    tester,
  ) async {
    useLargeSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: AchievementDetailPage(
          achievement: buildAchievement(
            unlockedAt: DateTime(2026, 5, 12, 20, 35),
          ),
        ),
      ),
    );

    expect(find.text('成就详情'), findsOneWidget);
    expect(find.text('诗词背诵者'), findsOneWidget);
    expect(find.text('已解锁'), findsOneWidget);
    expect(find.text('成就说明'), findsOneWidget);
    expect(find.text('获取方法'), findsOneWidget);
    expect(find.text('在景点详情页完成 10 首古诗词的背诵打卡。'), findsOneWidget);
    expect(find.text('获得时间'), findsOneWidget);
    expect(find.text('2026-05-12 20:35'), findsOneWidget);
  });

  testWidgets('locked achievement shows progress and no unlock time', (
    tester,
  ) async {
    useLargeSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: AchievementDetailPage(achievement: buildAchievement())),
    );

    expect(find.text('未解锁'), findsOneWidget);
    expect(find.text('当前进度'), findsOneWidget);
    expect(find.text('6 / 10'), findsOneWidget);
    expect(find.textContaining('还差 4 次'), findsOneWidget);
    expect(find.text('尚未获得'), findsOneWidget);
  });
}
