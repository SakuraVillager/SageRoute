import 'dart:async';

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../../../data/location_repository.dart';
import '../../../data/topic_repository.dart';
import '../../../models/celebrity_profile.dart';
import '../../../models/location_record.dart';
import '../../../route_planning/deterministic_amap_gateway.dart';
import '../../../route_planning/models/route_place.dart';
import '../../../route_planning/models/route_plan_constraints.dart';
import '../../../route_planning/models/route_plan_command.dart';
import '../../../route_planning/models/route_preference_type.dart';
import '../../../route_planning/models/transport_type.dart';
import '../../../route_planning/route_planning_engine.dart';
import '../../../services/native_amap_gateway.dart';
import '../../../theme/color_schemes.dart';

class Step3Map extends StatefulWidget {
  final CelebrityProfile? figure;
  final String? topicId;
  final int selectedCount;
  final ValueChanged<int> onLocationsChanged;

  const Step3Map({
    super.key,
    this.figure,
    this.topicId,
    this.selectedCount = 0,
    required this.onLocationsChanged,
  });

  @override
  State<Step3Map> createState() => _Step3MapState();
}

class _Step3MapState extends State<Step3Map> {
  static const double _initialPanelFraction = 0.38;
  static const List<double> _panelStops = [0.16, 0.26, 0.38, 0.50, 0.64];

  double _panelFraction = _initialPanelFraction;
  List<RoutePlace> _allPlaces = [];
  List<RoutePlace> _selected = [];
  List<RoutePlace> _markerPlaces = [];
  bool _loading = true;
  String? _error;

  List<List<double>> _polyline = [];
  String _routeSummary = '';
  Timer? _routeDebounce;

  AMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void didUpdateWidget(covariant Step3Map oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topicId != oldWidget.topicId) {
      _loadLocations();
    }
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      const locationRepo = LocationRepository();
      const topicRepo = TopicRepository();
      final themeId = widget.topicId != null ? int.tryParse(widget.topicId!) : null;

      List<LocationRecord> raw;
      if (themeId != null) {
        final topic = await topicRepo.fetchTopicById(themeId);
        raw = (topic != null && topic.name.isNotEmpty)
            ? await locationRepo.fetchLocationsByTopic(topic.name)
            : <LocationRecord>[];
        if (raw.isEmpty) raw = await locationRepo.fetchLocations();
      } else {
        raw = await locationRepo.fetchLocations();
      }

      if (!mounted) return;

      final places = <RoutePlace>[];
      for (var i = 0; i < raw.length; i++) {
        final loc = raw[i];
        if (loc.coordinates.length >= 2) {
          // If DB id is missing (0), assign a unique synthetic id based on index
          final id = loc.id > 0 ? loc.id : 100000 + i;
          places.add(RoutePlace(
            id: id,
            name: loc.nameModern,
            latitude: loc.coordinates[1],
            longitude: loc.coordinates[0],
            averageVisitDurationMin: loc.averageVisitDurationMin,
            topic: loc.topic,
            categories: loc.categories.join(', '),
          ));
        }
      }
      places.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _allPlaces = places;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<RoutePlace> get _unselected =>
      _allPlaces.where((p) => !_selected.contains(p)).toList();

  void _addPlace(RoutePlace place) {
    setState(() {
      _selected = [..._selected, place];
      _markerPlaces = [..._markerPlaces, place];
    });
    widget.onLocationsChanged(_selected.length);
    _scheduleRoute();
  }

  void _removePlace(RoutePlace place) {
    setState(() {
      _selected = _selected.where((p) => p != place).toList();
      _markerPlaces = _markerPlaces.where((p) => p != place).toList();
    });
    widget.onLocationsChanged(_selected.length);
    _scheduleRoute();
  }

