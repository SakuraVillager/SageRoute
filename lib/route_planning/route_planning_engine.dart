import 'amap_gateway.dart';
import 'models/route_plan_command.dart';
import 'models/route_plan_constraints.dart';
import 'models/route_place.dart';
import 'models/route_recommendation.dart';
import 'multi_stop_route_planner.dart';

/// Builds route previews from the places explicitly selected by the user.
///
/// The input order is authoritative. Recommendation filters must never remove
/// a selected stop or silently change the order shown in the wizard.
class RoutePlanningEngine {
  const RoutePlanningEngine({required AmapGateway gateway})
    : _gateway = gateway;

  final AmapGateway _gateway;

  Future<RouteRecommendationBundle> plan(RoutePlanCommand command) async {
    _validate(command.constraints, command.places.length);
    final selectedPlaces = List<RoutePlace>.unmodifiable(command.places);
    final routes = <RecommendedRoute>[];

    for (final preference in command.preferences) {
      final result = await MultiStopRoutePlanner(gateway: _gateway).plan(
        places: selectedPlaces,
        transportType: command.constraints.transportType,
        preferenceKey: preference.name,
      );
      final totalDuration =
          result.travelDuration + _estimateStayDuration(selectedPlaces);
      final passed = _passesTimeWindow(command.constraints, totalDuration);

      routes.add(
        RecommendedRoute(
          preference: preference,
          orderedPlaces: selectedPlaces,
          stats: RouteStats(
            distanceMeters: result.distanceMeters,
            travelDuration: result.travelDuration,
            totalDuration: totalDuration,
            placesCount: selectedPlaces.length,
          ),
          report: ConstraintReport(
            passed: passed,
            reason: passed ? null : '总时长超出约束区间',
          ),
          meta: const RouteBuildMeta(note: '按用户选择顺序规划全部地点'),
          polyline: result.polyline,
        ),
      );
    }

    return RouteRecommendationBundle(routes: routes);
  }

  void _validate(RoutePlanConstraints constraints, int placesCount) {
    if (constraints.maxPlaces < constraints.minPlaces) {
      throw ArgumentError('maxPlaces must be >= minPlaces');
    }
    if (placesCount < constraints.minPlaces) {
      throw ArgumentError('places count must be >= minPlaces');
    }
  }

  Duration _estimateStayDuration(List<RoutePlace> places) {
    final totalMinutes = places.fold<int>(
      0,
      (sum, place) => sum + (place.averageVisitDurationMin ?? 0),
    );
    return Duration(minutes: totalMinutes);
  }

  bool _passesTimeWindow(
    RoutePlanConstraints constraints,
    Duration totalDuration,
  ) {
    final timeWindow = constraints.timeWindow;
    return timeWindow == null || totalDuration <= timeWindow;
  }
}
