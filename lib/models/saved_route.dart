import '../route_planning/models/route_place.dart';
import '../route_planning/models/transport_type.dart';

/// 用户规划的路线（持久化于 Supabase `user_routes` + `user_route_waypoints`）。
class SavedRoute {
  const SavedRoute({
    required this.id,
    required this.title,
    required this.dateRange,
    required this.duration,
    required this.distance,
    required this.waypoints,
    this.figureId,
    this.figureName,
  });

  final String id;
  final String title;
  final String dateRange;
  final String duration;
  final String distance;
  final int? figureId;
  final String? figureName;
  final List<RouteWaypoint> waypoints;

  factory SavedRoute.fromMap(
    Map<String, dynamic> row, {
    List<RouteWaypoint> waypoints = const <RouteWaypoint>[],
  }) {
    return SavedRoute(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      dateRange: row['date_range'] as String? ?? '',
      duration: row['duration'] as String? ?? '',
      distance: row['distance'] as String? ?? '',
      figureId: row['figure_id'] as int?,
      figureName: row['figure_name'] as String?,
      waypoints: waypoints,
    );
  }

  /// 写入 `user_routes` 的行数据（id 由数据库生成，新建时不含）。
  Map<String, dynamic> toMap({required String userId}) {
    return <String, dynamic>{
      'user_id': userId,
      'title': title,
      'date_range': dateRange,
      'duration': duration,
      'distance': distance,
      'figure_id': figureId,
      'figure_name': figureName,
    };
  }

  SavedRoute copyWith({String? id, List<RouteWaypoint>? waypoints}) {
    return SavedRoute(
      id: id ?? this.id,
      title: title,
      dateRange: dateRange,
      duration: duration,
      distance: distance,
      figureId: figureId,
      figureName: figureName,
      waypoints: waypoints ?? this.waypoints,
    );
  }
}

/// 路线途经点（持久化于 `user_route_waypoints`，坐标冗余存储以便离线渲染地图）。
class RouteWaypoint {
  const RouteWaypoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.locationId,
    this.visitDurationMin,
    this.categories,
    this.transportToNext,
  });

  final String name;
  final double latitude;
  final double longitude;
  final int? locationId;
  final int? visitDurationMin;
  final String? categories;

  /// 前往下一段（下一路径点）的交通方式；最后一点为 null。
  final TransportType? transportToNext;

  factory RouteWaypoint.fromRoutePlace(
    RoutePlace place, {
    TransportType? transportToNext,
  }) {
    return RouteWaypoint(
      name: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
      // A place without a catalog ID can still be saved as a coordinate
      // snapshot; zero is not a valid Location foreign key.
      locationId: place.id > 0 ? place.id : null,
      visitDurationMin: place.averageVisitDurationMin,
      categories: place.categories,
      transportToNext: transportToNext,
    );
  }

  factory RouteWaypoint.fromMap(Map<String, dynamic> row) {
    return RouteWaypoint(
      name: row['name'] as String? ?? '',
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      locationId: row['location_id'] as int?,
      visitDurationMin: row['visit_duration_min'] as int?,
      categories: row['categories'] as String?,
      transportToNext: _transportFromString(
        row['transport_to_next'] as String?,
      ),
    );
  }

  /// 写入 `user_route_waypoints` 的行数据。
  Map<String, dynamic> toMap({
    required String routeId,
    required int sortOrder,
  }) {
    final row = <String, dynamic>{
      'route_id': routeId,
      'sort_order': sortOrder,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'location_id': locationId,
      'visit_duration_min': visitDurationMin,
      'categories': categories,
    };
    // Omit a null value instead of sending JSON null. Older deployed schemas
    // define this column as NOT NULL with a default, so omission remains
    // compatible until the nullable-column migration reaches that database.
    final transport = transportToNext;
    if (transport != null) row['transport_to_next'] = transport.name;
    return row;
  }

  RoutePlace toRoutePlace() {
    return RoutePlace(
      id: locationId ?? 0,
      name: name,
      latitude: latitude,
      longitude: longitude,
      averageVisitDurationMin: visitDurationMin,
      topic: null,
      categories: categories,
    );
  }

  static TransportType? _transportFromString(String? value) {
    if (value == null) return null;
    for (final type in TransportType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
