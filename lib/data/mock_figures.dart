// Mock data for historical figures (移植自 Web 版 data.ts).
//
// 对应 Web types.ts 中的 Figure 接口，提供三个诗人数据：
// 白居易、苏东坡、李白。

class MockFigure {
  final String id;
  final String name;
  final String pinyinName;
  final String dynasty;
  final List<String> role;
  final String years;
  final String shortDesc;
  final String description;
  final String imageUrl;
  final int locationsCount;
  final int routesCount;
  final int poemsCount;
  final double rating;

  const MockFigure({
    required this.id,
    required this.name,
    required this.pinyinName,
    required this.dynasty,
    required this.role,
    required this.years,
    required this.shortDesc,
    required this.description,
    required this.imageUrl,
    required this.locationsCount,
    required this.routesCount,
    required this.poemsCount,
    required this.rating,
  });
}

/// 白居易
const baiJuyi = MockFigure(
  id: 'bai-juyi',
  name: '白居易',
  pinyinName: 'Bai Juyi',
  dynasty: '唐朝',
  role: ['诗人', '官员', '哲学家'],
  years: '772 - 846 年',
  shortDesc: '唐代诗人与官员',
  description:
      '白居易（772—846年）是唐代最多产、最负盛名的诗人之一。'
      '生于河南新郑，于公元800年考中进士，历仕多职，成为一代文学巨擘与朝廷重臣。\n\n'
      '白居易以平易近人的诗风和悲悯苍生的情怀著称。'
      '据传他每作新诗，必读给目不识丁的老妪听，反复修改直至通俗易懂。'
      '其作品涵盖爱情、离别、流放与山水...',
  imageUrl:
      'https://images.unsplash.com/photo-1543335759-33eb91f5a5e3?auto=format&fit=crop&q=80&w=800',
  locationsCount: 12,
  routesCount: 4,
  poemsCount: 2800,
  rating: 4.9,
);

/// 苏东坡
const suDongpo = MockFigure(
  id: 'su-dongpo',
  name: '苏东坡',
  pinyinName: 'Su Dongpo',
  dynasty: '宋朝',
  role: ['诗人', '官员'],
  years: '1037 - 1101 年',
  shortDesc: '北宋文学家、书画家',
  description:
      '苏轼，字子瞻，号东坡居士。北宋著名文学家、书法家、画家，历史治水名人。',
  imageUrl:
      'https://images.unsplash.com/photo-1563200923-a1af9bb4ce2f?auto=format&fit=crop&q=80&w=800',
  locationsCount: 16,
  routesCount: 8,
  poemsCount: 3000,
  rating: 4.9,
);

/// 李白
const liBai = MockFigure(
  id: 'li-bai',
  name: '李白',
  pinyinName: 'Li Bai',
  dynasty: '唐朝',
  role: ['诗人', '漫游者'],
  years: '701 - 762 年',
  shortDesc: '唐代浪漫主义诗人',
  description:
      '李白，字太白，号青莲居士，被后人誉为"诗仙"。',
  imageUrl:
      'https://images.unsplash.com/photo-1473661131718-4e1b43aa10c0?auto=format&fit=crop&q=80&w=800',
  locationsCount: 21,
  routesCount: 5,
  poemsCount: 1000,
  rating: 5.0,
);

/// 所有人物列表
const List<MockFigure> mockFigures = [
  baiJuyi,
  suDongpo,
  liBai,
];

/// 按 id 查找人物
MockFigure? findFigureById(String id) {
  try {
    return mockFigures.firstWhere((f) => f.id == id);
  } catch (_) {
    return null;
  }
}
