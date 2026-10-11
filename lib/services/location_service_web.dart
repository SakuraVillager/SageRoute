import 'dart:async';
import 'dart:js_interop';
import '../components/map/map_types.dart';
import 'client_config.dart';
import 'location_service.dart';
import 'web/map_bridge.dart';

Future<LocationResult> locate() async {
  try {
    final raw = await mapBridge
        .locate(ClientConfig.mapConfig.jsify()!)
        .toDart
        .timeout(const Duration(seconds: 15));
    final result = raw!.dartify()! as Map;
    if (result['coordinateSystem'] != 'gcj02') {
      throw const FormatException('定位结果不是高德坐标');
    }
    return LocationResult(
      LocationStatus.ready,
      coordinate: MapCoordinate(
        (result['latitude'] as num).toDouble(),
        (result['longitude'] as num).toDouble(),
      ),
    );
  } on TimeoutException {
    return const LocationResult(LocationStatus.timeout, message: '定位超时，请重试');
  } catch (error) {
    final message = error.toString();
    final denied =
        message.contains('denied') ||
        message.contains('PERMISSION') ||
        message.contains('permission');
    return LocationResult(
      denied ? LocationStatus.denied : LocationStatus.unavailable,
      message: denied ? '请在浏览器的站点设置中允许定位后重试' : '定位失败：$message',
    );
  }
}
