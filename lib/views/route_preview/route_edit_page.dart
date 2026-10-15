import '../../components/web/web_back_button.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:flutter/foundation.dart';
import '../../services/route_draft_storage.dart';
import '../../services/database_service.dart';
import '../../components/draft_exit_guard.dart';
import '../../navigation/app_navigation.dart';
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
  bool _dirty = false;
  bool _saved = false;
  RouteDraftStorage? _draft;
  void _persistDraft() {
    if (!_dirty || _saved) return;
    _draft?.save({
      'places': _places.map((p) => p.toJson()).toList(),
      'transports': _transportTypes.map(
        (key, value) => MapEntry(key, value.name),
      ),
    });
  }

  void _restoreDraft() {
    if (!kIsWeb) return;
    final user = DatabaseService.client.auth.currentUser;
    if (user == null) return;
    _draft = RouteDraftStorage(
      userId: user.id,
      draftId: 'edit.${widget.route.id}',
    );
    final data = _draft!.load();
    if (data == null) return;
    try {
      _places = (data['places'] as List)
          .map((p) => RoutePlace.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      _transportTypes = (data['transports'] as Map).map(
        (key, value) => MapEntry(
          key as String,
          TransportType.values.byName(value as String),
        ),
      );
      _dirty = true;
    } catch (_) {
      _draft!.clear();
    }
  }

  Future<void> _leave() async {
    if (kIsWeb && _dirty) {
      await requestDraftDiscard(
        context,
        () {
          setState(() => _saved = true);
          _draft?.clear();
        },
        () => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) finishAppPage(context);
        }),
      );
    } else {
      finishAppPage(context);
    }
  }

  @override
  void dispose() {
    _persistDraft();
    super.dispose();
  }

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
    _restoreDraft();
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
      _saved = true;
      _draft?.clear();
      finishAppPage(context, true);
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
    return DraftExitGuard(
      dirty: kIsWeb && _dirty && !_saving,
      onDiscard: () {
        _saved = true;
        _draft?.clear();
      },
      child: Scaffold(
        backgroundColor: AppColors.sageCard,
        body: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: Step3Map(
                  figure: _figure,
                  selectedPlaces: _places,
                  onLocationsChanged: (places) {
                    setState(() {
                      _places = List<RoutePlace>.from(places);
                      _dirty = true;
                    });
                    _persistDraft();
                  },
                  onPreviewStatusChanged: (_) {},
                  onTransportTypesChanged: (types) {
                    setState(() {
                      _transportTypes = types;
                      _dirty = true;
                    });
                    _persistDraft();
                  },
                  initialSegmentTransports: [
                    for (var i = 0; i < _places.length - 1; i++)
                      _transportTypes[Step3Map.segmentKey(
                            _places[i],
                            _places[i + 1],
                          )] ??
                          TransportType.driving,
                  ],
                  onSaveRequested: _handleSave,
                ),
              ),
              SafeArea(
                child: PointerInterceptor(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        WebBackButton(
                          onPressed: _leave,
                          mobileChild: _CircleIconButton(
                            icon: Icons.arrow_back,
                            tooltip: '返回',
                            onTap: _leave,
                          ),
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
              ),
              if (_saving)
                Positioned.fill(
                  child: PointerInterceptor(
                    child: Container(
                      color: const Color(0xCCF0F0F2),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
            ],
          ),
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
