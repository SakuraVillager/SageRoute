import '../../models/location_record.dart';
import '../../models/heritage_grade.dart';

class RoutePlace {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int? averageVisitDurationMin;
  final String? topic;
  final String? categories;
  final HeritageGrade? heritageGrade;
  final List<String> themes;
  final LocationRecord? details;

  const RoutePlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.averageVisitDurationMin,
    required this.topic,
    required this.categories,
    this.heritageGrade,
    this.themes = const [],
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'averageVisitDurationMin': averageVisitDurationMin,
    'topic': topic,
    'categories': categories,
    if (heritageGrade != null) 'heritageGrade': heritageGrade!.name,
    if (themes.isNotEmpty) 'themes': themes,
    if (details != null) 'details': details!.toMap(),
  };

  factory RoutePlace.fromJson(Map<String, dynamic> data) => RoutePlace(
    id: (data['id'] as num).toInt(),
    name: data['name'] as String,
    latitude: (data['latitude'] as num).toDouble(),
    longitude: (data['longitude'] as num).toDouble(),
    averageVisitDurationMin: (data['averageVisitDurationMin'] as num?)?.toInt(),
    topic: data['topic'] as String?,
    categories: data['categories'] as String?,
    heritageGrade: HeritageGrade.parse(data['heritageGrade']),
    themes: (data['themes'] as List?)?.cast<String>() ?? const [],
    details: data['details'] is Map
        ? LocationRecord.fromMap(
            Map<String, dynamic>.from(data['details'] as Map),
          )
        : null,
  );

  factory RoutePlace.fromLocation(LocationRecord location) {
    final coordinates = location.coordinates;
    if (!location.hasValidCoordinates ||
        (coordinates[0] == 0 && coordinates[1] == 0)) {
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
      heritageGrade: location.heritageGrade,
      themes: location.themes,
      details: location,
    );
  }
}
