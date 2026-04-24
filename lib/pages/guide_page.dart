import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../data/location_repository.dart';
import '../models/location_record.dart';

/// 导览页：承载高德地图。
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

enum _LocationStage { coarse, precise, native }

class _GuidePageState extends State<GuidePage> with TickerProviderStateMixin {
  static const double _previewRandomDistanceMeters = 800;
  static const int _previewDriftMinDurationMs = 1000;
  static const int _previewDriftMaxDurationMs = 3000;

  Future<_GuideMapAssets>? _assetsFuture;
  late final LocationRepository _locationRepository;
  final math.Random _previewRandom = math.Random();
  late final AnimationController _previewDriftController;
  late final AnimationController _previewSettleController;
  AMapController? _mapController;
  bool _hasAdjustedInitialViewport = false;
  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;
  bool _locationPermissionChecked = false;
  LatLng? _latestUserLatLng;
  LatLng? _previewCurrentPoint;
  LatLng? _previewDriftFrom;
  LatLng? _previewDriftTo;
  LatLng? _previewSettleFrom;
  LatLng? _previewSettleTo;
  bool _hasNativeLocationDot = false;
  bool _isCenteringToMyLocation = false;
  bool _isPrimingLocation = false;
  bool _isRefiningLocation = false;
  bool _isPreviewDriftEnabled = false;
  bool _pendingNativeDotReveal = false;
  bool _freezePreviewDriftAfterSettle = false;
  Color? _markerFillColor;

  bool get _isSettlingPreviewDot => _previewSettleController.isAnimating;

  Duration _nextPreviewDriftDuration() {
    final span = _previewDriftMaxDurationMs - _previewDriftMinDurationMs;
    final milliseconds =
        _previewDriftMinDurationMs + _previewRandom.nextInt(span + 1);
    return Duration(milliseconds: milliseconds);
  }

