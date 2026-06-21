import 'package:flutter/foundation.dart';

import '../../data/location_repository.dart';
import '../../data/topic_repository.dart';
import '../../models/location_record.dart';
import '../models/route_place.dart';

class RoutePlaceRepository {
  const RoutePlaceRepository({
    TopicRepository? topicRepository,
    LocationRepository? locationRepository,
  }) : _topicRepository = topicRepository ?? const TopicRepository(),
       _locationRepository =
           locationRepository ?? const LocationRepository();

  final TopicRepository _topicRepository;
  final LocationRepository _locationRepository;

  Future<List<RoutePlace>> fetchPlacesByThemeId(int? themeId) async {
    List<LocationRecord> locations;
    try {
      locations = themeId == null
          ? await _locationRepository.fetchLocations()
          : await _fetchLocationsByThemeId(themeId);
    } catch (error, stackTrace) {
      debugPrint('fetchPlacesByThemeId: 查询失败 themeId=$themeId, error=$error');
      debugPrint('fetchPlacesByThemeId: 异常堆栈:\n$stackTrace');
      return const <RoutePlace>[];
    }

    final cleaned = locations
        .where((location) => location.coordinates.length >= 2)
        .map(RoutePlace.fromLocation)
        .toList(growable: false);

    debugPrint('fetchPlacesByThemeId: themeId=$themeId, 原始${locations.length}个, 有效坐标${cleaned.length}个');

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

  Future<List<LocationRecord>> _fetchLocationsByThemeId(int themeId) async {
    final topic = await _topicRepository.fetchTopicById(themeId);
    if (topic == null) {
      debugPrint('_fetchLocationsByThemeId: 未找到主题 themeId=$themeId');
      return const <LocationRecord>[];
    }

    debugPrint('_fetchLocationsByThemeId: 主题名="${topic.name}", 开始获取地点');
    final locations = await _locationRepository.fetchLocationsByTopic(topic.name);
    debugPrint('_fetchLocationsByThemeId: 获取到 ${locations.length} 个地点');
    return locations;
  }
}
