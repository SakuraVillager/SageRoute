import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/supabase_table_repository.dart';
import 'package:sageroute/data/user_route_repository.dart';
import 'package:sageroute/models/saved_route.dart';

void main() {
  group('UserRouteRepository', () {
    test('explains a missing route table migration', () {
      expect(
        describeRoutePersistenceError(
          Exception('PostgrestException(code: PGRST205, user_routes)'),
        ),
        '路线保存功能尚未启用，请先部署 user_routes 数据库迁移。',
      );
    });

    test('keeps the signed-in requirement actionable', () {
      expect(
        describeRoutePersistenceError(StateError('需登录后才能保存路线')),
        '需登录后才能保存路线',
      );
    });

    test('reports database constraint failures as database errors', () {
      expect(
        describeRoutePersistenceError(
          Exception(
            'PostgrestException(message: null value violates not-null constraint, code: 23502)',
          ),
        ),
        '数据库字段约束不匹配，路线没有完整保存。请更新数据库结构后重试。',
      );
    });

    test('requires a signed-in user', () async {
      final repository = _buildRepository(currentUserId: () => null);

      expect(repository.fetchUserRoutes, throwsStateError);
      expect(() => repository.createRoute(_draft()), throwsStateError);
    });

    test('fetchUserRoutes assembles waypoints ordered by sort_order', () async {
      final repository = _buildRepository(
        routeRows: const [
          <String, dynamic>{
            'id': 'route-b',
            'title': '路线B',
            'created_at': '2026-09-02T10:00:00Z',
          },
          <String, dynamic>{
            'id': 'route-a',
            'title': '路线A',
            'created_at': '2026-09-10T10:00:00Z',
          },
        ],
        waypointRows: const {
          'route-a': [
            <String, dynamic>{
              'sort_order': 1,
              'name': '第二站',
              'latitude': 30.2,
              'longitude': 120.2,
            },
            <String, dynamic>{
              'sort_order': 0,
              'name': '第一站',
              'latitude': 30.1,
              'longitude': 120.1,
              'categories': '寺庙',
            },
          ],
          'route-b': [
            <String, dynamic>{
              'sort_order': 0,
              'name': '孤站',
              'latitude': 31.0,
              'longitude': 121.0,
              'transport_to_next': 'driving',
            },
          ],
        },
      );

      final routes = await repository.fetchUserRoutes();

      // 新→旧排序。
      expect(routes.map((r) => r.id), ['route-a', 'route-b']);
      expect(routes[0].waypoints.map((w) => w.name), ['第一站', '第二站']);
      expect(routes[0].waypoints.first.categories, '寺庙');
      expect(routes[1].waypoints.single.name, '孤站');
      expect(routes[1].waypoints.single.transportToNext, isNull);
    });

    test(
      'createRoute inserts route row then waypoints with sort order',
      () async {
        final writes = <_Write>[];
        final repository = _buildRepository(writes: writes);

        final routeId = await repository.createRoute(
          _draft(
            waypoints: const [
              RouteWaypoint(
                name: 'A',
                latitude: 1,
                longitude: 2,
                categories: '园林',
              ),
              RouteWaypoint(name: 'B', latitude: 3, longitude: 4),
            ],
          ),
        );

        expect(routeId, 'generated-id');
        expect(writes, hasLength(2));

        final routeInsert = writes[0];
        expect(routeInsert.table, 'user_routes');
        expect(routeInsert.operation, 'insert');
        expect(routeInsert.row!['user_id'], 'user-1');
        expect(routeInsert.row!['title'], '测试路线');

        final waypointInsert = writes[1];
        expect(waypointInsert.table, 'user_route_waypoints');
        expect(waypointInsert.operation, 'insertAll');
        expect(waypointInsert.rows, hasLength(2));
        expect(waypointInsert.rows![0]['route_id'], 'generated-id');
        expect(waypointInsert.rows![0]['sort_order'], 0);
        expect(waypointInsert.rows![0]['categories'], '园林');
        expect(waypointInsert.rows![1]['sort_order'], 1);
      },
    );

    test('createRoute removes the parent when waypoint saving fails', () async {
      final writes = <_Write>[];
      final repository = _buildRepository(
        writes: writes,
        failWaypointInsert: true,
      );

      await expectLater(
        repository.createRoute(
          _draft(
            waypoints: const [
              RouteWaypoint(name: 'A', latitude: 1, longitude: 2),
            ],
          ),
        ),
        throwsException,
      );

      expect(writes.map((write) => '${write.table}:${write.operation}'), [
        'user_routes:insert',
        'user_route_waypoints:insertAll',
        'user_routes:delete',
      ]);
      expect(writes.last.equals, {'id': 'generated-id'});
    });

    test('updateWaypoints deletes then re-inserts all waypoints', () async {
      final writes = <_Write>[];
      final repository = _buildRepository(writes: writes);

      await repository.updateWaypoints('route-1', const [
        RouteWaypoint(name: '仅一站', latitude: 1, longitude: 1),
      ]);

      expect(writes, hasLength(2));
      expect(writes[0].operation, 'delete');
      expect(writes[0].equals, {'route_id': 'route-1'});
      expect(writes[1].operation, 'insertAll');
      expect(writes[1].rows!.single['name'], '仅一站');
    });

    test('fetchRouteById returns null when missing', () async {
      final repository = _buildRepository(routeRows: const []);

      expect(await repository.fetchRouteById('nope'), isNull);
    });
  });
}

