import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/route_planning/deterministic_amap_gateway.dart';
import 'package:sageroute/route_planning/models/route_place.dart';
import 'package:sageroute/route_planning/models/route_plan_command.dart';
import 'package:sageroute/route_planning/models/route_plan_constraints.dart';
import 'package:sageroute/route_planning/models/route_preference_type.dart';
import 'package:sageroute/route_planning/models/transport_type.dart';
import 'package:sageroute/route_planning/route_planning_engine.dart';

void main() {
  test('keeps every explicitly selected place in the user order', () async {
    final places = <RoutePlace>[
      _place(1, 30.0, 120.0),
      // Deliberately far outside the old five-kilometre corridor.
      _place(2, 31.0, 121.0),
      _place(3, 30.1, 120.1),
    ];
    const engine = RoutePlanningEngine(gateway: DeterministicAmapGateway());

    final bundle = await engine.plan(
      RoutePlanCommand(
        theme: null,
        places: places,
        constraints: const RoutePlanConstraints(
          minPlaces: 2,
          maxPlaces: 3,
          transportType: TransportType.driving,
        ),
        preferences: const [RoutePreferenceType.shortest],
      ),
    );

    final route = bundle.routes.single;
    expect(route.orderedPlaces.map((place) => place.id), [1, 2, 3]);
    expect(route.stats.placesCount, 3);
    expect(route.polyline, hasLength(3));
  });
}

RoutePlace _place(int id, double latitude, double longitude) => RoutePlace(
  id: id,
  name: '地点$id',
  latitude: latitude,
  longitude: longitude,
  averageVisitDurationMin: null,
  topic: null,
  categories: null,
);
