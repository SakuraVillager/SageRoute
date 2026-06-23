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
  late List<RoutePlace> _selected;
  late Future<List<TopicRecord>> _topicsFuture;
  bool _loading = true;
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

      setState(() {
        _allPlaces = places;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMapToMarkers();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Set<int> get _selectedIds => _selected.map((p) => p.id).toSet();

  List<RoutePlace> get _unselected =>
      _allPlaces.where((p) => !_selectedIds.contains(p.id)).toList();

  List<RoutePlace> get _markerPlaces {
    final byId = <int, RoutePlace>{};
    for (final place in _allPlaces) {
      byId[place.id] = place;
    }
    for (final place in _selected) {
      byId[place.id] = place;
    }
    return byId.values.toList(growable: false);
  }

  void _addPlace(RoutePlace place) {
    if (_selectedIds.contains(place.id)) return;
    setState(() => _selected = [..._selected, place]);
    widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
  }

  void _removePlace(RoutePlace place) {
    setState(() {
      _selected = _selected.where((p) => p.id != place.id).toList();
    });
    widget.onLocationsChanged(List<RoutePlace>.unmodifiable(_selected));
  }

  void _reorderSelected(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final updated = [..._selected];
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _selected = updated;
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

    if (_loading) return const Center(child: CircularProgressIndicator());
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
        Positioned(
          top: 8,
          left: 20,
          right: 20,
          child: _ThemeStrip(
            future: _topicsFuture,
            selectedTopicId: widget.topicId,
            onSelect: widget.onTopicChanged,
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
              const Row(
                children: [
                  Expanded(
                    child: _PanelHeader(
                      icon: Icons.check_circle_outline,
                      label: '已选地点',
                      accent: AppColors.primaryLight,
                    ),
                  ),
                  SizedBox(
                    height: 28,
                    child: VerticalDivider(
                      width: 1,
                      color: AppColors.sageBorder,
                    ),
                  ),
                  Expanded(
                    child: _PanelHeader(
                      icon: Icons.place_outlined,
                      label: '可用地点',
                      accent: AppColors.sageGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 0.5, color: AppColors.sageBorder),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _selected.isEmpty
                    ? const _EmptyHint(
                        icon: Icons.add_location_alt_outlined,
                        text: '从右侧添加地点',
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                          place: _selected[i],
                          index: i,
                          onRemove: () => _removePlace(_selected[i]),
                        ),
                      ),
              ),
              Container(
                width: 1,
                color: AppColors.sageBorder.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _unselected.isEmpty
                    ? const _EmptyHint(icon: Icons.done_all, text: '所有地点已选')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        itemCount: _unselected.length,
                        itemBuilder: (_, i) => _UnselectedTile(
                          key: ValueKey(_unselected[i].id),
                          place: _unselected[i],
                          onTap: () => _addPlace(_unselected[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeStrip extends StatelessWidget {
  const _ThemeStrip({
    required this.future,
    required this.selectedTopicId,
    required this.onSelect,
  });

  final Future<List<TopicRecord>> future;
  final String? selectedTopicId;
  final void Function(String id, String name) onSelect;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TopicRecord>>(
      future: future,
      builder: (context, snapshot) {
        final topics = snapshot.data ?? const <TopicRecord>[];
        final loading = snapshot.connectionState != ConnectionState.done;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '选择主题',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sageText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    loading ? '加载中' : '${topics.length} 个主题',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.sageMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (loading)
                const LinearProgressIndicator(minHeight: 2)
              else if (topics.isEmpty)
                const Text(
                  '暂无关联主题，可先从全部地点中选择',
                  style: TextStyle(fontSize: 12, color: AppColors.sageMuted),
                )
              else
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: topics.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      final selected = topic.id.toString() == selectedTopicId;
                      return _ThemeChip(
                        topic: topic,
                        selected: selected,
                        onTap: () => onSelect(topic.id.toString(), topic.name),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  final TopicRecord topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageText : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.sageText : AppColors.sageBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 13, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              topic.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.sageText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.sageText,
            ),
          ),
        ],
      ),
    );
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

class _SelectedTile extends StatelessWidget {
  const _SelectedTile({
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.sageText,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142B2724),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sageText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              place.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.drag_indicator,
                size: 16,
                color: Colors.white70,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnselectedTile extends StatelessWidget {
  const _UnselectedTile({super.key, required this.place, required this.onTap});

  final RoutePlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sageBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.sageBorder),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 13, color: AppColors.sageMuted),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                place.name,
                style: const TextStyle(fontSize: 13, color: AppColors.sageText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
