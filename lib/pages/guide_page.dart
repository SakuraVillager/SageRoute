import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

/// 导览页：承载高德地图。
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AMapWidget(
          initialCameraPosition: CameraPosition(
            // 西安钟楼附近，作为导览初始中心点。
            target: LatLng(34.259462, 108.947151),
            zoom: 14,
          ),
          trafficEnabled: false,
          touchPoiEnabled: true,
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
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                '导览地图已接入高德地图，可在此继续叠加景点、路线和讲解能力。',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
