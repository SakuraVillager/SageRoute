import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/ticket_card.dart';
import '../models/new_route_draft.dart';
import '../theme/color_schemes.dart';

/// Home page matching the Web version's Home.tsx layout.
///
/// Sections:
/// - Header: greeting + notification bell + avatar
/// - Search bar (UI placeholder, no real search logic)
///
/// Navigation is handled via optional callbacks.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.createdRoutesListenable});

  final ValueListenable<List<NewRouteDraft>>? createdRoutesListenable;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<NewRouteDraft> _items;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _items = widget.createdRoutesListenable != null
        ? List<NewRouteDraft>.from(widget.createdRoutesListenable!.value)
        : <NewRouteDraft>[];
    if (widget.createdRoutesListenable != null) {
      _listener = _onCreatedRoutesChanged;
      widget.createdRoutesListenable!.addListener(_listener!);
    }
  }

  @override
  void dispose() {
    if (_listener != null) widget.createdRoutesListenable!.removeListener(_listener!);
    super.dispose();
  }

  void _onCreatedRoutesChanged() {
    try {
      final newList = widget.createdRoutesListenable!.value;
      if (newList.length > _items.length) {
        // Inserted at front in MainScreen logic
        final inserted = newList.firstWhere(
          (n) => !_items.any((o) => o.id == n.id),
          orElse: () => newList.first,
        );

        if (!mounted) return;
        setState(() => _items = [inserted, ..._items]);

        // Skipping AnimatedList insert — using simple list rendering for now.
        debugPrint('[HomePage] inserted into _items (no animated insert)');
        return;
      }

      if (newList.length < _items.length) {
        // Simple non-animated sync for removals or resets
        if (!mounted) return;
        setState(() => _items = List<NewRouteDraft>.from(newList));
        return;
      }

      // Same length — replace if different
      if (!listEquals(_items, newList)) {
        if (!mounted) return;
        setState(() => _items = List<NewRouteDraft>.from(newList));
      }
    } catch (e, st) {
      debugPrint('Error in _onCreatedRoutesChanged: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[HomePage.build] items=${_items.map((i)=>i.id).toList()}');
    return Scaffold(
      backgroundColor: AppColors.sageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildTicketSection(),
            ],
          ),
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
              color: Color(0xFFEBE5DA),
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
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=150',
                ),
                fit: BoxFit.cover,
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
          // Animated list for freshly created routes
          // NOTE: Temporarily rendering as a simple Column for reliability.
          for (final route in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TicketCard(
                title: route.title,
                dateRange: route.dateRange,
                memberText: '全新规划的旅程',
                duration: route.duration,
                distance: route.distance,
              ),
            ),

          // Preset example cards (always shown)
          TicketCard(
            title: '白居易的江南遗迹',
            dateRange: '2026.06.15 — 2026.06.18',
            memberText: '共 2 名成员同行',
            duration: '4天3晚',
            distance: '12.5 KM',
            onTap: () {},
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
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
