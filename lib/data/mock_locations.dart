// Mock data for locations (移植自 Web 版 data.ts)。
//
// 对应 Web types.ts 中的 Location 接口。

class MockLocation {
  final String id;
  final String figureId;
  final String name;
  final String pinyinName;
  final String region;
  final String years;
  final List<String> tags;
  final String distance;
  final String recommendedTime;
  final int relatedPoems;
  final double rating;
  final String imageUrl;
  final String description;

  const MockLocation({
    required this.id,
    required this.figureId,
    required this.name,
    required this.pinyinName,
    required this.region,
    required this.years,
    required this.tags,
    required this.distance,
    required this.recommendedTime,
    required this.relatedPoems,
    required this.rating,
    required this.imageUrl,
    required this.description,
  });
}

/// 白堤 — 白居易
const baiCauseway = MockLocation(
  id: 'bai-causeway',
  figureId: 'bai-juyi',
  name: '白堤',
  pinyinName: 'Bai Causeway',
  region: '西湖，杭州，浙江',
  years: '822-824 年',
  tags: ['地标', '白居易所建', '世界遗产', '免费入场'],
  distance: '3.9km',
  recommendedTime: '2-3h',
  relatedPoems: 6,
  rating: 4.9,
  imageUrl:
      'https://images.unsplash.com/photo-1577626992523-886ec5cfb881?auto=format&fit=crop&q=80&w=800',
  description:
      '杭州西湖著名的白堤，是为了纪念唐代诗人白居易而命名的。'
      '白居易任杭州刺史时，曾主持修筑西湖堤坝...',
);

/// 西湖 — 白居易
const westLake = MockLocation(
  id: 'west-lake',
  figureId: 'bai-juyi',
  name: '西湖',
  pinyinName: 'West Lake',
  region: '杭州，浙江',
  years: '822-824 年',
  tags: ['湖泊', '世界遗产', '文化景观'],
  distance: '15km',
  recommendedTime: '4-6h',
  relatedPoems: 12,
  rating: 4.8,
  imageUrl:
      'https://images.unsplash.com/photo-1596178060671-7a80dc8058f4?auto=format&fit=crop&q=80&w=800',
  description:
      '西湖位于浙江省杭州市西面，是中国大陆首批国家重点风景名胜区和中国十大风景名胜之一。'
      '白居易任杭州刺史期间，曾写有大量关于西湖的诗篇。',
);

/// 黄州 — 苏东坡
const huangzhou = MockLocation(
  id: 'huangzhou',
  figureId: 'su-dongpo',
  name: '黄州',
  pinyinName: 'Huangzhou',
  region: '黄冈，湖北',
  years: '1080-1084 年',
  tags: ['贬谪地', '文学', '历史名城'],
  distance: '5km',
  recommendedTime: '3-4h',
  relatedPoems: 9,
  rating: 4.7,
  imageUrl:
      'https://images.unsplash.com/photo-1599630661590-5b3d9d83de5a?auto=format&fit=crop&q=80&w=800',
  description:
      '黄州是苏轼被贬之地，在此他写下了《赤壁赋》《念奴娇·赤壁怀古》等千古名篇，'
      '也是他自号"东坡居士"的地方。',
);

/// 庐山 — 李白/苏东坡
const lushan = MockLocation(
  id: 'lushan',
  figureId: 'li-bai',
  name: '庐山',
  pinyinName: 'Mount Lu',
  region: '九江，江西',
  years: '725-726 年',
  tags: ['名山', '道教', '风景名胜'],
  distance: '10km',
  recommendedTime: '6-8h',
  relatedPoems: 8,
  rating: 4.9,
  imageUrl:
      'https://images.unsplash.com/photo-1596178060671-7a80dc8058f4?auto=format&fit=crop&q=80&w=800',
  description:
      '庐山以雄、奇、险、秀闻名于世。李白曾多次游历庐山，'
      '写下了"飞流直下三千尺，疑是银河落九天"的千古绝句。',
);

/// 长安 — 李白
const changan = MockLocation(
  id: 'changan',
  figureId: 'li-bai',
  name: '长安',
  pinyinName: "Chang'an",
  region: '西安，陕西',
  years: '742-744 年',
  tags: ['古都', '唐代', '文化中心'],
  distance: '8km',
  recommendedTime: '4-5h',
  relatedPoems: 15,
  rating: 4.9,
  imageUrl:
      'https://images.unsplash.com/photo-1543335759-33eb91f5a5e3?auto=format&fit=crop&q=80&w=800',
  description:
      '长安是唐朝的都城，李白曾在长安任翰林待诏，'
      '在此写下了"云想衣裳花想容"等名句。',
);

/// 杭州 — 苏东坡
const hangzhou = MockLocation(
  id: 'hangzhou',
  figureId: 'su-dongpo',
  name: '杭州',
  pinyinName: 'Hangzhou',
  region: '杭州，浙江',
  years: '1089-1091 年',
  tags: ['城市', '苏堤', '文化'],
  distance: '12km',
  recommendedTime: '2-3天',
  relatedPoems: 10,
  rating: 4.8,
  imageUrl:
      'https://images.unsplash.com/photo-1577626992523-886ec5cfb881?auto=format&fit=crop&q=80&w=800',
  description:
      '杭州是苏东坡第二次被贬之地。他在杭州任知州期间，疏浚西湖、修筑苏堤，'
      '留下了"水光潋滟晴方好，山色空蒙雨亦奇"的诗句。',
);

/// 所有地点列表
const List<MockLocation> mockLocations = [
  baiCauseway,
  westLake,
  huangzhou,
  lushan,
  changan,
  hangzhou,
];

/// 按 figureId 筛选地点
List<MockLocation> locationsByFigure(String figureId) {
  return mockLocations.where((loc) => loc.figureId == figureId).toList();
}

/// 按 id 查找地点
MockLocation? findLocationById(String id) {
  try {
    return mockLocations.firstWhere((loc) => loc.id == id);
  } catch (_) {
    return null;
  }
}
