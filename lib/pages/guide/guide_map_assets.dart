part of 'guide_page.dart';

class _GuideMapAssets {
  final Set<MapMarkerData> markers;
  final MapIcon userLocationIcon;
  final MapCoordinate? focusPoint;
  final MapBounds? locationBounds;
  final List<LocationRecord> sites;
  final bool isLocalCopy;

  const _GuideMapAssets({
    required this.markers,
    required this.userLocationIcon,
    required this.focusPoint,
    required this.locationBounds,
    required this.sites,
    required this.isLocalCopy,
  });
}
