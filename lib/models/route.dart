import 'package:flutter/foundation.dart';

/// 路线中的单个地点项，对应 Web 版 route.locations 数组元素。
class RouteLocation {
  final String name;
  final String time;
  final String duration;
  final String imageUrl;
  final List<String> tags;

  const RouteLocation({
    required this.name,
    this.time = '',
    this.duration = '',
    this.imageUrl = '',
    this.tags = const <String>[],
  });

  factory RouteLocation.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return RouteLocation(
      name: (json['name'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      imageUrl:
          (json['image_url'] ?? json['imageUrl'] ?? '').toString(),
      tags: rawTags is List
          ? rawTags.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'time': time,
      'duration': duration,
      'image_url': imageUrl,
      'tags': tags,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteLocation &&
          other.name == name &&
          other.time == time &&
          other.duration == duration &&
          other.imageUrl == imageUrl &&
          listEquals(other.tags, tags);

  @override
  int get hashCode => Object.hash(
        name,
        time,
        duration,
        imageUrl,
        Object.hashAll(tags),
      );

  RouteLocation copyWith({
    String? name,
    String? time,
    String? duration,
    String? imageUrl,
    List<String>? tags,
  }) =>
      RouteLocation(
        name: name ?? this.name,
        time: time ?? this.time,
        duration: duration ?? this.duration,
        imageUrl: imageUrl ?? this.imageUrl,
        tags: tags ?? this.tags,
      );

  @override
  String toString() =>
      'RouteLocation(name: $name, time: $time, duration: $duration)';
}

/// Web 风格的路线模型，对应 Web 版 Route 类型。
/// 用于路线列表预览和路线详情页。
class Route {
  final String id;
  final String name;
  final String figureId;
  final String figureName;
  final int days;
  final int locationsCount;
  final double totalDistance;
  final String startDate;
  final List<RouteLocation> locations;

  const Route({
    required this.id,
    required this.name,
    this.figureId = '',
    this.figureName = '',
    this.days = 0,
    this.locationsCount = 0,
    this.totalDistance = 0.0,
    this.startDate = '',
    this.locations = const <RouteLocation>[],
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'];
    return Route(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      figureId:
          (json['figure_id'] ?? json['figureId'] ?? '').toString(),
      figureName:
          (json['figure_name'] ?? json['figureName'] ?? '').toString(),
      days: (json['days'] as num?)?.toInt() ?? 0,
      locationsCount:
          (json['locations_count'] ?? json['locationsCount'] ?? 0) as int,
      totalDistance:
          (json['total_distance'] ?? json['totalDistance'] ?? 0.0)
              as double,
      startDate:
          (json['start_date'] ?? json['startDate'] ?? '').toString(),
      locations: rawLocations is List
          ? rawLocations
              .map(
                (item) =>
                    RouteLocation.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false)
          : const <RouteLocation>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'figure_id': figureId,
      'figure_name': figureName,
      'days': days,
      'locations_count': locationsCount,
      'total_distance': totalDistance,
      'start_date': startDate,
      'locations':
          locations.map((l) => l.toJson()).toList(growable: false),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Route &&
          other.id == id &&
          other.name == name &&
          other.figureId == figureId &&
          other.figureName == figureName &&
          other.days == days &&
          other.locationsCount == locationsCount &&
          other.totalDistance == totalDistance &&
          other.startDate == startDate &&
          listEquals(other.locations, locations);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        figureId,
        figureName,
        days,
        locationsCount,
        totalDistance,
        startDate,
        Object.hashAll(locations),
      );

  Route copyWith({
    String? id,
    String? name,
    String? figureId,
    String? figureName,
    int? days,
    int? locationsCount,
    double? totalDistance,
    String? startDate,
    List<RouteLocation>? locations,
  }) =>
      Route(
        id: id ?? this.id,
        name: name ?? this.name,
        figureId: figureId ?? this.figureId,
        figureName: figureName ?? this.figureName,
        days: days ?? this.days,
        locationsCount: locationsCount ?? this.locationsCount,
        totalDistance: totalDistance ?? this.totalDistance,
        startDate: startDate ?? this.startDate,
        locations: locations ?? this.locations,
      );

  @override
  String toString() =>
      'Route(id: $id, name: $name, figureName: $figureName, days: $days, '
      'locationsCount: $locationsCount, totalDistance: $totalDistance)';
}
