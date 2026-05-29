// Mock data for saved routes and route previews.

/// 路线中的地点项
class MockRouteLocation {
  final String locationId;
  final String name;
  final int dayOrder; // 第几天
  final int orderInDay; // 当天第几个

  const MockRouteLocation({
    required this.locationId,
    required this.name,
    required this.dayOrder,
    required this.orderInDay,
  });
}

/// 路线预览
class MockRoute {
  final String id;
  final String name;
  final String figureId;
  final String figureName;
  final int days;
  final int locationsCount;
  final String totalDistance;
  final String? startDate;
  final List<MockRouteLocation> locations;

  const MockRoute({
    required this.id,
    required this.name,
    required this.figureId,
    required this.figureName,
    required this.days,
    required this.locationsCount,
    required this.totalDistance,
    required this.startDate,
    required this.locations,
  });

  /// 按天数分组的行程
  Map<int, List<MockRouteLocation>> get itineraryByDay {
    final map = <int, List<MockRouteLocation>>{};
    for (final loc in locations) {
      map.putIfAbsent(loc.dayOrder, () => []);
      map[loc.dayOrder]!.add(loc);
    }
    return map;
  }
}

/// 白居易的杭州之旅 — 4天3夜
const baiJuyiHangzhouRoute = MockRoute(
  id: 'bai-juyi-hangzhou',
  name: '白居易的杭州之旅',
  figureId: 'bai-juyi',
  figureName: '白居易',
  days: 4,
  locationsCount: 9,
  totalDistance: '14.2km',
  startDate: '2024-04-01',
  locations: [
    MockRouteLocation(
      locationId: 'bai-causeway',
      name: '白堤',
      dayOrder: 1,
      orderInDay: 1,
    ),
    MockRouteLocation(
      locationId: 'west-lake',
      name: '西湖',
      dayOrder: 1,
      orderInDay: 2,
    ),
    MockRouteLocation(
      locationId: 'bai-causeway',
      name: '白堤',
      dayOrder: 2,
      orderInDay: 1,
    ),
    MockRouteLocation(
      locationId: 'west-lake',
      name: '西湖',
      dayOrder: 2,
      orderInDay: 2,
    ),
    MockRouteLocation(
      locationId: 'bai-causeway',
      name: '白堤',
      dayOrder: 3,
      orderInDay: 1,
    ),
    MockRouteLocation(
      locationId: 'west-lake',
      name: '西湖',
      dayOrder: 3,
      orderInDay: 2,
    ),
    MockRouteLocation(
      locationId: 'bai-causeway',
      name: '白堤',
      dayOrder: 4,
      orderInDay: 1,
    ),
    MockRouteLocation(
      locationId: 'west-lake',
      name: '西湖',
      dayOrder: 4,
      orderInDay: 2,
    ),
    MockRouteLocation(
      locationId: 'bai-causeway',
      name: '白堤',
      dayOrder: 4,
      orderInDay: 3,
    ),
  ],
);

/// 苏东坡的赤壁之行 — 2天1夜
const suDongpoChibiRoute = MockRoute(
  id: 'su-dongpo-chibi',
  name: '苏东坡的赤壁之行',
  figureId: 'su-dongpo',
  figureName: '苏东坡',
  days: 2,
  locationsCount: 5,
  totalDistance: '8.5km',
  startDate: null,
  locations: [
    MockRouteLocation(
      locationId: 'huangzhou',
      name: '黄州',
      dayOrder: 1,
      orderInDay: 1,
    ),
    MockRouteLocation(
      locationId: 'huangzhou',
      name: '黄州',
      dayOrder: 2,
      orderInDay: 1,
    ),
    MockRouteLocation(
      locationId: 'huangzhou',
      name: '黄州',
      dayOrder: 2,
      orderInDay: 2,
    ),
    MockRouteLocation(
      locationId: 'huangzhou',
      name: '黄州',
      dayOrder: 2,
      orderInDay: 3,
    ),
    MockRouteLocation(
      locationId: 'huangzhou',
      name: '黄州',
      dayOrder: 2,
      orderInDay: 4,
    ),
  ],
);

/// 李白的庐山漫游 — 3天2夜
const liBaiLushanRoute = MockRoute(
  id: 'li-bai-lushan',
  name: '李白的庐山漫游',
  figureId: 'li-bai',
  figureName: '李白',
  days: 3,
  locationsCount: 6,
  totalDistance: '18.3km',
  startDate: null,
  locations: [
    MockRouteLocation(
      locationId: 'lushan',
      name: '庐山',
      dayOrder: 1,
      orderInDay: 1,
    ),
    MockRouteLocation(
      locationId: 'lushan',
      name: '庐山',
      dayOrder: 2,
      orderInDay: 1,
    ),
    MockRouteLocation(
      locationId: 'lushan',
      name: '庐山',
      dayOrder: 2,
      orderInDay: 2,
    ),
    MockRouteLocation(
      locationId: 'lushan',
      name: '庐山',
      dayOrder: 3,
      orderInDay: 1,
    ),
    MockRouteLocation(
      locationId: 'lushan',
      name: '庐山',
      dayOrder: 3,
      orderInDay: 2,
    ),
    MockRouteLocation(
      locationId: 'lushan',
      name: '庐山',
      dayOrder: 3,
      orderInDay: 3,
    ),
  ],
);

/// 所有路线列表
const List<MockRoute> mockRoutes = [
  baiJuyiHangzhouRoute,
  suDongpoChibiRoute,
  liBaiLushanRoute,
];

/// 按 figureId 筛选路线
List<MockRoute> routesByFigure(String figureId) {
  return mockRoutes.where((r) => r.figureId == figureId).toList();
}

/// 按 id 查找路线
MockRoute? findRouteById(String id) {
  try {
    return mockRoutes.firstWhere((r) => r.id == id);
  } catch (_) {
    return null;
  }
}
