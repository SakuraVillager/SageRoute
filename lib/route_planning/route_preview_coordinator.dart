import 'dart:async';

import 'amap_gateway.dart';
import 'models/route_place.dart';
import 'models/transport_type.dart';
import 'multi_stop_route_planner.dart';

enum RoutePreviewStatus { insufficient, planning, ready, failed }

enum RouteSaveAction { disabled, save, confirmFailure }

RouteSaveAction resolveRouteSaveAction({
  required int placesCount,
  required RoutePreviewStatus previewStatus,
}) {
  if (placesCount < 2 ||
      previewStatus == RoutePreviewStatus.insufficient ||
      previewStatus == RoutePreviewStatus.planning) {
    return RouteSaveAction.disabled;
  }
  if (previewStatus == RoutePreviewStatus.failed) {
    return RouteSaveAction.confirmFailure;
  }
  return RouteSaveAction.save;
}

class RoutePreviewSnapshot {
  const RoutePreviewSnapshot({
    required this.status,
    this.polyline = const <List<double>>[],
    this.distanceMeters,
    this.travelDuration,
    this.segments = const <RouteSegmentPreview>[],
    this.error,
    this.diagnostics,
  });

  final RoutePreviewStatus status;
  final List<List<double>> polyline;
  final int? distanceMeters;
  final Duration? travelDuration;
  final List<RouteSegmentPreview> segments;
  final String? error;
  final String? diagnostics;
}

class RouteSegmentPreview {
  const RouteSegmentPreview({
    required this.index,
    required this.transportType,
    required this.distanceMeters,
    required this.travelDuration,
    required this.polyline,
  });

  final int index;
  final TransportType transportType;
  final int distanceMeters;
  final Duration travelDuration;
  final List<List<double>> polyline;
}

typedef RoutePreviewListener = void Function(RoutePreviewSnapshot value);

class RoutePreviewCoordinator {
  RoutePreviewCoordinator({
    required AmapGateway gateway,
    this.debounce = const Duration(milliseconds: 240),
  }) : _planner = MultiStopRoutePlanner(gateway: gateway);

  final MultiStopRoutePlanner _planner;
  final Duration debounce;
  Timer? _timer;
  int _generation = 0;

  void schedule({
    required List<RoutePlace> places,
    required List<TransportType> transportTypes,
    required RoutePreviewListener onChanged,
  }) {
    final generation = ++_generation;
    _timer?.cancel();
    final selected = List<RoutePlace>.unmodifiable(places);

    if (selected.length < 2) {
      onChanged(
        const RoutePreviewSnapshot(status: RoutePreviewStatus.insufficient),
      );
      return;
    }
    if (transportTypes.length != selected.length - 1) {
      throw ArgumentError(
        'transportTypes must contain one value for every route segment',
      );
    }
    final selectedTransportTypes = List<TransportType>.unmodifiable(
      transportTypes,
    );

    onChanged(const RoutePreviewSnapshot(status: RoutePreviewStatus.planning));
    _timer = Timer(
      debounce,
      () => _compute(
        generation: generation,
        places: selected,
        transportTypes: selectedTransportTypes,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _compute({
    required int generation,
    required List<RoutePlace> places,
    required List<TransportType> transportTypes,
    required RoutePreviewListener onChanged,
  }) async {
    try {
      final segments = <RouteSegmentPreview>[];
      final mergedPolyline = <List<double>>[];
      var totalDistanceMeters = 0;
      var totalTravelDuration = Duration.zero;

      for (var index = 0; index < places.length - 1; index++) {
        final result = await _planner.plan(
          places: <RoutePlace>[places[index], places[index + 1]],
          transportType: transportTypes[index],
          preferenceKey: 'shortest',
        );
        if (generation != _generation) return;
        final clean = result.polyline
            .where(
              (point) =>
                  point.length >= 2 && point[0].isFinite && point[1].isFinite,
            )
            .map((point) => <double>[point[0], point[1]])
            .toList(growable: false);
        if (clean.length < 2) {
          throw StateError('第 ${index + 1} 段暂未获取到可渲染的路线');
        }
        final segment = RouteSegmentPreview(
          index: index,
          transportType: transportTypes[index],
          distanceMeters: result.distanceMeters,
          travelDuration: result.travelDuration,
          polyline: clean,
        );
        segments.add(segment);
        totalDistanceMeters += result.distanceMeters;
        totalTravelDuration += result.travelDuration;
        _appendPolyline(mergedPolyline, clean);
      }

      onChanged(
        RoutePreviewSnapshot(
          status: RoutePreviewStatus.ready,
          polyline: mergedPolyline,
          distanceMeters: totalDistanceMeters,
          travelDuration: totalTravelDuration,
          segments: List<RouteSegmentPreview>.unmodifiable(segments),
        ),
      );
    } catch (error) {
      if (generation != _generation) return;
      onChanged(
        RoutePreviewSnapshot(
          status: RoutePreviewStatus.failed,
          error: '路径规划失败：$error',
        ),
      );
    }
  }

  void _appendPolyline(List<List<double>> target, List<List<double>> segment) {
    for (final point in segment) {
      if (target.isNotEmpty && _samePoint(target.last, point)) continue;
      target.add(point);
    }
  }

  bool _samePoint(List<double> first, List<double> second) =>
      (first[0] - second[0]).abs() < 0.0000001 &&
      (first[1] - second[1]).abs() < 0.0000001;

  void dispose() {
    _generation++;
    _timer?.cancel();
  }
}
