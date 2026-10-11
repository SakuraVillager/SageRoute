import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/route_planning/amap_gateway.dart';
import 'package:sageroute/route_planning/models/amap_route_types.dart';
import 'package:sageroute/route_planning/models/route_place.dart';
import 'package:sageroute/route_planning/models/transport_type.dart';
import 'package:sageroute/route_planning/route_preview_coordinator.dart';

void main() {
  test('maps every preview state to the intended save action', () {
    expect(
      resolveRouteSaveAction(
        placesCount: 1,
        previewStatus: RoutePreviewStatus.insufficient,
      ),
      RouteSaveAction.disabled,
    );
    expect(
      resolveRouteSaveAction(
        placesCount: 2,
        previewStatus: RoutePreviewStatus.planning,
      ),
      RouteSaveAction.disabled,
    );
    expect(
      resolveRouteSaveAction(
        placesCount: 2,
        previewStatus: RoutePreviewStatus.ready,
      ),
      RouteSaveAction.save,
    );
    expect(
      resolveRouteSaveAction(
        placesCount: 2,
        previewStatus: RoutePreviewStatus.failed,
      ),
      RouteSaveAction.confirmFailure,
    );
  });

  test('debounces edits and plans only the latest place order', () async {
    final gateway = _ImmediateGateway();
    final coordinator = RoutePreviewCoordinator(
      gateway: gateway,
      debounce: const Duration(milliseconds: 15),
    );
    final snapshots = <RoutePreviewSnapshot>[];
    final first = [_place(1), _place(2), _place(3)];
    final reordered = [_place(3), _place(1), _place(2)];

    coordinator.schedule(
      places: first,
      transportTypes: const [TransportType.driving, TransportType.driving],
      onChanged: snapshots.add,
    );
    coordinator.schedule(
      places: reordered,
      transportTypes: const [TransportType.walking, TransportType.driving],
      onChanged: snapshots.add,
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(gateway.requests, hasLength(2));
    expect(gateway.requests.first.transportType, TransportType.walking);
    expect(gateway.requests.last.transportType, TransportType.driving);
    expect(gateway.requests.first.origin.id, 3);
    expect(gateway.requests.first.destination.id, 1);
    expect(gateway.requests.last.origin.id, 1);
    expect(gateway.requests.last.destination.id, 2);
    expect(snapshots.last.status, RoutePreviewStatus.ready);
    expect(snapshots.last.segments, hasLength(2));
    expect(snapshots.last.distanceMeters, 2400);
    expect(snapshots.last.travelDuration, const Duration(minutes: 36));
    coordinator.dispose();
  });

  test('ignores a stale in-flight result after a newer request', () async {
    final gateway = _DeferredGateway();
    final coordinator = RoutePreviewCoordinator(
      gateway: gateway,
      debounce: Duration.zero,
    );
    final snapshots = <RoutePreviewSnapshot>[];

    coordinator.schedule(
      places: [_place(1), _place(2)],
      transportTypes: const [TransportType.driving],
      onChanged: snapshots.add,
    );
    await _waitFor(() => gateway.requests.length == 1);

    coordinator.schedule(
      places: [_place(3), _place(4)],
      transportTypes: const [TransportType.walking],
      onChanged: snapshots.add,
    );
    await _waitFor(() => gateway.requests.length == 2);

    gateway.complete(1);
    await _waitFor(() => snapshots.last.status == RoutePreviewStatus.ready);
    final latestPolyline = snapshots.last.polyline;
    gateway.complete(0);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(snapshots.last.polyline, latestPolyline);
    expect(latestPolyline.first, [_place(3).latitude, _place(3).longitude]);
    coordinator.dispose();
  });

  test(
    'reports route failures without discarding the selected places',
    () async {
      final coordinator = RoutePreviewCoordinator(
        gateway: _FailingGateway(),
        debounce: Duration.zero,
      );
      final snapshots = <RoutePreviewSnapshot>[];

      coordinator.schedule(
        places: [_place(1), _place(2)],
        transportTypes: const [TransportType.driving],
        onChanged: snapshots.add,
      );
      await _waitFor(() => snapshots.last.status == RoutePreviewStatus.failed);

      expect(snapshots.last.error, contains('路径规划失败'));
      expect(snapshots.last.polyline, isEmpty);
      coordinator.dispose();
    },
  );
}

RoutePlace _place(int id) => RoutePlace(
  id: id,
  name: '地点$id',
  latitude: 30 + id / 100,
  longitude: 120 + id / 100,
  averageVisitDurationMin: 30,
  topic: null,
  categories: null,
);

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for asynchronous route preview state');
}

class _ImmediateGateway implements AmapGateway {
  final requests = <AmapRouteDraftRequest>[];

  @override
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request) async {
    requests.add(request);
    return _resultFor(request);
  }
}

class _DeferredGateway implements AmapGateway {
  final requests = <AmapRouteDraftRequest>[];
  final _completers = <Completer<AmapRouteResult>>[];

  @override
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request) {
    requests.add(request);
    final completer = Completer<AmapRouteResult>();
    _completers.add(completer);
    return completer.future;
  }

  void complete(int index) {
    _completers[index].complete(_resultFor(requests[index]));
  }
}

class _FailingGateway implements AmapGateway {
  @override
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request) {
    return Future<AmapRouteResult>.error(StateError('network unavailable'));
  }
}

AmapRouteResult _resultFor(AmapRouteDraftRequest request) {
  final ordered = [request.origin, ...request.waypoints, request.destination];
  return AmapRouteResult(
    distanceMeters: 1200,
    travelDuration: const Duration(minutes: 18),
    polyline: [
      for (final place in ordered) <double>[place.latitude, place.longitude],
    ],
    waypointOrder: null,
  );
}
