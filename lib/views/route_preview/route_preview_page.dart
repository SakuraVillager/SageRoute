import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/user_route_repository.dart';
import '../../models/saved_route.dart';
import '../../route_planning/models/transport_type.dart';
import '../../services/amap_navigation.dart';
import '../../theme/color_schemes.dart';
import '../../utils/slide_route.dart';
import '../create_route_wizard/steps/step3_map.dart';
import 'route_edit_page.dart';

/// 路线导航/预览页：从首页票据点击进入。
/// 顶部提供返回与编辑入口，主体为 [Step3Map] 的只读预览（地图 + 行程面板），
/// footer 主按钮「开始导航」将首站交给高德地图导航。
class RoutePreviewPage extends StatefulWidget {
  const RoutePreviewPage({
    super.key,
    required this.routeId,
    this.initialRoute,
    this.repository,
    this.openNavigationUrl,
  });

  final String routeId;
  final SavedRoute? initialRoute;
  final UserRouteRepository? repository;
  final Future<bool> Function(Uri uri)? openNavigationUrl;

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> {
  late SavedRoute? _route;
  late bool _loading;
  Object? _error;

  UserRouteRepository get _repository =>
      widget.repository ?? const UserRouteRepository();

  @override
  void initState() {
    super.initState();
    _route = widget.initialRoute;
    _loading = _route == null;
    if (_route == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final route = await _repository.fetchRouteById(widget.routeId);
      if (!mounted) return;
      setState(() {
        _route = route;
        _loading = false;
        _error = route == null ? '路线不存在或已被删除' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _openEdit() async {
    final route = _route;
    if (route == null) return;
    final changed = await Navigator.of(context).push<bool>(
      slideFromRightRoute(
        RouteEditPage(route: route, repository: widget.repository),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _onStartNavigation() async {
    final route = _route;
    if (route == null || route.waypoints.isEmpty) {
      _showNavigationError('路线没有可导航的地点');
      return;
    }

    try {
      final uri = buildAmapNavigationUri(route.waypoints.first);
      final opened =
          await (widget.openNavigationUrl?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened && mounted) _showNavigationError('未找到高德地图 App，请先安装后重试');
    } catch (_) {
      if (mounted) _showNavigationError('未找到高德地图 App，请先安装后重试');
    }
  }

  void _showNavigationError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.sageCard, body: _buildBody());
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.sageMuted,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '路线加载失败：$error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.sageMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }
    final route = _route!;
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Step3Map(
              mode: Step3Mode.preview,
              selectedPlaces: route.waypoints
                  .map((waypoint) => waypoint.toRoutePlace())
                  .toList(growable: false),
              onLocationsChanged: (_) {},
              onPreviewStatusChanged: (_) {},
              onSaveRequested: () async {},
              onStartNavigation: _onStartNavigation,
              initialSegmentTransports: route.waypoints
                  .take(
                    route.waypoints.length > 1 ? route.waypoints.length - 1 : 0,
                  )
                  .map(
                    (waypoint) =>
                        waypoint.transportToNext ?? TransportType.driving,
                  )
                  .toList(growable: false),
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
                  Expanded(
                    child: Text(
                      route.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sageText,
                        shadows: [Shadow(color: Colors.white, blurRadius: 6)],
                      ),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: '编辑路线',
                    onTap: _openEdit,
                  ),
                ],
              ),
            ),
          ),
        ],
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
