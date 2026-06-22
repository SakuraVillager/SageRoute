import 'amap_gateway.dart';
import 'models/amap_route_types.dart';
import 'models/route_plan_command.dart';
import 'models/route_plan_constraints.dart';
import 'models/route_place.dart';
import 'models/route_preference_type.dart';
import 'models/route_recommendation.dart';
import 'place_set_generator.dart';

class RoutePlanningEngine {
  const RoutePlanningEngine({required AmapGateway gateway})
      : _gateway = gateway,
        _shortestGenerator = const ShortestPlaceSetGenerator(),
        _diversityGenerator = const DiversityPlaceSetGenerator();

  final AmapGateway _gateway;
  final ShortestPlaceSetGenerator _shortestGenerator;
  final DiversityPlaceSetGenerator _diversityGenerator;

  /// Amap driving API max waypoints limit.
  static const int maxAmapWaypoints = 16;

  Future<RouteRecommendationBundle> plan(RoutePlanCommand command) async {
    _validate(command.constraints, command.places.length);

    final resolved = _resolveEndpoints(command);
    final routes = <RecommendedRoute>[];

    for (final preference in command.preferences) {
      final selectedPlaces = _selectPlaces(
        command.places,
        resolved.origin,
        resolved.destination,
        preference,
        command.constraints,
      );

      if (selectedPlaces.length < command.constraints.minPlaces) {
        routes.add(
          RecommendedRoute(
            preference: preference,
            orderedPlaces: selectedPlaces,
            stats: RouteStats(
              distanceMeters: null,
              travelDuration: null,
              totalDuration: null,
              placesCount: selectedPlaces.length,
            ),
            report: const ConstraintReport(
              passed: false,
              reason: '地点数量不足以满足最小值',
            ),
          ),
        );
        continue;
      }

      // Request Compose (Stage D): build draft request with waypoints limit
      final interiorPlaces = selectedPlaces.length <= 2
          ? const <RoutePlace>[]
          : selectedPlaces.sublist(1, selectedPlaces.length - 1);
      final limitedWaypoints = interiorPlaces.length > maxAmapWaypoints
          ? interiorPlaces.sublist(0, maxAmapWaypoints)
          : interiorPlaces;

      final draftRequest = AmapRouteDraftRequest(
        origin: selectedPlaces.first,
        destination: selectedPlaces.last,
        waypoints: limitedWaypoints,
        transportType: command.constraints.transportType,
        optimizeOrder: true,
        preferenceKey: preference.name,
      );

      final result = await _gateway.fetchRoute(draftRequest);
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
          meta: result.waypointOrder == null
              ? null
              : RouteBuildMeta(note: 'waypoint_order:${result.waypointOrder}'),
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

  _ResolvedEndpoints _resolveEndpoints(RoutePlanCommand command) {
    final start = _findPlace(command.places, command.startPlaceId) ?? command.places.first;
    final end = _findPlace(command.places, command.endPlaceId) ?? start;
    return _ResolvedEndpoints(origin: start, destination: end);
  }

  RoutePlace? _findPlace(List<RoutePlace> places, String? placeId) {
    if (placeId == null) {
      return null;
    }

    final parsedId = int.tryParse(placeId);
    if (parsedId == null) {
      return null;
    }

    for (final place in places) {
      if (place.id == parsedId) {
        return place;
      }
    }
    return null;
  }

  List<RoutePlace> _selectPlaces(
    List<RoutePlace> places,
    RoutePlace origin,
    RoutePlace destination,
    RoutePreferenceType preference,
    RoutePlanConstraints constraints,
  ) {
    final generator = preference == RoutePreferenceType.shortest
        ? _shortestGenerator
        : _diversityGenerator;
    return generator.select(
      places: places,
      origin: origin,
      destination: destination,
      constraints: constraints,
    );
  }

  Duration _estimateStayDuration(List<RoutePlace> places) {
    final totalMinutes = places.fold<int>(
      0,
      (sum, place) => sum + (place.averageVisitDurationMin ?? 0),
    );
    return Duration(minutes: totalMinutes);
  }

  bool _passesTimeWindow(RoutePlanConstraints constraints, Duration totalDuration) {
    final timeWindow = constraints.timeWindow;
    if (timeWindow == null) {
      return true;
    }
    return totalDuration <= timeWindow;
  }
}

class _ResolvedEndpoints {
  final RoutePlace origin;
  final RoutePlace destination;

  const _ResolvedEndpoints({required this.origin, required this.destination});
}
