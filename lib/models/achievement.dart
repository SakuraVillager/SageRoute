import 'package:flutter/foundation.dart';

/// 本地成就模型。
///
/// Phase 2 起成就数据只保存在本机：
/// - 定义（名称、说明、获取方法、目标进度）来自 `lib/data/mock_achievements.dart`；
/// - 解锁时间由 `LocalAchievementRepository` 持久化到 SharedPreferences。
///
/// 后续如需把“特殊成就”同步到云端，只需替换仓库实现，页面不感知数据来源。
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = '',
    this.howToUnlock = '',
    this.progress = 0,
    this.target = 1,
    this.unlockedAt,
  });

  final String id;
  final String name;

  /// 成就说明。
  final String description;

  /// 图标名，映射见 `lib/utils/achievement_icons.dart`。
  final String icon;

  /// 获取方法（展示在详情页）。
  final String howToUnlock;

  /// 当前进度。
  final int progress;

  /// 目标进度。
  final int target;

  /// 获得时间；为空表示尚未解锁。
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  /// 进度是否已达到目标（与是否写入 [unlockedAt] 分开判断）。
  bool get isCompleted => target > 0 && progress >= target;

  /// 0.0 ~ 1.0 的进度比例，用于进度条。
  double get progressRatio {
    if (target <= 0) return 0;
    final ratio = progress / target;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  Achievement withUnlockedAt(DateTime? value) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      icon: icon,
      howToUnlock: howToUnlock,
      progress: progress,
      target: target,
      unlockedAt: value,
    );
  }

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? howToUnlock,
    int? progress,
    int? target,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      howToUnlock: howToUnlock ?? this.howToUnlock,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      unlockedAt: unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'how_to_unlock': howToUnlock,
      'progress': progress,
      'target': target,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final rawUnlockedAt = json['unlocked_at'] ?? json['unlockedAt'];
    DateTime? unlockedAt;
    if (rawUnlockedAt is String && rawUnlockedAt.isNotEmpty) {
      unlockedAt = DateTime.tryParse(rawUnlockedAt);
    }
    return Achievement(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      howToUnlock: (json['how_to_unlock'] ?? json['howToUnlock'] ?? '')
          .toString(),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 1,
      unlockedAt: unlockedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Achievement &&
            other.id == id &&
            other.name == name &&
            other.description == description &&
            other.icon == icon &&
            other.howToUnlock == howToUnlock &&
            other.progress == progress &&
            other.target == target &&
            other.unlockedAt == unlockedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    icon,
    howToUnlock,
    progress,
    target,
    unlockedAt,
  );

  @override
  String toString() =>
      'Achievement(id: $id, name: $name, progress: $progress/$target, '
      'unlockedAt: $unlockedAt)';
}
