import 'package:flutter/material.dart';

import '../../../data/location_repository.dart';
import '../../../data/topic_repository.dart';
import '../../../models/celebrity_profile.dart';
import '../../../models/location_record.dart';
import '../../../models/topic_record.dart';
import '../../../route_planning/models/route_place.dart';
import '../../../theme/color_schemes.dart';

/// Compact place picker designed to be presented as a modal bottom sheet.
/// Search and topic filtering remain on the same surface, so no secondary page
/// is required to select places under a topic.
class AddPlacePage extends StatefulWidget {
  const AddPlacePage({
    super.key,
    required this.figure,
    required this.currentSelectedPlaces,
  });

  final CelebrityProfile? figure;
  final List<RoutePlace> currentSelectedPlaces;

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  final Set<String> _selectedPlaceNames = <String>{};
  final TextEditingController _searchController = TextEditingController();

  List<LocationRecord> _allLocations = const <LocationRecord>[];
  List<TopicRecord> _topics = const <TopicRecord>[];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _selectedTopic;

  @override
  void initState() {
    super.initState();
    _selectedPlaceNames.addAll(widget.currentSelectedPlaces.map((p) => p.name));
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      const locationRepo = LocationRepository();
      final locations = List<LocationRecord>.from(
        await locationRepo.fetchLocations(),
      );
      locations.removeWhere((location) => !_hasValidCoordinates(location));
      final topics = widget.figure == null
          ? <TopicRecord>[]
          : await const TopicRepository().fetchTopicsByCelebrity(
              widget.figure!.name,
            );
      locations.sort((a, b) => a.nameModern.compareTo(b.nameModern));
      if (!mounted) return;
      setState(() {
        _allLocations = locations;
        _topics = topics;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  int get _selectedCount => _selectedPlaceNames.length;

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

  void _togglePlace(String placeName) {
    setState(() {
      if (!_selectedPlaceNames.add(placeName)) {
        _selectedPlaceNames.remove(placeName);
      }
    });
  }

  void _clearSelected() {
    setState(() => _selectedPlaceNames.clear());
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

  bool _matchesTopic(LocationRecord location) {
    final topic = _selectedTopic;
    if (topic == null) return true;
    return _parseLocationTopics(
      location.topic,
    ).contains(_normalizeTopicName(topic));
  }

  bool _matchesSearch(LocationRecord location) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return location.nameModern.toLowerCase().contains(query) ||
        (location.topic?.toLowerCase().contains(query) ?? false) ||
        location.categories.any(
          (category) => category.toLowerCase().contains(query),
        );
  }

  List<LocationRecord> get _visibleLocations {
    return _allLocations
        .where(
          (location) => _matchesTopic(location) && _matchesSearch(location),
        )
        .toList();
  }

  List<RoutePlace> _buildSelectedPlaces() {
    final byName = <String, LocationRecord>{
      for (final location in _allLocations) location.nameModern: location,
    };
    final result = <RoutePlace>[];
    final addedNames = <String>{};
    var fallbackId = 900000;

    RoutePlace fromLocation(LocationRecord location) {
      if (!_hasValidCoordinates(location)) {
        throw FormatException('地点“${location.nameModern}”缺少有效经纬度');
      }
      return RoutePlace(
        id: location.id > 0 ? location.id : fallbackId++,
        name: location.nameModern,
        latitude: location.coordinates[1],
        longitude: location.coordinates[0],
        averageVisitDurationMin: location.averageVisitDurationMin,
        topic: location.topic,
        categories: location.categories.join(', '),
      );
    }

    // Keep the user's existing route order for places that remain selected.
    for (final place in widget.currentSelectedPlaces) {
      if (!_selectedPlaceNames.contains(place.name) ||
          !addedNames.add(place.name)) {
        continue;
      }
      final location = byName[place.name];
      result.add(location == null ? place : fromLocation(location));
    }

    // Append newly selected places in a predictable alphabetical order.
    for (final location in _allLocations) {
      if (_selectedPlaceNames.contains(location.nameModern) &&
          addedNames.add(location.nameModern)) {
        result.add(fromLocation(location));
      }
    }
    return result;
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_buildSelectedPlaces());
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxSheetHeight = media.size.height * 0.88;
    final minSheetHeight = maxSheetHeight < 300.0 ? maxSheetHeight : 300.0;
    final desiredSheetHeight = maxSheetHeight - media.viewInsets.bottom;
    final sheetHeight = desiredSheetHeight
        .clamp(minSheetHeight, maxSheetHeight)
        .toDouble();
    final visibleLocations = _visibleLocations;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: sheetHeight,
          child: Material(
            color: const Color(0xFFFFFFFF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 9),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.sageBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                _buildHeader(),
                _buildSearchField(),
                _buildTopicFilters(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? _buildError()
                      : visibleLocations.isEmpty
                      ? const Center(
                          child: Text(
                            '没有符合条件的地点',
                            style: TextStyle(color: AppColors.sageMuted),
                          ),
                        )
                      : ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          itemCount: visibleLocations.length,
                          itemBuilder: (context, index) {
                            final location = visibleLocations[index];
                            return _PlaceListTile(
                              key: ValueKey('place-${location.nameModern}'),
                              location: location,
                              isSelected: _selectedPlaceNames.contains(
                                location.nameModern,
                              ),
                              onToggle: () => _togglePlace(location.nameModern),
                            );
                          },
                        ),
                ),
                _BottomActionBar(
                  selectedCount: _selectedCount,
                  onConfirm: _confirmSelection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '添加地点',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.sageText,
              ),
            ),
          ),
          if (_selectedCount > 0)
            TextButton(onPressed: _clearSelected, child: const Text('清空')),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.sageText),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: '搜索地点、主题或分类',
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.sageBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.sageBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicFilters() {
    if (_topics.isEmpty) return const SizedBox(height: 2);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _topics.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final topicName = index == 0 ? null : _topics[index - 1].name;
          final selected = _selectedTopic == topicName;
          return InkWell(
            onTap: () => setState(() => _selectedTopic = topicName),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(2, 7, 2, 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                topicName ?? '全部',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppColors.primaryLight : AppColors.sageText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.sageMuted),
            const SizedBox(height: 8),
            Text(
              '地点加载失败\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.sageMuted),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadData();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceListTile extends StatelessWidget {
  const _PlaceListTile({
    super.key,
    required this.location,
    required this.isSelected,
    required this.onToggle,
  });

  final LocationRecord location;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      if ((location.averageVisitDurationMin ?? 0) > 0)
        '${location.averageVisitDurationMin} 分钟',
      if (location.categories.isNotEmpty)
        location.categories.take(2).join(' · '),
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? AppColors.primaryLight.withValues(alpha: 0.09)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.sageBorder.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.add_location_alt_outlined,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.sageMuted,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.nameModern,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.sageText,
                        ),
                      ),
                      if (location.topic?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          location.topic!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.sageMuted,
                          ),
                        ),
                      ],
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.sageMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.selectedCount,
    required this.onConfirm,
  });

  final int selectedCount;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.sageBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedCount == 0 ? '未选择地点' : '已选 $selectedCount 个地点',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selectedCount == 0
                    ? AppColors.sageMuted
                    : AppColors.primaryLight,
              ),
            ),
          ),
          SizedBox(
            width: 138,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageText,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                '完成',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