class _Write {
  _Write({
    required this.table,
    required this.operation,
    this.row,
    this.rows,
    this.equals,
    this.values,
  });

  final String table;
  final String operation;
  final Map<String, dynamic>? row;
  final List<Map<String, dynamic>>? rows;
  final Map<String, dynamic>? equals;
  final Map<String, dynamic>? values;
}

UserRouteRepository _buildRepository({
  String? Function()? currentUserId,
  List<Map<String, dynamic>> routeRows = const [
    <String, dynamic>{'id': 'generated-id', 'title': '测试路线'},
  ],
  Map<String, List<Map<String, dynamic>>> waypointRows = const {},
  List<_Write>? writes,
  bool failWaypointInsert = false,
}) {
  final capturedWrites = writes ?? <_Write>[];
  return UserRouteRepository(
    currentUserId: currentUserId ?? () => 'user-1',
    routesTable: SupabaseTableRepository(
      tableName: 'user_routes',
      rawFetcher:
          ({required tableName, required columns, limit, equals}) async {
            final idEquals = equals?['id'];
            if (idEquals != null) {
              return routeRows.where((row) => row['id'] == idEquals).toList();
            }
            return routeRows;
          },
      rawWriter:
          ({
            required tableName,
            required operation,
            row,
            rows,
            equals,
            values,
          }) async {
            capturedWrites.add(
              _Write(
                table: tableName,
                operation: operation,
                row: row,
                rows: rows,
                equals: equals,
                values: values,
              ),
            );
            if (operation == 'insert') {
              return [routeRows.first];
            }
            return null;
          },
    ),
    waypointsTable: SupabaseTableRepository(
      tableName: 'user_route_waypoints',
      rawFetcher:
          ({required tableName, required columns, limit, equals}) async {
            return waypointRows[equals?['route_id']] ?? const [];
          },
      rawWriter:
          ({
            required tableName,
            required operation,
            row,
            rows,
            equals,
            values,
          }) async {
            capturedWrites.add(
              _Write(
                table: tableName,
                operation: operation,
                row: row,
                rows: rows,
                equals: equals,
                values: values,
              ),
            );
            if (failWaypointInsert &&
                tableName == 'user_route_waypoints' &&
                operation == 'insertAll') {
              throw Exception('PostgrestException(code: 23502)');
            }
            return null;
          },
    ),
  );
}

SavedRoute _draft({List<RouteWaypoint> waypoints = const []}) {
  return SavedRoute(
    id: '',
    title: '测试路线',
    dateRange: '2026.09.19',
    duration: '1天0晚',
    distance: '3.2km',
    waypoints: waypoints,
  );
}
