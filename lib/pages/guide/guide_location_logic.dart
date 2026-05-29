// ignore_for_file: invalid_use_of_protected_member

part of 'guide_page.dart';

/// ---------- location stage enum ----------

enum _LocationStage { coarse, precise, native }

/// ---------- top-level functions (location / permission logic) ----------

Future<void> _requestLocationPermission(_GuidePageState state) async {
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

Future<LatLng?> _resolveCoarseUserLocation(_GuidePageState state) async {
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

Future<void> _refineUserLocationInBackground(
  _GuidePageState state, {
  LatLng? coarseAnchor,
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
    final preciseLatLng = LatLng(precise.latitude, precise.longitude);
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
      CameraUpdate.newLatLngZoom(preciseLatLng, 16),
      duration: 420,
    );
  } catch (_) {
    // 精定位失败时保留粗定位结果，不影响已完成的相机移动。
  } finally {
    state._isRefiningLocation = false;
  }
}

void _handleLocationChanged(_GuidePageState state, AMapLocation location) {
  _cacheUserLocation(state, location.latLng, stage: _LocationStage.native);
}

void _cacheUserLocation(
  _GuidePageState state,
  LatLng latLng, {
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
    final fromPosition =
        state._previewCurrentPoint ?? previousAnchor ?? latLng;
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

  final shouldSettle =
      previousAnchor != null && stage == _LocationStage.native;

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
        .moveCamera(
          CameraUpdate.newLatLngZoom(target, 15),
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
      await state._mapController!.moveCamera(
        CameraUpdate.newLatLngBounds(assets.locationBounds!, 120),
        animated: false,
      );
      state._hasAdjustedInitialViewport = true;
      return;
    }

    if (assets.focusPoint != null) {
      await state._mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(assets.focusPoint!, 14),
        animated: false,
      );
      state._hasAdjustedInitialViewport = true;
    }
  } catch (_) {
    // 使用默认视角兜底，不中断页面展示。
  }
}
