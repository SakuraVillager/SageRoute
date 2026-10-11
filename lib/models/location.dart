import 'package:flutter/foundation.dart';

/// Web 风格的地点模型，对应 Web 版 Location 类型。
/// 与现有 `LocationRecord` 互补：`LocationRecord` 保持 Supabase 原表结构，
/// `Location` 面向新 UI 层使用更语义化的字段名。
class Location {
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

  const Location({
    required this.id,
    required this.name,
    this.figureId = '',
    this.pinyinName = '',
    this.region = '',
    this.years = '',
    this.tags = const <String>[],
    this.distance = '',
    this.recommendedTime = '',
    this.relatedPoems = 0,
    this.rating = 0.0,
    this.imageUrl = '',
    this.description = '',
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return Location(
      id: (json['id'] ?? '').toString(),
      figureId:
          (json['figure_id'] ?? json['figureId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      pinyinName:
          (json['pinyin_name'] ?? json['pinyinName'] ?? '').toString(),
      region: (json['region'] ?? '').toString(),
      years: (json['years'] ?? '').toString(),
      tags: rawTags is List
          ? rawTags.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      distance: (json['distance'] ?? '').toString(),
      recommendedTime:
          (json['recommended_time'] ?? json['recommendedTime'] ?? '')
              .toString(),
      relatedPoems:
          (json['related_poems'] ?? json['relatedPoems'] ?? 0) as int,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl:
          (json['image_url'] ?? json['imageUrl'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'figure_id': figureId,
      'name': name,
      'pinyin_name': pinyinName,
      'region': region,
      'years': years,
      'tags': tags,
      'distance': distance,
      'recommended_time': recommendedTime,
      'related_poems': relatedPoems,
      'rating': rating,
      'image_url': imageUrl,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          other.id == id &&
          other.figureId == figureId &&
          other.name == name &&
          other.pinyinName == pinyinName &&
          other.region == region &&
          other.years == years &&
          listEquals(other.tags, tags) &&
          other.distance == distance &&
          other.recommendedTime == recommendedTime &&
          other.relatedPoems == relatedPoems &&
          other.rating == rating &&
          other.imageUrl == imageUrl &&
          other.description == description;

  @override
  int get hashCode => Object.hash(
        id,
        figureId,
        name,
        pinyinName,
        region,
        years,
        Object.hashAll(tags),
        distance,
        recommendedTime,
        relatedPoems,
        rating,
        imageUrl,
        description,
      );

  Location copyWith({
    String? id,
    String? figureId,
    String? name,
    String? pinyinName,
    String? region,
    String? years,
    List<String>? tags,
    String? distance,
    String? recommendedTime,
    int? relatedPoems,
    double? rating,
    String? imageUrl,
    String? description,
  }) =>
      Location(
        id: id ?? this.id,
        figureId: figureId ?? this.figureId,
        name: name ?? this.name,
        pinyinName: pinyinName ?? this.pinyinName,
        region: region ?? this.region,
        years: years ?? this.years,
        tags: tags ?? this.tags,
        distance: distance ?? this.distance,
        recommendedTime: recommendedTime ?? this.recommendedTime,
        relatedPoems: relatedPoems ?? this.relatedPoems,
        rating: rating ?? this.rating,
        imageUrl: imageUrl ?? this.imageUrl,
        description: description ?? this.description,
      );

  @override
  String toString() =>
      'Location(id: $id, name: $name, pinyinName: $pinyinName, region: $region, '
      'years: $years, tags: $tags, distance: $distance, rating: $rating)';
}
