import 'package:flutter/foundation.dart';

import '../../data/location_repository.dart';
import '../../data/planning_catalog_repository.dart';
import '../../data/dongpo_site_repository.dart';
import '../../data/topic_repository.dart';
import '../../models/location_record.dart';
import '../models/route_place.dart';

class RoutePlaceRepository {
  const RoutePlaceRepository({
    TopicRepository? topicRepository,
    LocationRepository? locationRepository,
    this.dongpoRepository = const DongpoSiteRepository(),
  }) : _topicRepository = topicRepository ?? const TopicRepository(),
       _locationRepository = locationRepository ?? const LocationRepository();

  final TopicRepository _topicRepository;
  final LocationRepository _locationRepository;
  final DongpoSiteRepository dongpoRepository;

  Future<List<RoutePlace>> fetchPlacesByThemeId(int? themeId) async {
    List<LocationRecord> locations;
    try {
      final catalog = await PlanningCatalogRepository(
        locations: _locationRepository,
        topics: _topicRepository,
        dongpo: dongpoRepository,
      ).fetchCatalog();
      final themes = catalog.topics.where(
        (topic) =>
            topic.id == themeId ||
            (themeId == dongpoRouteId && isDongpoRouteName(topic.name)),
      );
      locations = themeId == null
          ? catalog.locations
          : themes.isEmpty
          ? const []
          : catalog.locations
                .where(
                  (location) =>
                      locationTopics(location).contains(themes.first.name),
                )
                .toList();
    } catch (error, stackTrace) {
      debugPrint('fetchPlacesByThemeId: 查询失败 themeId=$themeId, error=$error');
      debugPrint('fetchPlacesByThemeId: 异常堆栈:\n$stackTrace');
      return const <RoutePlace>[];
    }

    final cleaned = locations
        .where((location) => location.canPlanRoute)
        .map(RoutePlace.fromLocation)
        .toList(growable: false);

    debugPrint(
      'fetchPlacesByThemeId: themeId=$themeId, 原始${locations.length}个, 有效坐标${cleaned.length}个',
    );

    cleaned.sort((left, right) {
      final leftDuration = left.averageVisitDurationMin ?? 0;
      final rightDuration = right.averageVisitDurationMin ?? 0;
      final durationCompare = rightDuration.compareTo(leftDuration);
      if (durationCompare != 0) {
        return durationCompare;
      }
      return left.name.compareTo(right.name);
    });

    return cleaned;
  }
}
