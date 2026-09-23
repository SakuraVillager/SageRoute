import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/local_achievement_repository.dart';
import 'package:sageroute/models/achievement.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'marks completed seed achievements as unlocked with seeded times',
    () async {
      final achievements = await const LocalAchievementRepository()
          .fetchAchievements();

      expect(achievements, hasLength(6));

      final songCi = achievements.firstWhere((a) => a.id == 'song-ci-tracker');
      expect(songCi.isUnlocked, isTrue);
      expect(songCi.unlockedAt, DateTime(2026, 5, 12, 20, 35));

      final beginner = achievements.firstWhere(
        (a) => a.id == 'beginner-explorer',
      );
      expect(beginner.isUnlocked, isTrue);
      expect(beginner.unlockedAt, DateTime(2026, 5, 28, 9, 12));

      final tang = achievements.firstWhere((a) => a.id == 'tang-poetry-master');
      expect(tang.isUnlocked, isFalse);
      expect(tang.progress, 0);
      expect(tang.target, 3);
    },
  );

  test(
    'persists the assigned unlock time for completed achievements',
    () async {
      const repository = LocalAchievementRepository(
        seeds: <Achievement>[
          Achievement(
            id: 'test-achievement',
            name: '测试成就',
            howToUnlock: '完成 3 次测试',
            progress: 3,
            target: 3,
          ),
        ],
      );
      final clock = DateTime(2026, 6, 1, 12, 30);

      final first = await repository.fetchAchievements(clock: () => clock);
      expect(first.single.unlockedAt, clock);

      final second = await repository.fetchAchievements(
        clock: () => DateTime(2026, 9, 9),
      );
      expect(second.single.unlockedAt, clock);
    },
  );

  test('tolerates corrupt persisted data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalAchievementRepository.unlockedAtKey: 'not-json',
    });

    final achievements = await const LocalAchievementRepository()
        .fetchAchievements();

    expect(achievements, hasLength(6));
    expect(achievements.where((a) => a.isUnlocked).length, 2);
  });
}
