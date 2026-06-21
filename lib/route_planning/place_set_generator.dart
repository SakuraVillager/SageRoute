import 'dart:math' as math;

import 'models/route_place.dart';
import 'models/route_plan_constraints.dart';

/// Selects and orders places for a route based on a preference strategy.
abstract class PlaceSetGenerator {
  const PlaceSetGenerator();

  /// Select and order places from the candidate set.
  /// Returns a list starting with [origin] and ending with [destination].
  List<RoutePlace> select({
    required List<RoutePlace> places,
    required RoutePlace origin,
    required RoutePlace destination,
    required RoutePlanConstraints constraints,
  });

  // ---- shared utilities ----

  static const double earthRadiusMeters = 6371000.0;

  /// Haversine distance in meters between two points.
  static double distanceMeters(RoutePlace a, RoutePlace b) {
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final ha = sinDLat * sinDLat +
        math.cos(_toRad(a.latitude)) *
            math.cos(_toRad(b.latitude)) *
            sinDLon * sinDLon;
    return 2 * earthRadiusMeters * math.atan2(math.sqrt(ha), math.sqrt(1 - ha));
  }

  /// Perpendicular distance (in degrees) from [point] to the line segment
  static double perpendicularDistanceDeg(
    RoutePlace start,
    RoutePlace end,
    RoutePlace point,
  ) {
    final x1 = start.longitude;
    final y1 = start.latitude;
    final x2 = end.longitude;
    final y2 = end.latitude;
    final x0 = point.longitude;
    final y0 = point.latitude;

    final numerator =
        ((x2 - x1) * (y1 - y0)) - ((x1 - x0) * (y2 - y1));
    final denominator =
        math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2).toDouble());
    if (denominator == 0) return 0;
    return numerator.abs() / denominator;
  }

  /// Approximate corridor filter: keep only places within [bufferKm] km
  /// of the direct line between origin and destination.
  static bool isWithinCorridor(
    RoutePlace origin,
    RoutePlace destination,
    RoutePlace place, {
    double bufferKm = 5.0,
  }) {
    final perpDeg = perpendicularDistanceDeg(origin, destination, place);
    // Rough conversion: 1 degree ≈ 111 km at mid-latitudes
    final perpKm = perpDeg * 111.0;
    return perpKm <= bufferKm;
  }

  /// Ellipse filter: keep only places where the detour (via the place)
  /// is within [expansionFactor] times the direct distance.
  static bool isWithinEllipse(
    RoutePlace origin,
    RoutePlace destination,
    RoutePlace place, {
    double expansionFactor = 1.5,
  }) {
    final directM = distanceMeters(origin, destination);
    if (directM <= 0) return true;
    final viaM =
        distanceMeters(origin, place) + distanceMeters(place, destination);
    return viaM <= directM * expansionFactor;
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;
}

// ---------------------------------------------------------------------------
// ShortestPlaceSetGenerator
// ---------------------------------------------------------------------------

/// Selects a compact set of places closest to the origin→destination corridor.
///
/// 1. Filter by corridor (perpendicular distance ≤ buffer) AND ellipse (detour ≤ 1.5× direct)
/// 2. Sort candidates by distance from origin (ascending)
/// 3. Pick top `maxPlaces - 2` candidates (reserving slots for origin & dest)
class ShortestPlaceSetGenerator extends PlaceSetGenerator {
  const ShortestPlaceSetGenerator({this.corridorBufferKm = 5.0});

  final double corridorBufferKm;

