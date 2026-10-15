import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/location_repository.dart';
import '../../../data/dongpo_site_repository.dart';
import '../../../data/planning_catalog_repository.dart';
import '../../../components/place_metadata_tags.dart';
import '../../../components/planning_place_details.dart';
import '../../../models/heritage_grade.dart';
import '../../../data/poi_celebrity_relation_repository.dart';
import '../../../data/topic_repository.dart';
import '../../../models/celebrity_profile.dart';
import '../../../models/location_record.dart';
import '../../../models/poi_celebrity_relation_record.dart';
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
    this.locationRepository = const LocationRepository(),
    this.relationRepository = const PoiCelebrityRelationRepository(),
    this.topicRepository = const TopicRepository(),
    this.dongpoRepository = const DongpoSiteRepository(),
  });

  final CelebrityProfile? figure;
  final List<RoutePlace> currentSelectedPlaces;
  final LocationRepository locationRepository;
  final PoiCelebrityRelationRepository relationRepository;
  final TopicRepository topicRepository;
  final DongpoSiteRepository? dongpoRepository;

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  final Set<String> _selectedPlaceNames = <String>{};
  final TextEditingController _searchController = TextEditingController();

  List<LocationRecord> _allLocations = const <LocationRecord>[];
  List<TopicRecord> _topics = const <TopicRecord>[];
  Set<String>? _relatedLocationNames;
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _selectedTopic;
  String? _selectedTheme;
  HeritageGrade? _selectedGrade;
  bool _isLocalCopy = false;
  bool _allowReferenceLocations = false;

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
      final dongpo = widget.dongpoRepository;
      final catalog = dongpo == null
          ? null
          : await PlanningCatalogRepository(
              locations: widget.locationRepository,
              topics: widget.topicRepository,
              dongpo: dongpo,
            ).fetchCatalog();
      final locations = List<LocationRecord>.from(
        catalog?.locations ?? await widget.locationRepository.fetchLocations(),
      );
      final figure = widget.figure;
      final relatedLocationNames = figure == null
          ? null
          : (await widget.relationRepository
                    .fetchRelationsByCelebrity(figure.name)
                    .timeout(const Duration(seconds: 8))
                    .catchError((Object error) {
                      if (catalog != null && isDongpoFigure(figure.name)) {
                        _isLocalCopy = true;
                        return <PoiCelebrityRelationRecord>[];
                      }
                      throw error;
                    }))
                .map((relation) => relation.locationName?.trim() ?? '')
                .where((name) => name.isNotEmpty)
                .toSet();
      final topics = catalog == null
          ? await widget.topicRepository.fetchTopicsByCelebrity(
              figure?.name ?? '',
            )
          : catalog.topics
                .where(
                  (topic) =>
                      figure == null ||
                      topic.celebrity == figure.name ||
                      (isDongpoFigure(figure.name) &&
                          isDongpoFigure(topic.celebrity)),
                )
                .toList();
      if (figure == null || isDongpoFigure(figure.name)) {
        relatedLocationNames?.addAll(
          locations
              .where((location) => location.dongpoSiteId != null)
              .map((location) => location.nameModern),
        );
      }
      // The curated display name may replace a former address-like name.
      for (final selected in widget.currentSelectedPlaces) {
        for (final location in locations) {
          if (selected.id != 0 && location.id == selected.id) {
            _selectedPlaceNames.remove(selected.name);
            _selectedPlaceNames.add(location.nameModern);
          }
        }
      }
      locations.sort((a, b) => a.nameModern.compareTo(b.nameModern));
      if (!mounted) return;
      setState(() {
        _allLocations = locations;
        _relatedLocationNames = relatedLocationNames;
        _topics = topics;
        _isLocalCopy = _isLocalCopy || (catalog?.isLocalCopy ?? false);
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

  bool _canPlanRoute(LocationRecord location) =>
      location.hasValidCoordinates &&
      (location.routeEligible != false || _allowReferenceLocations);

  void _setAllowReferenceLocations(bool value) {
    setState(() {
      _allowReferenceLocations = value;
      if (!value) {
        _selectedPlaceNames.removeAll(
          _allLocations
              .where((location) => location.routeEligible == false)
              .map((location) => location.nameModern),
        );
      }
    });
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

  bool _matchesTopic(LocationRecord location) {
    final topic = _selectedTopic;
    if (topic == null) return true;
    return locationTopics(location).contains(topic);
  }

  bool _matchesSearch(LocationRecord location) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return location.nameModern.toLowerCase().contains(query) ||
        (location.nameAncient?.toLowerCase().contains(query) ?? false) ||
        location.themes.any((theme) => theme.toLowerCase().contains(query)) ||
        (location.heritageGrade?.label.contains(query) ?? false) ||
        (location.topic?.toLowerCase().contains(query) ?? false) ||
        location.categories.any(
          (category) => category.toLowerCase().contains(query),
        );
  }

  List<LocationRecord> get _visibleLocations {
    return _allLocations
        .where(
          (location) =>
              (_relatedLocationNames?.contains(location.nameModern.trim()) ??
                  true) &&
              _matchesTopic(location) &&
              (_selectedTheme == null ||
                  location.themes.contains(_selectedTheme)) &&
              (_selectedGrade == null ||
                  location.heritageGrade == _selectedGrade) &&
              _matchesSearch(location),
        )
        .toList();
  }

  List<RoutePlace> _buildSelectedPlaces() {
    final byName = <String, LocationRecord>{
      for (final location in _allLocations) location.nameModern: location,
    };
    final result = <RoutePlace>[];
    final addedNames = <String>{};
    RoutePlace fromLocation(LocationRecord location) {
      if (!_canPlanRoute(location)) {
        throw FormatException('地点“${location.nameModern}”缺少有效经纬度');
      }
      return RoutePlace.fromLocation(location);
    }

    // Keep the user's existing route order for places that remain selected.
    for (final place in widget.currentSelectedPlaces) {
      final match = _allLocations.where(
        (location) => place.id != 0 && location.id == place.id,
      );
      final name = match.isEmpty ? place.name : match.first.nameModern;
      if (!_selectedPlaceNames.contains(name) || !addedNames.add(name)) {
        continue;
      }
      final location = byName[name];
      result.add(
        location == null || !location.canPlanRoute
            ? place
            : fromLocation(location),
      );
    }

    // Append newly selected places in a predictable alphabetical order.
    for (final location in _allLocations) {
      if (_canPlanRoute(location) &&
          _selectedPlaceNames.contains(location.nameModern) &&
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
    final desktop = kIsWeb && media.size.width >= 1024;
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
            color: AppColors.sageCard,
            borderRadius: desktop
                ? BorderRadius.circular(8)
                : const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (!desktop) ...[
                  const SizedBox(height: 9),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.sageBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
                _buildHeader(),
                _buildSearchField(),
                _buildTopicFilters(),
                if (!_loading && _error == null) _buildEditorialFilters(),
                if (!_loading &&
                    _error == null &&
                    _allLocations.any(
                      (location) =>
                          location.routeEligible == false &&
                          location.hasValidCoordinates &&
                          (_relatedLocationNames?.contains(
                                location.nameModern,
                              ) ??
                              true),
                    ))
                  SwitchListTile.adaptive(
                    title: const Text(
                      '允许选择参考位置',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      '接受位置未核实的地点（需有坐标）',
                      style: TextStyle(fontSize: 11),
                    ),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    value: _allowReferenceLocations,
                    onChanged: _setAllowReferenceLocations,
                  ),
                if (_isLocalCopy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('部分资料使用本地副本', style: TextStyle(fontSize: 11)),
                  ),
                if (!_loading && _error == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${visibleLocations.length} 个地点 · ${visibleLocations.where(_canPlanRoute).length} 个可加入路线',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.sageMuted,
                        ),
                      ),
                    ),
                  ),
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
                              onToggle:
                                  _canPlanRoute(location) ||
                                      _selectedPlaceNames.contains(
                                        location.nameModern,
                                      )
                                  ? () => _togglePlace(location.nameModern)
                                  : null,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '添加地点',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sageText,
                  ),
                ),
                if (widget.figure != null)
                  Text(
                    '仅显示${widget.figure!.name}相关景点',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.sageMuted,
                    ),
                  ),
              ],
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
          fillColor: AppColors.brandWash,
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
            onTap: () => setState(() {
              _selectedTopic = topicName;
              _selectedTheme = null;
            }),
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

  Widget _buildEditorialFilters() {
    final themes =
        _allLocations
            .where(
              (location) =>
                  (_relatedLocationNames?.contains(location.nameModern) ??
                      true) &&
                  _matchesTopic(location),
            )
            .expand((location) => location.themes)
            .where((label) => !_topics.any((topic) => topic.name == label))
            .toSet()
            .toList()
          ..sort();
    if (!_allLocations.any((location) => location.heritageGrade != null)) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (themes.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final theme in themes)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(theme, style: const TextStyle(fontSize: 11)),
                      selected: _selectedTheme == theme,
                      onSelected: (selected) => setState(
                        () => _selectedTheme = selected ? theme : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        SizedBox(
          height: 38,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              const Center(
                child: Text('遗存等级  ', style: TextStyle(fontSize: 11)),
              ),
              for (final grade in HeritageGrade.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    avatar: Icon(Icons.circle, size: 9, color: grade.color),
                    label: Text(
                      grade.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _selectedGrade == grade,
                    onSelected: (selected) => setState(
                      () => _selectedGrade = selected ? grade : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      if ((location.averageVisitDurationMin ?? 0) > 0)
        '${location.averageVisitDurationMin} 分钟',
      if (!location.hasValidCoordinates)
        '暂无坐标 · 暂不可加入路线'
      else if (location.routeEligible == false)
        onToggle == null ? '参考位置 · 打开开关后可选' : '参考位置',
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? AppColors.primaryLight.withValues(alpha: 0.09)
            : AppColors.brandWash,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onToggle ?? () => showPlanningPlaceDetails(context, location),
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
                    onToggle == null
                        ? Icons.location_off_outlined
                        : isSelected
                        ? Icons.check
                        : Icons.add_location_alt_outlined,
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
                      const SizedBox(height: 5),
                      PlaceMetadataTags(
                        categories: location.categories,
                        grade: location.heritageGrade,
                        themes: location.themes
                            .where((label) => !label.startsWith('苏轼·'))
                            .toList(),
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
                IconButton(
                  tooltip: '查看${location.nameModern}详情',
                  onPressed: () => showPlanningPlaceDetails(context, location),
                  icon: const Icon(Icons.info_outline, size: 20),
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
        color: AppColors.sageCard,
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
