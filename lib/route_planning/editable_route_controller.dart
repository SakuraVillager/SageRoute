import 'package:flutter/foundation.dart';

import 'amap_gateway.dart';
import 'deterministic_amap_gateway.dart';
import 'models/route_place.dart';
import 'models/route_preference_type.dart';
import 'models/route_recommendation.dart';
import 'models/transport_type.dart';
import 'multi_stop_route_planner.dart';

class EditableRouteController extends ChangeNotifier {
  EditableRouteController(
    RouteRecommendationBundle bundle, {
    AmapGateway? gateway,
    TransportType transportType = TransportType.driving,
  }) : _gateway = gateway ?? const DeterministicAmapGateway(),
       _transportType = transportType,
       _routesByPreference = {
         for (final route in bundle.routes) route.preference: route,
       },
       _selectedPreference = bundle.routes.isEmpty
           ? RoutePreferenceType.shortest
           : bundle.routes.first.preference;

  final AmapGateway _gateway;
  final TransportType _transportType;
  final Map<RoutePreferenceType, RecommendedRoute> _routesByPreference;
  RoutePreferenceType _selectedPreference;

  RoutePreferenceType get selectedPreference => _selectedPreference;

  List<RoutePreferenceType> get availablePreferences =>
      _routesByPreference.keys.toList(growable: false);

  bool get hasRoutes => _routesByPreference.isNotEmpty;

  RecommendedRoute? get activeRouteOrNull =>
      _routesByPreference[_selectedPreference];

  RecommendedRoute get activeRoute {
    final route = activeRouteOrNull;
    if (route == null) {
      throw StateError('No active route');
    }
    return route;
  }

  void switchPreference(RoutePreferenceType preference) {
    if (!_routesByPreference.containsKey(preference)) {
      return;
    }
    if (_selectedPreference == preference) {
      return;
    }
    _selectedPreference = preference;
    notifyListeners();
  }

  void removePlace(int placeId) {
    final currentRoute = activeRouteOrNull;
    if (currentRoute == null) {
      return;
    }
    final updatedPlaces = currentRoute.orderedPlaces
        .where((place) => place.id != placeId)
        .toList(growable: false);

    if (updatedPlaces.length == currentRoute.orderedPlaces.length) {
      return;
    }
    if (updatedPlaces.length < 2) {
      return;
    }

    final preference = _selectedPreference;
    _rebuildRouteWithAmap(preference, currentRoute, updatedPlaces);
  }

  Future<void> _rebuildRouteWithAmap(
    RoutePreferenceType preference,
    RecommendedRoute route,
    List<RoutePlace> updatedPlaces,
  ) async {
    try {
      final result = await MultiStopRoutePlanner(gateway: _gateway).plan(
        places: updatedPlaces,
        transportType: _transportType,
        preferenceKey: preference.name,
      );
      final stayDuration = _estimateStayDuration(updatedPlaces);
      final totalDuration = result.travelDuration + stayDuration;

      _routesByPreference[preference] = RecommendedRoute(
        preference: route.preference,
        orderedPlaces: updatedPlaces,
        stats: RouteStats(
          distanceMeters: result.distanceMeters,
          travelDuration: result.travelDuration,
          totalDuration: totalDuration,
          placesCount: updatedPlaces.length,
        ),
        report: ConstraintReport(
          passed: updatedPlaces.length >= 2,
          reason: updatedPlaces.length >= 2 ? null : '地点数量不足',
        ),
        meta: route.meta,
        polyline: result.polyline,
      );
    } catch (_) {
      _routesByPreference[preference] = _rebuildRouteFallback(
        route,
        updatedPlaces,
      );
    }

    notifyListeners();
  }

  Duration _estimateStayDuration(List<RoutePlace> places) {
    final totalMinutes = places.fold<int>(
      0,
      (sum, place) => sum + (place.averageVisitDurationMin ?? 0),
    );
    return Duration(minutes: totalMinutes);
  }

  RecommendedRoute _rebuildRouteFallback(
    RecommendedRoute route,
    List<RoutePlace> updatedPlaces,
  ) {
    final stayMinutes = updatedPlaces.fold<int>(
      0,
      (sum, place) => sum + (place.averageVisitDurationMin ?? 0),
    );
    final travelMinutes = 20 + (updatedPlaces.length - 2) * 5;
    final distanceMeters = 1000 + (updatedPlaces.length - 2) * 250;
    final totalMinutes = stayMinutes + travelMinutes;

    return RecommendedRoute(
      preference: route.preference,
      orderedPlaces: updatedPlaces,
      stats: RouteStats(
        distanceMeters: distanceMeters,
        travelDuration: Duration(minutes: travelMinutes),
        totalDuration: Duration(minutes: totalMinutes),
        placesCount: updatedPlaces.length,
      ),
      report: ConstraintReport(
        passed: updatedPlaces.length >= 2,
        reason: updatedPlaces.length >= 2 ? null : '地点数量不足',
      ),
      meta: route.meta,
    );
  }
}
