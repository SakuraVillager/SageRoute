import 'dart:async';

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../../../route_planning/models/route_place.dart';
import '../../../route_planning/models/route_plan_command.dart';
import '../../../route_planning/models/route_plan_constraints.dart';
import '../../../route_planning/models/route_preference_type.dart';
import '../../../route_planning/models/transport_type.dart';
import '../../../route_planning/route_planning_engine.dart';
import '../../../services/native_amap_gateway.dart';
import '../../../theme/color_schemes.dart';

class Step4RoutePreview extends StatefulWidget {
  const Step4RoutePreview({super.key, required this.places});

  final List<RoutePlace> places;

  @override
  State<Step4RoutePreview> createState() => _Step4RoutePreviewState();
}

class _Step4RoutePreviewState extends State<Step4RoutePreview> {
  TransportType _transportType = TransportType.driving;
  List<List<double>> _polyline = [];
  String _routeSummary = '';
  String? _error;
  bool _planning = false;
  Timer? _routeDebounce;
  AMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _scheduleRoute();
  }

  @override
  void didUpdateWidget(covariant Step4RoutePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasSamePlaceIds(widget.places, oldWidget.places)) {
      _scheduleRoute();
    }
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    super.dispose();
  }

  bool _hasSamePlaceIds(List<RoutePlace> a, List<RoutePlace> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _selectTransportType(TransportType type) {
    if (_transportType == type) return;
    setState(() => _transportType = type);
    _scheduleRoute();
  }

  void _scheduleRoute() {
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(milliseconds: 240), _computeRoute);
  }

  Future<void> _computeRoute() async {
    final selected = widget.places;
    if (selected.length < 2) {
      if (mounted) {
        setState(() {
          _polyline = [];
          _routeSummary = '';
          _error = '至少选择 2 个地点后才能预览路线';
          _planning = false;
        });
      }
      return;
    }

    setState(() {
      _planning = true;
      _error = null;
    });

    final command = RoutePlanCommand(
      theme: null,
      places: selected,
      constraints: RoutePlanConstraints(
        minPlaces: 2,
        maxPlaces: 16,
        transportType: _transportType,
      ),
      preferences: const [RoutePreferenceType.shortest],
    );

    try {
      const engine = RoutePlanningEngine(gateway: NativeAmapGateway());
      final bundle = await engine.plan(command);
      final route = bundle.routes.isNotEmpty ? bundle.routes.first : null;
      final clean = route?.polyline
          ?.where((p) => p.length >= 2 && p[0].isFinite && p[1].isFinite)
          .toList();

      if (!mounted) return;

      if (route == null || clean == null || clean.length < 2) {
        setState(() {
          _polyline = [];
          _routeSummary = '';
          _error = '暂未获取到可渲染的路线';
          _planning = false;
        });
        return;
      }

      final km = (route.stats.distanceMeters ?? 0) / 1000;
      final min = route.stats.travelDuration?.inMinutes ?? 0;
      setState(() {
        _polyline = clean;
        _routeSummary =
            '${_transportLabel(_transportType)} · '
            '${km.toStringAsFixed(1)} km · '
            '${min ~/ 60 > 0 ? '${min ~/ 60}时' : ''}${min % 60}分';
        _planning = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMap();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _polyline = [];
        _routeSummary = '';
        _error = '路径规划失败：$e';
        _planning = false;
      });
    }
  }

  void _onMapCreated(AMapController ctrl) {
    _mapController = ctrl;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitMap();
    });
  }

  void _fitMap() {
    final points = _polyline.isNotEmpty
        ? _polyline
        : widget.places.map((p) => <double>[p.latitude, p.longitude]).toList();
    if (points.isEmpty || _mapController == null) return;

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;

    for (final p in points) {
      if (p.length < 2 || !p[0].isFinite || !p[1].isFinite) continue;
      if (p[0] < minLat) minLat = p[0];
      if (p[0] > maxLat) maxLat = p[0];
      if (p[1] < minLon) minLon = p[1];
      if (p[1] > maxLon) maxLon = p[1];
    }
    if (!minLat.isFinite || !maxLat.isFinite) return;

    const edge = 0.0005;
    if ((maxLat - minLat) < edge) {
      maxLat += edge;
      minLat -= edge;
    }
    if ((maxLon - minLon) < edge) {
      maxLon += edge;
      minLon -= edge;
    }

    _mapController!.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLon),
          northeast: LatLng(maxLat, maxLon),
        ),
        64,
      ),
    );
  }

  String _transportLabel(TransportType type) {
    switch (type) {
      case TransportType.driving:
        return '驾车';
      case TransportType.walking:
        return '步行';
    }
  }

  IconData _transportIcon(TransportType type) {
    switch (type) {
      case TransportType.driving:
        return Icons.directions_car_filled_outlined;
      case TransportType.walking:
        return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AMapWidget(
              initialCameraPosition: const CameraPosition(
                target: LatLng(30.259462, 120.147151),
                zoom: 13,
              ),
              onMapCreated: _onMapCreated,
              polylines: _polyline.isEmpty
                  ? {}
                  : {
                      Polyline(
                        points: _polyline
                            .map((p) => LatLng(p[0], p[1]))
                            .toList(),
                        width: 7,
                        color: AppColors.primaryLight,
                      )..setIdForCopy('route-preview-main'),
                    },
              markers: widget.places.asMap().entries.map((entry) {
                final marker = Marker(
                  position: LatLng(entry.value.latitude, entry.value.longitude),
                  infoWindow: InfoWindow(
                    title: '${entry.key + 1}. ${entry.value.name}',
                  ),
                );
                marker.setIdForCopy('preview-marker-${entry.value.id}');
                return marker;
              }).toSet(),
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 20,
          right: 20,
          child: _TransportSelector(
            value: _transportType,
            labelFor: _transportLabel,
            iconFor: _transportIcon,
            onChanged: _selectTransportType,
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: _RoutePreviewPanel(
            places: widget.places,
            planning: _planning,
            summary: _routeSummary,
            error: _error,
            transportLabel: _transportLabel(_transportType),
          ),
        ),
      ],
    );
  }
}

