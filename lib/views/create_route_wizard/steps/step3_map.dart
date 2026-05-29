import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../../../theme/color_schemes.dart';

/// Step 3 of CreateRouteWizard — map exploration with real AMap.
class Step3Map extends StatefulWidget {
  final List<String> selectedLocations;
  final ValueChanged<List<String>> onLocationsChanged;

  const Step3Map({
    super.key,
    this.selectedLocations = const [],
    required this.onLocationsChanged,
  });

  @override
  State<Step3Map> createState() => _Step3MapState();
}

class _Step3MapState extends State<Step3Map> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map fills the entire area between progress bar and bottom button
        Expanded(
          child: Stack(
            children: [
              // Real AMap
              AMapWidget(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(30.259462, 120.147151),
                  zoom: 13,
                ),
              ),

              // Hint overlay at the bottom
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_outlined,
                          size: 18, color: AppColors.sageAccent),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '在地图上探索，选择你想前往的地点',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.sageText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Selected count badge
                      if (widget.selectedLocations.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${widget.selectedLocations.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
