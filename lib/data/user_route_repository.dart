import 'dart:developer' as developer;

import '../models/saved_route.dart';
import '../services/database_service.dart';
import 'supabase_table_repository.dart';

typedef CurrentUserIdProvider = String? Function();

/// Converts known persistence failures into an actionable message for the UI.
/// Keep the PostgREST code check string-based so repository tests do not need a
/// live Supabase client or an SDK-specific exception instance.
String describeRoutePersistenceError(Object error) {
  final details = error.toString();
  if (details.contains('PGRST205') &&
      (details.contains('user_routes') ||
          details.contains('user_route_waypoints'))) {
    return '路线保存功能尚未启用，请先部署 user_routes 数据库迁移。';
  }
  if (error is StateError) return error.message.toString();
  if (details.contains('23502') || details.contains('not-null constraint')) {
    return '数据库字段约束不匹配，路线没有完整保存。请更新数据库结构后重试。';
  }
  if (details.contains('42501') || details.contains('row-level security')) {
    return '数据库权限校验未通过，请重新登录后重试。';
  }
  if (details.contains('PostgrestException')) {
    return '数据库拒绝了路线保存：$details';
  }
  if (details.contains('SocketException') ||
      details.contains('TimeoutException') ||
      details.contains('ClientException') ||
      details.contains('网络异常')) {
    return '保存失败，请检查网络后重试。';
  }
  return '路线保存失败：$details';
}

/// 用户路线仓储：
/// - 对外提供强类型 `SavedRoute`（含途经点）
/// - 底层复用通用 `SupabaseTableRepository`（`user_routes` / `user_route_waypoints`）
/// - 表仓库与 userId 提供器均可注入，便于测试
class UserRouteRepository {
  const UserRouteRepository({
    SupabaseTableRepository? routesTable,
    SupabaseTableRepository? waypointsTable,
    CurrentUserIdProvider? currentUserId,
  }) : _routesTable =
           routesTable ??
           const SupabaseTableRepository(tableName: 'user_routes'),
       _waypointsTable =
           waypointsTable ??
           const SupabaseTableRepository(tableName: 'user_route_waypoints'),
       _currentUserId = currentUserId ?? _defaultCurrentUserId;

  final SupabaseTableRepository _routesTable;
  final SupabaseTableRepository _waypointsTable;
  final CurrentUserIdProvider _currentUserId;

  static String? _defaultCurrentUserId() =>
      DatabaseService.client.auth.currentUser?.id;

  /// 当前用户的全部路线（新→旧），途经点按 sort_order 组装。
  Future<List<SavedRoute>> fetchUserRoutes() async {
    final userId = _requireUserId();
    final routeRows = await _routesTable.fetchAllRaw(
      equals: <String, dynamic>{'user_id': userId},
    );
    routeRows.sort((a, b) {
      final aTime =
          DateTime.tryParse(a['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          DateTime.tryParse(b['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    final routes = <SavedRoute>[];
    for (final row in routeRows) {
      final waypoints = await _fetchWaypoints(row['id'] as String);
      routes.add(SavedRoute.fromMap(row, waypoints: waypoints));
    }
    return routes;
  }

  /// 按 id 取单条路线（含途经点）；不存在时返回 null。
  Future<SavedRoute?> fetchRouteById(String routeId) async {
    final rows = await _routesTable.fetchAllRaw(
      equals: <String, dynamic>{'id': routeId},
    );
    if (rows.isEmpty) return null;
    final waypoints = await _fetchWaypoints(routeId);
    return SavedRoute.fromMap(rows.first, waypoints: waypoints);
  }

  /// 新建路线（含途经点），返回生成的路线 id。
  Future<String> createRoute(SavedRoute draft) async {
    final userId = _requireUserId();
    final inserted = await _routesTable.insertRaw(draft.toMap(userId: userId));
    final routeId = inserted['id'] as String;

    try {
      await _waypointsTable.insertAllRaw(
        _waypointRows(routeId, draft.waypoints),
      );
    } catch (error, stackTrace) {
      // The two REST writes are not a single transaction. Remove the parent
      // route if its waypoint batch fails so a failed save is not left behind
      // as an empty route card. Preserve the original database error.
      try {
        await _routesTable.deleteRaw(<String, dynamic>{'id': routeId});
      } catch (cleanupError, cleanupStackTrace) {
        developer.log(
          'Failed to clean up route $routeId after waypoint insert failure',
          name: 'UserRouteRepository',
          error: cleanupError,
          stackTrace: cleanupStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    return routeId;
  }

  /// 全量替换某条路线的途经点（编辑保存）。
  Future<void> updateWaypoints(
    String routeId,
    List<RouteWaypoint> waypoints,
  ) async {
    final existing = await _fetchWaypoints(routeId);
    await _waypointsTable.deleteRaw(<String, dynamic>{'route_id': routeId});
    try {
      await _waypointsTable.insertAllRaw(_waypointRows(routeId, waypoints));
    } catch (error, stackTrace) {
      try {
        await _waypointsTable.insertAllRaw(_waypointRows(routeId, existing));
      } catch (restoreError, restoreStackTrace) {
        developer.log(
          'Failed to restore waypoints for route $routeId after edit failure',
          name: 'UserRouteRepository',
          error: restoreError,
          stackTrace: restoreStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<List<RouteWaypoint>> _fetchWaypoints(String routeId) async {
    final rows = await _waypointsTable.fetchAllRaw(
      equals: <String, dynamic>{'route_id': routeId},
    );
    rows.sort(
      (a, b) => (a['sort_order'] as int? ?? 0).compareTo(
        b['sort_order'] as int? ?? 0,
      ),
    );
    final waypoints = rows.map(RouteWaypoint.fromMap).toList();
    if (waypoints.isEmpty) return waypoints;

    // No route has a transport segment after its final waypoint. Older
    // schemas may fill an omitted transport_to_next with their default, so
    // normalize that database value back to the domain model's null.
    final last = waypoints.removeLast();
    waypoints.add(
      RouteWaypoint(
        name: last.name,
        latitude: last.latitude,
        longitude: last.longitude,
        locationId: last.locationId,
        visitDurationMin: last.visitDurationMin,
        categories: last.categories,
      ),
    );
    return waypoints;
  }

  List<Map<String, dynamic>> _waypointRows(
    String routeId,
    List<RouteWaypoint> waypoints,
  ) {
    return <Map<String, dynamic>>[
      for (var i = 0; i < waypoints.length; i++)
        waypoints[i].toMap(routeId: routeId, sortOrder: i),
    ];
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('需登录后才能保存路线');
    }
    return userId;
  }
}