  void _reorderSelected(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final updated = [..._selected];
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _selected = updated;
    });
    _scheduleRoute();
  }

  void _dragPanel(DragUpdateDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (screenHeight <= 0) return;
    final next = _panelFraction - details.delta.dy / screenHeight;
    setState(() {
      _panelFraction = next
          .clamp(_panelStops.first, _panelStops.last)
          .toDouble();
    });
  }

  void _settlePanel(DragEndDetails details) {
    setState(() {
      _panelFraction = _nearestPanelStop(_panelFraction);
    });
  }

  double _nearestPanelStop(double value) {
    var nearest = _panelStops.first;
    var minDistance = (value - nearest).abs();
    for (final stop in _panelStops.skip(1)) {
      final distance = (value - stop).abs();
      if (distance < minDistance) {
        nearest = stop;
        minDistance = distance;
      }
    }
    return nearest;
  }

  void _scheduleRoute() {
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(milliseconds: 300), () {
      _computeRoute(_selected);
    });
  }

  Future<void> _computeRoute(List<RoutePlace> selected) async {
    debugPrint('[Step3Map] _computeRoute called, selectedCount=${selected.length}');
    if (selected.length < 2) {
      if (mounted) {
        setState(() { _polyline = []; _routeSummary = ''; });
      }
      return;
    }

    List<List<double>>? polyline;
    String? summary;

    final cmd = RoutePlanCommand(
      theme: null,
      places: selected,
      constraints: const RoutePlanConstraints(minPlaces: 2, maxPlaces: 16, transportType: TransportType.driving),
      preferences: const [RoutePreferenceType.shortest],
    );

    // Primary: native AMap SDK (RouteSearch via MethodChannel)
    try {
      const engine = RoutePlanningEngine(gateway: NativeAmapGateway());
      final bundle = await engine.plan(cmd);
      final route = bundle.routes.isNotEmpty ? bundle.routes.first : null;
      debugPrint('[Step3Map] Native route polylineLen=${route?.polyline?.length} meters=${route?.stats.distanceMeters}');
      if (route?.polyline != null && route!.polyline!.length >= 2) {
        final clean = route.polyline!.where((p) => p.length >= 2 && p[0].isFinite && p[1].isFinite).toList();
        if (clean.length >= 2) {
          final km = (route.stats.distanceMeters ?? 0) / 1000;
          final min = route.stats.travelDuration?.inMinutes ?? 0;
          polyline = clean;
          summary = '${km.toStringAsFixed(1)} km · ${min ~/ 60 > 0 ? '${min ~/ 60}时' : ''}${min % 60}分';
          debugPrint('[Step3Map] Native SUCCESS: $summary');
        }
      }
    } catch (e) {
      debugPrint('[Step3Map] Native route failed: $e');
    }

    // Fallback: deterministic straight-line
    if (polyline == null) {
      debugPrint('[Step3Map] Falling back to deterministic...');
      try {
        const detEngine = RoutePlanningEngine(gateway: DeterministicAmapGateway());
        final bundle = await detEngine.plan(cmd);
        final route = bundle.routes.isNotEmpty ? bundle.routes.first : null;
        if (route?.polyline != null && route!.polyline!.length >= 2) {
          final clean = route.polyline!.where((p) => p.length >= 2 && p[0].isFinite && p[1].isFinite).toList();
          if (clean.length >= 2) {
            final km = (route.stats.distanceMeters ?? 0) / 1000;
            final min = route.stats.travelDuration?.inMinutes ?? 0;
            polyline = clean;
            summary = '${km.toStringAsFixed(1)} km · ${min ~/ 60 > 0 ? '${min ~/ 60}时' : ''}${min % 60}分 (直线估算)';
          }
        }
      } catch (e) {
        debugPrint('[Step3Map] Det exception: $e');
      }
    }

    if (!mounted) return;

    if (polyline != null) {
      final plannedPolyline = polyline;
      debugPrint('[Step3Map] Setting polyline with ${plannedPolyline.length} points');
      setState(() { _polyline = plannedPolyline; _routeSummary = summary ?? ''; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMap();
      });
    } else {
      setState(() { _polyline = []; _routeSummary = ''; });
    }
  }

  void _fitMap() {
    if (_polyline.isEmpty || _mapController == null) return;
    double minLat = double.infinity, maxLat = double.negativeInfinity;
    double minLon = double.infinity, maxLon = double.negativeInfinity;
    for (final p in _polyline) {
      if (!p[0].isFinite || !p[1].isFinite) continue;
      if (p[0] < minLat) minLat = p[0];
      if (p[0] > maxLat) maxLat = p[0];
      if (p[1] < minLon) minLon = p[1];
      if (p[1] > maxLon) maxLon = p[1];
    }
    if (!minLat.isFinite || !maxLat.isFinite) return;
    const e = 0.0005;
    if ((maxLat - minLat) < e) { maxLat += e; minLat -= e; }
    if ((maxLon - minLon) < e) { maxLon += e; minLon -= e; }
    _mapController!.moveCamera(
      CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLat, minLon), northeast: LatLng(maxLat, maxLon)), 60),
    );
  }

  void _onMapCreated(AMapController ctrl) {
    _mapController = ctrl;
    if (_polyline.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMap();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = MediaQuery.sizeOf(context).height;
    final panelH = totalHeight * _panelFraction;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('加载失败: $_error', style: const TextStyle(color: AppColors.sageMuted), textAlign: TextAlign.center),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AMapWidget(
              initialCameraPosition: const CameraPosition(target: LatLng(30.259462, 120.147151), zoom: 13),
              onMapCreated: _onMapCreated,
              polylines: _polyline.isEmpty ? {} : {
                Polyline(
                  points: _polyline.map((p) => LatLng(p[0], p[1])).toList(),
                  width: 6,
                  color: AppColors.primaryLight,
                )..setIdForCopy('route-main'),
              },
              markers: _markerPlaces.map((place) {
                final m = Marker(
                  position: LatLng(place.latitude, place.longitude),
                  infoWindow: InfoWindow(title: place.name),
                );
                m.setIdForCopy('marker-${place.id}');
                return m;
              }).toSet(),
            ),
          ),
        ),
        if (_routeSummary.isNotEmpty)
          Positioned(
            top: 8, left: 24, right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Color(0x152B2724), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route, size: 16, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Text(_routeSummary, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sageText)),
                ],
              ),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          left: 0, right: 0, bottom: 0, height: panelH,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.sageCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPanelContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildPanelContent() {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: _dragPanel,
          onVerticalDragEnd: _settlePanel,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.sageBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 6),
              const Row(children: [
                Expanded(child: _PanelHeader(icon: Icons.check_circle_outline, label: '已选地点', accent: AppColors.primaryLight)),
                SizedBox(height: 28, child: VerticalDivider(width: 1, color: AppColors.sageBorder)),
                Expanded(child: _PanelHeader(icon: Icons.place_outlined, label: '可用地点', accent: AppColors.sageGreen)),
              ]),
            ],
          ),
        ),
        Container(height: 0.5, color: AppColors.sageBorder),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _selected.isEmpty
                  ? const _EmptyHint(icon: Icons.add_location_alt_outlined, text: '从右侧添加地点')
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      buildDefaultDragHandles: false,
                      itemCount: _selected.length,
                      onReorder: _reorderSelected,
                      proxyDecorator: (child, _, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Material(
                              color: Colors.transparent,
                              child: Transform.scale(
                                scale: 1 + animation.value * 0.03,
                                child: child,
                              ),
                            );
                          },
                          child: child,
                        );
                      },
                      itemBuilder: (_, i) => _SelectedTile(
                        key: ValueKey('selected-${_selected[i].id}'),
                        place: _selected[i], index: i,
                        onRemove: () => _removePlace(_selected[i]),
                      ),
                    )),
              Container(width: 1, color: AppColors.sageBorder.withValues(alpha: 0.5)),
              Expanded(child: _unselected.isEmpty
                  ? const _EmptyHint(icon: Icons.done_all, text: '所有地点已选')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      itemCount: _unselected.length,
                      itemBuilder: (_, i) => _UnselectedTile(
                        key: ValueKey(_unselected[i].id), place: _unselected[i],
                        onTap: () => _addPlace(_unselected[i]),
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Panel header ──

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.icon, required this.label, required this.accent});
  final IconData icon; final String label; final Color accent;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(children: [
        Icon(icon, size: 15, color: accent), const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sageText)),
      ]),
    );
  }
}

