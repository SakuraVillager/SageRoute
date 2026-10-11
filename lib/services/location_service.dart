import '../components/map/map_types.dart';
import 'location_service_native.dart'
    if (dart.library.js_interop) 'location_service_web.dart'
    as platform;

enum LocationStatus { ready, denied, unavailable, timeout }

enum LocationCoordinateSystem { gcj02, wgs84 }

class LocationResult {
  const LocationResult(
    this.status, {
    this.coordinate,
    this.message,
    this.coordinateSystem = LocationCoordinateSystem.gcj02,
  });
  final LocationStatus status;
  final MapCoordinate? coordinate;
  final String? message;

  /// Native system GPS is explicitly tagged; callers must convert it before
  /// passing it to a map. Web AMap Geolocation already returns GCJ-02.
  final LocationCoordinateSystem coordinateSystem;
}

abstract final class LocationService {
  static Future<LocationResult> locate() => platform.locate();
}
