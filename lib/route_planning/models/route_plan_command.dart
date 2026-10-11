import '../../models/topic_record.dart';
import 'route_place.dart';
import 'route_plan_constraints.dart';
import 'route_preference_type.dart';

class RoutePlanCommand {
  final TopicRecord? theme;
  final List<RoutePlace> places;
  final RoutePlanConstraints constraints;
  final String? startPlaceId;
  final String? endPlaceId;
  final List<RoutePreferenceType> preferences;

  RoutePlanCommand({
    required this.theme,
    required this.places,
    required this.constraints,
    String? startPlaceId,
    String? endPlaceId,
    required this.preferences,
  })  : startPlaceId = startPlaceId ??
            (places.isNotEmpty ? places.first.id.toString() : null),
        endPlaceId = endPlaceId ??
            (places.isNotEmpty ? places.last.id.toString() : null);
}
