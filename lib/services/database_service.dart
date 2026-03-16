import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

typedef InitFn = Future<void> Function(String url, String anonKey);
typedef QueryTableFn = Future<dynamic> Function(String table);
typedef QueryFieldFn = Future<dynamic> Function(String table, String field);

/// 封装所有与 Supabase 交互的方法，并提供共用客户端。
/// 其他代码只需调用这一层，不必直接 new SupabaseClient。
class DatabaseService {
  static bool _initialized = false;
  static const Duration _queryTimeout = Duration(seconds: 25);
  static const int _maxRetryCount = 2;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize({
    Map<String, String>? env,
    InitFn? initializer,
  }) async {
    // 这里必须提前初始化 Supabase，并使用 assets/env.env 中的 URL/Key。
    if (_initialized) {
      return;
    }

    if (env == null) {
      await dotenv.load(fileName: 'assets/env.env');
    }

    final sourceEnv = env ?? dotenv.env;
    final supabaseUrl = sourceEnv['SUPABASE_URL'] ?? '';
    final supabaseKey = sourceEnv['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception('SUPABASE_URL 或 SUPABASE_ANON_KEY 未配置');
    }

    final init = initializer ??
        (String url, String anonKey) =>
            Supabase.initialize(url: url, anonKey: anonKey);
    try {
      await init(supabaseUrl, supabaseKey);
      _initialized = true;
    } catch (error) {
      final message = error.toString();
      if (message.contains('already initialized')) {
        _initialized = true;
        return;
      }
      rethrow;
    }
  }

  static Future<void> testConnection({
    String table = 'Celebrity',
    QueryTableFn? query,
  }) async {
    // 通过 Supabase Client 检查 Celebrity 表是否可访问。
    final executeQuery =
        query ??
        (String tableName) => client.from(tableName).select().limit(1);
    final response = await runQueryWithRetry(
      () => executeQuery(table).timeout(_queryTimeout),
      operationName: 'testConnection($table)',
    );
    final data = _normalizeRows(response);
    developer.log('连接成功！查询结果: $data', name: 'DatabaseService');
  }

  static Future<List<dynamic>> getFieldList({
    required String table,
    required String field,
    QueryFieldFn? query,
  }) async {
    // 通过 Supabase 表字段查询结果并返回非空值。
    final executeQuery =
        query ??
        (String tableName, String fieldName) =>
            client.from(tableName).select(fieldName);
    final response = await runQueryWithRetry(
      () => executeQuery(table, field).timeout(_queryTimeout),
      operationName: 'getFieldList($table.$field)',
    );
    final rows = _normalizeRows(response);
    return rows
        .map<dynamic>((row) => row[field])
        .where((value) => value != null)
        .toList();
  }

  static Future<T> runQueryWithRetry<T>(
    Future<T> Function() operation, {
    String operationName = 'supabase_query',
    int maxRetries = _maxRetryCount,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } on TimeoutException catch (error) {
        lastError = error;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }

      if (attempt < maxRetries) {
        final delay = Duration(milliseconds: 400 * (attempt + 1));
        await Future<void>.delayed(delay);
      }
    }

    throw Exception('数据库请求失败：$operationName，重试后仍超时/网络异常。原始错误: $lastError');
  }

  static List<Map<String, dynamic>> _normalizeRows(dynamic response) {
    if (response is! List) {
      throw Exception('数据库返回格式错误：期望 List，实际 ${response.runtimeType}');
    }

    return response
        .whereType<Map>()
        .map<Map<String, dynamic>>(
          (row) => Map<String, dynamic>.from(row),
        )
        .toList(growable: false);
  }

  @visibleForTesting
  static void debugResetForTest() {
    _initialized = false;
  }
}