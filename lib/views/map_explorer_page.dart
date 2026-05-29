import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../data/mock_locations.dart';
import '../theme/color_schemes.dart';

/// Map explorer page matching the Web version's [MapExplorer.tsx].
///
/// Uses [AMapWidget] as the base map layer (same AMap engine as
/// [GuidePage]) with a styled UI overlay:
/// - Top search bar (white pill, Search icon + placeholder + Filter button)
/// - Horizontal filter capsules ("全部历史遗迹", "白居易路线 - 杭州", "宋代")
/// - Right floating buttons (compass + locate, circular white with shadow)
/// - Bottom location preview card (white rounded-3xl, image + name + region + stats)
///
/// Search/filter interactions are UI-only placeholders — no real logic attached.
class MapExplorerPage extends StatefulWidget {
  const MapExplorerPage({super.key});

  @override
  State<MapExplorerPage> createState() => _MapExplorerPageState();
}

class _MapExplorerPageState extends State<MapExplorerPage> {
  // ignore: unused_field — kept for future map interactions
  AMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      body: Stack(
        children: [
          // ── Base map layer (AMap, preserves GuidePage engine) ──
          AMapWidget(
            initialCameraPosition: const CameraPosition(
              // Centered near 杭州西湖, matching Web map area.
              target: LatLng(30.259462, 120.147151),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // ── Top search bar ──
          Positioned(
            top: 44,
            left: 24,
            right: 24,
            child: _buildSearchBar(),
          ),

          // ── Filter capsules (horizontal scroll) ──
          Positioned(
            top: 104,
            left: 24,
            right: 24,
            child: _buildFilterCapsules(),
          ),

          // ── Right floating action buttons ──
          Positioned(
            right: 24,
            bottom: 140,
            child: _buildFloatingButtons(),
          ),

          // ── Bottom location preview card ──
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: _buildLocationPreview(),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 22, color: AppColors.sageMuted),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '搜索附近的历史遗迹...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.sageMuted,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppColors.sageBorder,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.filter_list, size: 20, color: AppColors.sageText),
        ],
      ),
    );
  }

  // ── Filter Capsules ──

  Widget _buildFilterCapsules() {
    final filters = [
      ('全部历史遗迹', true),
      ('白居易路线 - 杭州', false),
      ('宋代', false),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final label = f.$1;
          final isActive = f.$2;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.sageDeep : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border:
                  isActive ? null : Border.all(color: AppColors.sageBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : AppColors.sageText,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Right Floating Buttons ──

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFloatingButton(Icons.explore),
        const SizedBox(height: 12),
        _buildFloatingButton(Icons.my_location),
      ],
    );
  }

  Widget _buildFloatingButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 22, color: AppColors.sageText),
        onPressed: () {},
      ),
    );
  }

  // ── Bottom Location Preview Card ──

  Widget _buildLocationPreview() {
    final location = mockLocations[0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Main content row
            Row(
              children: [
                  // Image with dynasty badge overlay
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              location.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Text(
                                '唐',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          location.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sageText,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location.region,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.sageMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatBadge(
                              Icons.route,
                              AppColors.sageAccent,
                              '距您 ${location.distance}',
                            ),
                            const SizedBox(width: 12),
                            _buildStatBadge(
                              Icons.location_on,
                              AppColors.sageText,
                              '白居易路线',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            // Decorative gradient corner (matches Web version)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFFF0DED3),
                      Colors.transparent,
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
