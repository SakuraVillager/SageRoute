import 'package:amap_map/amap_map.dart' as native;
import 'package:x_amap_base/x_amap_base.dart' as base;
import 'package:flutter/material.dart';
import 'map_types.dart';

base.LatLng _point(MapCoordinate p) => base.LatLng(p.latitude, p.longitude);
native.BitmapDescriptor _icon(MapIcon icon) => icon.bytes == null
    ? native.BitmapDescriptor.defaultMarker
    : native.BitmapDescriptor.fromBytes(icon.bytes!);

class PlatformMap extends StatelessWidget {
  const PlatformMap({
    super.key,
    required this.initialCameraPosition,
    required this.markers,
    required this.polylines,
    this.onMapCreated,
    this.onLocationChanged,
    this.myLocationStyleOptions,
  });
  final MapCameraPosition initialCameraPosition;
  final Set<MapMarkerData> markers;
  final Set<MapPolylineData> polylines;
  final ValueChanged<SageMapController>? onMapCreated;
  final ValueChanged<MapUserLocation>? onLocationChanged;
  final MapLocationStyle? myLocationStyleOptions;
  @override
  Widget build(BuildContext context) {
    final location = myLocationStyleOptions;
    return native.AMapWidget(
      initialCameraPosition: native.CameraPosition(
        target: _point(initialCameraPosition.target),
        zoom: initialCameraPosition.zoom,
      ),
      markers: markers.map((m) {
        final result = native.Marker(
          position: _point(m.position),
          icon: _icon(m.icon),
          anchor: m.anchor,
          infoWindow: native.InfoWindow(title: m.infoWindow.title),
          infoWindowEnable: m.infoWindowEnable,
          clickable: m.clickable,
          zIndex: m.zIndex,
          onTap: m.onTap,
        );
        if (m.id != null) result.setIdForCopy(m.id!);
        return result;
      }).toSet(),
      polylines: polylines.map((p) {
        final result = native.Polyline(
          points: p.points.map(_point).toList(),
          width: p.width.toDouble(),
          color: p.color,
        );
        if (p.id != null) result.setIdForCopy(p.id!);
        return result;
      }).toSet(),
      onMapCreated: (controller) =>
          onMapCreated?.call(_NativeController(controller)),
      onLocationChanged: (location) => onLocationChanged?.call(
        MapUserLocation(
          MapCoordinate(location.latLng.latitude, location.latLng.longitude),
        ),
      ),
      myLocationStyleOptions: location == null
          ? null
          : native.MyLocationStyleOptions(
              location.enabled,
              icon: location.icon == null ? null : _icon(location.icon!),
              circleFillColor: location.circleFillColor,
              circleStrokeColor: location.circleStrokeColor,
              circleStrokeWidth: location.circleStrokeWidth,
            ),
    );
  }
}

class _NativeController implements SageMapController {
  _NativeController(this.controller);
  final native.AMapController controller;
  @override
  Future<void> moveCamera(
    MapCameraUpdate update, {
    bool animated = true,
    int duration = 300,
  }) async {
    final bounds = update.bounds;
    final native.CameraUpdate camera;
    if (bounds != null) {
      camera = native.CameraUpdate.newLatLngBounds(
        base.LatLngBounds(
          southwest: _point(bounds.southwest),
          northeast: _point(bounds.northeast),
        ),
        update.padding,
      );
    } else if (update.zoom != null) {
      camera = native.CameraUpdate.newLatLngZoom(
        _point(update.target!),
        update.zoom!,
      );
    } else {
      camera = native.CameraUpdate.newLatLng(_point(update.target!));
    }
    await controller.moveCamera(camera, animated: animated, duration: duration);
  }
}
