import '../navigation/app_navigation.dart';
import 'create_route_wizard/create_route_wizard.dart';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/bottom_nav.dart';
import '../components/ticket_card.dart';
import '../components/route_invitation_inbox.dart';
import '../models/saved_route.dart';
import '../theme/color_schemes.dart';
import 'route_preview/route_preview_page.dart';

/// Home page matching the Web version's Home.tsx layout.
///
/// Sections:
/// - Header: greeting + notification bell + avatar
/// - Search bar (UI placeholder, no real search logic)
///
/// Navigation is handled via optional callbacks.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.createdRoutesListenable,
    this.onRefreshRoutes,
    this.onDeleteRoute,
  });

  final ValueListenable<List<SavedRoute>>? createdRoutesListenable;
  final Future<void> Function()? onRefreshRoutes;
  final Future<void> Function(String routeId)? onDeleteRoute;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<SavedRoute> _items;
  VoidCallback? _listener;
  final Set<String> _deletingRouteIds = <String>{};
  final Set<String> _selectedRouteIds = <String>{};
  final Set<String> _selectedExampleIds = <String>{};
  final Set<String> _deletedExampleIds = <String>{};
  bool _examplesLoaded = false;
  bool _selectionMode = false;
  bool _bulkDeleting = false;
  int _inboxVersion = 0;

  Future<void> _refresh() async {
    await widget.onRefreshRoutes?.call();
    if (mounted) setState(() => _inboxVersion++);
  }

  static const _deletedExamplesPreferenceKey = 'home_deleted_example_routes';

  @override
  void initState() {
    super.initState();
    _items = widget.createdRoutesListenable != null
        ? List<SavedRoute>.from(widget.createdRoutesListenable!.value)
        : <SavedRoute>[];
    if (widget.createdRoutesListenable != null) {
      _listener = _onCreatedRoutesChanged;
      widget.createdRoutesListenable!.addListener(_listener!);
    }
    _loadDeletedExamples();
  }

  @override
  void dispose() {
    if (_listener != null) {
      widget.createdRoutesListenable!.removeListener(_listener!);
    }
    super.dispose();
  }

  void _onCreatedRoutesChanged() {
    final newList = widget.createdRoutesListenable!.value;
    if (listEquals(_items, newList) || !mounted) return;

    // Only a single newly saved route needs the insertion animation. Initial
    // sync can return many records at once; AnimatedList must be recreated
    // with the complete item count in that case.
    final insertedAtFront =
        newList.length == _items.length + 1 &&
        listEquals(
          newList.skip(1).map((route) => route.id).toList(),
          _items.map((route) => route.id).toList(),
        );
    if (insertedAtFront && _listKey.currentState != null) {
      _items = List<SavedRoute>.from(newList);
      _listKey.currentState!.insertItem(
        0,
        duration: const Duration(milliseconds: 450),
      );
      return;
    }

    setState(() {
      _items = List<SavedRoute>.from(newList);
      _selectedRouteIds.removeWhere(
        (id) => !newList.any((route) => route.id == id),
      );
      if (_items.isEmpty && _visibleExamples.isEmpty) _selectionMode = false;
      _listKey = GlobalKey<AnimatedListState>();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kIsWeb && MediaQuery.sizeOf(context).width >= 1024)
            _buildWebHeader()
          else
            _buildHeader(context),
          const SizedBox(height: 32),
          RouteInvitationInbox(
            key: ValueKey(_inboxVersion),
            onAccepted: _refresh,
          ),
          _buildTicketSection(),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      body: SafeArea(
        child: widget.onRefreshRoutes == null
            ? content
            : RefreshIndicator(onRefresh: _refresh, child: content),
      ),
    );
  }

  Widget _buildWebHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的旅程',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                '收藏沿途的故事，安排下一次出发。',
                style: TextStyle(color: AppColors.sageMuted, fontSize: 14),
              ),
            ],
          ),
        ),
        if (widget.onRefreshRoutes != null)
          IconButton(
            onPressed: _refresh,
            tooltip: '刷新行程',
            icon: const Icon(Icons.refresh, size: 20),
          ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => openAppPage(context, const CreateRouteWizard()),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('创建行程'),
        ),
      ],
    ),
  );

  // ── Header ──

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '你好，旅行者',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.sageMuted,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic, // Web: font-serif italic
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '准备好探索历史了吗？',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sageText,
                    letterSpacing: 1.5, // Web: tracking-wide
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Notification bell
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.brandLight,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.notifications_outlined, size: 20),
              color: AppColors.sageText,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          // Avatar with accent ring
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sageAccent, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=150',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.person_outline, color: AppColors.sageText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ticket Section ──

  Widget _buildTicketSection() {
    final visibleExamples = _visibleExamples;
    final canManageRoutes = _items.isNotEmpty && widget.onDeleteRoute != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canManageRoutes || visibleExamples.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectionMode
                        ? '已选择 ${_selectedRouteIds.length + _selectedExampleIds.length} 项'
                        : '我的行程',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sageText,
                    ),
                  ),
                ),
                if (_selectionMode) ...[
                  TextButton(
                    onPressed: _bulkDeleting ? null : _exitSelectionMode,
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: _bulkDeleting || _selectedTicketCount == 0
                        ? null
                        : _confirmBulkDelete,
                    child: Text('删除($_selectedTicketCount)'),
                  ),
                ] else
                  TextButton(
                    onPressed: () => setState(() => _selectionMode = true),
                    child: const Text('批量删除'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // AnimatedList for freshly created routes (insert animation)
          AnimatedList(
            key: _listKey,
            initialItemCount: _items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index, animation) {
              final route = _items[index];
              return SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Stack(
                    children: [
                      TicketCard(
                        title: route.title,
                        dateRange: route.dateRange,
                        memberText: route.accessRole == RouteAccessRole.owner
                            ? route.memberCount > 1
                                  ? '${route.memberCount} 人同行 · 我创建的'
                                  : '全新规划的旅程'
                            : '${route.memberCount} 人同行 · ${route.accessRole.label}',
                        duration: route.duration,
                        distance: route.distance,
                        onLongPress:
                            !route.canManage ||
                                widget.onDeleteRoute == null ||
                                _deletingRouteIds.contains(route.id) ||
                                _bulkDeleting
                            ? null
                            : () => _selectionMode
                                  ? _toggleSelection(route.id)
                                  : _showRouteActions(route),
                        onTap:
                            _selectionMode &&
                                route.canManage &&
                                widget.onDeleteRoute != null
                            ? () => _toggleSelection(route.id)
                            : () => _openRoute(route),
                      ),
                      if (_selectionMode &&
                          route.canManage &&
                          widget.onDeleteRoute != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IgnorePointer(
                            child: Icon(
                              _selectedRouteIds.contains(route.id)
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _selectedRouteIds.contains(route.id)
                                  ? AppColors.sageAccent
                                  : AppColors.sageMuted,
                              size: 24,
                            ),
                          ),
                        ),
                      if (_deletingRouteIds.contains(route.id))
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Preset example cards remain local placeholders, but support the
          // same long-press and bulk removal interactions as saved routes.
          for (final example in visibleExamples)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Stack(
                children: [
                  TicketCard(
                    title: example.title,
                    dateRange: example.dateRange,
                    memberText: example.memberText,
                    duration: example.duration,
                    distance: example.distance,
                    stampLine1: example.stampLine1,
                    stampLine2: example.stampLine2,
                    onLongPress: _bulkDeleting
                        ? null
                        : () => _selectionMode
                              ? _toggleExampleSelection(example.id)
                              : _showExampleActions(example),
                    onTap: _selectionMode
                        ? () => _toggleExampleSelection(example.id)
                        : _showExampleRouteNotice,
                  ),
                  if (_selectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IgnorePointer(
                        child: Icon(
                          _selectedExampleIds.contains(example.id)
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _selectedExampleIds.contains(example.id)
                              ? AppColors.sageAccent
                              : AppColors.sageMuted,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<_ExampleRoute> get _visibleExamples => !_examplesLoaded
      ? const <_ExampleRoute>[]
      : _exampleRoutes
            .where((example) => !_deletedExampleIds.contains(example.id))
            .toList(growable: false);

  Future<void> _loadDeletedExamples() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _deletedExampleIds.addAll(
        preferences.getStringList(_deletedExamplesPreferenceKey) ??
            const <String>[],
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load deleted example routes',
        name: 'SageRoute.HomePage',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!mounted) return;
    setState(() {
      _examplesLoaded = true;
      if (_items.isEmpty && _visibleExamples.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Future<void> _persistDeletedExamples(Set<String> ids) async {
    final updated = <String>{..._deletedExampleIds, ...ids};
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(
      _deletedExamplesPreferenceKey,
      updated.toList(growable: false),
    );
    if (!saved) throw StateError('示例删除状态未能保存');
    _deletedExampleIds.addAll(ids);
  }

  int get _selectedTicketCount =>
      _selectedRouteIds.length + _selectedExampleIds.length;

  Future<void> _openRoute(SavedRoute route) async {
    await openAppPage(
      context,
      RoutePreviewPage(routeId: route.id, initialRoute: route),
    );
    if (mounted) await widget.onRefreshRoutes?.call();
  }

  void _toggleSelection(String id) {
    if (_bulkDeleting || _deletingRouteIds.contains(id)) return;
    setState(() {
      if (!_selectedRouteIds.add(id)) _selectedRouteIds.remove(id);
    });
  }

  void _toggleExampleSelection(String id) {
    if (_bulkDeleting) return;
    setState(() {
      if (!_selectedExampleIds.add(id)) _selectedExampleIds.remove(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedRouteIds.clear();
      _selectedExampleIds.clear();
    });
  }

  Future<void> _showExampleActions(_ExampleRoute example) async {
    final delete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.sageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: AppColors.sageAccent,
            ),
            title: const Text('删除示例'),
            subtitle: Text(
              example.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(sheetContext).pop(true),
          ),
        ),
      ),
    );
    if (delete == true && mounted) await _confirmDeleteExample(example);
  }

  Future<void> _confirmDeleteExample(_ExampleRoute example) async {
    final confirmed = await _showDeleteDialog(
      '“${example.title}”',
      example: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await _persistDeletedExamples(<String>{example.id});
    } catch (error) {
      if (mounted) _showSnack('删除失败：$error');
      return;
    }
    if (!mounted) return;
    setState(() {
      _selectedExampleIds.remove(example.id);
      if (_visibleExamples.isEmpty && _items.isEmpty) {
        _selectionMode = false;
      }
    });
    _showSnack('示例已从首页移除');
  }

  Future<void> _showRouteActions(SavedRoute route) async {
    final delete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.sageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: AppColors.sageAccent,
            ),
            title: const Text('删除行程'),
            subtitle: Text(
              route.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(sheetContext).pop(true),
          ),
        ),
      ),
    );
    if (delete == true && mounted) await _confirmDelete(route);
  }

  Future<void> _confirmBulkDelete() async {
    final ids = Set<String>.from(_selectedRouteIds);
    final exampleIds = Set<String>.from(_selectedExampleIds);
    if (ids.isEmpty && exampleIds.isEmpty || _bulkDeleting) return;
    final total = ids.length + exampleIds.length;
    final confirmed = await _showDeleteDialog(
      '$total 条行程',
      containsExamples: exampleIds.isNotEmpty,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _bulkDeleting = true);
    var success = 0;
    Object? lastError;
    for (final id in ids) {
      try {
        await widget.onDeleteRoute!(id);
        success++;
        _selectedRouteIds.remove(id);
      } catch (error, stackTrace) {
        lastError = error;
        developer.log(
          'Failed to delete saved route $id in batch',
          name: 'SageRoute.HomePage',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (exampleIds.isNotEmpty) {
      try {
        await _persistDeletedExamples(exampleIds);
        _selectedExampleIds.removeAll(exampleIds);
        success += exampleIds.length;
      } catch (error, stackTrace) {
        lastError = error;
        developer.log(
          'Failed to persist deleted example routes',
          name: 'SageRoute.HomePage',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _bulkDeleting = false;
      if (_selectedRouteIds.isEmpty && _selectedExampleIds.isEmpty) {
        _selectionMode = false;
      }
    });
    if (lastError == null) {
      _showSnack('已删除 $success 条行程');
    } else {
      _showSnack('已删除 $success 条，${total - success} 条失败：$lastError');
    }
  }

  Future<bool?> _showDeleteDialog(
    String subject, {
    bool example = false,
    bool containsExamples = false,
  }) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除行程？'),
      content: Text(
        example
            ? '确定从首页移除$subject吗？'
            : containsExamples
            ? '确定删除$subject吗？真实行程及其途经点会从数据库删除，示例卡片会从首页移除。'
            : '确定删除$subject吗？路线及途经点将永久删除，无法恢复。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('删除'),
        ),
      ],
    ),
  );

  Future<void> _confirmDelete(SavedRoute route) async {
    if (_deletingRouteIds.contains(route.id)) return;
    final confirmed = await _showDeleteDialog('“${route.title}”');
    if (confirmed != true || !mounted) return;

    setState(() => _deletingRouteIds.add(route.id));
    try {
      await widget.onDeleteRoute!(route.id);
      if (mounted) _showSnack('行程已删除');
    } catch (error, stackTrace) {
      developer.log(
        'Failed to delete saved route',
        name: 'SageRoute.HomePage',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) _showSnack('删除失败：$error');
    } finally {
      if (mounted) setState(() => _deletingRouteIds.remove(route.id));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            SageRouteBottomNav.barHeight +
                MediaQuery.paddingOf(context).bottom +
                12,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showExampleRouteNotice() {
    _showSnack('仅占位示例行程，暂不可查看');
  }
}

class _ExampleRoute {
  const _ExampleRoute({
    required this.id,
    required this.title,
    required this.dateRange,
    required this.memberText,
    required this.duration,
    required this.distance,
    this.stampLine1 = 'MY TRIP',
    this.stampLine2 = 'PASSED',
  });

  final String id;
  final String title;
  final String dateRange;
  final String memberText;
  final String duration;
  final String distance;
  final String stampLine1;
  final String stampLine2;
}

const _exampleRoutes = <_ExampleRoute>[
  _ExampleRoute(
    id: 'bai-juyi-jiangnan',
    title: '白居易的江南遗迹',
    dateRange: '2026.06.15 — 2026.06.18',
    memberText: '共 2 名成员同行',
    duration: '4天3晚',
    distance: '12.5 KM',
  ),
  _ExampleRoute(
    id: 'su-shi-hangzhou',
    title: '苏轼杭州诗意行',
    dateRange: '2026.07.01 — 2026.07.01',
    memberText: '仅限自己独行',
    duration: '1天0晚',
    distance: '3.2 KM',
    stampLine1: 'WEEKEND',
    stampLine2: 'WALK',
  ),
];
