import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../../../data/mock_locations.dart';
import '../../../theme/color_schemes.dart';

/// Step 3 of CreateRouteWizard — map with draggable floating location panel.
class Step3Map extends StatefulWidget {
  final List<String> selectedLocations;
  final ValueChanged<List<String>> onLocationsChanged;

  const Step3Map({
    super.key,
    this.selectedLocations = const [],
    required this.onLocationsChanged,
  });

  @override
  State<Step3Map> createState() => _Step3MapState();
}

class _Step3MapState extends State<Step3Map> {
  // Panel fraction of screen height
  static const double _minFraction = 0.18;
  static const double _maxFraction = 0.72;
  double _panelFraction = 0.38;

  // Drag state
  double _dragStartDy = 0;
  double _dragStartFraction = 0.38;
  bool _isDraggingPanel = false;

  List<MockLocation> get _selected => widget.selectedLocations
      .map((id) => findLocationById(id))
      .whereType<MockLocation>()
      .toList();

  List<MockLocation> get _unselected {
    final list = mockLocations
        .where((loc) => !widget.selectedLocations.contains(loc.id))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  void _addLocation(MockLocation loc) {
    widget.onLocationsChanged([...widget.selectedLocations, loc.id]);
  }

  void _removeLocation(String id) {
    widget.onLocationsChanged(
      List<String>.from(widget.selectedLocations)..remove(id),
    );
  }

  void _reorderSelected(int oldIndex, int newIndex) {
    final updated = List<String>.from(widget.selectedLocations);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    widget.onLocationsChanged(updated);
  }

  void _onPointerDown(PointerDownEvent details) {
    _dragStartDy = details.position.dy;
    _dragStartFraction = _panelFraction;
    setState(() => _isDraggingPanel = true);
  }

  void _onPointerMove(PointerMoveEvent details) {
    final totalHeight = MediaQuery.sizeOf(context).height;
    final deltaPixels = _dragStartDy - details.position.dy;
    final deltaFraction = deltaPixels / totalHeight;
    setState(() {
      _panelFraction =
          (_dragStartFraction + deltaFraction).clamp(_minFraction, _maxFraction);
    });
  }

  void _onPointerUp(PointerUpEvent details) {
    setState(() => _isDraggingPanel = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = MediaQuery.sizeOf(context).height;
    final panelH = totalHeight * _panelFraction;

    return Stack(
      children: [
        // Full-screen map — RepaintBoundary prevents rebuilds during panel drag.
        Positioned.fill(
          child: RepaintBoundary(
            child: AMapWidget(
              initialCameraPosition: const CameraPosition(
                target: LatLng(30.259462, 120.147151),
                zoom: 13,
              ),
            ),
          ),
        ),

        // Floating panel overlay
        if (_isDraggingPanel)
          Positioned(
            left: 0, right: 0, bottom: 0, height: panelH,
            child: _buildPanel(),
          )
        else
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: 0, right: 0, bottom: 0, height: panelH,
            child: _buildPanel(),
          ),
      ],
    );
  }

  Widget _buildPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sageCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Content
          Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sageBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Expanded(child: _PanelHeader(
                    icon: Icons.check_circle_outline,
                    label: '已选地点',
                    accent: AppColors.primaryLight,
                  )),
                  SizedBox(
                    height: 28,
                    child: VerticalDivider(width: 1, color: AppColors.sageBorder),
                  ),
                  Expanded(child: _PanelHeader(
                    icon: Icons.place_outlined,
                    label: '可用地点',
                    accent: AppColors.sageGreen,
                  )),
                ],
              ),
              Container(height: 0.5, color: AppColors.sageBorder),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildSelectedList()),
                    Container(
                      width: 1,
                      color: AppColors.sageBorder.withValues(alpha: 0.5),
                    ),
                    Expanded(child: _buildUnselectedList()),
                  ],
                ),
              ),
            ],
          ),

          // Drag overlay for panel resize (Listener avoids gesture arena conflicts)
          Positioned(
            top: 0, left: 0, right: 0, height: 60,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
            ),
          ),
        ],
      ),
    );
  }

  // ── Left: selected list with ReorderableListView ──

  Widget _buildSelectedList() {
    final selected = _selected;
    if (selected.isEmpty) {
      return const _EmptyHint(
        icon: Icons.add_location_alt_outlined,
        text: '从右侧添加地点',
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: selected.length,
      buildDefaultDragHandles: false,
      onReorder: _reorderSelected,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12 * animation.value),
                    blurRadius: 12 * animation.value,
                    offset: Offset(0, 4 * animation.value),
                  ),
                ],
              ),
              child: child,
            );
          },
        );
      },
      itemBuilder: (_, index) {
        final loc = selected[index];
        return _SelectedTile(
          key: ValueKey(loc.id),
          location: loc,
          index: index,
          onRemove: () => _removeLocation(loc.id),
        );
      },
    );
  }

  // ── Right: unselected list ──

  Widget _buildUnselectedList() {
    final unselected = _unselected;
    if (unselected.isEmpty) {
      return const _EmptyHint(
        icon: Icons.done_all,
        text: '所有地点已选',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      itemCount: unselected.length,
      itemBuilder: (_, i) => _UnselectedTile(
        key: ValueKey(unselected[i].id),
        location: unselected[i],
        onTap: () => _addLocation(unselected[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Panel header
// ═══════════════════════════════════════════════════════════

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
          Text(label, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sageText,
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Empty hint
// ═══════════════════════════════════════════════════════════

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
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.sageMuted)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Selected tile — with drag handle (☰ icon)
// ═══════════════════════════════════════════════════════════

class _SelectedTile extends StatelessWidget {
  const _SelectedTile({
    super.key,
    required this.location,
    required this.index,
    required this.onRemove,
  });

  final MockLocation location;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Order badge — stays fixed
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              location.name,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.sageText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Remove button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: AppColors.sageBorder.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(Icons.close, size: 12, color: AppColors.sageMuted),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Drag handle — three horizontal bars (☰)
          ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 24, height: 24,
              alignment: Alignment.center,
              child: const Icon(
                Icons.drag_handle,
                size: 16,
                color: AppColors.sageMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Unselected tile — tap to add
// ═══════════════════════════════════════════════════════════

class _UnselectedTile extends StatelessWidget {
  const _UnselectedTile({
    super.key,
    required this.location,
    required this.onTap,
  });

  final MockLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
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
                location.name,
                style: const TextStyle(
                  fontSize: 13, color: AppColors.sageText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              location.pinyinName,
              style: const TextStyle(
                fontSize: 10, color: AppColors.sageMuted, fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
