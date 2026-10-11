import 'route_place.dart';
import 'transport_type.dart';

class AmapRouteDraftRequest {
  final RoutePlace origin;
  final RoutePlace destination;
  final List<RoutePlace> waypoints;
  final TransportType transportType;
  final bool optimizeOrder;
  final String preferenceKey;

  const AmapRouteDraftRequest({
    required this.origin,
    required this.destination,
    required this.waypoints,
    required this.transportType,
    required this.optimizeOrder,
    required this.preferenceKey,
  });
}

class AmapRouteResult {
  final int distanceMeters;
  final Duration travelDuration;
  /// List of [latitude, longitude] pairs forming the route polyline.
  final List<List<double>> polyline;
  final List<int>? waypointOrder;

  const AmapRouteResult({
    required this.distanceMeters,
    required this.travelDuration,
    required this.polyline,
    required this.waypointOrder,
  });

  /// Parse from Amap Web Service API v3 direction response.
  ///
  /// Response JSON structure (v3 driving/walking):
  /// ```json
  /// {
  ///   "status": "1",
  ///   "info": "OK",
  ///   "infocode": "10000",
  ///   "count": "1",
  ///   "route": {
  ///     "paths": [
  ///       {
  ///         "distance": "123456",
  ///         "duration": "3600",
  ///         "steps": [
  ///           {
  ///             "polyline": "116.1,39.2;116.2,39.3",
  ///             ...
  ///           }
  ///         ]
  ///       }
  ///     ]
  ///   }
  /// }
  /// ```
  factory AmapRouteResult.fromMap(Map<String, dynamic> map) {
    // Check Amap API status field if present ("1" = success)
    final status = map['status']?.toString();
    if (status != null && status != '1') {
      final info = map['info']?.toString() ?? 'unknown error';
      throw Exception('Amap API error: $info (status: $status)');
    }

    final route =
        (map['route'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final paths = (route['paths'] as List?) ?? const <dynamic>[];
    if (paths.isEmpty) {
      throw Exception('Amap response has no paths');
    }

    final firstPath = (paths.first as Map).cast<String, dynamic>();

    // Amap v3 returns distance / duration as strings; parse to int
    final distanceMeters =
        int.tryParse(firstPath['distance']?.toString() ?? '') ?? 0;
    final durationSeconds =
        int.tryParse(firstPath['duration']?.toString() ?? '') ?? 0;

    // Build polyline from step polylines (Amap returns per-step polylines).
    // Amap step polyline format: "lon,lat;lon,lat" (longitude first).
    final polyline = <List<double>>[];
    final steps = (firstPath['steps'] as List?) ?? const <dynamic>[];
    for (final step in steps) {
      final stepMap = (step as Map).cast<String, dynamic>();
      final rawPolyline = stepMap['polyline'];
      if (rawPolyline is String && rawPolyline.isNotEmpty) {
        final values = rawPolyline.split(';');
        for (final value in values) {
          final parts = value.split(',');
          if (parts.length == 2) {
            // Amap: lon first, lat second → store as [lat, lon]
            final longitude = double.tryParse(parts[0]);
            final latitude = double.tryParse(parts[1]);
            if (latitude != null && longitude != null) {
              polyline.add(<double>[latitude, longitude]);
            }
          }
        }
      }
    }

    // Fallback: if no steps, try to read polyline directly from path level
    if (polyline.isEmpty) {
      final rawPolyline = firstPath['polyline'];
      if (rawPolyline is String && rawPolyline.isNotEmpty) {
        final values = rawPolyline.split(';');
        for (final value in values) {
          final parts = value.split(',');
          if (parts.length == 2) {
            final longitude = double.tryParse(parts[0]);
            final latitude = double.tryParse(parts[1]);
            if (latitude != null && longitude != null) {
              polyline.add(<double>[latitude, longitude]);
            }
          }
        }
      }
    }

    final rawOrder = firstPath['waypoint_order'];
    final waypointOrder = rawOrder is List
        ? rawOrder
            .whereType<num>()
            .map((value) => value.toInt())
            .toList(growable: false)
        : null;

    return AmapRouteResult(
      distanceMeters: distanceMeters,
      travelDuration: Duration(seconds: durationSeconds),
      polyline: polyline,
      waypointOrder: waypointOrder,
    );
  }
}