  @override
  void initState() {
    super.initState();
    _locationRepository = const LocationRepository();
    final initialDriftDuration = _nextPreviewDriftDuration();
    _previewDriftController =
        AnimationController(vsync: this, duration: initialDriftDuration)
          ..addListener(() {
            if (!mounted ||
                !_shouldShowPreviewLocationDot ||
                !_isPreviewDriftEnabled ||
                _isSettlingPreviewDot ||
                _previewDriftFrom == null ||
                _previewDriftTo == null) {
              return;
            }
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed ||
                !_shouldShowPreviewLocationDot ||
                !_isPreviewDriftEnabled ||
                _isSettlingPreviewDot) {
              return;
            }

            if (_previewDriftTo != null) {
              _previewCurrentPoint = _previewDriftTo;
            }
            _startNextPreviewDriftStep();
          });
    _previewSettleController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 680),
          )
          ..addListener(() {
            if (!mounted || !_isSettlingPreviewDot) {
              return;
            }
            setState(() {});
          })
          ..addStatusListener((status) {
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
            }

            if (mounted) {
              setState(() {
                if (revealNative) {
                  _hasNativeLocationDot = true;
                }
              });
            }

            _syncPreviewDriftState();
          });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  @override
  void dispose() {
    _previewDriftController.dispose();
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
    _assetsFuture = _loadAssets(markerFillColor: nextMarkerColor);
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _locationPermissionStatus = status;
      _locationPermissionChecked = true;
    });
    _syncPreviewDriftState();

    if (status.isGranted) {
      unawaited(_primeUserLocation());
    }
  }

  bool get _shouldShowPreviewLocationDot {
    return _locationPermissionStatus.isGranted &&
        !_hasNativeLocationDot &&
        _latestUserLatLng != null;
  }

  void _syncPreviewDriftState() {
    if (!_shouldShowPreviewLocationDot) {
      if (_previewDriftController.isAnimating) {
        _previewDriftController.stop();
      }
      if (_previewSettleController.isAnimating) {
        _previewSettleController.stop();
      }
      _previewDriftFrom = null;
      _previewDriftTo = null;
      _previewCurrentPoint = null;
      _previewSettleFrom = null;
      _previewSettleTo = null;
      _pendingNativeDotReveal = false;
      _freezePreviewDriftAfterSettle = false;
      _isPreviewDriftEnabled = false;
      return;
    }

    if (_isSettlingPreviewDot || !_isPreviewDriftEnabled) {
      if (_previewDriftController.isAnimating) {
        _previewDriftController.stop();
      }
      _previewDriftFrom = null;
      _previewDriftTo = null;
      return;
    }

    if (!_previewDriftController.isAnimating ||
        _previewDriftFrom == null ||
        _previewDriftTo == null) {
      _startNextPreviewDriftStep();
    }
  }

  LatLng _previewMarkerPosition(LatLng anchor) {
    if (_isSettlingPreviewDot &&
        _previewSettleFrom != null &&
        _previewSettleTo != null) {
      final t = _previewSettleController.value;
      return LatLng(
        ui.lerpDouble(
          _previewSettleFrom!.latitude,
          _previewSettleTo!.latitude,
          t,
        )!,
        ui.lerpDouble(
          _previewSettleFrom!.longitude,
          _previewSettleTo!.longitude,
          t,
        )!,
      );
    }

    if (!_shouldShowPreviewLocationDot || !_isPreviewDriftEnabled) {
      return _previewCurrentPoint ?? anchor;
    }

    if (_previewDriftFrom == null || _previewDriftTo == null) {
      return _previewCurrentPoint ?? anchor;
    }

    final t = _previewDriftController.value;
    return LatLng(
      ui.lerpDouble(_previewDriftFrom!.latitude, _previewDriftTo!.latitude, t)!,
      ui.lerpDouble(
        _previewDriftFrom!.longitude,
        _previewDriftTo!.longitude,
        t,
      )!,
    );
  }

  LatLng _randomNearbyPoint(
    LatLng anchor, {
    double distanceMeters = _previewRandomDistanceMeters,
  }) {
    final angle = _previewRandom.nextDouble() * 2 * math.pi;
    final radius = distanceMeters;
    final latOffset = (radius * math.sin(angle)) / 111320;
    final metersPerLng = (111320 * math.cos(anchor.latitude * math.pi / 180))
        .abs();
    final lngOffset = metersPerLng < 1
        ? 0
        : (radius * math.cos(angle)) / metersPerLng;
    return LatLng(anchor.latitude + latOffset, anchor.longitude + lngOffset);
  }

  void _startNextPreviewDriftStep() {
    // 下一段始终从“当前游走点”出发，避免回拉到真实定位锚点。
    final anchor = _previewCurrentPoint ?? _latestUserLatLng;
    if (anchor == null ||
        !_shouldShowPreviewLocationDot ||
        !_isPreviewDriftEnabled) {
      return;
    }

    final from = anchor;
    final to = _randomNearbyPoint(anchor);
    _previewDriftFrom = from;
    _previewDriftTo = to;

    _previewDriftController.duration = _nextPreviewDriftDuration();
    _previewDriftController
      ..stop()
      ..value = 0
      ..forward();
  }

  void _startPreviewSettle({
    required LatLng from,
    required LatLng to,
    bool revealNativeAfter = false,
    bool freezeDriftAfterSettle = false,
  }) {
    _previewDriftFrom = null;
    _previewDriftTo = null;
    _previewSettleFrom = from;
    _previewSettleTo = to;
    _pendingNativeDotReveal = revealNativeAfter;
    _freezePreviewDriftAfterSettle = freezeDriftAfterSettle;
    _previewCurrentPoint = from;

    _previewSettleController
      ..stop()
      ..value = 0
      ..forward();

    _syncPreviewDriftState();
  }

  Future<void> _primeUserLocation({bool force = false}) async {
    if (!_locationPermissionStatus.isGranted || _isPrimingLocation) {
      return;
    }

    if (!force && _latestUserLatLng != null) {
      return;
    }

    _isPrimingLocation = true;
    try {
      final coarseTarget = await _resolveCoarseUserLocation();
      if (coarseTarget != null) {
        _cacheUserLocation(coarseTarget);
      }

      unawaited(_refineUserLocationInBackground());
    } finally {
      _isPrimingLocation = false;
    }
  }

  Future<LatLng?> _resolveCoarseUserLocation() async {
    if (_latestUserLatLng != null) {
      return _latestUserLatLng;
    }

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return null;
      }
    } catch (_) {
      // 定位服务状态查询失败时继续尝试，避免误判。
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
    } catch (_) {
      // 使用下一条链路兜底。
    }

    try {
      final coarse = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 2),
        ),
      );
      return LatLng(coarse.latitude, coarse.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refineUserLocationInBackground({
    LatLng? coarseAnchor,
    bool recenterOnUpdate = false,
  }) async {
    if (!_locationPermissionStatus.isGranted || _isRefiningLocation) {
      return;
    }

    _isRefiningLocation = true;
    try {
      final precise = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final preciseLatLng = LatLng(precise.latitude, precise.longitude);
      _cacheUserLocation(preciseLatLng, stage: _LocationStage.precise);

      if (!recenterOnUpdate || coarseAnchor == null) {
        return;
      }
      if (!mounted || _mapController == null) {
        return;
      }

      final driftMeters = Geolocator.distanceBetween(
        coarseAnchor.latitude,
        coarseAnchor.longitude,
        preciseLatLng.latitude,
        preciseLatLng.longitude,
      );

      if (driftMeters < 25) {
        return;
      }

      await _mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(preciseLatLng, 16),
        animated: true,
        duration: 420,
      );
    } catch (_) {
      // 精定位失败时保留粗定位结果，不影响已完成的相机移动。
    } finally {
      _isRefiningLocation = false;
    }
  }

  Future<void> _showLocationDetails(LocationRecord location) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (_) => _LocationDetailSheet(location: location),
    );
  }

  void _handleLocationChanged(AMapLocation location) {
    _cacheUserLocation(location.latLng, stage: _LocationStage.native);
  }

  void _cacheUserLocation(
    LatLng latLng, {
    _LocationStage stage = _LocationStage.coarse,
  }) {
    final previousAnchor = _latestUserLatLng;
    _latestUserLatLng = latLng;

    if (stage == _LocationStage.coarse) {
      _isPreviewDriftEnabled = true;
      _previewCurrentPoint ??= latLng;
    }

    if (!mounted) {
      _syncPreviewDriftState();
      return;
    }

    if (_hasNativeLocationDot) {
      _syncPreviewDriftState();
      return;
    }

    if (stage == _LocationStage.precise) {
      // 精确定位只更新真实坐标缓存，不打断当前随机位移链路。
      return;
    }

    if (stage == _LocationStage.native &&
        (_pendingNativeDotReveal || _isSettlingPreviewDot)) {
      return;
    }

    final shouldSettle =
        previousAnchor != null && stage == _LocationStage.native;

    if (shouldSettle) {
      _startPreviewSettle(
        from: _previewMarkerPosition(previousAnchor),
        to: latLng,
        revealNativeAfter: true,
      );
      setState(() {});
      return;
    }

    if (stage == _LocationStage.native) {
      setState(() {
        _hasNativeLocationDot = true;
      });
      _previewCurrentPoint = latLng;
      _syncPreviewDriftState();
      return;
    }

    _syncPreviewDriftState();
    setState(() {});
  }

  Future<void> _focusOnMyLocation() async {
    if (_isCenteringToMyLocation) {
      return;
    }

    if (_mapController == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('地图正在初始化，请稍后重试。')));
      return;
    }

    if (!_locationPermissionStatus.isGranted) {
      await _requestLocationPermission();
      if (!_locationPermissionStatus.isGranted) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _locationPermissionStatus.isPermanentlyDenied
                  ? '定位权限被永久拒绝，请先在系统设置中开启。'
                  : '请先允许定位权限后再定位。',
            ),
          ),
        );
        return;
      }
    }

    final target = await _resolveCoarseUserLocation();
    if (target == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正在获取当前位置，请确认已开启定位后重试。')));
      return;
    }

    _cacheUserLocation(target);

    setState(() {
      // 一旦用户主动点击定位，后续不再自动回退到“全景框选”视角。
      _hasAdjustedInitialViewport = true;
      _isCenteringToMyLocation = true;
    });

    try {
      await _mapController!
          .moveCamera(
            CameraUpdate.newLatLngZoom(target, 15),
            animated: true,
            duration: 300,
          )
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              // 某些机型上 moveCamera Future 可能不返回，超时后自动解锁按钮。
            },
          );

      unawaited(
        _refineUserLocationInBackground(
          coarseAnchor: target,
          recenterOnUpdate: true,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('定位失败，请稍后重试。')));
    } finally {
      if (mounted) {
        setState(() {
          _isCenteringToMyLocation = false;
        });
      }
    }
  }

  Future<_GuideMapAssets> _loadAssets({required Color markerFillColor}) async {
    final locations = await _locationRepository.fetchLocations();
    final scenicMarkerIcon = await _buildScenicMarkerIcon(
      markerFillColor: markerFillColor,
    );
    final userLocationIcon = await _buildUserLocationIcon();
    double? minLatitude;
    double? maxLatitude;
    double? minLongitude;
    double? maxLongitude;

    final markers = locations
        .where((location) => location.coordinates.length >= 2)
        .map<Marker>((location) {
          final longitude = location.coordinates[0];
          final latitude = location.coordinates[1];

          if (minLatitude == null || latitude < minLatitude!) {
            minLatitude = latitude;
          }
          if (maxLatitude == null || latitude > maxLatitude!) {
            maxLatitude = latitude;
          }
          if (minLongitude == null || longitude < minLongitude!) {
            minLongitude = longitude;
          }
          if (maxLongitude == null || longitude > maxLongitude!) {
            maxLongitude = longitude;
          }

          return Marker(
            position: LatLng(latitude, longitude),
            icon: scenicMarkerIcon,
            infoWindowEnable: false,
            anchor: const ui.Offset(0.5, 0.5),
            zIndex: 1,
            onTap: (_) => _showLocationDetails(location),
          );
        })
        .toSet();

    LatLng? focusPoint;
    LatLngBounds? locationBounds;

    if (minLatitude != null &&
        maxLatitude != null &&
        minLongitude != null &&
        maxLongitude != null) {
      final hasSinglePoint =
          minLatitude == maxLatitude && minLongitude == maxLongitude;

      if (hasSinglePoint) {
        focusPoint = LatLng(minLatitude!, minLongitude!);
      } else {
        locationBounds = LatLngBounds(
          southwest: LatLng(minLatitude!, minLongitude!),
          northeast: LatLng(maxLatitude!, maxLongitude!),
        );
      }
    }

    return _GuideMapAssets(
      markers: markers,
      userLocationIcon: userLocationIcon,
      focusPoint: focusPoint,
      locationBounds: locationBounds,
    );
  }

  Future<void> _fitAllLocationsOnMap(_GuideMapAssets? assets) async {
    if (_hasAdjustedInitialViewport ||
        assets == null ||
        _mapController == null) {
      return;
    }

    try {
      if (assets.locationBounds != null) {
        await _mapController!.moveCamera(
          CameraUpdate.newLatLngBounds(assets.locationBounds!, 120),
          animated: false,
        );
        _hasAdjustedInitialViewport = true;
        return;
      }

      if (assets.focusPoint != null) {
        await _mapController!.moveCamera(
          CameraUpdate.newLatLngZoom(assets.focusPoint!, 14),
          animated: false,
        );
        _hasAdjustedInitialViewport = true;
      }
    } catch (_) {
      // 使用默认视角兜底，不中断页面展示。
    }
  }

  Future<BitmapDescriptor> _buildScenicMarkerIcon({
    required Color markerFillColor,
  }) async {
    const int size = 56;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = ui.Offset(size / 2, size / 2);

    final borderPaint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = const ui.Color(0xFFFFFFFF);
    final fillPaint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = markerFillColor;

    canvas.drawCircle(center, 26, borderPaint);
    canvas.drawCircle(center, 18, fillPaint);

    final image = await recorder.endRecording().toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _buildUserLocationIcon() async {
    const int size = 56;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = ui.Offset(size / 2, size / 2);

    final borderPaint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = const ui.Color(0xFFFFFFFF);
    final fillPaint = ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = const ui.Color(0xFF1E88E5);

    canvas.drawCircle(center, 26, borderPaint);
    canvas.drawCircle(center, 18, fillPaint);

    final image = await recorder.endRecording().toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  Set<Marker> _buildMapMarkers({
    required Set<Marker> scenicMarkers,
    required BitmapDescriptor? userLocationIcon,
  }) {
    final previewLatLng = _shouldShowPreviewLocationDot
        ? _latestUserLatLng
        : null;
    if (previewLatLng == null || userLocationIcon == null) {
      return scenicMarkers;
    }

    final markers = Set<Marker>.from(scenicMarkers);
    markers.add(
      Marker(
        position: _previewMarkerPosition(previewLatLng),
        icon: userLocationIcon,
        infoWindowEnable: false,
        clickable: false,
        anchor: const ui.Offset(0.5, 0.5),
        zIndex: 4,
      ),
    );
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GuideMapAssets>(
      future: _assetsFuture,
      builder: (context, snapshot) {
        final assets = snapshot.data;
        final markers = _buildMapMarkers(
          scenicMarkers: assets?.markers ?? const <Marker>{},
          userLocationIcon: assets?.userLocationIcon,
        );
        if (assets != null &&
            _mapController != null &&
            !_hasAdjustedInitialViewport &&
            !_isCenteringToMyLocation) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitAllLocationsOnMap(assets);
          });
        }
        final mapMessage = snapshot.hasError
            ? '地点加载失败：${snapshot.error}'
            : snapshot.connectionState != ConnectionState.done
            ? '正在加载地点...'
            : markers.isEmpty
            ? '当前没有可显示的地点数据。'
            : '导览地图已接入高德地图，可在此继续叠加景点、路线和讲解能力。';
        final permissionMessage = !_locationPermissionChecked
            ? '正在申请定位权限...'
            : _locationPermissionStatus.isGranted
            ? null
            : _locationPermissionStatus.isPermanentlyDenied
            ? '定位权限被永久拒绝，请到系统设置中开启后重试。'
            : '定位权限未开启，无法显示你的位置。';
        final message = permissionMessage ?? mapMessage;

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
              onMapCreated: (controller) {
                _mapController = controller;
                _fitAllLocationsOnMap(assets);
                unawaited(_primeUserLocation());
              },
              onLocationChanged: _handleLocationChanged,
              myLocationStyleOptions: MyLocationStyleOptions(
                _locationPermissionStatus.isGranted,
                icon:
                    assets?.userLocationIcon ?? BitmapDescriptor.defaultMarker,
                circleFillColor: const Color(0x00000000),
                circleStrokeColor: const Color(0x00000000),
                circleStrokeWidth: 0,
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
            if (_locationPermissionChecked &&
                !_locationPermissionStatus.isGranted)
              Positioned(
                right: 16,
                bottom: 88,
                child: FilledButton.icon(
                  onPressed: _locationPermissionStatus.isPermanentlyDenied
                      ? openAppSettings
                      : _requestLocationPermission,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _locationPermissionStatus.isPermanentlyDenied
                        ? '打开设置'
                        : '允许定位',
                  ),
                ),
              ),
            Positioned(
              right: 16,
              bottom: 24,
              child: FloatingActionButton.small(
                heroTag: 'guide_page_locate_me',
                onPressed: _isCenteringToMyLocation ? null : _focusOnMyLocation,
                child: const Icon(Icons.my_location_rounded),
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
  final LatLng? focusPoint;
  final LatLngBounds? locationBounds;

  const _GuideMapAssets({
    required this.markers,
    required this.userLocationIcon,
    required this.focusPoint,
    required this.locationBounds,
  });
}

class _LocationDetailSheet extends StatelessWidget {
  final LocationRecord location;

  const _LocationDetailSheet({required this.location});

  String _displayText(String? value, String fallback) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    return text;
  }

  String _durationText() {
    final minutes = location.averageVisitDurationMin;
    if (minutes == null) {
      return '未提供';
    }
    return '$minutes 分钟';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = location.categories;

    return DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.30,
      initialChildSize: 0.44,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: const [0.44, 0.94],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 14,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        location.nameModern,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _displayText(location.nameAncient, '古称未记录'),
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: Icons.schedule_rounded,
                            text: '平均游玩 ${_durationText()}',
                          ),
                          _InfoPill(
                            icon: Icons.auto_awesome_rounded,
                            text: '主题 ${_displayText(location.topic, '未分类')}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '地点简介',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _displayText(location.description, '暂无简介'),
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.86),
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '分类',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (categories.isEmpty)
                        Text(
                          '未分类',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                            fontSize: 14,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories
                              .map(
                                (category) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.86),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
