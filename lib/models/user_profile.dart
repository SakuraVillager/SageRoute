import 'package:flutter/foundation.dart';

/// 成就徽章模型，对应 Web 版 Achievement 类型。
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = '',
    this.isUnlocked = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      isUnlocked:
          json['is_unlocked'] ?? json['isUnlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'is_unlocked': isUnlocked,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.icon == icon &&
          other.isUnlocked == isUnlocked;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        icon,
        isUnlocked,
      );

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? isUnlocked,
  }) =>
      Achievement(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        isUnlocked: isUnlocked ?? this.isUnlocked,
      );

  @override
  String toString() =>
      'Achievement(id: $id, name: $name, isUnlocked: $isUnlocked)';
}

/// Web 风格的用户个人资料模型，对应 Web 版 UserProfile 类型。
class UserProfile {
  final String name;
  final String avatarUrl;
  final String bio;
  final int achievementsCount;
  final int exploredLocations;
  final int completedRoutes;
  final List<Achievement> achievements;

  const UserProfile({
    required this.name,
    this.avatarUrl = '',
    this.bio = '',
    this.achievementsCount = 0,
    this.exploredLocations = 0,
    this.completedRoutes = 0,
    this.achievements = const <Achievement>[],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawAchievements = json['achievements'];
    return UserProfile(
      name: (json['name'] ?? '').toString(),
      avatarUrl:
          (json['avatar_url'] ?? json['avatarUrl'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      achievementsCount:
          (json['achievements_count'] ?? json['achievementsCount'] ?? 0)
              as int,
      exploredLocations:
          (json['explored_locations'] ??
                  json['exploredLocations'] ??
                  0)
              as int,
      completedRoutes:
          (json['completed_routes'] ??
                  json['completedRoutes'] ??
                  0)
              as int,
      achievements: rawAchievements is List
          ? rawAchievements
              .map(
                (item) =>
                    Achievement.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false)
          : const <Achievement>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatar_url': avatarUrl,
      'bio': bio,
      'achievements_count': achievementsCount,
      'explored_locations': exploredLocations,
      'completed_routes': completedRoutes,
      'achievements':
          achievements.map((a) => a.toJson()).toList(growable: false),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.name == name &&
          other.avatarUrl == avatarUrl &&
          other.bio == bio &&
          other.achievementsCount == achievementsCount &&
          other.exploredLocations == exploredLocations &&
          other.completedRoutes == completedRoutes &&
          listEquals(other.achievements, achievements);

  @override
  int get hashCode => Object.hash(
        name,
        avatarUrl,
        bio,
        achievementsCount,
        exploredLocations,
        completedRoutes,
        Object.hashAll(achievements),
      );

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    String? bio,
    int? achievementsCount,
    int? exploredLocations,
    int? completedRoutes,
    List<Achievement>? achievements,
  }) =>
      UserProfile(
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        achievementsCount:
            achievementsCount ?? this.achievementsCount,
        exploredLocations:
            exploredLocations ?? this.exploredLocations,
        completedRoutes:
            completedRoutes ?? this.completedRoutes,
        achievements: achievements ?? this.achievements,
      );

  @override
  String toString() =>
      'UserProfile(name: $name, achievementsCount: $achievementsCount, '
      'exploredLocations: $exploredLocations, completedRoutes: $completedRoutes)';
}
