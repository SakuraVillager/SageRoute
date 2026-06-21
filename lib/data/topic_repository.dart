import '../models/topic_record.dart';
import 'supabase_table_repository.dart';

typedef TopicFetcher = Future<List<TopicRecord>> Function();

/// `Topic` 表仓储。
class TopicRepository {
  const TopicRepository({
    TopicFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
  }) : _fetcher = fetcher,
       _tableRepository =
          tableRepository ?? const SupabaseTableRepository(tableName: 'Topic');

  final TopicFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;

  /// 获取全部主题。
  Future<List<TopicRecord>> fetchTopics({int? limit}) async {
    if (_fetcher != null) {
      final all = await _fetcher();
      if (limit != null && limit < all.length) {
        return all.sublist(0, limit);
      }
      return all;
    }
    return _tableRepository.fetchAll<TopicRecord>(
      mapper: TopicRecord.fromMap,
      limit: limit,
    );
  }

  /// 按人物名过滤主题。
  Future<List<TopicRecord>> fetchTopicsByCelebrity(String celebrityName) async {
    final normalizedName = _normalizeName(celebrityName);
    if (normalizedName.isEmpty) {
      return const <TopicRecord>[];
    }

    if (_fetcher != null) {
      final all = await _fetcher();
      return all
          .where((t) => t.celebrity == celebrityName)
          .toList(growable: false);
    }

    final exactMatched = await _tableRepository.fetchAll<TopicRecord>(
      mapper: TopicRecord.fromMap,
      equals: {'celebrity': celebrityName},
    );

    return exactMatched;
  }

  /// 按 ID 获取单个主题。
  Future<TopicRecord?> fetchTopicById(int id) async {
    if (_fetcher != null) {
      final all = await _fetcher();
      for (final t in all) {
        if (t.id == id) return t;
      }
      return null;
    }
    final results = await _tableRepository.fetchAll<TopicRecord>(
      mapper: TopicRecord.fromMap,
      equals: {'id': id},
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  String _normalizeName(String value) {
    return value.replaceAll(RegExp(r'[\s\u3000]+'), '').trim();
  }
}
