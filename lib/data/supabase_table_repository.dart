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

/// 通用 Supabase 表仓储：
/// - 通过 tableName 指定目标表
/// - 统一复用 DatabaseService 的重试与超时能力
/// - 通过 mapper 把 Map 行数据转换为业务模型对象
class SupabaseTableRepository {
  const SupabaseTableRepository({
    required this.tableName,
    RawTableFetcher? rawFetcher,
    RawTableIlikeFetcher? rawIlikeFetcher,
  }) : _rawFetcher = rawFetcher,
       _rawIlikeFetcher = rawIlikeFetcher;

  final String tableName;
  final RawTableFetcher? _rawFetcher;
  final RawTableIlikeFetcher? _rawIlikeFetcher;

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
}
