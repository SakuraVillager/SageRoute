import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../../../data/location_repository.dart';
import '../../../data/topic_repository.dart';
import '../../../models/celebrity_profile.dart';
import '../../../models/location_record.dart';
import '../../../models/topic_record.dart';
import '../../../route_planning/models/route_place.dart';
import '../../../theme/color_schemes.dart';
import 'add_place_page.dart';

class Step3Map extends StatefulWidget {
  final CelebrityProfile? figure;
  final String? topicId;
  final List<RoutePlace> selectedPlaces;
  final void Function(String id, String name) onTopicChanged;
  final ValueChanged<List<RoutePlace>> onLocationsChanged;

  const Step3Map({
    super.key,
    this.figure,
    this.topicId,
    this.selectedPlaces = const [],
    required this.onTopicChanged,
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
  List<RoutePlace> _themePlaces = [];
  List<RoutePlace> _visiblePlaces = [];
  late List<RoutePlace> _selected;
  late Future<List<TopicRecord>> _topicsFuture;
  bool _loading = true;
  int _loadSequence = 0;
  String? _error;

  AMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selected = List<RoutePlace>.from(widget.selectedPlaces);
    _loadTopics();
    _loadLocations();
  }

  @override
  void didUpdateWidget(covariant Step3Map oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.figure?.name != oldWidget.figure?.name) {
      _loadTopics();
    }
    if (widget.topicId != oldWidget.topicId) {
      _loadLocations();
    }
    if (!_hasSamePlaceIds(widget.selectedPlaces, oldWidget.selectedPlaces)) {
      _selected = List<RoutePlace>.from(widget.selectedPlaces);
    }
  }

