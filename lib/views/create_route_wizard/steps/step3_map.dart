import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../../../data/location_repository.dart';
import '../../../models/celebrity_profile.dart';
import '../../../models/location_record.dart';
import '../../../route_planning/models/route_place.dart';
import '../../../route_planning/models/transport_type.dart';
import '../../../route_planning/route_preview_coordinator.dart';
import '../../../services/native_amap_gateway.dart';
import '../../../theme/color_schemes.dart';
import 'add_place_page.dart';

class Step3Map extends StatefulWidget {
  final CelebrityProfile? figure;
  final List<RoutePlace> selectedPlaces;
  final ValueChanged<List<RoutePlace>> onLocationsChanged;
  final ValueChanged<RoutePreviewStatus> onPreviewStatusChanged;
  final Future<void> Function() onSaveRequested;

  const Step3Map({
    super.key,
    this.figure,
    this.selectedPlaces = const [],
    required this.onLocationsChanged,
    required this.onPreviewStatusChanged,
    required this.onSaveRequested,
  });

  @override
  State<Step3Map> createState() => _Step3MapState();
}

class _Step3MapState extends State<Step3Map> {
  static const double _initialPanelFraction = 0.56;
  static const List<double> _panelStops = [0.32, 0.56, 0.78];

  double _panelFraction = _initialPanelFraction;
  List<RoutePlace> _allPlaces = [];
  List<RoutePlace> _themePlaces = [];
  List<RoutePlace> _visiblePlaces = [];
  late List<RoutePlace> _selected;
  bool _loading = true;
  int _loadSequence = 0;
  String? _loadError;

  final Map<String, TransportType> _segmentTransportTypes = {};
  RoutePreviewStatus _previewStatus = RoutePreviewStatus.insufficient;
  List<List<double>> _polyline = [];
  List<RouteSegmentPreview> _segmentPreviews = [];
  int? _totalDistanceMeters;
  Duration? _totalTravelDuration;
  String? _routeError;
  String? _diagInfo;
  late final RoutePreviewCoordinator _routeCoordinator;

  AMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selected = List<RoutePlace>.from(widget.selectedPlaces);
    _routeCoordinator = RoutePreviewCoordinator(
      gateway: const NativeAmapGateway(),
    );
    _loadLocations();
  }

  @override
  void didUpdateWidget(covariant Step3Map oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasSamePlaceIds(widget.selectedPlaces, oldWidget.selectedPlaces)) {
      setState(() {
        _selected = List<RoutePlace>.from(widget.selectedPlaces);
        _visiblePlaces = _mergeVisiblePlaces(_themePlaces, _selected);
      });
      _scheduleRoute();
    }
  }

  @override
  void dispose() {
    _routeCoordinator.dispose();
    super.dispose();
  }

  bool _hasSamePlaceIds(List<RoutePlace> a, List<RoutePlace> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].name != b[i].name) return false;
    }
    return true;
  }

  Future<void> _loadLocations() async {
    final sequence = ++_loadSequence;
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      const locationRepo = LocationRepository();
      final raw = await locationRepo.fetchLocations();

      if (!mounted || sequence != _loadSequence) return;

      final places = _recordsToPlaces(raw);
      final themePlaces = places;
      final visiblePlaces = _mergeVisiblePlaces(themePlaces, _selected);
      final selected = _selectedInVisibleOrder(visiblePlaces);

      setState(() {
        _allPlaces = places;
        _themePlaces = themePlaces;
        _visiblePlaces = visiblePlaces;
        _selected = selected;
        _loading = false;
      });
      widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
      _scheduleRoute();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMapToMarkers();
      });
    } catch (e) {
      if (!mounted || sequence != _loadSequence) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  List<RoutePlace> _recordsToPlaces(List<LocationRecord> raw) {
    final places = <RoutePlace>[];
    for (var i = 0; i < raw.length; i++) {
      final loc = raw[i];
      if (_hasValidCoordinates(loc)) {
        final id = loc.id > 0 ? loc.id : 100000 + i;
        places.add(
          RoutePlace(
            id: id,
            name: loc.nameModern,
            latitude: loc.coordinates[1],
            longitude: loc.coordinates[0],
            averageVisitDurationMin: loc.averageVisitDurationMin,
            topic: loc.topic,
            categories: loc.categories.join(', '),
          ),
        );
      }
    }
    places.sort((a, b) => a.name.compareTo(b.name));
    return places;
  }

  bool _hasValidCoordinates(LocationRecord location) {
    if (location.coordinates.length < 2) return false;
    final longitude = location.coordinates[0];
    final latitude = location.coordinates[1];
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  List<RoutePlace> _mergeVisiblePlaces(
    List<RoutePlace> themePlaces,
    List<RoutePlace> selectedPlaces,
  ) {
    final allowedNames = <String>{
      for (final place in themePlaces) place.name,
      for (final place in selectedPlaces) place.name,
    };
    final byName = <String, RoutePlace>{};
    for (final place in selectedPlaces) {
      byName[place.name] = place;
    }
    for (final place in themePlaces) {
      byName[place.name] = place;
    }

    final merged = <RoutePlace>[];
    final mergedNames = <String>{};
    for (final place in _visiblePlaces) {
      final next = byName[place.name];
      if (next != null && allowedNames.contains(place.name)) {
        merged.add(next);
        mergedNames.add(place.name);
      }
    }
    for (final place in selectedPlaces) {
      if (allowedNames.contains(place.name) && mergedNames.add(place.name)) {
        merged.add(byName[place.name] ?? place);
      }
    }
    for (final place in themePlaces) {
      if (mergedNames.add(place.name)) {
        merged.add(place);
      }
    }
    return merged;
  }

  List<RoutePlace> _selectedInVisibleOrder(List<RoutePlace> visiblePlaces) {
    final selectedNames = _selected.map((place) => place.name).toSet();
    return visiblePlaces
        .where((place) => selectedNames.contains(place.name))
        .toList(growable: false);
  }

  void _setPreviewStatus(RoutePreviewStatus status) {
    if (_previewStatus == status) return;
    _previewStatus = status;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPreviewStatusChanged(status);
    });
  }

  String _segmentKey(RoutePlace from, RoutePlace to) =>
      '${from.id}:${from.name}->${to.id}:${to.name}';

  List<TransportType> get _currentTransportTypes => <TransportType>[
    for (var index = 0; index < _selected.length - 1; index++)
      _segmentTransportTypes[_segmentKey(
            _selected[index],
            _selected[index + 1],
          )] ??
          TransportType.driving,
  ];

  void _selectSegmentTransportType(int index, TransportType type) {
    if (index < 0 || index >= _selected.length - 1) return;
    final key = _segmentKey(_selected[index], _selected[index + 1]);
    if ((_segmentTransportTypes[key] ?? TransportType.driving) == type) return;
    setState(() => _segmentTransportTypes[key] = type);
    _scheduleRoute();
  }

  void _scheduleRoute() {
    _routeCoordinator.schedule(
      places: _selected,
      transportTypes: _currentTransportTypes,
      onChanged: _applyRouteSnapshot,
    );
  }

  void _applyRouteSnapshot(RoutePreviewSnapshot snapshot) {
    if (!mounted) return;
    setState(() {
      _polyline = snapshot.polyline;
      _segmentPreviews = snapshot.segments;
      _totalDistanceMeters = snapshot.distanceMeters;
      _totalTravelDuration = snapshot.travelDuration;
      _routeError = snapshot.error;
      _diagInfo = snapshot.diagnostics;
    });
    _setPreviewStatus(snapshot.status);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitMapToMarkers();
    });
  }

  void _removePlace(RoutePlace place) {
    setState(() {
      // 按名称移除（数据库 id 可能重复）
      _selected = _selected
          .where((selectedPlace) => selectedPlace.name != place.name)
          .toList(growable: false);
      _visiblePlaces = _mergeVisiblePlaces(_themePlaces, _selected);
    });
    widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
    _scheduleRoute();
    if (_selected.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMapToMarkers();
      });
    }
  }

  void _clearAllPlaces() {
    setState(() {
      _selected = const [];
      _visiblePlaces = _mergeVisiblePlaces(_themePlaces, _selected);
    });
    widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
    _scheduleRoute();
  }

  Future<void> _confirmRemovePlace(RoutePlace place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除地点'),
        content: Text('确定要从路线中删除「${place.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.sageAccent),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _removePlace(place);
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空全部地点'),
        content: const Text('确定要清空所有已选地点吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.sageAccent),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _clearAllPlaces();
    }
  }

  void _dragPanel(DragUpdateDetails details) {
    final availableHeight =
        context.size?.height ?? MediaQuery.sizeOf(context).height;
    if (availableHeight <= 0) return;
    final next = _panelFraction - details.delta.dy / availableHeight;
    setState(() {
      _panelFraction = next
          .clamp(_panelStops.first, _panelStops.last)
          .toDouble();
    });
  }

  void _settlePanel(DragEndDetails details) {
    setState(() => _panelFraction = _nearestPanelStop(_panelFraction));
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

  void _onMapCreated(AMapController ctrl) {
    _mapController = ctrl;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitMapToMarkers();
    });
  }

  void _fitMapToMarkers() {
    final points = _polyline.isNotEmpty
        ? _polyline
        : _markerPlaces
              .map((place) => <double>[place.latitude, place.longitude])
              .toList(growable: false);
    if (points.isEmpty || _mapController == null) return;

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;

    for (final point in points) {
      if (point.length < 2 || !point[0].isFinite || !point[1].isFinite) {
        continue;
      }
      minLat = mathMin(minLat, point[0]);
      maxLat = mathMax(maxLat, point[0]);
      minLon = mathMin(minLon, point[1]);
      maxLon = mathMax(maxLon, point[1]);
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
        60,
      ),
    );
  }

  double mathMin(double a, double b) => a < b ? a : b;

  double mathMax(double a, double b) => a > b ? a : b;

  List<RoutePlace> get _markerPlaces => _visiblePlaces;

  @override
  Widget build(BuildContext context) {
    if (_loading && _allPlaces.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '加载失败: $_loadError',
            style: const TextStyle(color: AppColors.sageMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelH = constraints.maxHeight * _panelFraction;
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
                      ? const <Polyline>{}
                      : {
                          Polyline(
                            points: _polyline
                                .map((point) => LatLng(point[0], point[1]))
                                .toList(growable: false),
                            width: 7,
                            color: AppColors.primaryLight,
                          )..setIdForCopy('route-preview-main'),
                        },
                  markers: _markerPlaces.map((place) {
                    final selectedIndex = _selected.indexWhere(
                      (item) => item.name == place.name,
                    );
                    final marker = Marker(
                      position: LatLng(place.latitude, place.longitude),
                      infoWindow: InfoWindow(
                        title: selectedIndex >= 0
                            ? '${selectedIndex + 1}. ${place.name}'
                            : place.name,
                      ),
                    );
                    marker.setIdForCopy('marker-${place.id}-${place.name}');
                    return marker;
                  }).toSet(),
                ),
              ),
            ),
            if (_loading)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.18),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: 0,
              height: panelH,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.sageCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A202124),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildPanelContent(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanelContent() {
    final compact = _panelFraction <= 0.32;
    final statusTitle = switch (_previewStatus) {
      RoutePreviewStatus.insufficient =>
        _selected.isEmpty ? '尚未添加地点' : '已选 ${_selected.length} 个地点',
      RoutePreviewStatus.planning => '正在规划路线',
      RoutePreviewStatus.ready => '行程路线',
      RoutePreviewStatus.failed => '路线预览失败',
    };
    final statusSubtitle = switch (_previewStatus) {
      RoutePreviewStatus.insufficient => '至少选择 2 个地点后自动生成路线',
      RoutePreviewStatus.planning => '正在更新各路段的距离与耗时…',
      RoutePreviewStatus.ready => '点击地点间的交通信息，可单独切换驾车或步行',
      RoutePreviewStatus.failed => _routeError ?? '可继续调整地点或直接保存',
    };
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: _dragPanel,
          onVerticalDragEnd: _settlePanel,
          onTap: () {
            setState(() {
              _panelFraction = compact ? 0.56 : 0.32;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.sageBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.route_outlined,
                      size: 16,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sageText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: _previewStatus == RoutePreviewStatus.failed
                                  ? AppColors.primaryLight
                                  : AppColors.sageMuted,
                            ),
                          ),
                          if (_diagInfo != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              _diagInfo!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.sageMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_previewStatus == RoutePreviewStatus.planning)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (_selected.isNotEmpty)
                      Tooltip(
                        message: '清空地点',
                        child: IconButton(
                          onPressed: _confirmClearAll,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 19,
                            color: AppColors.sageMuted,
                          ),
                        ),
                      ),
                    Tooltip(
                      message: '添加地点',
                      child: Material(
                        color: AppColors.sageText,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _navigateToAddPlace,
                          borderRadius: BorderRadius.circular(12),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.add_location_alt_outlined,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      compact
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.sageMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(height: 0.5, color: AppColors.sageBorder),
        Expanded(
          child: _selected.isEmpty
              ? const _EmptyHint(
                  icon: Icons.add_location_alt_outlined,
                  text: '点击面板右上角按钮添加地点',
                )
              : compact
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
                  itemCount: _selected.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final place = _selected[index];
                    return _SelectedPlaceChip(
                      index: index,
                      place: place,
                      onRemove: () => _removePlace(place),
                    );
                  },
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  buildDefaultDragHandles: false,
                  itemCount: _selected.length,
                  onReorder: _reorderSelectedPlaces,
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
                  itemBuilder: (_, i) {
                    final place = _selected[i];
                    final segment = _segmentPreviewAt(i);
                    final transportType = i < _selected.length - 1
                        ? _currentTransportTypes[i]
                        : null;
                    return _ItineraryTimelineTile(
                      key: ValueKey('timeline-${place.id}-${place.name}'),
                      place: place,
                      index: i,
                      visitWindow: _visitWindowLabel(i),
                      transportType: transportType,
                      segment: segment,
                      isPlanning: _previewStatus == RoutePreviewStatus.planning,
                      onTransportChanged: transportType == null
                          ? null
                          : (type) => _selectSegmentTransportType(i, type),
                      onRemove: () => _confirmRemovePlace(place),
                    );
                  },
                ),
        ),
        _buildRouteFooter(),
      ],
    );
  }

  RouteSegmentPreview? _segmentPreviewAt(int index) {
    for (final segment in _segmentPreviews) {
      if (segment.index == index) return segment;
    }
    return null;
  }

  String _visitWindowLabel(int index) {
    var cursorMinutes = 9 * 60;
    for (var current = 0; current < index; current++) {
      cursorMinutes += _selected[current].averageVisitDurationMin ?? 60;
      cursorMinutes +=
          _segmentPreviewAt(current)?.travelDuration.inMinutes ?? 20;
    }
    final visitMinutes = _selected[index].averageVisitDurationMin ?? 60;
    return '${_clockLabel(cursorMinutes)} - '
        '${_clockLabel(cursorMinutes + visitMinutes)}';
  }

  String _clockLabel(int totalMinutes) {
    final normalized = totalMinutes % (24 * 60);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRouteFooter() {
    final saveAction = resolveRouteSaveAction(
      placesCount: _selected.length,
      previewStatus: _previewStatus,
    );
    final saveEnabled = saveAction != RouteSaveAction.disabled;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.sageCard,
        border: Border(top: BorderSide(color: AppColors.sageBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RouteTotalMetric(
              icon: Icons.route_outlined,
              label: '总里程',
              value: _formatDistance(_totalDistanceMeters),
            ),
          ),
          Expanded(
            child: _RouteTotalMetric(
              icon: Icons.schedule_outlined,
              label: '总时长',
              value: _formatDuration(_totalTravelDuration),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 118,
            height: 48,
            child: ElevatedButton(
              onPressed: saveEnabled ? widget.onSaveRequested : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageDeep,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.brandLight,
                disabledForegroundColor: AppColors.sageMuted,
                elevation: 0,
                minimumSize: const Size(118, 38.4),
                tapTargetSize: MaterialTapTargetSize.padded,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.8),
                ),
              ),
              child: Text(
                _previewStatus == RoutePreviewStatus.planning ? '规划中…' : '保存行程',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(int? distanceMeters) {
    if (distanceMeters == null) return '--';
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    final minutes = duration.inMinutes;
    if (minutes < 60) return '$minutes 分钟';
    return '${minutes ~/ 60}h ${minutes % 60}min';
  }

  void _reorderSelectedPlaces(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= _selected.length) return;
    if (newIndex < 0 || newIndex >= _selected.length) return;

    setState(() {
      final updated = [..._selected];
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _selected = updated;
    });
    widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
    _scheduleRoute();
  }

  Future<void> _navigateToAddPlace() async {
    final result = await showModalBottomSheet<List<RoutePlace>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) =>
          AddPlacePage(figure: widget.figure, currentSelectedPlaces: _selected),
    );

    if (result == null) return;
    setState(() {
      // Replace the complete selection so removals made in the picker take effect.
      _selected = List<RoutePlace>.from(result);
      _visiblePlaces = _mergeVisiblePlaces(_themePlaces, _selected);
      _panelFraction = _initialPanelFraction;
    });
    widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
    _scheduleRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitMapToMarkers();
    });
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AppColors.sageBorder),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.sageMuted),
          ),
        ],
      ),
    );
  }
}

