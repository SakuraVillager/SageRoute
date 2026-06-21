import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/amap_route_types.dart';
import 'models/transport_type.dart';

abstract class AmapGateway {
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request);
}

/// Real Amap Web Service API v3 gateway.
///
/// Calls the REST direction API:
///   - driving: GET {baseUrl}/driving?key=...&origin=lon,lat&destination=lon,lat&waypoints=...
///   - walking: GET {baseUrl}/walking?key=...&origin=lon,lat&destination=lon,lat
///
/// baseUrl should be the Amap direction base, e.g. https://restapi.amap.com/v3/direction
class HttpAmapGateway implements AmapGateway {
  const HttpAmapGateway({
    required http.Client client,
    required this.baseUrl,
    required this.apiKey,
  }) : _client = client;

  final http.Client _client;
  final String baseUrl;
  final String apiKey;

  String _pathForTransport(TransportType type) {
    switch (type) {
      case TransportType.driving:
        return 'driving';
      case TransportType.walking:
        return 'walking';
    }
  }

  @override
  Future<AmapRouteResult> fetchRoute(AmapRouteDraftRequest request) async {
    // Amap format: longitude first, then latitude (lon,lat)
    final origin = '${request.origin.longitude},${request.origin.latitude}';
    final destination =
        '${request.destination.longitude},${request.destination.latitude}';

    final waypointsStr = request.waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final transportPath = _pathForTransport(request.transportType);

    final queryParams = <String, String>{
      'key': apiKey,
      'origin': origin,
      'destination': destination,
      'output': 'json',
    };
    if (waypointsStr.isNotEmpty) {
      queryParams['waypoints'] = waypointsStr;
    }
    if (request.origin.id > 0) {
      queryParams['origin_id'] = request.origin.id.toString();
    }
    if (request.destination.id > 0) {
      queryParams['destination_id'] = request.destination.id.toString();
    }

    final uri = Uri.parse('$baseUrl/$transportPath')
        .replace(queryParameters: queryParams);

    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Amap HTTP request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Amap response format error: not a JSON object');
    }

    return AmapRouteResult.fromMap(decoded);
  }
}