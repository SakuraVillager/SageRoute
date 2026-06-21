import 'dart:math' as math;

import 'amap_gateway.dart';
import 'models/amap_route_types.dart';
import 'models/route_place.dart';
import 'models/transport_type.dart';

class DeterministicAmapGateway implements AmapGateway {
  const DeterministicAmapGateway({this.drivingSpeedKmh = 40, this.walkingSpeedKmh = 5});

  final double drivingSpeedKmh;
  final double walkingSpeedKmh;

  @override
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request) async {
    // Simple deterministic calculation: sum straight-line distances between points
    final points = <RoutePlace>[];
    points.add(request.origin);
    points.addAll(request.waypoints);
    points.add(request.destination);

    double totalMeters = 0.0;
    final polyline = <List<double>>[];

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      polyline.add([p.latitude, p.longitude]);
      if (i == 0) continue;
      final prev = points[i - 1];
      totalMeters += _distanceMeters(prev.latitude, prev.longitude, p.latitude, p.longitude);
    }

    final speedKmh = request.transportType == TransportType.walking ? walkingSpeedKmh : drivingSpeedKmh;
    final speedMps = speedKmh * 1000 / 3600;
    final travelSeconds = (totalMeters / speedMps).round();

    // waypointOrder: if optimizeOrder=true we don't change ordering in deterministic gateway
    return AmapRouteResult(
      distanceMeters: totalMeters.round(),
      travelDuration: Duration(seconds: travelSeconds),
      polyline: polyline,
      waypointOrder: null,
    );
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula
    const earthRadius = 6371000.0; // meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * math.pi / 180.0;
}
