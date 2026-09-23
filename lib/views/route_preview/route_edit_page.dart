import 'package:flutter/material.dart';

import '../../data/celebrity_repository.dart';
import '../../data/user_route_repository.dart';
import '../../models/celebrity_profile.dart';
import '../../models/saved_route.dart';
import '../../route_planning/models/route_place.dart';
import '../../route_planning/models/transport_type.dart';
import '../../theme/color_schemes.dart';
import '../../utils/route_save_diagnostics.dart';
import '../create_route_wizard/steps/step3_map.dart';

/// 路线编辑页：与规划向导第 3 步一致的编辑界面（地图 + 途经点面板），
/// 保存后全量替换该路线的途经点并 `pop(true)` 通知调用方刷新。
class RouteEditPage extends StatefulWidget {
  const RouteEditPage({
    super.key,
    required this.route,
    this.repository,
    this.celebrityRepository,
  });

  final SavedRoute route;
  final UserRouteRepository? repository;
  final CelebrityRepository? celebrityRepository;

  @override
  State<RouteEditPage> createState() => _RouteEditPageState();
}

class _RouteEditPageState extends State<RouteEditPage> {
  late List<RoutePlace> _places;
  Map<String, TransportType> _transportTypes = <String, TransportType>{};
  CelebrityProfile? _figure;
  bool _saving = false;

  UserRouteRepository get _repository =>
      widget.repository ?? const UserRouteRepository();

  @override
  void initState() {
    super.initState();
    _places = widget.route.waypoints
        .map((waypoint) => waypoint.toRoutePlace())
        .toList(growable: false);
    for (var i = 0; i < _places.length - 1; i++) {
      _transportTypes[Step3Map.segmentKey(_places[i], _places[i + 1])] =
          widget.route.waypoints[i].transportToNext ?? TransportType.driving;
    }
    _loadFigure();
  }

  Future<void> _loadFigure() async {
    final figureId = widget.route.figureId;
    if (figureId == null) return;
    try {
      final figure =
          await (widget.celebrityRepository ?? const CelebrityRepository())
              .fetchById(figureId);
      if (mounted && figure != null) setState(() => _figure = figure);
    } catch (_) {
      // 人物回填失败仅影响「添加地点」推荐，主流程不受影响。
    }
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repository.updateWaypoints(widget.route.id, _buildWaypoints());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showRouteSaveDiagnostics(
        context,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  List<RouteWaypoint> _buildWaypoints() {
    return <RouteWaypoint>[
      for (var i = 0; i < _places.length; i++)
        RouteWaypoint.fromRoutePlace(
          _places[i],
          transportToNext: i < _places.length - 1
              ? _transportTypes[Step3Map.segmentKey(
                      _places[i],
                      _places[i + 1],
                    )] ??
                    TransportType.driving
              : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageCard,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: Step3Map(
                figure: _figure,
                selectedPlaces: _places,
                onLocationsChanged: (places) =>
                    _places = List<RoutePlace>.from(places),
                onPreviewStatusChanged: (_) {},
                onTransportTypesChanged: (types) => _transportTypes = types,
                initialSegmentTransports: widget.route.waypoints
                    .take(
                      widget.route.waypoints.length > 1
                          ? widget.route.waypoints.length - 1
                          : 0,
                    )
                    .map(
                      (waypoint) =>
                          waypoint.transportToNext ?? TransportType.driving,
                    )
                    .toList(growable: false),
                onSaveRequested: _handleSave,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back,
                      tooltip: '返回',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '编辑路线',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sageText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_saving)
              Positioned.fill(
                child: Container(
                  color: const Color(0xCCF0F0F2),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: AppColors.sageText),
          ),
        ),
      ),
    );
  }
}
