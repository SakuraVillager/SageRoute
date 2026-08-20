import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../route_planning/amap_gateway.dart';
import '../route_planning/models/amap_route_types.dart';
import '../route_planning/models/transport_type.dart';

/// 通过原生高德 Android SDK（RouteSearch）做路径规划的 Gateway。
///
/// 与 Kotlin 端 RoutePlanningHandler 通过 MethodChannel 通信，
/// 只需要 AndroidManifest 中配置的高德 SDK Key，无需 Web 服务 Key。
class NativeAmapGateway implements AmapGateway {
  const NativeAmapGateway({this.timeout = const Duration(seconds: 15)});

  final Duration timeout;

  static const MethodChannel _channel = MethodChannel(
    'com.sageroute/route_planning',
  );

  @override
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request) async {
    final waypoints = request.waypoints
        .map((p) => {'lat': p.latitude, 'lon': p.longitude})
        .toList(growable: false);

    final methodName = switch (request.transportType) {
      TransportType.driving => 'calculateDriveRoute',
      TransportType.walking => 'calculateWalkRoute',
    };

    debugPrint(
      '[GW] → $methodName '
      'origin=(${request.origin.latitude},${request.origin.longitude}) '
      'dest=(${request.destination.latitude},${request.destination.longitude}) '
      'waypoints=${waypoints.length}',
    );

    final Map<dynamic, dynamic>? raw;
    try {
      raw = await _channel
          .invokeMethod<Map<dynamic, dynamic>>(methodName, {
            'originLat': request.origin.latitude,
            'originLon': request.origin.longitude,
            'destLat': request.destination.latitude,
            'destLon': request.destination.longitude,
            'waypoints': waypoints,
          })
          .timeout(timeout);
    } on TimeoutException {
      debugPrint('[GW] ⏱ 调用超时 (${timeout.inSeconds}s)');
      throw Exception(
        '原生路径规划超时 (${timeout.inSeconds}s)，'
        '请检查高德 Key 是否已开通路线规划服务',
      );
    } on MissingPluginException catch (e) {
      debugPrint('[GW] ⚠ MethodChannel 未注册: $e');
      throw Exception('原生路由模块未注册，请确保 RoutePlanningHandler 已正确初始化');
    } on PlatformException catch (e) {
      debugPrint(
        '[GW] 高德路径规划失败: code=${e.code}, '
        'message=${e.message}, details=${e.details}',
      );
      final details = e.details;
      final amapErrorCode = details is Map
          ? (details['amapErrorCode'] as num?)?.toInt()
          : null;
      if (e.code == 'AMAP_AUTH_ERROR' || amapErrorCode == 1008) {
        throw Exception(
          '高德 Android Key 签名校验失败（1008）。'
          '请在高德开放平台中将该 Key 绑定到当前 APK 的 SHA1，'
          '包名必须为 com.sageroute.sageroute。',
        );
      }
      throw Exception(e.message ?? '高德路径规划失败（${e.code}）');
    }

    debugPrint('[GW] ← raw keys=${raw?.keys}');

    if (raw == null) {
      throw Exception('原生路径规划返回空结果');
    }

    final distance = (raw['distance'] as num?)?.toInt() ?? 0;
    final duration = (raw['duration'] as num?)?.toInt() ?? 0;

    // polyline 原生返回 [[lat, lon], ...]
    final rawPolyline = (raw['polyline'] as List?) ?? [];
    debugPrint(
      '[GW] distance=$distance duration=${duration}s '
      'rawPolylineLen=${rawPolyline.length}',
    );
    final polyline = <List<double>>[];
    for (final point in rawPolyline) {
      if (point is List && point.length >= 2) {
        final lat = (point[0] as num).toDouble();
        final lon = (point[1] as num).toDouble();
        polyline.add(<double>[lat, lon]);
      }
    }

    if (polyline.isEmpty && distance > 0) {
      debugPrint(
        '[GW] ⚠ 路线距离非零但 polyline 为空，'
        '高德 SDK 可能未返回步骤折线数据',
      );
    }

    return AmapRouteResult(
      distanceMeters: distance,
      travelDuration: Duration(seconds: duration),
      polyline: polyline,
      waypointOrder: null,
    );
  }
}
