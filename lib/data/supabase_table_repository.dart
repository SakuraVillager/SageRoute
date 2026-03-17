import '../services/database_service.dart';

typedef RowMapper<T> = T Function(Map<String, dynamic> row);

/// 通用 Supabase 表仓储：
/// - 通过 tableName 指定目标表
/// - 统一复用 DatabaseService 的重试与超时能力
/// - 通过 mapper 把 Map 行数据转换为业务模型对象
class SupabaseTableRepository {
  const SupabaseTableRepository({required this.tableName});

  final String tableName;

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
      () async {
        dynamic query = DatabaseService.client.from(tableName).select(columns);

        if (equals != null && equals.isNotEmpty) {
          equals.forEach((key, value) {
            query = query.eq(key, value);
          });
        }

        if (limit != null) {
          query = query.limit(limit);
        }

        return await query;
      },
      operationName: 'fetchAllRaw($tableName)',
    );

    if (response is! List) {
      throw Exception('表 $tableName 返回格式错误：期望 List，实际 ${response.runtimeType}');
    }

    return response
        .whereType<Map>()
        .map<Map<String, dynamic>>(
          (row) => Map<String, dynamic>.from(row),
        )
        .toList(growable: false);
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
}