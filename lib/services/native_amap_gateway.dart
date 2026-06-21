import 'package:flutter/services.dart';

import '../route_planning/amap_gateway.dart';
import '../route_planning/models/amap_route_types.dart';

/// 通过原生高德 Android SDK（RouteSearch）做驾车路径规划的 Gateway。
///
/// 与 Kotlin 端 RoutePlanningHandler 通过 MethodChannel 通信，
/// 只需要 AndroidManifest 中配置的高德 SDK Key，无需 Web 服务 Key。
class NativeAmapGateway implements AmapGateway {
  const NativeAmapGateway();

  static const MethodChannel _channel =
      MethodChannel('com.sageroute/route_planning');

  @override
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request) async {
    final waypoints = request.waypoints
        .map((p) => {'lat': p.latitude, 'lon': p.longitude})
        .toList(growable: false);

    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'calculateDriveRoute',
      {
        'originLat': request.origin.latitude,
        'originLon': request.origin.longitude,
        'destLat': request.destination.latitude,
        'destLon': request.destination.longitude,
        'waypoints': waypoints,
      },
    );

    if (raw == null) {
      throw Exception('原生路径规划返回空结果');
    }

    final distance = (raw['distance'] as num?)?.toInt() ?? 0;
    final duration = (raw['duration'] as num?)?.toInt() ?? 0;

    // polyline 原生返回 [[lat, lon], ...]
    final rawPolyline = (raw['polyline'] as List?) ?? const [];
    final polyline = <List<double>>[];
    for (final point in rawPolyline) {
      if (point is List && point.length >= 2) {
        final lat = (point[0] as num).toDouble();
        final lon = (point[1] as num).toDouble();
        polyline.add(<double>[lat, lon]);
      }
    }

    return AmapRouteResult(
      distanceMeters: distance,
      travelDuration: Duration(seconds: duration),
      polyline: polyline,
      waypointOrder: null,
    );
  }
}
