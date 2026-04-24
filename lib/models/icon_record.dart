/// `Icons` 表模型。
/// name 对应景点类别名，svg 对应 SVG 路径数据（d 属性）。
class IconRecord {
  final String name;
  final String svg;

  const IconRecord({required this.name, required this.svg});

  factory IconRecord.fromMap(Map<String, dynamic> map) {
    return IconRecord(
      name: (map['name'] ?? '').toString(),
      svg: (map['svg'] ?? map['SVG'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'svg': svg};
  }
}
