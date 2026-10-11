import 'transport_type.dart';

class RoutePlanConstraints {
  final int minPlaces;
  final int maxPlaces;
  final TransportType transportType;
  final Duration? timeWindow;

  const RoutePlanConstraints({
    required this.minPlaces,
    required this.maxPlaces,
    this.transportType = TransportType.walking,
    this.timeWindow,
  });
}
