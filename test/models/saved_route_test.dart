import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/location_record.dart';
import 'package:sageroute/models/saved_route.dart';
import 'package:sageroute/route_planning/models/route_place.dart';
import 'package:sageroute/route_planning/models/transport_type.dart';

void main() {
  group('RouteWaypoint', () {
    test('saves the live Location primary key through the picker model', () {
      final location = LocationRecord.fromMap(const {
        'id (PK)': 76,
        'name_modern': '苏堤',
        'coordinates': [120.13, 30.21],
      });

      final row = RouteWaypoint.fromRoutePlace(
        RoutePlace.fromLocation(location),
      ).toMap(routeId: 'route-1', sortOrder: 0);

      expect(row['location_id'], 76);
    });

    test('fromRoutePlace keeps coordinates and meta', () {
      const place = RoutePlace(
        id: 7,
        name: '白堤',
        latitude: 30.258,
        longitude: 120.147,
        averageVisitDurationMin: 45,
        topic: '西湖',
        categories: '自然景观',
      );

      final waypoint = RouteWaypoint.fromRoutePlace(
        place,
        transportToNext: TransportType.walking,
      );

      expect(waypoint.name, '白堤');
      expect(waypoint.latitude, 30.258);
      expect(waypoint.longitude, 120.147);
      expect(waypoint.locationId, 7);
      expect(waypoint.visitDurationMin, 45);
      expect(waypoint.categories, '自然景观');
      expect(waypoint.transportToNext, TransportType.walking);
    });

    test('does not persist an unknown catalog ID as a foreign key', () {
      const place = RoutePlace(
        id: 0,
        name: '自定义地点',
        latitude: 30.2,
        longitude: 120.1,
        averageVisitDurationMin: null,
        topic: null,
        categories: null,
      );

      final row = RouteWaypoint.fromRoutePlace(
        place,
      ).toMap(routeId: 'route-1', sortOrder: 0);

      expect(row['location_id'], isNull);
      expect(row['name'], '自定义地点');
      expect(row['latitude'], 30.2);
    });

    test('map round-trip preserves all fields', () {
      const original = RouteWaypoint(
        name: '苏堤',
        latitude: 30.21,
        longitude: 120.13,
        locationId: 9,
        visitDurationMin: 60,
        categories: '园林, 古迹',
        transportToNext: TransportType.driving,
      );

      final restored = RouteWaypoint.fromMap(
        original.toMap(routeId: 'r-1', sortOrder: 2),
      );

      expect(restored.name, original.name);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.locationId, original.locationId);
      expect(restored.visitDurationMin, original.visitDurationMin);
      expect(restored.categories, original.categories);
      expect(restored.transportToNext, original.transportToNext);
    });

    test('map round-trip tolerates missing optional fields', () {
      const original = RouteWaypoint(
        name: '断桥',
        latitude: 30.26,
        longitude: 120.15,
      );

      final restored = RouteWaypoint.fromMap(
        original.toMap(routeId: 'r-1', sortOrder: 0),
      );

      expect(restored.name, '断桥');
      expect(restored.locationId, isNull);
      expect(restored.visitDurationMin, isNull);
      expect(restored.transportToNext, isNull);
      expect(
        original
            .toMap(routeId: 'r-1', sortOrder: 0)
            .containsKey('transport_to_next'),
        isFalse,
      );
    });

    test('toRoutePlace restores a usable planning place', () {
      const waypoint = RouteWaypoint(
        name: '灵隐寺',
        latitude: 30.24,
        longitude: 120.1,
        locationId: 3,
        visitDurationMin: 90,
        categories: '寺庙',
      );

      final place = waypoint.toRoutePlace();

      expect(place.id, 3);
      expect(place.name, '灵隐寺');
      expect(place.latitude, 30.24);
      expect(place.longitude, 120.1);
      expect(place.averageVisitDurationMin, 90);
      expect(place.categories, '寺庙');
    });
  });

  group('SavedRoute', () {
    test('fromMap reads snake_case columns and attaches waypoints', () {
      const waypoint = RouteWaypoint(
        name: '白堤',
        latitude: 30.258,
        longitude: 120.147,
      );
      final route = SavedRoute.fromMap(
        const <String, dynamic>{
          'id': 'route-1',
          'title': '白居易的杭州之旅',
          'date_range': '2026.06.15 — 2026.06.18',
          'duration': '4天3晚',
          'distance': '12.5km',
          'figure_id': 5,
          'figure_name': '白居易',
        },
        waypoints: const [waypoint],
      );

      expect(route.id, 'route-1');
      expect(route.title, '白居易的杭州之旅');
      expect(route.dateRange, '2026.06.15 — 2026.06.18');
      expect(route.duration, '4天3晚');
      expect(route.distance, '12.5km');
      expect(route.figureId, 5);
      expect(route.figureName, '白居易');
      expect(route.waypoints, hasLength(1));
      expect(route.waypoints.single.name, '白堤');
    });

    test('toMap emits user-owned row without id', () {
      const route = SavedRoute(
        id: 'ignored',
        title: '苏轼杭州诗意行',
        dateRange: '2026.07.01',
        duration: '1天0晚',
        distance: '3.2km',
        waypoints: <RouteWaypoint>[],
      );

      final row = route.toMap(userId: 'user-1');

      expect(row['user_id'], 'user-1');
      expect(row.containsKey('id'), isFalse);
      expect(row['title'], '苏轼杭州诗意行');
      expect(row['figure_id'], isNull);
    });

    test('copyWith overrides id and waypoints only', () {
      const route = SavedRoute(
        id: 'old-id',
        title: '标题',
        dateRange: 'd',
        duration: 'dur',
        distance: 'dist',
        figureId: 1,
        figureName: '人物',
        waypoints: <RouteWaypoint>[],
      );

      final updated = route.copyWith(
        id: 'new-id',
        waypoints: const [
          RouteWaypoint(name: '新地点', latitude: 1, longitude: 2),
        ],
      );

      expect(updated.id, 'new-id');
      expect(updated.title, '标题');
      expect(updated.figureName, '人物');
      expect(updated.waypoints.single.name, '新地点');
    });
  });
}
