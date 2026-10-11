import '../../models/location_record.dart';

class RoutePlace {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int? averageVisitDurationMin;
  final String? topic;
  final String? categories;

  const RoutePlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.averageVisitDurationMin,
    required this.topic,
    required this.categories,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'averageVisitDurationMin': averageVisitDurationMin,
    'topic': topic,
    'categories': categories,
  };

  factory RoutePlace.fromJson(Map<String, dynamic> data) => RoutePlace(
    id: (data['id'] as num).toInt(),
    name: data['name'] as String,
    latitude: (data['latitude'] as num).toDouble(),
    longitude: (data['longitude'] as num).toDouble(),
    averageVisitDurationMin: (data['averageVisitDurationMin'] as num?)?.toInt(),
    topic: data['topic'] as String?,
    categories: data['categories'] as String?,
  );

  factory RoutePlace.fromLocation(LocationRecord location) {
    final coordinates = location.coordinates;
    if (coordinates.length < 2) {
      throw FormatException('地点 ${location.id} 缺少有效坐标');
    }

    return RoutePlace(
      id: location.id,
      name: location.nameModern,
      latitude: coordinates[1],
      longitude: coordinates[0],
      averageVisitDurationMin: location.averageVisitDurationMin,
      topic: location.topic,
      categories: location.categories.join(', '),
    );
  }
}
