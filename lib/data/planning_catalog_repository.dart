import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/location_record.dart';
import '../models/topic_record.dart';
import '../models/planning_topic.dart';
import '../route_planning/models/route_place.dart';
import 'dongpo_site_repository.dart';
import 'location_repository.dart';
import 'topic_repository.dart';

export '../models/planning_topic.dart';

Set<String> locationTopics(LocationRecord location) => {
  ...parseTopicLabels(location.topic),
  ...location.themes,
};

Set<String> parseTopicLabels(String? value) => (value ?? '')
    .replaceAll(RegExp(r'[\[\]【】]'), '')
    .split(RegExp(r'[。,.，、;；\s]+'))
    .map((label) => label.trim())
    .where((label) => label.isNotEmpty)
    .toSet();

class PlanningCatalog {
  const PlanningCatalog({
    required this.locations,
    required this.topics,
    this.isLocalCopy = false,
  });

  final List<LocationRecord> locations;
  final List<TopicRecord> topics;
  final bool isLocalCopy;
}

/// Composes the editorial catalog with existing places without copying their
/// IDs into the Location namespace. A negative ID is a catalog-only place;
/// saved routes persist its name/coordinates rather than an invalid FK.
class PlanningCatalogRepository {
  const PlanningCatalogRepository({
    this.locations = const LocationRepository(),
    this.topics = const TopicRepository(),
    this.dongpo = const DongpoSiteRepository(),
  });

  final LocationRepository locations;
  final TopicRepository topics;
  final DongpoSiteRepository dongpo;

  Future<PlanningCatalog> fetchCatalog() async {
    final existingFuture = locations.fetchLocations().timeout(
      const Duration(seconds: 8),
    );
    final topicsFuture = topics.fetchTopics().timeout(
      const Duration(seconds: 8),
    );
    final catalogFuture = dongpo.fetchCatalog();
    final metadataFuture = rootBundle.loadString(
      'assets/data/dongpo_planning_metadata.json',
    );
    // Register handlers immediately so independent failures never escape as
    // unhandled errors while the other sources are loading.
    var local = false;
    final results = await Future.wait<Object>([
      existingFuture.catchError((Object _) {
        local = true;
        return <LocationRecord>[];
      }),
      topicsFuture.catchError((Object _) {
        local = true;
        return <TopicRecord>[];
      }),
      catalogFuture,
      metadataFuture,
    ]);
    final catalog = results[2] as DongpoCatalog;
    return merge(
      results[0] as List<LocationRecord>,
      results[1] as List<TopicRecord>,
      catalog.sites,
      (jsonDecode(results[3] as String) as List).cast<Map<String, dynamic>>(),
      isLocalCopy: local || catalog.isLocalCopy,
    );
  }

  /// Saved waypoints already contain stable names and coordinates. Restore
  /// editorial metadata locally, including on deployed databases which do not
  /// yet store evidence grades on waypoint snapshots. Never move a saved stop.
  static Future<List<RoutePlace>> restoreDetails(
    List<RoutePlace> places,
  ) async {
    if (places.isEmpty || places.every((place) => place.details != null)) {
      return places;
    }
    final catalog = await const DongpoSiteRepository().fetchLocalCatalog();
    final metadata =
        (jsonDecode(
                  await rootBundle.loadString(
                    'assets/data/dongpo_planning_metadata.json',
                  ),
                )
                as List)
            .cast<Map<String, dynamic>>();
    return places.map((place) {
      if (place.details != null) return place;
      final matches = catalog.sites.where((site) {
        final spec = metadata.firstWhere((row) => row['site_id'] == site.id);
        return site.nameModern == place.name ||
            (spec['existing_names'] as List).contains(place.name);
      });
      if (matches.isEmpty) return place;
      final site = matches.first;
      final spec = metadata.firstWhere((row) => row['site_id'] == site.id);
      final details = site.copyWith(
        id: place.id,
        dongpoSiteId: site.id,
        nameModern: place.name,
        coordinates: [place.longitude, place.latitude],
        categories: place.categories?.isNotEmpty == true
            ? place.categories!
                  .split(RegExp(r'[,，、]+'))
                  .map((v) => v.trim())
                  .toList()
            : [spec['category'] as String],
        averageVisitDurationMin: place.averageVisitDurationMin,
        themes: site.themes.map((tag) => tag == '自然山水' ? '自然景观' : tag).toList(),
      );
      return RoutePlace.fromLocation(details);
    }).toList();
  }

  static PlanningCatalog merge(
    List<LocationRecord> existing,
    List<TopicRecord> topics,
    List<LocationRecord> sites,
    List<Map<String, dynamic>> metadata, {
    bool isLocalCopy = false,
  }) {
    final routeTopic =
        topics.where((topic) => isDongpoRouteName(topic.name)).firstOrNull ??
        dongpoPlanningTopic;
    final oldLabels = {
      '自然景观',
      ...topics.map((topic) => topic.name),
      ...existing.expand(locationTopics),
    };
    const equivalents = {
      '自然山水': ['自然景观', '山水风光'],
      '诗词题咏': ['诗词文化', '诗词'],
      '交游酬唱': ['诗友交游', '交游'],
      '水利治绩': ['水利治理', '治水'],
      '民生善政': ['为政惠民', '民生'],
    };
    String canonical(String label) {
      for (final alias in equivalents[label] ?? const <String>[]) {
        if (oldLabels.contains(alias)) return alias;
      }
      return label;
    }

    final merged = {for (final place in existing) place.id: place};
    for (final site in sites) {
      final spec = metadata.firstWhere((row) => row['site_id'] == site.id);
      final aliases = (spec['existing_names'] as List).cast<String>();
      final matches = <LocationRecord>[
        ...existing.where((place) => place.dongpoSiteId == site.id),
        ...existing.where(
          (place) =>
              place.dongpoSiteId == null &&
              place.nameModern == site.nameModern &&
              (place.nameAncient == site.nameAncient ||
                  place.heritageGrade != null),
        ),
        for (final name in aliases)
          ...existing.where(
            (place) => place.dongpoSiteId == null && place.nameModern == name,
          ),
      ];
      final tags = site.themes.map(canonical).toSet();
      // Other historical records of the same place keep their original route
      // association, while gaining the same editorial labels and grade.
      for (final old in matches) {
        merged[old.id] = old.copyWith(
          themes: {...old.themes.map(canonical), ...tags}.toList(),
          heritageGrade: site.heritageGrade,
        );
      }
      final old = matches.isEmpty ? null : matches.first;
      final id = old?.id ?? -(10000 + site.id);
      merged[id] = site.copyWith(
        id: id,
        dongpoSiteId: site.id,
        topic: routeTopic.name,
        routeEligible: old?.routeEligible,
        themes: {
          if (old != null) ...locationTopics(old).map(canonical),
          ...tags,
        }.toList(),
        categories: old?.categories.isNotEmpty == true
            ? old!.categories
            : [spec['category'] as String],
        averageVisitDurationMin: old?.averageVisitDurationMin,
      );
    }
    final result = merged.values.toList(growable: false);
    return PlanningCatalog(
      locations: result,
      topics: [
        routeTopic,
        ...topics.where((topic) => !isDongpoRouteName(topic.name)),
      ],
      isLocalCopy: isLocalCopy,
    );
  }
}
