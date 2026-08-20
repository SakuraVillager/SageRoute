import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/route_planning/amap_gateway.dart';
import 'package:sageroute/route_planning/models/amap_route_types.dart';
import 'package:sageroute/route_planning/models/route_place.dart';
import 'package:sageroute/route_planning/models/transport_type.dart';
import 'package:sageroute/route_planning/multi_stop_route_planner.dart';

void main() {
  group('MultiStopRoutePlanner', () {
    test(
      'splits walking into adjacent pairs and merges every segment',
      () async {
        final gateway = _RecordingGateway();
        final places = [_place(1), _place(2), _place(3)];

        final result = await MultiStopRoutePlanner(gateway: gateway).plan(
          places: places,
          transportType: TransportType.walking,
          preferenceKey: 'shortest',
        );

        expect(gateway.requests, hasLength(2));
        expect(gateway.requests[0].origin.id, 1);
        expect(gateway.requests[0].destination.id, 2);
        expect(gateway.requests[1].origin.id, 2);
        expect(gateway.requests[1].destination.id, 3);
        expect(
          gateway.requests.every((request) => request.waypoints.isEmpty),
          isTrue,
        );
        expect(result.polyline, hasLength(3));
        expect(result.distanceMeters, 2000);
      },
    );

    test('splits nine driving places without dropping a leg', () async {
      final gateway = _RecordingGateway();
      final places = [for (var id = 1; id <= 9; id++) _place(id)];

      final result = await MultiStopRoutePlanner(gateway: gateway).plan(
        places: places,
        transportType: TransportType.driving,
        preferenceKey: 'shortest',
      );

      expect(gateway.requests, hasLength(2));
      expect(gateway.requests[0].origin.id, 1);
      expect(gateway.requests[0].destination.id, 8);
      expect(gateway.requests[0].waypoints.map((place) => place.id), [
        2,
        3,
        4,
        5,
        6,
        7,
      ]);
      expect(gateway.requests[1].origin.id, 8);
      expect(gateway.requests[1].destination.id, 9);
      expect(result.polyline, hasLength(9));
      expect(
        result.polyline.map((point) => point[1]),
        places.map((place) => place.longitude),
      );
    });

    test('rejects a missing coordinate before calling AMap', () async {
      final gateway = _RecordingGateway();
      final places = [_place(1), _place(2, latitude: 0, longitude: 0)];

      await expectLater(
        MultiStopRoutePlanner(gateway: gateway).plan(
          places: places,
          transportType: TransportType.driving,
          preferenceKey: 'shortest',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(gateway.requests, isEmpty);
    });
  });
}

RoutePlace _place(int id, {double? latitude, double? longitude}) => RoutePlace(
  id: id,
  name: '地点$id',
  latitude: latitude ?? 30 + id / 100,
  longitude: longitude ?? 120 + id / 100,
  averageVisitDurationMin: 30,
  topic: null,
  categories: null,
);

class _RecordingGateway implements AmapGateway {
  final requests = <AmapRouteDraftRequest>[];

  @override
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request) async {
    requests.add(request);
    final places = <RoutePlace>[
      request.origin,
      ...request.waypoints,
      request.destination,
    ];
    return AmapRouteResult(
      distanceMeters: (places.length - 1) * 1000,
      travelDuration: Duration(minutes: (places.length - 1) * 10),
      polyline: [
        for (final place in places) <double>[place.latitude, place.longitude],
      ],
      waypointOrder: null,
    );
  }
}
