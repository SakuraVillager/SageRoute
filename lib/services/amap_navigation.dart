import '../models/saved_route.dart';

/// Opens AMap's native route planner for the first stop. With no start
/// coordinates supplied, AMap uses the device's current position.
Uri buildAmapNavigationUri(RouteWaypoint firstStop) {
  final latitude = firstStop.latitude;
  final longitude = firstStop.longitude;
  if (!latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    throw const FormatException('首站缺少有效坐标');
  }

  final name = firstStop.name.trim().replaceAll(',', ' ');
  return Uri(
    scheme: 'amapuri',
    host: 'route',
    path: '/plan/',
    queryParameters: {
      'sourceApplication': 'SageRoute',
      'sname': '我的位置',
      'dlat': latitude.toString(),
      'dlon': longitude.toString(),
      'dname': name,
      'dev': '0',
      't': '0',
    },
  );
}
