import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/ticket_card.dart';
import '../models/saved_route.dart';
import '../theme/color_schemes.dart';
import '../utils/slide_route.dart';
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
  });

  final ValueListenable<List<SavedRoute>>? createdRoutesListenable;
  final Future<void> Function()? onRefreshRoutes;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<SavedRoute> _items;
  VoidCallback? _listener;

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
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildTicketSection(),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      body: SafeArea(
        child: widget.onRefreshRoutes == null
            ? content
            : RefreshIndicator(
                onRefresh: widget.onRefreshRoutes!,
                child: content,
              ),
      ),
    );
  }

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  child: TicketCard(
                    title: route.title,
                    dateRange: route.dateRange,
                    memberText: '全新规划的旅程',
                    duration: route.duration,
                    distance: route.distance,
                    onTap: () => Navigator.of(context).push(
                      slideFromRightRoute(
                        RoutePreviewPage(
                          routeId: route.id,
                          initialRoute: route,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Preset example cards (always shown)
          TicketCard(
            title: '白居易的江南遗迹',
            dateRange: '2026.06.15 — 2026.06.18',
            memberText: '共 2 名成员同行',
            duration: '4天3晚',
            distance: '12.5 KM',
            onTap: _showExampleRouteNotice,
          ),
          const SizedBox(height: 16),
          TicketCard(
            title: '苏轼杭州诗意行',
            dateRange: '2026.07.01 — 2026.07.01',
            memberText: '仅限自己独行',
            duration: '1天0晚',
            distance: '3.2 KM',
            stampLine1: 'WEEKEND',
            stampLine2: 'WALK',
            onTap: _showExampleRouteNotice,
          ),
        ],
      ),
    );
  }

  void _showExampleRouteNotice() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('仅占位示例行程，暂不可查看'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }
}
