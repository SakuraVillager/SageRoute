part of 'guide_page.dart';

class _GuideMapAssets {
  final Set<Marker> markers;
  final BitmapDescriptor userLocationIcon;
  final LatLng? focusPoint;
  final LatLngBounds? locationBounds;

  const _GuideMapAssets({
    required this.markers,
    required this.userLocationIcon,
    required this.focusPoint,
    required this.locationBounds,
  });
}
