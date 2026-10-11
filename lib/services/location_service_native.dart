import 'package:geolocator/geolocator.dart';
import '../components/map/map_types.dart';
import 'location_service.dart';

Future<LocationResult> locate() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const LocationResult(LocationStatus.denied, message: '请允许定位权限');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 10),
      ),
    );
    return LocationResult(
      LocationStatus.ready,
      coordinate: MapCoordinate(position.latitude, position.longitude),
      coordinateSystem: LocationCoordinateSystem.wgs84,
    );
  } catch (error) {
    return LocationResult(LocationStatus.unavailable, message: '定位失败：$error');
  }
}
