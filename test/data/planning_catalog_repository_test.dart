import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/dongpo_site_repository.dart';
import 'package:sageroute/data/location_repository.dart';
import 'package:sageroute/data/planning_catalog_repository.dart';
import 'package:sageroute/data/topic_repository.dart';
import 'package:sageroute/models/heritage_grade.dart';
import 'package:sageroute/models/location_record.dart';
import 'package:sageroute/models/saved_route.dart';
import 'package:sageroute/models/topic_record.dart';
import 'package:sageroute/route_planning/data/route_place_repository.dart';
import 'package:sageroute/route_planning/models/route_place.dart';

class LocalDongpoRepository extends DongpoSiteRepository {
  const LocalDongpoRepository();

  @override
  Future<DongpoCatalog> fetchCatalog() => fetchLocalCatalog();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sites =
      (jsonDecode(File('assets/data/dongpo_sites.json').readAsStringSync())
              as List)
          .map(
            (row) =>
                LocationRecord.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
  final metadata =
      (jsonDecode(
                File(
                  'assets/data/dongpo_planning_metadata.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  final old = LocationRecord.fromMap({
    'id': 19,
    'name_modern': '浙江省杭州市西湖区北山路宝石山麓',
    'categories': '亭台楼阁',
    'Topic': '[苏轼·望湖楼与凤凰山]',
    'coordinates': [120.1, 30.2],
    'average_visit_duration_min': 45,
  });

  test(
    '37 records join the new route without ID collisions or losing source content',
    () {
      final catalog = PlanningCatalogRepository.merge(
        [old],
        [],
        sites,
        metadata,
      );
      final route = catalog.locations
          .where((place) => place.topic == dongpoRouteName)
          .toList();
      expect(route, hasLength(37));
      expect(route.map((place) => place.id).toSet(), hasLength(37));
      expect(route.where((place) => place.hasValidCoordinates), hasLength(30));
      final tower = route.singleWhere((place) => place.dongpoSiteId == 17);
      expect(tower.id, old.id);
      expect(tower.nameModern, '望湖楼');
      expect(tower.averageVisitDurationMin, 45);
      expect(tower.categories, ['亭台楼阁']);
      expect(locationTopics(tower), contains('苏轼·望湖楼与凤凰山'));
      expect(tower.themes, contains('自然景观'));
      expect(tower.themes, isNot(contains('自然山水')));
      for (final place in route) {
        final source = sites.singleWhere(
          (site) => site.id == place.dongpoSiteId,
        );
        expect(place.heritageGrade, source.heritageGrade);
        expect(place.historicalEvent, source.historicalEvent);
        expect(place.photos, source.photos);
        expect(place.categories, isNotEmpty);
        expect(LocationRecord.fromMap(place.toMap()), place);
      }
    },
  );

  test(
    'existing equivalent labels are reused and duplicate historical places are updated',
    () {
      final duplicate = old.copyWith(id: 40, nameModern: '杭州西湖北山街望湖楼景区');
      final topic = TopicRecord.fromMap({
        'id': 8,
        'name': '诗词文化',
        'celebrity': '苏轼',
      });
      final catalog = PlanningCatalogRepository.merge(
        [old, duplicate],
        [topic],
        sites,
        metadata,
      );
      final preserved = catalog.locations.singleWhere(
        (place) => place.id == 40,
      );
      expect(preserved.nameModern, duplicate.nameModern);
      expect(preserved.heritageGrade, HeritageGrade.confirmed);
      expect(preserved.themes, contains('诗词文化'));
      expect(
        catalog.locations.expand((place) => place.themes),
        isNot(contains('诗词题咏')),
      );
      expect(
        catalog.locations.where((place) => place.topic == dongpoRouteName),
        hasLength(37),
      );
    },
  );

  test(
    'already imported catalog keys reuse all positive IDs and the existing route',
    () async {
      final imported = sites.map((site) {
        final row = site.toMap()..remove('dongpo_site_id');
        row['id (PK)'] = 100 + site.id;
        row['catalog_key'] =
            'dongpo-hangzhou-${site.id.toString().padLeft(2, '0')}';
        row['Topic'] = null;
        if (site.id == 1) row['route_eligible'] = false;
        return LocationRecord.fromMap(row);
      }).toList();
      final topic = TopicRecord.fromMap({
        'id': 8,
        'name': '苏轼·杭州行迹',
        'celebrity': '苏轼',
      });
      final catalog = PlanningCatalogRepository.merge(
        imported,
        [topic],
        sites,
        metadata,
      );
      expect(catalog.locations, hasLength(37));
      expect(catalog.topics, [topic]);
      for (final place in catalog.locations) {
        expect(place.id, 100 + place.dongpoSiteId!);
        expect(place.topic, topic.name);
      }
      final area = catalog.locations.singleWhere(
        (place) => place.dongpoSiteId == 1,
      );
      expect(area.hasValidCoordinates, isTrue);
      expect(area.canPlanRoute, isFalse);
      expect(LocationRecord.fromMap(area.toMap()).routeEligible, isFalse);
      final topics = TopicRepository(fetcher: () async => [topic]);
      expect(await topics.fetchPlanningTopicsByCelebrity('苏轼'), [topic]);
      final repo = RoutePlaceRepository(
        locationRepository: LocationRepository(fetcher: () async => imported),
        topicRepository: topics,
        dongpoRepository: const LocalDongpoRepository(),
      );
      expect(await repo.fetchPlacesByThemeId(8), hasLength(29));
      expect(await repo.fetchPlacesByThemeId(dongpoRouteId), hasLength(29));
    },
  );

  test(
    'modern names and explicit identities take priority over legacy aliases',
    () {
      final source = sites.singleWhere((site) => site.id == 17);
      final modern = source.copyWith(id: 117);
      final catalog = PlanningCatalogRepository.merge(
        [old, modern],
        [],
        sites,
        metadata,
      );
      final tower = catalog.locations.singleWhere(
        (place) => place.dongpoSiteId == 17,
      );
      expect(tower.id, 117);
      expect(
        catalog.locations
            .singleWhere((place) => place.id == old.id)
            .heritageGrade,
        HeritageGrade.confirmed,
      );
      expect(
        catalog.locations.where((place) => place.topic == dongpoRouteName),
        hasLength(37),
      );
      expect(
        metadata.singleWhere((row) => row['site_id'] == 34)['category'],
        '林野花谷',
      );
      expect(
        metadata.singleWhere((row) => row['site_id'] == 35)['category'],
        '泉池溪涧',
      );
    },
  );

  test(
    'a legacy coordinate does not locate an explicitly unlocated source',
    () {
      final unverified = old.copyWith(id: 37, nameModern: '浙江省杭州市钱塘江（观潮）');
      final catalog = PlanningCatalogRepository.merge(
        [unverified],
        [],
        sites,
        metadata,
      );
      expect(
        catalog.locations
            .singleWhere((place) => place.dongpoSiteId == 10)
            .hasValidCoordinates,
        isFalse,
      );
    },
  );

  test(
    'draft snapshots round trip and persisted waypoints recover grades without invalid FKs',
    () async {
      final catalog = PlanningCatalogRepository.merge([], [], sites, metadata);
      final site = catalog.locations.singleWhere(
        (place) => place.dongpoSiteId == 17,
      );
      final place = RoutePlace.fromLocation(site);
      final draft = RoutePlace.fromJson(place.toJson());
      expect(draft.heritageGrade, HeritageGrade.confirmed);
      expect(draft.details, site);
      final row = RouteWaypoint.fromRoutePlace(
        place,
      ).toMap(routeId: 'route', sortOrder: 0);
      expect(row['location_id'], isNull);
      final reloaded = RouteWaypoint.fromMap(row).toRoutePlace();
      final restored = (await PlanningCatalogRepository.restoreDetails([
        reloaded,
      ])).single;
      expect(restored.heritageGrade, HeritageGrade.confirmed);
      expect(restored.details!.photos, site.photos);
      expect(restored.latitude, reloaded.latitude);
      expect(restored.longitude, reloaded.longitude);
    },
  );

  test(
    'route generation uses only the 30 located records in the new theme',
    () async {
      final repo = RoutePlaceRepository(
        locationRepository: LocationRepository(fetcher: () async => [old]),
        topicRepository: TopicRepository(fetcher: () async => []),
        dongpoRepository: const LocalDongpoRepository(),
      );
      final places = await repo.fetchPlacesByThemeId(dongpoRouteId);
      expect(places, hasLength(30));
      expect(places.every((place) => place.heritageGrade != null), isTrue);
      expect(await repo.fetchPlacesByThemeId(9999), isEmpty);
    },
  );

  test(
    'invalid coordinates and unknown evidence levels stay unrouteable and ungraded',
    () {
      final place = LocationRecord.fromMap({
        'id': 90,
        'heritage_grade': '未知',
        'coordinates': [0, 0],
      });
      expect(place.heritageGrade, isNull);
      expect(() => RoutePlace.fromLocation(place), throwsFormatException);
    },
  );
}
