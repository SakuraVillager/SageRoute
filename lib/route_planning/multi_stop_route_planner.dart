import 'amap_gateway.dart';
import 'models/amap_route_types.dart';
import 'models/route_place.dart';
import 'models/transport_type.dart';

/// Plans a route through every place in the supplied order.
///
/// AMap driving accepts at most six waypoints per request, while walking
/// accepts none. This planner splits long journeys and merges their results.
class MultiStopRoutePlanner {
  const MultiStopRoutePlanner({required AmapGateway gateway})
    : _gateway = gateway;

  final AmapGateway _gateway;

  static const int maxDrivingWaypoints = 6;
  static const int _maxDrivingPointsPerRequest = maxDrivingWaypoints + 2;

  Future<AmapRouteResult> plan({
    required List<RoutePlace> places,
    required TransportType transportType,
    required String preferenceKey,
  }) async {
    if (places.length < 2) {
      throw ArgumentError('At least two places are required');
    }
    for (final place in places) {
      _validatePlace(place);
    }

    final chunks = transportType == TransportType.walking
        ? _walkingChunks(places)
        : _drivingChunks(places);
    var totalDistance = 0;
    var totalDuration = Duration.zero;
    final mergedPolyline = <List<double>>[];

    for (var index = 0; index < chunks.length; index++) {
      final chunk = chunks[index];
      try {
        final result = await _gateway.fetchRoute(
          AmapRouteDraftRequest(
            origin: chunk.first,
            destination: chunk.last,
            waypoints: chunk.length <= 2
                ? const <RoutePlace>[]
                : chunk.sublist(1, chunk.length - 1),
            transportType: transportType,
            optimizeOrder: false,
            preferenceKey: preferenceKey,
          ),
        );
        if (result.polyline.length < 2) {
          throw StateError('高德未返回可绘制的路线折线');
        }
        totalDistance += result.distanceMeters;
        totalDuration += result.travelDuration;
        _appendPolyline(mergedPolyline, result.polyline);
      } catch (error) {
        throw StateError(
          '第 ${index + 1}/${chunks.length} 段'
          '“${chunk.first.name} → ${chunk.last.name}”规划失败：$error',
        );
      }
    }

    return AmapRouteResult(
      distanceMeters: totalDistance,
      travelDuration: totalDuration,
      polyline: mergedPolyline,
      waypointOrder: null,
    );
  }

  List<List<RoutePlace>> _walkingChunks(List<RoutePlace> places) => [
    for (var index = 0; index < places.length - 1; index++)
      <RoutePlace>[places[index], places[index + 1]],
  ];

  List<List<RoutePlace>> _drivingChunks(List<RoutePlace> places) {
    final chunks = <List<RoutePlace>>[];
    var start = 0;
    while (start < places.length - 1) {
      final endExclusive = (start + _maxDrivingPointsPerRequest).clamp(
        0,
        places.length,
      );
      chunks.add(places.sublist(start, endExclusive));
      // Reuse the previous destination as the next origin: no leg is skipped.
      start = endExclusive - 1;
    }
    return chunks;
  }

  void _appendPolyline(List<List<double>> target, List<List<double>> segment) {
    for (final point in segment) {
      if (point.length < 2 || !point[0].isFinite || !point[1].isFinite) {
        continue;
      }
      if (target.isNotEmpty && _samePoint(target.last, point)) continue;
      target.add(<double>[point[0], point[1]]);
    }
  }

  bool _samePoint(List<double> first, List<double> second) =>
      (first[0] - second[0]).abs() < 0.0000001 &&
      (first[1] - second[1]).abs() < 0.0000001;

  void _validatePlace(RoutePlace place) {
    final latitude = place.latitude;
    final longitude = place.longitude;
    final valid =
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
    if (!valid) {
      throw ArgumentError('地点“${place.name}”缺少有效经纬度');
    }
  }
}
