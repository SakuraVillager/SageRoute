import '../models/achievement.dart';

/// 本地成就种子数据。
///
/// 进度为本地模拟值，与 `mock_user.dart` 的统计口径保持一致：
/// 已探索 5 个景点、完成 1 条路线、收藏 2 条路线。
/// 已解锁成就预置了获得时间，首次加载时会由 `LocalAchievementRepository`
/// 写入本地存储，之后保持不变。
final List<Achievement> mockAchievements = <Achievement>[
  Achievement(
    id: 'song-ci-tracker',
    name: '宋词寻踪者',
    description: '完成一条宋词相关的文化路线',
    icon: 'book',
    howToUnlock: '在路线规划中选择宋词主题，完成任意一条包含江南宋词景点的路线。',
    progress: 1,
    unlockedAt: DateTime(2026, 5, 12, 20, 35),
  ),
  Achievement(
    id: 'beginner-explorer',
    name: '初级探险家',
    description: '累计探索 5 个文化景点',
    icon: 'compass',
    howToUnlock: '在导览页或路线中到访 5 个不同的文化景点。',
    progress: 5,
    target: 5,
    unlockedAt: DateTime(2026, 5, 28, 9, 12),
  ),
  const Achievement(
    id: 'tang-poetry-master',
    name: '大唐盛世',
    description: '完成所有唐代诗人路线',
    icon: 'crown',
    howToUnlock: '完成全部 3 条唐代诗人主题路线。',
    target: 3,
  ),
  const Achievement(
    id: 'route-collector',
    name: '路线收藏家',
    description: '收藏 10 条文化路线',
    icon: 'star',
    howToUnlock: '在收藏页保存 10 条不同的文化路线。',
    progress: 2,
    target: 10,
  ),
  const Achievement(
    id: 'photo-enthusiast',
    name: '摄影爱好者',
    description: '上传 20 张景点照片',
    icon: 'camera',
    howToUnlock: '在景点详情或游记中上传 20 张照片。',
    target: 20,
  ),
  const Achievement(
    id: 'poem-reciter',
    name: '诗词背诵者',
    description: '背诵 10 首景点相关古诗词',
    icon: 'quote',
    howToUnlock: '在景点详情页完成 10 首古诗词的背诵打卡。',
    progress: 6,
    target: 10,
  ),
];
