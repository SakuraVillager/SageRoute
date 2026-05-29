// Mock data for user profile and achievements.

class MockAchievement {
  final String id;
  final String name;
  final String description;
  final bool unlocked;
  final String? iconName;

  const MockAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.unlocked,
    this.iconName,
  });
}

class MockUser {
  final String name;
  final String avatarUrl;
  final String bio;
  final int achievementsCount;
  final int exploredLocations;
  final int completedRoutes;
  final List<MockAchievement> achievements;

  const MockUser({
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.achievementsCount,
    required this.exploredLocations,
    required this.completedRoutes,
    required this.achievements,
  });
}

/// 成就列表
const mockAchievements = [
  MockAchievement(
    id: 'song-ci-tracker',
    name: '宋词寻踪者',
    description: '完成一条宋词相关的文化路线',
    unlocked: true,
    iconName: 'book',
  ),
  MockAchievement(
    id: 'beginner-explorer',
    name: '初级探险家',
    description: '累计探索 5 个文化景点',
    unlocked: true,
    iconName: 'compass',
  ),
  MockAchievement(
    id: 'tang-poetry-master',
    name: '大唐盛世',
    description: '完成所有唐代诗人路线',
    unlocked: false,
    iconName: 'crown',
  ),
  MockAchievement(
    id: 'route-collector',
    name: '路线收藏家',
    description: '收藏 10 条文化路线',
    unlocked: false,
    iconName: 'star',
  ),
  MockAchievement(
    id: 'photo-enthusiast',
    name: '摄影爱好者',
    description: '上传 20 张景点照片',
    unlocked: false,
    iconName: 'camera',
  ),
  MockAchievement(
    id: 'poem-reciter',
    name: '诗词背诵者',
    description: '背诵 10 首景点相关古诗词',
    unlocked: true,
    iconName: 'quote',
  ),
];

/// 默认模拟用户
const mockUser = MockUser(
  name: '旅行者',
  avatarUrl:
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=200',
  bio: '热爱历史文化，用脚步丈量诗与远方',
  achievementsCount: 6,
  exploredLocations: 3,
  completedRoutes: 1,
  achievements: mockAchievements,
);
