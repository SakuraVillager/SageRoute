import '../services/database_service.dart';

typedef _CelebrityFetcher = Future<List<Map<String, dynamic>>> Function();

/// 该仓库直接使用 Supabase 客户端从 `Celebrity` 表拉取人物数据，供页面层消费。
class CelebrityRepository {
  const CelebrityRepository({
    _CelebrityFetcher? fetcher,
  }) : _fetcher = fetcher ?? _defaultFetcher;

  final _CelebrityFetcher _fetcher;

  static Future<List<Map<String, dynamic>>> _defaultFetcher() async {
    // 这里直接通过全局 Supabase client 请求 Celebrity 表。
    final response = await DatabaseService.runQueryWithRetry(
      () => DatabaseService.client.from('Celebrity').select(),
      operationName: 'fetchCelebrities(Celebrity)',
    );

    return response
        .map<Map<String, dynamic>>(
          (row) => Map<String, dynamic>.from(row as Map),
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchCelebrities() async {
    return _fetcher();
  }
}