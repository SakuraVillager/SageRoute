import 'package:flutter/foundation.dart';
import '../../services/location_service.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../components/map/sage_map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/icon_repository.dart';
import '../../data/location_repository.dart';
import '../../models/location_record.dart';
import '../../theme/color_schemes.dart';
import '../../utils/svg_path_parser.dart';

part 'guide_location_logic.dart';
part 'guide_preview_animation.dart';
part 'guide_marker_builder.dart';
part 'guide_map_assets.dart';
part 'location_detail_sheet.dart';

/// 导览页：承载高德地图。
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> with TickerProviderStateMixin {
  // Constants moved to guide_preview_animation.dart (_previewRandomDistanceMeters, etc.)

  Future<_GuideMapAssets>? _assetsFuture;
  late final LocationRepository _locationRepository;
  late final IconRepository _iconRepository;
  final math.Random _previewRandom = math.Random();
  late final AnimationController _previewDriftController;
  late final AnimationController _previewSettleController;
  SageMapController? _mapController;
  final _mapKey = GlobalKey();
  bool _hasAdjustedInitialViewport = false;
  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;
  bool _locationPermissionChecked = false;
  MapCoordinate? _latestUserLatLng;
  MapCoordinate? _previewCurrentPoint;
  MapCoordinate? _previewDriftFrom;
  MapCoordinate? _previewDriftTo;
  MapCoordinate? _previewSettleFrom;
  MapCoordinate? _previewSettleTo;
  bool _hasNativeLocationDot = false;
  bool _isCenteringToMyLocation = false;
  bool _isPrimingLocation = false;
  bool _isRefiningLocation = false;
  bool _isPreviewDriftEnabled = false;
  bool _pendingNativeDotReveal = false;
  bool _freezePreviewDriftAfterSettle = false;
  Color? _markerFillColor;
  Set<MapMarkerData> _cachedScenicMarkers = const {};

  bool get _isSettlingPreviewDot => _previewSettleController.isAnimating;

  Duration _nextPreviewDriftDuration() {
    const span = _previewDriftMaxDurationMs - _previewDriftMinDurationMs;
    final milliseconds =
        _previewDriftMinDurationMs + _previewRandom.nextInt(span + 1);
    return Duration(milliseconds: milliseconds);
  }

  @override
  void initState() {
    super.initState();
    _locationRepository = const LocationRepository();
    _iconRepository = const IconRepository();
    final initialDriftDuration = _nextPreviewDriftDuration();
    _previewDriftController =
        AnimationController(vsync: this, duration: initialDriftDuration)
          ..addListener(_onPreviewDriftTick)
          ..addStatusListener(_onPreviewDriftStatus);
    _previewSettleController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 680),
          )
          ..addListener(_onPreviewSettleTick)
          ..addStatusListener(_onPreviewSettleStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) _requestLocationPermission(this);
    });
  }

  void _onPreviewDriftTick() {
    // No setState — the AnimatedBuilder wrapping SageMap handles repaints.
  }

  void _onPreviewDriftStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !_shouldShowPreviewLocationDot(this) ||
        !_isPreviewDriftEnabled ||
        _isSettlingPreviewDot) {
      return;
    }

    if (_previewDriftTo != null) {
      _previewCurrentPoint = _previewDriftTo;
    }
    _startNextPreviewDriftStep(this);
  }

  void _onPreviewSettleTick() {
    // No setState — the AnimatedBuilder wrapping SageMap handles repaints.
  }

  void _onPreviewSettleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }

    final revealNative = _pendingNativeDotReveal;
    final freezeDrift = _freezePreviewDriftAfterSettle;

    _pendingNativeDotReveal = false;
    _freezePreviewDriftAfterSettle = false;
    _previewSettleFrom = null;
    _previewSettleTo = null;

    if (freezeDrift) {
      _isPreviewDriftEnabled = false;
      _previewCurrentPoint = _latestUserLatLng;
    }

    if (mounted) {
      setState(() {
        if (revealNative) {
          _hasNativeLocationDot = true;
        }
      });
    }

    _syncPreviewDriftState(this);
  }

  @override
  void dispose() {
    _previewDriftController.removeListener(_onPreviewDriftTick);
    _previewDriftController.dispose();
    _previewSettleController.removeListener(_onPreviewSettleTick);
    _previewSettleController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextMarkerColor = Theme.of(context).colorScheme.primary;
    if (_markerFillColor == nextMarkerColor && _assetsFuture != null) {
      return;
    }

    _markerFillColor = nextMarkerColor;
    _assetsFuture = _loadAssets(this, markerFillColor: nextMarkerColor);
    _assetsFuture?.then((loadedAssets) {
      if (mounted) {
        _cachedScenicMarkers = loadedAssets.markers;
        _fitAllLocationsOnMap(this, loadedAssets);
      }
    });
  }

  Future<void> _showLocationDetails(LocationRecord location) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (_) =>
          PointerInterceptor(child: _LocationDetailSheet(location: location)),
    );
  }

  Set<MapMarkerData> _buildMapMarkers({required MapIcon? userLocationIcon}) {
    final markers = Set<MapMarkerData>.from(_cachedScenicMarkers);

    // 始终使用自定义蓝色标记显示用户位置，确保粗定位和精定位使用同一个图标。
    if (_latestUserLatLng != null && userLocationIcon != null) {
      // 精确定位后使用真实坐标，粗定位时使用带漂移动画的坐标。
      final userPosition = _hasNativeLocationDot
          ? _latestUserLatLng!
          : _shouldShowPreviewLocationDot(this)
          ? _previewMarkerPosition(this, _latestUserLatLng!)
          : _latestUserLatLng!;
      markers.add(
        MapMarkerData(
          position: userPosition,
          icon: userLocationIcon,
          infoWindowEnable: false,
          clickable: false,
          anchor: const ui.Offset(0.5, 0.5),
          zIndex: 100,
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GuideMapAssets>(
      future: _assetsFuture,
      builder: (context, snapshot) {
        final colorScheme = Theme.of(context).colorScheme;
        final assets = snapshot.data;
        // Viewport adjustment is handled in onMapCreated
        // and via the then() callback in didChangeDependencies.
        final mapMessage = snapshot.hasError
            ? '地点加载失败：${snapshot.error}'
            : snapshot.connectionState != ConnectionState.done
            ? '正在加载地点...'
            : _cachedScenicMarkers.isEmpty
            ? '当前没有可显示的地点数据。'
            : '导览地图已接入高德地图，可在此继续叠加景点、路线和讲解能力。';
        final permissionMessage = !_locationPermissionChecked
            ? (kIsWeb ? '点击右下角定位按钮获取当前位置' : '正在申请定位权限...')
            : _locationPermissionStatus.isGranted
            ? null
            : _locationPermissionStatus.isPermanentlyDenied
            ? '定位权限被永久拒绝，请到系统设置中开启后重试。'
            : '定位权限未开启，无法显示你的位置。';
        final message = permissionMessage ?? mapMessage;

        final desktop = kIsWeb && MediaQuery.sizeOf(context).width >= 1024;
        final map = Stack(
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _previewDriftController,
                  _previewSettleController,
                ]),
                builder: (context, _) {
                  final animatedMarkers = _buildMapMarkers(
                    userLocationIcon: assets?.userLocationIcon,
                  );
                  return SageMap(
                    key: _mapKey,
                    initialCameraPosition: const MapCameraPosition(
                      // 西安钟楼附近，作为导览初始中心点。
                      target: MapCoordinate(34.259462, 108.947151),
                    ),
                    markers: animatedMarkers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitAllLocationsOnMap(this, assets);
                      unawaited(_primeUserLocation(this));
                    },
                    onLocationChanged: (location) =>
                        _handleLocationChanged(this, location),
                    myLocationStyleOptions: MapLocationStyle(
                      _locationPermissionStatus.isGranted,
                      icon: _transparentIcon,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: PointerInterceptor(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest.withValues(
                      alpha: 0.96,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
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
            ),
            if (_locationPermissionChecked &&
                !_locationPermissionStatus.isGranted)
              Positioned(
                right: 16,
                bottom: 88,
                child: PointerInterceptor(
                  child: FilledButton.icon(
                    onPressed: _locationPermissionStatus.isPermanentlyDenied
                        ? openAppSettings
                        : () => _requestLocationPermission(this),
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      _locationPermissionStatus.isPermanentlyDenied
                          ? '打开设置'
                          : '允许定位',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 16,
              bottom: 24,
              child: PointerInterceptor(
                child: FloatingActionButton.small(
                  heroTag: 'guide_page_locate_me',
                  onPressed: _isCenteringToMyLocation
                      ? null
                      : () => _focusOnMyLocation(this),
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  foregroundColor: colorScheme.primary,
                  elevation: 2,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ),
            ),
          ],
        );
        if (!desktop) return map;
        return Row(
          children: [
            SizedBox(
              width: 360,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '地点导览',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(message),
                  const SizedBox(height: 16),
                  for (final marker in _cachedScenicMarkers)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(marker.infoWindow.title),
                      onTap: () {
                        _mapController?.moveCamera(
                          MapCameraUpdate.newLatLngZoom(marker.position, 15),
                        );
                        marker.onTap?.call(marker.id ?? '');
                      },
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: map),
          ],
        );
      },
    );
  }
}
