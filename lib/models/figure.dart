import 'package:flutter/foundation.dart';

/// Web 风格的人物模型，对应 Web 版 Figure 类型。
/// 与现有 `CelebrityProfile` 互补：`CelebrityProfile` 保持 Supabase 表结构，
/// `Figure` 面向新 UI 层使用更语义化的字段名。
class Figure {
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

  const Figure({
    required this.id,
    required this.name,
    this.pinyinName = '',
    required this.dynasty,
    this.role = const <String>[],
    this.years = '',
    this.shortDesc = '',
    this.description = '',
    this.imageUrl = '',
    this.locationsCount = 0,
    this.routesCount = 0,
    this.poemsCount = 0,
    this.rating = 0.0,
  });

  factory Figure.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'];
    return Figure(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      pinyinName:
          (json['pinyin_name'] ?? json['pinyinName'] ?? '').toString(),
      dynasty: (json['dynasty'] ?? '').toString(),
      role: rawRole is List
          ? rawRole.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      years: (json['years'] ?? '').toString(),
      shortDesc:
          (json['short_desc'] ?? json['shortDesc'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl:
          (json['image_url'] ?? json['imageUrl'] ?? json['heroImageUrl'] ?? json['hero_image_url'] ?? '')
              .toString(),
      locationsCount:
          (json['locations_count'] ?? json['locationsCount'] ?? 0) as int,
      routesCount:
          (json['routes_count'] ?? json['routesCount'] ?? 0) as int,
      poemsCount:
          (json['poems_count'] ?? json['poemsCount'] ?? 0) as int,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pinyin_name': pinyinName,
      'dynasty': dynasty,
      'role': role,
      'years': years,
      'short_desc': shortDesc,
      'description': description,
      'image_url': imageUrl,
      'locations_count': locationsCount,
      'routes_count': routesCount,
      'poems_count': poemsCount,
      'rating': rating,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Figure &&
          other.id == id &&
          other.name == name &&
          other.pinyinName == pinyinName &&
          other.dynasty == dynasty &&
          listEquals(other.role, role) &&
          other.years == years &&
          other.shortDesc == shortDesc &&
          other.description == description &&
          other.imageUrl == imageUrl &&
          other.locationsCount == locationsCount &&
          other.routesCount == routesCount &&
          other.poemsCount == poemsCount &&
          other.rating == rating;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        pinyinName,
        dynasty,
        Object.hashAll(role),
        years,
        shortDesc,
        description,
        imageUrl,
        locationsCount,
        routesCount,
        poemsCount,
        rating,
      );

  Figure copyWith({
    String? id,
    String? name,
    String? pinyinName,
    String? dynasty,
    List<String>? role,
    String? years,
    String? shortDesc,
    String? description,
    String? imageUrl,
    int? locationsCount,
    int? routesCount,
    int? poemsCount,
    double? rating,
  }) =>
      Figure(
        id: id ?? this.id,
        name: name ?? this.name,
        pinyinName: pinyinName ?? this.pinyinName,
        dynasty: dynasty ?? this.dynasty,
        role: role ?? this.role,
        years: years ?? this.years,
        shortDesc: shortDesc ?? this.shortDesc,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        locationsCount: locationsCount ?? this.locationsCount,
        routesCount: routesCount ?? this.routesCount,
        poemsCount: poemsCount ?? this.poemsCount,
        rating: rating ?? this.rating,
      );

  @override
  String toString() =>
      'Figure(id: $id, name: $name, pinyinName: $pinyinName, dynasty: $dynasty, '
      'role: $role, years: $years, shortDesc: $shortDesc, rating: $rating)';
}