  @override
  List<RoutePlace> select({
    required List<RoutePlace> places,
    required RoutePlace origin,
    required RoutePlace destination,
    required RoutePlanConstraints constraints,
  }) {
    // Step 1: corridor + ellipse filter
    final candidates = places.where((place) {
      if (place.id == origin.id || place.id == destination.id) return false;
      return PlaceSetGenerator.isWithinCorridor(origin, destination, place,
              bufferKm: corridorBufferKm) &&
          PlaceSetGenerator.isWithinEllipse(origin, destination, place);
    }).toList(growable: false);

    // Step 2: sort by distance from origin (closest first)
    candidates.sort((a, b) {
      return PlaceSetGenerator.distanceMeters(origin, a)
          .compareTo(PlaceSetGenerator.distanceMeters(origin, b));
    });

    // Step 3: pick top N (reserve slots for origin + dest)
    final maxInterior = math.max(0, constraints.maxPlaces - 2);
    final selected = candidates.take(maxInterior).toList(growable: false);

    return _buildOrderedPlaces(origin, destination, selected, constraints);
  }
}

// ---------------------------------------------------------------------------
// DiversityPlaceSetGenerator
// ---------------------------------------------------------------------------

/// Selects a diverse set of places by category rotation sampling.
///
/// 1. Filter by corridor (same as Shortest)
/// 2. Group candidates by category (fallback: topic, then name)
/// 3. Round-robin pick from each category until reaching maxPlaces - 2
class DiversityPlaceSetGenerator extends PlaceSetGenerator {
  const DiversityPlaceSetGenerator({this.corridorBufferKm = 5.0});

  final double corridorBufferKm;

  @override
  List<RoutePlace> select({
    required List<RoutePlace> places,
    required RoutePlace origin,
    required RoutePlace destination,
    required RoutePlanConstraints constraints,
  }) {
    // Step 1: corridor filter
    final candidates = places.where((place) {
      if (place.id == origin.id || place.id == destination.id) return false;
      return PlaceSetGenerator.isWithinCorridor(origin, destination, place,
          bufferKm: corridorBufferKm);
    }).toList(growable: false);

    // Step 2: group by category
    final Map<String, List<RoutePlace>> byCategory = {};
    for (final place in candidates) {
      final key = _categoryKey(place);
      byCategory.putIfAbsent(key, () => <RoutePlace>[]).add(place);
    }

    // Sort places within each category by distance from origin
    for (final list in byCategory.values) {
      list.sort((a, b) =>
          PlaceSetGenerator.distanceMeters(origin, a)
              .compareTo(PlaceSetGenerator.distanceMeters(origin, b)));
    }

    // Step 3: round-robin pick
    final selected = <RoutePlace>[];
    final maxInterior = math.max(0, constraints.maxPlaces - 2);
    final categoryKeys = byCategory.keys.toList(growable: false);
    var round = 0;

    while (selected.length < maxInterior && categoryKeys.isNotEmpty) {
      var addedThisRound = false;
      for (final key in categoryKeys) {
        final list = byCategory[key]!;
        if (round < list.length) {
          selected.add(list[round]);
          addedThisRound = true;
          if (selected.length >= maxInterior) break;
        }
      }
      if (!addedThisRound) break; // no more candidates in any category
      round++;
    }

    return _buildOrderedPlaces(origin, destination, selected, constraints);
  }

  /// Extract a category key for grouping.
  static String _categoryKey(RoutePlace place) {
    final cat = (place.categories ?? '').trim();
    if (cat.isNotEmpty) return cat;
    final topic = (place.topic ?? '').trim();
    if (topic.isNotEmpty) return topic;
    return place.name;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build the final ordered list: [origin, ...selected, destination].
/// Ensures origin/dest are first/last and don't duplicate.
List<RoutePlace> _buildOrderedPlaces(
  RoutePlace origin,
  RoutePlace destination,
  List<RoutePlace> selected,
  RoutePlanConstraints constraints,
) {
  final result = <RoutePlace>[origin];
  for (final place in selected) {
    if (place.id != origin.id && place.id != destination.id) {
      result.add(place);
    }
  }
  if (destination.id != origin.id) {
    result.add(destination);
  }
  // Trim to maxPlaces
  final limit = math.min(constraints.maxPlaces, result.length);
  return result.sublist(0, limit);
}
