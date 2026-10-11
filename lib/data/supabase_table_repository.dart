import 'dart:developer' as developer;

import '../services/database_service.dart';

typedef RowMapper<T> = T Function(Map<String, dynamic> row);
typedef RawTableFetcher =
    Future<dynamic> Function({
      required String tableName,
      required String columns,
      int? limit,
      Map<String, dynamic>? equals,
    });

typedef RawTableIlikeFetcher =
    Future<dynamic> Function({
      required String tableName,
      required String columns,
      required String ilikeColumn,
      required String ilikePattern,
      int? limit,
    });

typedef RawTableWriter =
    Future<dynamic> Function({
      required String tableName,
      required String operation,
      Map<String, dynamic>? row,
      List<Map<String, dynamic>>? rows,
      Map<String, dynamic>? equals,
      Map<String, dynamic>? values,
    });

/// 通用 Supabase 表仓储：
/// - 通过 tableName 指定目标表
/// - 统一复用 DatabaseService 的重试与超时能力
/// - 通过 mapper 把 Map 行数据转换为业务模型对象
class SupabaseTableRepository {
  const SupabaseTableRepository({
    required this.tableName,
    RawTableFetcher? rawFetcher,
    RawTableIlikeFetcher? rawIlikeFetcher,
    RawTableWriter? rawWriter,
  }) : _rawFetcher = rawFetcher,
       _rawIlikeFetcher = rawIlikeFetcher,
       _rawWriter = rawWriter;

  final String tableName;
  final RawTableFetcher? _rawFetcher;
  final RawTableIlikeFetcher? _rawIlikeFetcher;
  final RawTableWriter? _rawWriter;

  /// 读取当前表全部记录并返回原始行数据。
  /// 可选参数：
  /// - columns: 选择字段，默认 `*`
  /// - limit: 限制返回数量
  /// - equals: 等值过滤（key = value）
  Future<List<Map<String, dynamic>>> fetchAllRaw({
    String columns = '*',
    int? limit,
    Map<String, dynamic>? equals,
  }) async {
    final response = await DatabaseService.runQueryWithRetry(
      () => _fetchRaw(columns: columns, limit: limit, equals: equals),
      operationName: 'fetchAllRaw($tableName)',
    );

    return DatabaseService.normalizeRows(response);
  }

  /// Reads records using Supabase/Postgres `ILIKE` with an explicit pattern.
  Future<List<Map<String, dynamic>>> fetchWhereIlikeRaw({
    required String column,
    required String pattern,
    String columns = '*',
    int? limit,
  }) async {
    final response = await DatabaseService.runQueryWithRetry(
      () => _fetchIlikeRaw(
        columns: columns,
        column: column,
        pattern: pattern,
        limit: limit,
      ),
      operationName: 'fetchWhereIlikeRaw($tableName.$column)',
    );

    return DatabaseService.normalizeRows(response);
  }

  Future<dynamic> _fetchRaw({
    required String columns,
    int? limit,
    Map<String, dynamic>? equals,
  }) async {
    final fetcher = _rawFetcher;
    if (fetcher != null) {
      return fetcher(
        tableName: tableName,
        columns: columns,
        limit: limit,
        equals: equals,
      );
    }

    dynamic query = DatabaseService.client.from(tableName).select(columns);

    if (equals != null && equals.isNotEmpty) {
      equals.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  Future<dynamic> _fetchIlikeRaw({
    required String columns,
    required String column,
    required String pattern,
    int? limit,
  }) async {
    final fetcher = _rawIlikeFetcher;
    if (fetcher != null) {
      return fetcher(
        tableName: tableName,
        columns: columns,
        ilikeColumn: column,
        ilikePattern: pattern,
        limit: limit,
      );
    }

    dynamic query = DatabaseService.client.from(tableName).select(columns);
    query = query.ilike(column, pattern);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query;
  }

  /// 读取当前表并直接映射为模型对象列表。
  Future<List<T>> fetchAll<T>({
    required RowMapper<T> mapper,
    String columns = '*',
    int? limit,
    Map<String, dynamic>? equals,
  }) async {
    final rows = await fetchAllRaw(
      columns: columns,
      limit: limit,
      equals: equals,
    );
    return rows.map<T>(mapper).toList(growable: false);
  }

  /// Reads and maps records matching a caller-provided `ILIKE` pattern.
  Future<List<T>> fetchWhereIlike<T>({
    required String column,
    required String pattern,
    required RowMapper<T> mapper,
    String columns = '*',
    int? limit,
  }) async {
    final rows = await fetchWhereIlikeRaw(
      column: column,
      pattern: pattern,
      columns: columns,
      limit: limit,
    );
    return rows.map<T>(mapper).toList(growable: false);
  }

  /// 插入单条记录并返回写入后的行（含数据库生成的默认值，如 id）。
  Future<Map<String, dynamic>> insertRaw(Map<String, dynamic> row) async {
    final response = await DatabaseService.runQueryWithRetry(
      () => _write(operation: 'insert', row: row),
      operationName: 'insertRaw($tableName)',
    );
    final rows = DatabaseService.normalizeRows(response);
    if (rows.isEmpty) {
      throw Exception('数据库写入失败：insertRaw($tableName) 未返回数据');
    }
    return rows.first;
  }

  /// 批量插入记录。
  Future<void> insertAllRaw(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await DatabaseService.runQueryWithRetry(
      () => _write(operation: 'insertAll', rows: rows),
      operationName: 'insertAllRaw($tableName)',
    );
  }

  /// 按等值条件更新记录。
  Future<void> updateRaw({
    required Map<String, dynamic> equals,
    required Map<String, dynamic> values,
  }) async {
    if (values.isEmpty) return;
    await DatabaseService.runQueryWithRetry(
      () => _write(operation: 'update', equals: equals, values: values),
      operationName: 'updateRaw($tableName)',
    );
  }

  /// 按等值条件删除记录。
  Future<void> deleteRaw(Map<String, dynamic> equals) async {
    await DatabaseService.runQueryWithRetry(
      () => _write(operation: 'delete', equals: equals),
      operationName: 'deleteRaw($tableName)',
    );
  }

  Future<dynamic> _write({
    required String operation,
    Map<String, dynamic>? row,
    List<Map<String, dynamic>>? rows,
    Map<String, dynamic>? equals,
    Map<String, dynamic>? values,
  }) async {
    try {
      final writer = _rawWriter;
      if (writer != null) {
        return await writer(
          tableName: tableName,
          operation: operation,
          row: row,
          rows: rows,
          equals: equals,
          values: values,
        );
      }

      switch (operation) {
        case 'insert':
          return await DatabaseService.client
              .from(tableName)
              .insert(row!)
              .select();
        case 'insertAll':
          return await DatabaseService.client.from(tableName).insert(rows!);
        case 'update':
          dynamic query = DatabaseService.client
              .from(tableName)
              .update(values!);
          equals!.forEach((key, value) {
            query = query.eq(key, value);
          });
          return await query;
        case 'delete':
          dynamic query = DatabaseService.client.from(tableName).delete();
          equals!.forEach((key, value) {
            query = query.eq(key, value);
          });
          return await query;
        default:
          throw ArgumentError('未知写操作: $operation');
      }
    } catch (error, stackTrace) {
      final rowCount = rows?.length ?? (row == null ? 0 : 1);
      developer.log(
        'SUPABASE_WRITE_FAILED table=$tableName operation=$operation '
        'row_count=$rowCount',
        name: 'SageRoute.SupabaseTableRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