  bool _hasSamePlaceIds(List<RoutePlace> a, List<RoutePlace> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _loadTopics() {
    final name = widget.figure?.name ?? '';
    _topicsFuture = const TopicRepository().fetchTopicsByCelebrity(name);
  }

  Future<void> _loadLocations() async {
    final sequence = ++_loadSequence;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      const locationRepo = LocationRepository();
      const topicRepo = TopicRepository();
      final themeId = widget.topicId != null
          ? int.tryParse(widget.topicId!)
          : null;
      final selectedTopic = themeId == null
          ? null
          : await topicRepo.fetchTopicById(themeId);
      final raw = await locationRepo.fetchLocations();

      if (!mounted || sequence != _loadSequence) return;

      final places = _recordsToPlaces(raw);
      final themeName = selectedTopic?.name ?? '';
      final themePlaces = themeName.isEmpty
          ? places
          : places
                .where((place) => _placeHasTopic(place, themeName))
                .toList(growable: false);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMapToMarkers();
      });
    } catch (e) {
      if (!mounted || sequence != _loadSequence) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<RoutePlace> _recordsToPlaces(List<LocationRecord> raw) {
    final places = <RoutePlace>[];
    for (var i = 0; i < raw.length; i++) {
      final loc = raw[i];
      if (loc.coordinates.length >= 2) {
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

  List<RoutePlace> _mergeVisiblePlaces(
    List<RoutePlace> themePlaces,
    List<RoutePlace> selectedPlaces,
  ) {
    final allowedIds = <int>{
      for (final place in themePlaces) place.id,
      for (final place in selectedPlaces) place.id,
    };
    final byId = <int, RoutePlace>{};
    for (final place in selectedPlaces) {
      byId[place.id] = place;
    }
    for (final place in themePlaces) {
      byId[place.id] = place;
    }

    final merged = <RoutePlace>[];
    for (final place in _visiblePlaces) {
      final next = byId[place.id];
      if (next != null && allowedIds.contains(place.id)) {
        merged.add(next);
      }
    }

    final mergedIds = merged.map((p) => p.id).toSet();
    for (final place in selectedPlaces) {
      if (allowedIds.contains(place.id) && !mergedIds.contains(place.id)) {
        merged.add(byId[place.id] ?? place);
        mergedIds.add(place.id);
      }
    }
    for (final place in themePlaces) {
      if (!mergedIds.contains(place.id)) {
        merged.add(place);
        mergedIds.add(place.id);
      }
    }
    return merged;
  }

  List<RoutePlace> _selectedInVisibleOrder(
    List<RoutePlace> visiblePlaces, {
    int? extraSelectedId,
  }) {
    final selectedIds = {..._selectedIds};
    if (extraSelectedId != null) selectedIds.add(extraSelectedId);
    return visiblePlaces
        .where((place) => selectedIds.contains(place.id))
        .toList(growable: false);
  }

  bool _placeHasTopic(RoutePlace place, String topicName) {
    final normalized = _normalizeTopicName(topicName);
    if (normalized.isEmpty) return true;
    return _parseLocationTopics(place.topic).contains(normalized);
  }

  Set<String> _parseLocationTopics(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return const <String>{};

    final bracketMatch = RegExp(r'[\[【](.*)[\]】]').firstMatch(value);
    final inner = bracketMatch?.group(1) ?? value;
    return inner
        .split(RegExp(r'[\.。,，、;；\s]+'))
        .map(_normalizeTopicName)
        .where((topic) => topic.isNotEmpty)
        .toSet();
  }

  String _normalizeTopicName(String value) {
    return value.replaceAll(RegExp(r'^[\[【]+|[\]】]+$'), '').trim();
  }

  Set<int> get _selectedIds => _selected.map((p) => p.id).toSet();

  List<RoutePlace> get _markerPlaces => _visiblePlaces;

  void _addPlace(RoutePlace place) {
    if (_selectedIds.contains(place.id)) return;
    setState(() {
      _selected = _selectedInVisibleOrder(
        _visiblePlaces,
        extraSelectedId: place.id,
      );
    });
    widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
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
  }

  void _clearAllPlaces() {
    setState(() {
      _selected = const [];
      _visiblePlaces = _mergeVisiblePlaces(_themePlaces, _selected);
    });
    widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _clearAllPlaces();
    }
  }

  void _reorderVisiblePlaces(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= _visiblePlaces.length) return;
    if (newIndex < 0 || newIndex >= _visiblePlaces.length) return;

    setState(() {
      final updated = [..._visiblePlaces];
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _visiblePlaces = updated;
      _selected = _selectedInVisibleOrder(_visiblePlaces);
    });
    widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
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
    final places = _markerPlaces;
    if (places.isEmpty || _mapController == null) return;

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;

    for (final place in places) {
      if (!place.latitude.isFinite || !place.longitude.isFinite) continue;
      minLat = mathMin(minLat, place.latitude);
      maxLat = mathMax(maxLat, place.latitude);
      minLon = mathMin(minLon, place.longitude);
      maxLon = mathMax(maxLon, place.longitude);
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

  @override
  Widget build(BuildContext context) {
    final totalHeight = MediaQuery.sizeOf(context).height;
    final panelH = totalHeight * _panelFraction;

    if (_loading && _allPlaces.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '加载失败: $_error',
            style: const TextStyle(color: AppColors.sageMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
              markers: _markerPlaces.map((place) {
                final selectedIndex = _selected.indexWhere(
                  (item) => item.id == place.id,
                );
                final marker = Marker(
                  position: LatLng(place.latitude, place.longitude),
                  infoWindow: InfoWindow(
                    title: selectedIndex >= 0
                        ? '${selectedIndex + 1}. ${place.name}'
                        : place.name,
                  ),
                );
                marker.setIdForCopy('marker-${place.id}');
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
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sageBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.place, size: 15, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      '已选地点 (${_selected.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sageText,
                      ),
                    ),
                    const Spacer(),
                    _AddPlaceButton(
                      onTap: () => _navigateToAddPlace(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
        Container(height: 0.5, color: AppColors.sageBorder),
        Expanded(
          child: _selected.isEmpty
              ? _EmptyHint(
                  icon: Icons.add_location_alt_outlined,
                  text: '点击右上角添加地点',
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
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
                    return _SelectedPlaceTile(
                      key: ValueKey('selected-${place.name}'),
                      place: place,
                      index: i,
                      onRemove: () => _confirmRemovePlace(place),
                    );
                  },
                ),
        ),
        // 清空全部按钮
        if (_selected.isNotEmpty)
          GestureDetector(
            onTap: _confirmClearAll,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                  const SizedBox(width: 6),
                  Text(
                    '清空全部地点',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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
  }

  Future<void> _navigateToAddPlace() async {
    final result = await Navigator.of(context).push<List<RoutePlace>>(
      MaterialPageRoute(
        builder: (context) => AddPlacePage(
          figure: widget.figure,
          currentSelectedPlaces: _selected,
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        // 合并新选择的地点（按名称去重，数据库 id 可能重复）
        final existingNames = _selected.map((p) => p.name).toSet();
        final newPlaces = result.where((p) => !existingNames.contains(p.name)).toList();
        _selected = [..._selected, ...newPlaces];
      });
      widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMapToMarkers();
      });
    }
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

class _AddPlaceButton extends StatelessWidget {
  const _AddPlaceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text(
              '添加地点',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedPlaceTile extends StatelessWidget {
  const _SelectedPlaceTile({
    super.key,
    required this.place,
    required this.index,
    required this.onRemove,
  });

  final RoutePlace place;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${place.name}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      onDismissed: (_) => onRemove(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sageBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A2B2724),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.sageText,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sageText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((place.topic ?? place.categories ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      place.topic?.isNotEmpty == true
                          ? place.topic!
                          : place.categories!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.sageMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // 拖拽手柄
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(
                  Icons.drag_indicator,
                  size: 18,
                  color: AppColors.sageMuted,
                ),
              ),
            ),
            // 垃圾桶删除按钮
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.sageMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