// ── Empty hint ──

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 28, color: AppColors.sageBorder), const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.sageMuted)),
      ]),
    );
  }
}

// ── Selected tile ──

class _SelectedTile extends StatelessWidget {
  const _SelectedTile({super.key, required this.place, required this.index, required this.onRemove});
  final RoutePlace place; final int index; final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        ReorderableDragStartListener(
          index: index,
          child: Container(width: 22, height: 22, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(7)),
            child: Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(place.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.sageText), overflow: TextOverflow.ellipsis)),
        ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.drag_indicator, size: 16, color: AppColors.sageMuted),
          ),
        ),
        GestureDetector(
          onTap: onRemove,
          child: Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.sageBorder.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(6)),
            child: const Center(child: Icon(Icons.close, size: 12, color: AppColors.sageMuted))),
        ),
      ]),
    );
  }
}

// ── Unselected tile ──

class _UnselectedTile extends StatelessWidget {
  const _UnselectedTile({super.key, required this.place, required this.onTap});
  final RoutePlace place; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(children: [
          Container(width: 22, height: 22, decoration: BoxDecoration(border: Border.all(color: AppColors.sageBorder), borderRadius: BorderRadius.circular(7)),
            child: const Center(child: Icon(Icons.add, size: 13, color: AppColors.sageMuted))),
          const SizedBox(width: 10),
          Expanded(child: Text(place.name, style: const TextStyle(fontSize: 13, color: AppColors.sageText), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
