import 'dart:async';
import '../../components/web/web_back_button.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../components/route_sharing_sheet.dart';
import 'package:flutter/foundation.dart';
import '../../navigation/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/user_route_repository.dart';
import '../../models/saved_route.dart';
import '../../route_planning/models/transport_type.dart';
import '../../services/amap_navigation.dart';
import '../../theme/color_schemes.dart';
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
  StreamSubscription<void>? _updates;

  void _watch() {
    if (_updates != null || _route?.ownerId == null) return;
    _updates = _repository
        .watchRoute(widget.routeId)
        .listen((_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _updates?.cancel();
    super.dispose();
  }

  UserRouteRepository get _repository =>
      widget.repository ?? const UserRouteRepository();

  @override
  void initState() {
    super.initState();
    _route = widget.initialRoute;
    _loading = _route == null;
    _load(quiet: _route != null);
    _watch();
  }

  Future<void> _load({bool quiet = false}) async {
    setState(() {
      _loading = !quiet;
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
      _watch();
    } catch (error) {
      if (!mounted) return;
      // Keep the already loaded preview usable while an optional refresh is offline.
      if (quiet && _route != null) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _openEdit() async {
    final route = _route;
    if (route == null || !route.canEdit) return;
    final changed = await openAppPage<bool>(
      context,
      RouteEditPage(route: route, repository: widget.repository),
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
              launchUrl(
                uri,
                mode: kIsWeb
                    ? LaunchMode.platformDefault
                    : LaunchMode.externalApplication,
                webOnlyWindowName: '_blank',
              ));
      if (!opened && mounted) {
        _showNavigationError(
          kIsWeb ? '无法打开导航页面，请检查浏览器弹窗设置' : '未找到高德地图 App，请先安装后重试',
        );
      }
    } catch (_) {
      if (mounted) {
        _showNavigationError(
          kIsWeb ? '无法打开导航页面，请检查浏览器弹窗设置' : '未找到高德地图 App，请先安装后重试',
        );
      }
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
              key: ValueKey('${route.id}-${route.revision}'),
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
            child: PointerInterceptor(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    WebBackButton(
                      onPressed: () => finishAppPage(context),
                      mobileChild: _CircleIconButton(
                        icon: Icons.arrow_back,
                        tooltip: '返回',
                        onTap: () => finishAppPage(context),
                      ),
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
                    if (route.ownerId != null) ...[
                      _CircleIconButton(
                        icon: Icons.people_outline,
                        tooltip: '分享与协作 · ${route.accessRole.label}',
                        onTap: () async {
                          await showRouteSharing(context, route);
                          if (mounted) await _load(quiet: true);
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (route.canEdit)
                      _CircleIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: '编辑路线',
                        onTap: _openEdit,
                      ),
                  ],
                ),
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