class _TransportSelector extends StatelessWidget {
  const _TransportSelector({
    required this.value,
    required this.labelFor,
    required this.iconFor,
    required this.onChanged,
  });

  final TransportType value;
  final String Function(TransportType type) labelFor;
  final IconData Function(TransportType type) iconFor;
  final ValueChanged<TransportType> onChanged;

  @override
  Widget build(BuildContext context) {
    const modes = [TransportType.driving, TransportType.walking];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xF7FAF8F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x182B2724),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route, size: 14, color: AppColors.primaryLight),
              SizedBox(width: 6),
              Text(
                '交通方式',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sageText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: modes.map((mode) {
              final selected = value == mode;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: mode == modes.last ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => onChanged(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.sageText : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.sageText
                              : AppColors.sageBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            iconFor(mode),
                            size: 15,
                            color: selected
                                ? Colors.white
                                : AppColors.sageMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            labelFor(mode),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppColors.sageText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoutePreviewPanel extends StatelessWidget {
  const _RoutePreviewPanel({
    required this.places,
    required this.planning,
    required this.summary,
    required this.error,
    required this.transportLabel,
  });

  final List<RoutePlace> places;
  final bool planning;
  final String summary;
  final String? error;
  final String transportLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x202B2724),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.sageText,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.route, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planning ? '正在规划$transportLabel路线' : '路线预览',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sageText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.isNotEmpty
                          ? summary
                          : '${places.length} 个地点 · 可在后续扩展分组与修改地点',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.sageMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (planning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFC44536)),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: places.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final place = places[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: index == 0 || index == places.length - 1
                        ? AppColors.sageText
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: index == 0 || index == places.length - 1
                              ? Colors.white
                              : AppColors.sageMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        place.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: index == 0 || index == places.length - 1
                              ? Colors.white
                              : AppColors.sageText,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
