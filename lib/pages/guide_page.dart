import 'dart:ui' as ui;

import 'package:amap_map/amap_map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../data/location_repository.dart';

/// 导览页：承载高德地图。
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  late final Future<_GuideMapAssets> _assetsFuture;
  late final LocationRepository _locationRepository;

  @override
  void initState() {
    super.initState();
    _locationRepository = const LocationRepository();
    _assetsFuture = _loadAssets();
  }

  Future<_GuideMapAssets> _loadAssets() async {
    final locations = await _locationRepository.fetchLocations();
    final dotIcon = await _buildDotIcon();
    final userLocationIcon = await _buildAppleLocationIcon();

    final markers = locations
        .where((location) => location.coordinates.length >= 2)
        .map<Marker>((location) {
          final longitude = location.coordinates[0];
          final latitude = location.coordinates[1];

          return Marker(
            position: LatLng(latitude, longitude),
            icon: dotIcon,
            infoWindow: InfoWindow(title: location.nameModern),
            anchor: const ui.Offset(0.5, 0.5),
            zIndex: 1,
          );
        })
        .toSet();

    return _GuideMapAssets(
      markers: markers,
      userLocationIcon: userLocationIcon,
    );
  }

  Future<BitmapDescriptor> _buildDotIcon() async {
    const int size = 28;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = ui.Offset(size / 2, size / 2);

    final borderPaint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = const ui.Color(0xFFFFFFFF);
    final fillPaint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = const ui.Color(0xFF1E88E5);

    canvas.drawCircle(center, 13, borderPaint);
    canvas.drawCircle(center, 9, fillPaint);

    final image = await recorder.endRecording().toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _buildAppleLocationIcon() async {
    const int size = 42;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = ui.Offset(size / 2, size / 2);

    final circlePaint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = const ui.Color(0xFFFFFFFF);

    canvas.drawCircle(center, 18, circlePaint);
    canvas.drawCircle(
      center,
      16,
      ui.Paint()..color = const ui.Color(0xFFEEF5FF),
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(CupertinoIcons.location_solid.codePoint),
      style: TextStyle(
        fontFamily: CupertinoIcons.location_solid.fontFamily,
        package: CupertinoIcons.location_solid.fontPackage,
        color: const Color(0xFF1E88E5),
        fontSize: 18,
      ),
    );
    textPainter.layout();
    final iconOffset = ui.Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, iconOffset);

    final image = await recorder.endRecording().toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GuideMapAssets>(
      future: _assetsFuture,
      builder: (context, snapshot) {
        final assets = snapshot.data;
        final markers = assets?.markers ?? const <Marker>{};
        final message = snapshot.hasError
            ? '地点加载失败：${snapshot.error}'
            : snapshot.connectionState != ConnectionState.done
            ? '正在加载地点...'
            : markers.isEmpty
            ? '当前没有可显示的地点数据。'
            : '导览地图已接入高德地图，可在此继续叠加景点、路线和讲解能力。';

        return Stack(
          children: [
            AMapWidget(
              initialCameraPosition: const CameraPosition(
                // 西安钟楼附近，作为导览初始中心点。
                target: LatLng(34.259462, 108.947151),
                zoom: 14,
              ),
              trafficEnabled: false,
              touchPoiEnabled: true,
              markers: markers,
              myLocationStyleOptions: MyLocationStyleOptions(
                true,
                icon:
                    assets?.userLocationIcon ?? BitmapDescriptor.defaultMarker,
                circleFillColor: const Color(0x1A1E88E5),
                circleStrokeColor: const Color(0x331E88E5),
                circleStrokeWidth: 1,
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GuideMapAssets {
  final Set<Marker> markers;
  final BitmapDescriptor userLocationIcon;

  const _GuideMapAssets({
    required this.markers,
    required this.userLocationIcon,
  });
}
