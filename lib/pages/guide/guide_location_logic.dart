// ignore_for_file: invalid_use_of_protected_member

part of 'guide_page.dart';

/// ---------- location stage enum ----------

enum _LocationStage { coarse, precise, native }

/// ---------- top-level functions (location / permission logic) ----------

Future<void> _requestLocationPermission(_GuidePageState state) async {
  if (kIsWeb) {
    await _focusOnMyLocation(state);
    return;
  }
  var status = await Permission.locationWhenInUse.status;
  if (!status.isGranted) {
    status = await Permission.locationWhenInUse.request();
  }

  if (!state.mounted) {
    return;
  }

  state.setState(() {
    state._locationPermissionStatus = status;
    state._locationPermissionChecked = true;
  });
  _syncPreviewDriftState(state);

  if (status.isGranted) {
    unawaited(_primeUserLocation(state));
  }
}

Future<void> _primeUserLocation(
  _GuidePageState state, {
  bool force = false,
}) async {
  if (kIsWeb) return;
  if (!state._locationPermissionStatus.isGranted || state._isPrimingLocation) {
    return;
  }

  if (!force && state._latestUserLatLng != null) {
    return;
  }

  state._isPrimingLocation = true;
  try {
    final coarseTarget = await _resolveCoarseUserLocation(state);
    if (coarseTarget != null) {
      _cacheUserLocation(state, coarseTarget);
    }

    unawaited(_refineUserLocationInBackground(state));
  } finally {
    state._isPrimingLocation = false;
  }
}

Future<MapCoordinate?> _resolveCoarseUserLocation(_GuidePageState state) async {
  if (state._latestUserLatLng != null) {
    return state._latestUserLatLng;
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
      return MapCoordinate(lastKnown.latitude, lastKnown.longitude);
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
    return MapCoordinate(coarse.latitude, coarse.longitude);
  } catch (_) {
    return null;
  }
}

Future<void> _refineUserLocationInBackground(
  _GuidePageState state, {
  MapCoordinate? coarseAnchor,
  bool recenterOnUpdate = false,
}) async {
  if (!state._locationPermissionStatus.isGranted || state._isRefiningLocation) {
    return;
  }

  state._isRefiningLocation = true;
  try {
    final precise = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
    final preciseLatLng = MapCoordinate(precise.latitude, precise.longitude);
    _cacheUserLocation(state, preciseLatLng, stage: _LocationStage.precise);

    if (!recenterOnUpdate || coarseAnchor == null) {
      return;
    }
    if (!state.mounted || state._mapController == null) {
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

    await state._mapController!.moveCamera(
      MapCameraUpdate.newLatLngZoom(preciseLatLng, 16),
      duration: 420,
    );
  } catch (_) {
    // 精定位失败时保留粗定位结果，不影响已完成的相机移动。
  } finally {
    state._isRefiningLocation = false;
  }
}

void _handleLocationChanged(_GuidePageState state, MapUserLocation location) {
  _cacheUserLocation(state, location.latLng, stage: _LocationStage.native);
}

void _cacheUserLocation(
  _GuidePageState state,
  MapCoordinate latLng, {
  _LocationStage stage = _LocationStage.coarse,
}) {
  final previousAnchor = state._latestUserLatLng;
  state._latestUserLatLng = latLng;

  if (stage == _LocationStage.coarse) {
    state._isPreviewDriftEnabled = true;
    state._previewCurrentPoint ??= latLng;
  }

  if (!state.mounted) {
    _syncPreviewDriftState(state);
    return;
  }

  if (state._hasNativeLocationDot) {
    _syncPreviewDriftState(state);
    return;
  }

  if (stage == _LocationStage.precise) {
    // 精确定位成功后，立即将标记从当前漂移位置平滑拉回到真实位置，并停止后续漂移。
    final fromPosition = state._previewCurrentPoint ?? previousAnchor ?? latLng;
    _startPreviewSettle(
      state,
      from: fromPosition,
      to: latLng,
      freezeDriftAfterSettle: true,
    );
    state.setState(() {});
    return;
  }

  if (stage == _LocationStage.native &&
      (state._pendingNativeDotReveal || state._isSettlingPreviewDot)) {
    return;
  }

  final shouldSettle = previousAnchor != null && stage == _LocationStage.native;

  if (shouldSettle) {
    _startPreviewSettle(
      state,
      from: _previewMarkerPosition(state, previousAnchor),
      to: latLng,
      revealNativeAfter: true,
    );
    state.setState(() {});
    return;
  }

  if (stage == _LocationStage.native) {
    state.setState(() {
      state._hasNativeLocationDot = true;
    });
    state._previewCurrentPoint = latLng;
    _syncPreviewDriftState(state);
    return;
  }

  _syncPreviewDriftState(state);
  state.setState(() {});
}

Future<void> _focusOnMyLocation(_GuidePageState state) async {
  if (state._isCenteringToMyLocation) {
    return;
  }

  if (state._mapController == null) {
    if (!state.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      state.context,
    ).showSnackBar(const SnackBar(content: Text('地图正在初始化，请稍后重试。')));
    return;
  }

  if (kIsWeb) {
    state.setState(() => state._isCenteringToMyLocation = true);
    final result = await LocationService.locate();
    if (!state.mounted) return;
    state.setState(() {
      state._isCenteringToMyLocation = false;
      state._locationPermissionChecked = true;
      state._locationPermissionStatus = result.status == LocationStatus.ready
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    });
    final coordinate = result.coordinate;
    if (coordinate != null) {
      _cacheUserLocation(state, coordinate, stage: _LocationStage.native);
      await state._mapController!.moveCamera(
        MapCameraUpdate.newLatLngZoom(coordinate, 15),
      );
    } else {
      ScaffoldMessenger.of(
        state.context,
      ).showSnackBar(SnackBar(content: Text(result.message ?? '定位失败，请重试')));
    }
    return;
  }
  if (!state._locationPermissionStatus.isGranted) {
    await _requestLocationPermission(state);
    if (!state._locationPermissionStatus.isGranted) {
      if (!state.mounted) {
        return;
      }
      ScaffoldMessenger.of(state.context).showSnackBar(
        SnackBar(
          content: Text(
            state._locationPermissionStatus.isPermanentlyDenied
                ? '定位权限被永久拒绝，请先在系统设置中开启。'
                : '请先允许定位权限后再定位。',
          ),
        ),
      );
      return;
    }
  }

  final target = await _resolveCoarseUserLocation(state);
  if (target == null) {
    if (!state.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      state.context,
    ).showSnackBar(const SnackBar(content: Text('正在获取当前位置，请确认已开启定位后重试。')));
    return;
  }

  _cacheUserLocation(state, target);

  state.setState(() {
    // 一旦用户主动点击定位，后续不再自动回退到"全景框选"视角。
    state._hasAdjustedInitialViewport = true;
    state._isCenteringToMyLocation = true;
  });

  try {
    await state._mapController!
        .moveCamera(MapCameraUpdate.newLatLngZoom(target, 15))
        .timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            // 某些机型上 moveCamera Future 可能不返回，超时后自动解锁按钮。
          },
        );

    unawaited(
      _refineUserLocationInBackground(
        state,
        coarseAnchor: target,
        recenterOnUpdate: true,
      ),
    );
  } catch (_) {
    if (!state.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      state.context,
    ).showSnackBar(const SnackBar(content: Text('定位失败，请稍后重试。')));
  } finally {
    if (state.mounted) {
      state.setState(() {
        state._isCenteringToMyLocation = false;
      });
    }
  }
}