class _RouteTotalMetric extends StatelessWidget {
  const _RouteTotalMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: AppColors.sageAccent),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.sageMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sageText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedPlaceChip extends StatelessWidget {
  const _SelectedPlaceChip({
    required this.index,
    required this.place,
    required this.onRemove,
  });

  final int index;
  final RoutePlace place;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.fromLTRB(8, 6, 5, 6),
      decoration: BoxDecoration(
        color: AppColors.brandWash,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.sageBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sageText,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sageText,
              ),
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.close, size: 15, color: AppColors.sageMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryTimelineTile extends StatelessWidget {
  const _ItineraryTimelineTile({
    super.key,
    required this.place,
    required this.index,
    required this.visitWindow,
    required this.transportType,
    required this.segment,
    required this.isPlanning,
    required this.onTransportChanged,
    required this.onRemove,
  });

  final RoutePlace place;
  final int index;
  final String visitWindow;
  final TransportType? transportType;
  final RouteSegmentPreview? segment;
  final bool isPlanning;
  final ValueChanged<TransportType>? onTransportChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasNext = transportType != null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.sageAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (hasNext)
                  const Expanded(
                    child: CustomPaint(
                      painter: _DottedTimelinePainter(),
                      child: SizedBox(width: 1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sageText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            visitWindow,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.sageMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.drag_indicator,
                          size: 18,
                          color: AppColors.sageMuted,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.sageMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasNext) ...[
                  const SizedBox(height: 7),
                  _SegmentTransportRow(
                    value: transportType!,
                    segment: segment,
                    isPlanning: isPlanning,
                    onChanged: onTransportChanged!,
                  ),
                  const SizedBox(height: 9),
                ] else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTransportRow extends StatelessWidget {
  const _SegmentTransportRow({
    required this.value,
    required this.segment,
    required this.isPlanning,
    required this.onChanged,
  });

  final TransportType value;
  final RouteSegmentPreview? segment;
  final bool isPlanning;
  final ValueChanged<TransportType> onChanged;

  @override
  Widget build(BuildContext context) {
    final distance = segment == null
        ? '--'
        : segment!.distanceMeters < 1000
        ? '${segment!.distanceMeters} 米'
        : '${(segment!.distanceMeters / 1000).toStringAsFixed(1)} 公里';
    final duration = segment == null
        ? '--'
        : '${segment!.travelDuration.inMinutes} 分钟';
    return PopupMenuButton<TransportType>(
      initialValue: value,
      onSelected: onChanged,
      color: AppColors.sageCard,
      tooltip: '调整此路段交通方式',
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: TransportType.driving,
          child: Row(
            children: [
              Icon(Icons.directions_car_filled_outlined, size: 18),
              SizedBox(width: 9),
              Text('驾车'),
            ],
          ),
        ),
        PopupMenuItem(
          value: TransportType.walking,
          child: Row(
            children: [
              Icon(Icons.directions_walk, size: 18),
              SizedBox(width: 9),
              Text('步行'),
            ],
          ),
        ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.brandWash,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              value == TransportType.driving
                  ? Icons.directions_car_filled_outlined
                  : Icons.directions_walk,
              size: 17,
              color: AppColors.sageAccent,
            ),
            const SizedBox(width: 7),
            Text(
              value == TransportType.driving ? '驾车' : '步行',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.sageAccent,
              ),
            ),
            const SizedBox(width: 8),
            const Text('|', style: TextStyle(color: AppColors.sageBorder)),
            const SizedBox(width: 8),
            if (isPlanning) ...[
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.6),
              ),
              const SizedBox(width: 6),
              const Text(
                '更新中…',
                style: TextStyle(fontSize: 11, color: AppColors.sageMuted),
              ),
            ] else ...[
              Text(
                distance,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.sageMuted,
                ),
              ),
              const SizedBox(width: 8),
              const Text('|', style: TextStyle(color: AppColors.sageBorder)),
              const SizedBox(width: 8),
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.sageMuted,
                ),
              ),
            ],
            const Spacer(),
            const Icon(Icons.expand_more, size: 16, color: AppColors.sageMuted),
          ],
        ),
      ),
    );
  }
}

class _DottedTimelinePainter extends CustomPainter {
  const _DottedTimelinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.sageAccent
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashHeight = 4.0;
    const gap = 4.0;
    final centerX = size.width / 2;
    for (var y = 4.0; y < size.height; y += dashHeight + gap) {
      canvas.drawLine(
        Offset(centerX, y),
        Offset(centerX, (y + dashHeight).clamp(0, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
