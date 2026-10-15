import 'dart:async';
import '../../data/social_gateway.dart';
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
  late int _baseRevision;
  bool _remoteChanged = false;
  int _mapVersion = 0;
  StreamSubscription<void>? _updates;
  void _persistDraft() {
    if (!_dirty || _saved) return;
    _draft?.save({
      'places': _places.map((p) => p.toJson()).toList(),
      'revision': _baseRevision,
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
      _baseRevision = (data['revision'] as num?)?.toInt() ?? 0;
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
    _updates?.cancel();
    super.dispose();
  }

  UserRouteRepository get _repository =>
      widget.repository ?? const UserRouteRepository();

  @override
  void initState() {
    super.initState();
    _baseRevision = widget.route.revision;
    _places = widget.route.waypoints
        .map((waypoint) => waypoint.toRoutePlace())
        .toList(growable: false);
    for (var i = 0; i < _places.length - 1; i++) {
      _transportTypes[Step3Map.segmentKey(_places[i], _places[i + 1])] =
          widget.route.waypoints[i].transportToNext ?? TransportType.driving;
    }
    _restoreDraft();
    _loadFigure();
    if (widget.route.ownerId != null && widget.route.canEdit) {
      _updates = _repository.watchRoute(widget.route.id).listen((_) {
        if (mounted && !_saving) setState(() => _remoteChanged = true);
      });
    }
  }

  Future<void> _reloadLatest() async {
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('载入最新行程？'),
          content: const Text('你当前尚未保存的修改将被替换。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('保留修改'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('载入最新'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    try {
      final latest = await _repository.fetchRouteById(widget.route.id);
      if (latest == null || !latest.canEdit) {
        throw StateError('行程已删除或编辑权限已变更，请返回行程列表');
      }
      if (!mounted) return;
      setState(() {
        _places = latest.waypoints.map((p) => p.toRoutePlace()).toList();
        _transportTypes = {
          for (var i = 0; i < _places.length - 1; i++)
            Step3Map.segmentKey(_places[i], _places[i + 1]):
                latest.waypoints[i].transportToNext ?? TransportType.driving,
        };
        _baseRevision = latest.revision;
        _dirty = false;
        _remoteChanged = false;
        _mapVersion++;
      });
      _draft?.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(socialErrorMessage(error))));
      }
    }
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
    if (_saving || !widget.route.canEdit) return;
    setState(() => _saving = true);
    try {
      await _repository.updateWaypoints(
        widget.route.id,
        _buildWaypoints(),
        expectedRevision: _baseRevision,
      );
      if (!mounted) return;
      _saved = true;
      _draft?.clear();
      finishAppPage(context, true);
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (error is RouteEditConflict) {
        setState(() => _remoteChanged = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同行者已经更新了行程。你的修改已保留，请载入最新版本后重新调整。')),
        );
        return;
      }
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
    if (!widget.route.canEdit) {
      return const Scaffold(body: Center(child: Text('你拥有此行程的只读权限')));
    }
    return DraftExitGuard(
      dirty: kIsWeb && _dirty && !_saving,
      onDiscard: () {
        _saved = true;
        _draft?.clear();
      },
      child: Scaffold(
        backgroundColor: AppColors.sageCard,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final reserveToolbar = kIsWeb && constraints.maxWidth >= 760;
            final toolbarHeight = MediaQuery.paddingOf(context).top + 56;
            return SizedBox.expand(
              child: Stack(
                children: [
                  Positioned.fill(
                    top: reserveToolbar ? toolbarHeight : 0,
                    child: Step3Map(
                      key: ValueKey(_mapVersion),
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
                  if (_remoteChanged)
                    Positioned(
                      top:
                          MediaQuery.paddingOf(context).top +
                          (reserveToolbar ? 64 : 52),
                      left: 16,
                      right: 16,
                      child: PointerInterceptor(
                        child: Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('同行者已更新行程。保存前请载入最新版本。'),
                                ),
                                TextButton(
                                  onPressed: _reloadLatest,
                                  child: const Text('载入最新'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (reserveToolbar)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: toolbarHeight,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.sageCard,
                          border: Border(
                            bottom: BorderSide(color: AppColors.sageBorder),
                          ),
                        ),
                      ),
                    ),
                  SafeArea(
                    key: const ValueKey('route-edit-toolbar'),
                    child: PointerInterceptor(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          8,
                          reserveToolbar ? 8 : 4,
                          8,
                          reserveToolbar ? 8 : 0,
                        ),
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
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
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
