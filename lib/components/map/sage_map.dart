import 'package:flutter/material.dart';
import 'map_types.dart';
import 'sage_map_native.dart'
    if (dart.library.js_interop) 'sage_map_web.dart'
    as platform;
export 'map_types.dart';

class SageMap extends StatelessWidget {
  const SageMap({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
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
  Widget build(BuildContext context) => platform.PlatformMap(
    initialCameraPosition: initialCameraPosition,
    markers: markers,
    polylines: polylines,
    onMapCreated: onMapCreated,
    onLocationChanged: onLocationChanged,
    myLocationStyleOptions: myLocationStyleOptions,
  );
}
