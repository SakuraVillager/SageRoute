part of 'guide_page.dart';

/// ---------- top-level constants (preview-related) ----------

const double _previewRandomDistanceMeters = 800;
const int _previewDriftMinDurationMs = 1000;
const int _previewDriftMaxDurationMs = 3000;

/// ---------- top-level functions (preview dot animation) ----------

bool _shouldShowPreviewLocationDot(_GuidePageState state) {
  return state._locationPermissionStatus.isGranted &&
      !state._hasNativeLocationDot &&
      state._latestUserLatLng != null;
}

void _syncPreviewDriftState(_GuidePageState state) {
  if (!_shouldShowPreviewLocationDot(state)) {
    if (state._previewDriftController.isAnimating) {
      state._previewDriftController.stop();
    }
    if (state._previewSettleController.isAnimating) {
      state._previewSettleController.stop();
    }
    state._previewDriftFrom = null;
    state._previewDriftTo = null;
    state._previewCurrentPoint = null;
    state._previewSettleFrom = null;
    state._previewSettleTo = null;
    state._pendingNativeDotReveal = false;
    state._freezePreviewDriftAfterSettle = false;
    state._isPreviewDriftEnabled = false;
    return;
  }

  if (state._isSettlingPreviewDot || !state._isPreviewDriftEnabled) {
    if (state._previewDriftController.isAnimating) {
      state._previewDriftController.stop();
    }
    state._previewDriftFrom = null;
    state._previewDriftTo = null;
    return;
  }

  if (!state._previewDriftController.isAnimating ||
      state._previewDriftFrom == null ||
      state._previewDriftTo == null) {
    _startNextPreviewDriftStep(state);
  }
}

LatLng _previewMarkerPosition(_GuidePageState state, LatLng anchor) {
  if (state._isSettlingPreviewDot &&
      state._previewSettleFrom != null &&
      state._previewSettleTo != null) {
    final t = state._previewSettleController.value;
    return LatLng(
      ui.lerpDouble(
        state._previewSettleFrom!.latitude,
        state._previewSettleTo!.latitude,
        t,
      )!,
      ui.lerpDouble(
        state._previewSettleFrom!.longitude,
        state._previewSettleTo!.longitude,
        t,
      )!,
    );
  }

  if (!_shouldShowPreviewLocationDot(state) || !state._isPreviewDriftEnabled) {
    return state._previewCurrentPoint ?? anchor;
  }

  if (state._previewDriftFrom == null || state._previewDriftTo == null) {
    return state._previewCurrentPoint ?? anchor;
  }

  final t = state._previewDriftController.value;
  return LatLng(
    ui.lerpDouble(
      state._previewDriftFrom!.latitude,
      state._previewDriftTo!.latitude,
      t,
    )!,
    ui.lerpDouble(
      state._previewDriftFrom!.longitude,
      state._previewDriftTo!.longitude,
      t,
    )!,
  );
}

LatLng _randomNearbyPoint(
  _GuidePageState state,
  LatLng anchor, {
  double distanceMeters = _previewRandomDistanceMeters,
}) {
  final angle = state._previewRandom.nextDouble() * 2 * math.pi;
  final radius = distanceMeters;
  final latOffset = (radius * math.sin(angle)) / 111320;
  final metersPerLng = (111320 * math.cos(anchor.latitude * math.pi / 180))
      .abs();
  final lngOffset = metersPerLng < 1
      ? 0
      : (radius * math.cos(angle)) / metersPerLng;
  return LatLng(anchor.latitude + latOffset, anchor.longitude + lngOffset);
}

void _startNextPreviewDriftStep(_GuidePageState state) {
  // 下一段始终从"当前游走点"出发，避免回拉到真实定位锚点。
  final anchor = state._previewCurrentPoint ?? state._latestUserLatLng;
  if (anchor == null ||
      !_shouldShowPreviewLocationDot(state) ||
      !state._isPreviewDriftEnabled) {
    return;
  }

  final from = anchor;
  final to = _randomNearbyPoint(state, anchor);
  state._previewDriftFrom = from;
  state._previewDriftTo = to;

  state._previewDriftController.duration = state._nextPreviewDriftDuration();
  state._previewDriftController
    ..stop()
    ..value = 0
    ..forward();
}

void _startPreviewSettle(
  _GuidePageState state, {
  required LatLng from,
  required LatLng to,
  bool revealNativeAfter = false,
  bool freezeDriftAfterSettle = false,
}) {
  state._previewDriftFrom = null;
  state._previewDriftTo = null;
  state._previewSettleFrom = from;
  state._previewSettleTo = to;
  state._pendingNativeDotReveal = revealNativeAfter;
  state._freezePreviewDriftAfterSettle = freezeDriftAfterSettle;
  state._previewCurrentPoint = from;

  state._previewSettleController
    ..stop()
    ..value = 0
    ..forward();

  _syncPreviewDriftState(state);
}