Future<void> _fitAllLocationsOnMap(
  _GuidePageState state,
  _GuideMapAssets? assets,
) async {
  if (state._hasAdjustedInitialViewport ||
      assets == null ||
      state._mapController == null) {
    return;
  }

  try {
    if (assets.locationBounds != null) {
      final camera = _catalogCamera(state.context, assets);
      await state._mapController!.moveCamera(
        MapCameraUpdate.newLatLngZoom(camera.target, camera.zoom),
        animated: false,
      );
      state._hasAdjustedInitialViewport = true;
      return;
    }

    if (assets.focusPoint != null) {
      await state._mapController!.moveCamera(
        MapCameraUpdate.newLatLngZoom(assets.focusPoint!, 14),
        animated: false,
      );
      state._hasAdjustedInitialViewport = true;
    }
  } catch (_) {
    // 使用默认视角兜底，不中断页面展示。
  }
}

MapCameraPosition _catalogCamera(
  BuildContext context,
  _GuideMapAssets? assets,
) {
  final bounds = assets?.locationBounds;
  if (bounds == null) {
    return MapCameraPosition(
      target: assets?.focusPoint ?? const MapCoordinate(30.25, 120.14),
    );
  }
  final center = MapCoordinate(
    (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
    (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
  );
  // Keep the compact map useful: fit both geographic spans with an
  // explicit center, avoiding SDK-dependent setBounds padding behavior.
  final size = MediaQuery.sizeOf(context);
  final desktop = kIsWeb && size.width >= 1024;
  final width = desktop ? size.width - 380 : size.width;
  final height = desktop ? size.height - 100 : 220.0;
  final lonSpan = (bounds.northeast.longitude - bounds.southwest.longitude)
      .abs();
  final latSpan = (bounds.northeast.latitude - bounds.southwest.latitude).abs();
  final lonZoom =
      math.log(
        (width - 64).clamp(100, double.infinity) * 360 / (256 * lonSpan),
      ) /
      math.ln2;
  final latZoom =
      math.log(
        (height - 64).clamp(100, double.infinity) *
            360 *
            math.cos(center.latitude * math.pi / 180) /
            (256 * latSpan),
      ) /
      math.ln2;
  return MapCameraPosition(
    target: center,
    zoom: math.min(lonZoom, latZoom).clamp(3, 15),
  );
}
