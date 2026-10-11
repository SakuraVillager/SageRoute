import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/color_schemes.dart';

/// All map coordinates use GCJ-02. SDK-specific types stay in adapters.
class MapCoordinate {
  const MapCoordinate(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
  List<double> get lngLat => [longitude, latitude];
}

class MapBounds {
  const MapBounds({required this.southwest, required this.northeast});
  final MapCoordinate southwest;
  final MapCoordinate northeast;
}

class MapCameraPosition {
  const MapCameraPosition({required this.target, this.zoom = 14});
  final MapCoordinate target;
  final double zoom;
}

class MapCameraUpdate {
  const MapCameraUpdate._({
    this.target,
    this.zoom,
    this.bounds,
    this.padding = 0,
  });
  factory MapCameraUpdate.newLatLngZoom(MapCoordinate target, double zoom) =>
      MapCameraUpdate._(target: target, zoom: zoom);
  factory MapCameraUpdate.newLatLng(MapCoordinate target) =>
      MapCameraUpdate._(target: target);
  factory MapCameraUpdate.newLatLngBounds(MapBounds bounds, double padding) =>
      MapCameraUpdate._(bounds: bounds, padding: padding);
  final MapCoordinate? target;
  final double? zoom;
  final MapBounds? bounds;
  final double padding;
}

abstract class SageMapController {
  Future<void> moveCamera(
    MapCameraUpdate update, {
    bool animated = true,
    int duration = 300,
  });
}

class MapIcon {
  const MapIcon._(this.bytes);
  factory MapIcon.fromBytes(Uint8List bytes) => MapIcon._(bytes);
  static const defaultMarker = MapIcon._(null);
  final Uint8List? bytes;
}

class MapInfoWindow {
  const MapInfoWindow({this.title = ''});
  final String title;
}

class MapMarkerData {
  MapMarkerData({
    required this.position,
    this.icon = MapIcon.defaultMarker,
    this.anchor = const Offset(0.5, 1),
    this.infoWindow = const MapInfoWindow(),
    this.infoWindowEnable = true,
    this.clickable = true,
    this.zIndex = 1,
    this.onTap,
  });
  final MapCoordinate position;
  final MapIcon icon;
  final Offset anchor;
  final MapInfoWindow infoWindow;
  final bool infoWindowEnable;
  final bool clickable;
  final double zIndex;
  final ValueChanged<String>? onTap;
  String? id;
  void setIdForCopy(String value) => id = value;
}

class MapPolylineData {
  MapPolylineData({
    required this.points,
    this.width = 7,
    this.color = AppColors.primaryLight,
  });
  final List<MapCoordinate> points;
  final int width;
  final Color color;
  String? id;
  void setIdForCopy(String value) => id = value;
}

class MapUserLocation {
  const MapUserLocation(this.latLng);
  final MapCoordinate latLng;
}

class MapLocationStyle {
  const MapLocationStyle(
    this.enabled, {
    this.icon,
    this.circleFillColor = Colors.transparent,
    this.circleStrokeColor = Colors.transparent,
    this.circleStrokeWidth = 0,
  });
  final bool enabled;
  final MapIcon? icon;
  final Color circleFillColor;
  final Color circleStrokeColor;
  final double circleStrokeWidth;
}
