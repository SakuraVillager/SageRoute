import '../models/topic_record.dart';
import '../data/topic_repository.dart';
import 'data/route_place_repository.dart';
import 'models/route_plan_command.dart';
import 'models/route_plan_constraints.dart';
import 'models/route_preference_type.dart';

class RoutePlanCommandBuilder {
  const RoutePlanCommandBuilder({
    RoutePlaceRepository? placeRepository,
    TopicRepository? topicRepository,
  })  : _placeRepository = placeRepository ?? const RoutePlaceRepository(),
        _topicRepository = topicRepository ?? const TopicRepository();

  final RoutePlaceRepository _placeRepository;
  final TopicRepository _topicRepository;

  Future<RoutePlanCommand> build({
    required int? themeId,
    required RoutePlanConstraints constraints,
    String? startPlaceId,
    String? endPlaceId,
    List<RoutePreferenceType> preferences = const <RoutePreferenceType>[
      RoutePreferenceType.shortest,
      RoutePreferenceType.diversity,
    ],
  }) async {
    final places = await _placeRepository.fetchPlacesByThemeId(themeId);
    final TopicRecord? theme = themeId == null ? null : await _topicRepository.fetchTopicById(themeId);

    return RoutePlanCommand(
      theme: theme,
      places: places,
      constraints: constraints,
      startPlaceId: startPlaceId,
      endPlaceId: endPlaceId,
      preferences: preferences,
    );
  }
}
