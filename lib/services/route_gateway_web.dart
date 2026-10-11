import 'dart:js_interop';
import '../route_planning/amap_gateway.dart';
import '../route_planning/models/amap_route_types.dart';
import 'client_config.dart';
import 'web/map_bridge.dart';
import 'web_amap_route_parser.dart';

AmapGateway createRouteGateway() => const WebAmapGateway();

class WebAmapGateway implements AmapGateway {
  const WebAmapGateway();
  @override
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request) async {
    final result = await mapBridge
        .route(
          {
            'config': ClientConfig.mapConfig,
            'origin': [request.origin.longitude, request.origin.latitude],
            'destination': [
              request.destination.longitude,
              request.destination.latitude,
            ],
            'waypoints': request.waypoints
                .map((p) => [p.longitude, p.latitude])
                .toList(),
            'transport': request.transportType.name,
            'preference': request.preferenceKey,
          }.jsify()!,
        )
        .toDart
        .timeout(const Duration(seconds: 15));
    return parseWebAmapRoute(
      Map<String, dynamic>.from(result!.dartify()! as Map),
    );
  }
}
