import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';
import 'mock_achievements.dart';

/// 本地成就仓库。
///
/// 职责：合并「成就定义（种子数据）」与「本地解锁时间」，并把新解锁的成就
/// 写回 SharedPreferences。后续若要把特殊成就同步到云端，替换/包装本仓库即可。
class LocalAchievementRepository {
  const LocalAchievementRepository({this.seeds});

  /// 本地存储键：`{"achievement-id": "2026-05-12T20:35:00.000"}`。
  static const String unlockedAtKey = 'achievements.unlocked_at';

  /// 可注入的成就定义；默认使用 [mockAchievements]。
  final List<Achievement>? seeds;

  List<Achievement> get _definitions => seeds ?? mockAchievements;

  /// 读取成就列表。
  ///
  /// - 种子数据里 [Achievement.isCompleted] 的成就若还没有解锁时间，
  ///   会使用其预置时间或 [clock] 当前时间补上并持久化；
  /// - 已持久化的解锁时间优先，不会被覆盖。
  Future<List<Achievement>> fetchAchievements({
    DateTime Function()? clock,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final persisted = _decode(preferences.getString(unlockedAtKey));
    var changed = false;

    final result = <Achievement>[];
    for (final definition in _definitions) {
      var unlockedAt = persisted[definition.id];
      if (unlockedAt == null && definition.isCompleted) {
        unlockedAt = definition.unlockedAt ?? (clock ?? DateTime.now)();
        persisted[definition.id] = unlockedAt;
        changed = true;
      }
      result.add(
        definition.withUnlockedAt(unlockedAt ?? definition.unlockedAt),
      );
    }

    if (changed) {
      await preferences.setString(
        unlockedAtKey,
        jsonEncode(
          persisted.map((id, time) => MapEntry(id, time.toIso8601String())),
        ),
      );
    }

    return List<Achievement>.unmodifiable(result);
  }

  Map<String, DateTime> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <String, DateTime>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map<String, DateTime>((key, value) {
          return MapEntry('$key', DateTime.parse('$value'));
        });
      }
    } catch (error) {
      debugPrint('[LocalAchievementRepository] decode failed: $error');
    }
    return <String, DateTime>{};
  }
}
