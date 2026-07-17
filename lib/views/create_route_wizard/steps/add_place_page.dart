import 'package:flutter/material.dart';

import '../../../data/location_repository.dart';
import '../../../data/topic_repository.dart';
import '../../../models/celebrity_profile.dart';
import '../../../models/location_record.dart';
import '../../../models/topic_record.dart';
import '../../../route_planning/models/route_place.dart';
import '../../../theme/color_schemes.dart';

/// 添加地点页面
/// 通过 Tab 切换显示：搜索地点 / 按主题选择
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

class _AddPlacePageState extends State<AddPlacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// 选中的地点名称集合（数据库 id 可能重复，改用名称作为唯一标识）
  final Set<String> _selectedPlaceNames = {};

  List<LocationRecord> _allLocations = [];
  List<TopicRecord> _topics = [];
  bool _loading = true;

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  List<LocationRecord> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 初始化已有选中的地点
    for (final place in widget.currentSelectedPlaces) {
      _selectedPlaceNames.add(place.name);
    }

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      const locationRepo = LocationRepository();
      final locations = await locationRepo.fetchLocations();
      final topics = widget.figure != null
          ? await const TopicRepository().fetchTopicsByCelebrity(widget.figure!.name)
          : <TopicRecord>[];

      if (mounted) {
        setState(() {
          _allLocations = locations;
          _topics = topics;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  /// 切换地点选中状态（按名称标识）
  void togglePlace(String placeName) {
    setState(() {
      if (_selectedPlaceNames.contains(placeName)) {
        _selectedPlaceNames.remove(placeName);
      } else {
        _selectedPlaceNames.add(placeName);
      }
    });
  }

  /// 批量切换主题下地点的选中状态
  void toggleAllForTopic(List<String> placeNames, bool select) {
    setState(() {
      for (final name in placeNames) {
        if (select) {
          _selectedPlaceNames.add(name);
        } else {
          _selectedPlaceNames.remove(name);
        }
      }
    });
  }

  /// 获取选中的地点数量
  int get selectedCount => _selectedPlaceNames.length;

  /// 构建选中的 RoutePlace 列表
  List<RoutePlace> _buildSelectedPlaces() {
    final result = <RoutePlace>[];
    var fallbackId = 900000; // 防止数据库 id=0 导致下游去重失效
    for (final loc in _allLocations) {
      if (_selectedPlaceNames.contains(loc.nameModern)) {
        final id = loc.id > 0 ? loc.id : fallbackId++;
        result.add(RoutePlace(
          id: id,
          name: loc.nameModern,
          latitude: loc.coordinates.length >= 2 ? loc.coordinates[1].toDouble() : 0,
          longitude: loc.coordinates.isNotEmpty ? loc.coordinates[0].toDouble() : 0,
          averageVisitDurationMin: loc.averageVisitDurationMin,
          topic: loc.topic,
          categories: loc.categories.join(', '),
        ));
      }
    }
    return result;
  }

  void _onConfirm() {
    final selectedPlaces = _buildSelectedPlaces();
    Navigator.of(context).pop(selectedPlaces);
  }

  void _performSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      setState(() {
        _searching = false;
        _searchResults = [];
      });
      return;
    }

    final queryLower = trimmedQuery.toLowerCase();
    setState(() {
      _searching = true;
      _searchResults = _allLocations.where((loc) {
        // 匹配地点名称
        if (loc.nameModern.toLowerCase().contains(queryLower)) {
          return true;
        }
        // 匹配主题
        if (loc.topic?.toLowerCase().contains(queryLower) ?? false) {
          return true;
        }
        // 匹配分类
        for (final category in loc.categories) {
          if (category.toLowerCase().contains(queryLower)) {
            return true;
          }
        }
        return false;
      }).toList();
    });
  }

  void _clearSearch() {
    setState(() {
      _searching = false;
      _searchResults = [];
    });
    _searchController.clear();
  }

  List<LocationRecord> _getPlacesForTopic(String topicName) {
    return _allLocations.where((loc) {
      final topics = _parseLocationTopics(loc.topic ?? '');
      return topics.contains(_normalizeTopicName(topicName));
    }).toList();
  }

  Set<String> _parseLocationTopics(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return {};

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

  void _navigateToThemePlaces(TopicRecord topic, List<LocationRecord> places) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ThemePlaceSelectPage(
          topic: topic,
          places: places,
          selectedPlaceNames: _selectedPlaceNames,
          onToggle: togglePlace,
          onToggleAll: toggleAllForTopic,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.sageText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '添加地点',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.sageText,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.sageMuted,
          indicatorColor: AppColors.primaryLight,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '搜索地点'),
            Tab(text: '按主题选择'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildThemeTab(),
              ],
            ),
      bottomNavigationBar: _BottomActionBar(
        selectedCount: selectedCount,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: _onConfirm,
      ),
    );
  }

  /// 构建搜索 Tab
  Widget _buildSearchTab() {
    final displayPlaces = _searching ? _searchResults : _allLocations;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索地点名称或分类...',
              prefixIcon: const Icon(Icons.search, color: AppColors.sageMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.sageMuted),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.sageBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.sageBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _performSearch,
          ),
        ),
        Expanded(
          child: displayPlaces.isEmpty
              ? Center(
                  child: Text(
                    _searching ? '未找到匹配地点' : '暂无地点数据',
                    style: const TextStyle(color: AppColors.sageMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayPlaces.length,
                  itemBuilder: (context, index) {
                    final place = displayPlaces[index];
                    final isSelected = _selectedPlaceNames.contains(place.nameModern);
                    return _PlaceListTile(
                      key: ValueKey('place-${place.nameModern}'),
                      name: place.nameModern,
                      topic: place.topic,
                      isSelected: isSelected,
                      onToggle: () => togglePlace(place.nameModern),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 构建主题 Tab
  Widget _buildThemeTab() {
    if (_topics.isEmpty) {
      return const Center(
        child: Text(
          '暂无关联主题',
          style: TextStyle(color: AppColors.sageMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final topic = _topics[index];
        final places = _getPlacesForTopic(topic.name);
        final selectedCount = places.where((p) => _selectedPlaceNames.contains(p.nameModern)).length;

        return _TopicCard(
          key: ValueKey('topic-${topic.id}'),
          topic: topic,
          placeCount: places.length,
          selectedCount: selectedCount,
          onTap: () => _navigateToThemePlaces(topic, places),
          index: index,
        );
      },
    );
  }
}

/// 主题卡片组件
class _TopicCard extends StatelessWidget {
  const _TopicCard({
    super.key,
    required TopicRecord topic,
    required int placeCount,
    required int selectedCount,
    required VoidCallback onTap,
    required int index,
  }) : _topic = topic,
       _placeCount = placeCount,
       _selectedCount = selectedCount,
       _onTap = onTap,
       _index = index;

  final TopicRecord _topic;
  final int _placeCount;
  final int _selectedCount;
  final VoidCallback _onTap;
  final int _index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + _index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _selectedCount > 0
                ? AppColors.primaryLight.withValues(alpha: 0.5)
                : AppColors.sageBorder,
          ),
        ),
        elevation: 0,
        color: Colors.white,
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _topic.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sageText,
                        ),
                      ),
                      if (_topic.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          _topic.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.sageMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '$_placeCount 个地点${_selectedCount > 0 ? '（已选 $_selectedCount）' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedCount > 0
                              ? AppColors.primaryLight
                              : AppColors.sageMuted,
                          fontWeight: _selectedCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.sageMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 主题地点选择二级页面
class ThemePlaceSelectPage extends StatelessWidget {
  const ThemePlaceSelectPage({
    super.key,
    required this.topic,
    required this.places,
    required this.selectedPlaceNames,
    required this.onToggle,
    required this.onToggleAll,
  });

  final TopicRecord topic;
  final List<LocationRecord> places;
  final Set<String> selectedPlaceNames;
  final void Function(String) onToggle;
  final void Function(List<String>, bool) onToggleAll;

  @override
  Widget build(BuildContext context) {
    return ThemePlaceSelectContent(
      topic: topic,
      places: places,
      selectedPlaceNames: selectedPlaceNames,
      onToggle: onToggle,
      onToggleAll: onToggleAll,
    );
  }
}

/// 主题地点选择内容（使用 StatefulWidget 管理本地状态）
class ThemePlaceSelectContent extends StatefulWidget {
  const ThemePlaceSelectContent({
    super.key,
    required this.topic,
    required this.places,
    required this.selectedPlaceNames,
    required this.onToggle,
    required this.onToggleAll,
  });

  final TopicRecord topic;
  final List<LocationRecord> places;
  final Set<String> selectedPlaceNames;
  final void Function(String) onToggle;
  final void Function(List<String>, bool) onToggleAll;

  @override
  State<ThemePlaceSelectContent> createState() => _ThemePlaceSelectContentState();
}

class _ThemePlaceSelectContentState extends State<ThemePlaceSelectContent> {
  bool isPlaceSelected(String placeName) {
    return widget.selectedPlaceNames.contains(placeName);
  }

  int get selectedCount {
    return widget.places.where((p) => isPlaceSelected(p.nameModern)).length;
  }

  void _handleToggle(String placeName) {
    widget.onToggle(placeName);
    setState(() {});
  }

  void _handleToggleAll(bool select) {
    final names = widget.places.map((p) => p.nameModern).toList();
    widget.onToggleAll(names, select);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.sageText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.topic.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.sageText,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 主题描述卡片
          if (widget.topic.description?.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.topic.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.sageText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 全选/取消全选
          if (widget.places.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${widget.places.length} 个地点',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.sageMuted,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _handleToggleAll(true),
                    child: const Text('全选'),
                  ),
                  TextButton(
                    onPressed: () => _handleToggleAll(false),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),

          // 地点列表
          Expanded(
            child: widget.places.isEmpty
                ? const Center(
                    child: Text(
                      '该主题下暂无地点',
                      style: TextStyle(color: AppColors.sageMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.places.length,
                    itemBuilder: (context, index) {
                      final place = widget.places[index];
                      return _PlaceListTile(
                        key: ValueKey('theme-place-${place.nameModern}'),
                        name: place.nameModern,
                        topic: place.topic,
                        isSelected: isPlaceSelected(place.nameModern),
                        onToggle: () => _handleToggle(place.nameModern),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 地点列表项 - 右侧加号/勾选
class _PlaceListTile extends StatelessWidget {
  const _PlaceListTile({
    super.key,
    required this.name,
    required this.topic,
    required this.isSelected,
    required this.onToggle,
  });

  final String name;
  final String? topic;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryLight.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : AppColors.sageBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.sageText,
                        ),
                      ),
                      if (topic?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          topic!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.sageMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // 右侧加号/勾选
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.sageBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? Icons.check : Icons.add,
                        key: ValueKey(isSelected),
                        size: 20,
                        color: isSelected ? Colors.white : AppColors.sageMuted,
                      ),
                    ),
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

/// 底部操作栏
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.selectedCount,
    required this.onCancel,
    required this.onConfirm,
  });

  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.sageBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '取消',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: selectedCount > 0 ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCount > 0
                    ? AppColors.primaryLight
                    : AppColors.sageBorder,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                selectedCount > 0 ? '确定添加 ($selectedCount)' : '请选择地点',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
