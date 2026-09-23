// Mock data for the local profile page.

/// 本地模拟的用户资料。
///
/// 成就进度在 `mock_achievements.dart` 中单独维护，并与此处的统计口径保持一致。
class MockUser {
  final String name;
  final String avatarUrl;
  final String bio;
  final int exploredLocations;
  final int completedRoutes;

  const MockUser({
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.exploredLocations,
    required this.completedRoutes,
  });
}

/// 默认模拟用户。
///
/// 统计口径：已探索 5 个景点、完成 1 条路线，与 `mock_achievements.dart`
/// 中「初级探险家 5/5」「宋词寻踪者 1/1」一致。
const mockUser = MockUser(
  name: '旅行者',
  avatarUrl:
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=200',
  bio: '热爱历史文化，用脚步丈量诗与远方',
  exploredLocations: 5,
  completedRoutes: 1,
);
