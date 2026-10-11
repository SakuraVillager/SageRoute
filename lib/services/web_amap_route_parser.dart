import '../route_planning/models/amap_route_types.dart';

/// The bridge normalizes JS LngLat instances, not REST step strings.
AmapRouteResult parseWebAmapRoute(Map<String, dynamic> result) {
  final points = <List<double>>[];
  for (final raw in (result['polyline'] as List? ?? const [])) {
    if (raw is! List || raw.length < 2 || raw[0] is! num || raw[1] is! num) {
      continue;
    }
    final lat = (raw[0] as num).toDouble();
    final lon = (raw[1] as num).toDouble();
    if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180) {
      continue;
    }
    if (points.isNotEmpty && points.last[0] == lat && points.last[1] == lon) {
      continue;
    }
    points.add([lat, lon]);
  }
  final distance = result['distance'];
  final duration = result['duration'];
  if (points.length < 2 ||
      distance is! num ||
      duration is! num ||
      !distance.isFinite ||
      !duration.isFinite ||
      distance < 0 ||
      duration < 0) {
    throw const FormatException('高德返回的路线数据不完整');
  }
  return AmapRouteResult(
    distanceMeters: distance.round(),
    travelDuration: Duration(seconds: duration.round()),
    polyline: points,
    waypointOrder: null,
  );
}
