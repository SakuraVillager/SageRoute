/// `Icons` 表模型。
/// name 对应景点类别名，svg 对应 SVG 路径数据（d 属性）。
class IconRecord {
  final String name;
  final String svg;

  const IconRecord({required this.name, required this.svg});

  factory IconRecord.fromMap(Map<String, dynamic> map) {
    return IconRecord(
      name: (map['name'] ?? '').toString(),
      // 数据库字段名大小写不统一：部分记录使用 'svg'，部分使用 'SVG'。
      // 此处兼容两种写法，待数据库侧统一后可简化。
      svg: (map['svg'] ?? map['SVG'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'svg': svg};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconRecord &&
          other.name == name &&
          other.svg == svg;

  @override
  int get hashCode => Object.hash(name, svg);

  IconRecord copyWith({
    String? name,
    String? svg,
  }) =>
      IconRecord(
        name: name ?? this.name,
        svg: svg ?? this.svg,
      );

  @override
  String toString() => 'IconRecord(name: $name, svg: $svg)';
}
