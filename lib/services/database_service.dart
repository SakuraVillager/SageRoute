import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await dotenv.load(fileName: 'assets/env.env');
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception('SUPABASE_URL 或 SUPABASE_ANON_KEY 未配置');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  static Future<void> testConnection({
    String table = 'Celebrity',
  }) async {
    final data = await client.from(table).select().limit(1);
    print('连接成功！查询结果: $data');
  }

  static Future<List<dynamic>> getFieldList({
    required String table,
    required String field,
  }) async {
    final response = await client.from(table).select(field);
    return response
        .map<dynamic>((row) => row[field])
        .where((value) => value != null)
        .toList();
  }
}