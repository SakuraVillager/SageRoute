import 'route_place.dart';
import 'route_preference_type.dart';

class RouteStats {
  final int? distanceMeters;
  final Duration? travelDuration;
  final Duration? totalDuration;
  final int placesCount;

  const RouteStats({
    required this.distanceMeters,
    required this.travelDuration,
    required this.totalDuration,
    required this.placesCount,
  });
}

class ConstraintReport {
  final bool passed;
  final String? reason;

  const ConstraintReport({required this.passed, this.reason});
}

class RouteBuildMeta {
  final String? note;

  const RouteBuildMeta({this.note});
}

class RecommendedRoute {
  final RoutePreferenceType preference;
  final List<RoutePlace> orderedPlaces;
  final RouteStats stats;
  final ConstraintReport report;
  final RouteBuildMeta? meta;
  final List<List<double>>? polyline;

  const RecommendedRoute({
    required this.preference,
    required this.orderedPlaces,
    required this.stats,
    required this.report,
    this.meta,
    this.polyline,
  });
}

class RouteRecommendationBundle {
  final List<RecommendedRoute> routes;

  const RouteRecommendationBundle({required this.routes});
}
