import '../models/topic_record.dart';
import 'supabase_table_repository.dart';

/// `Topic` 表仓储。
class TopicRepository {
  const TopicRepository({SupabaseTableRepository? tableRepository})
    : _tableRepository =
          tableRepository ?? const SupabaseTableRepository(tableName: 'Topic');

  final SupabaseTableRepository _tableRepository;

  /// 获取全部主题。
  Future<List<TopicRecord>> fetchTopics({int? limit}) {
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

    final exactMatched = await _tableRepository.fetchAll<TopicRecord>(
      mapper: TopicRecord.fromMap,
      equals: {'celebrity': celebrityName},
    );

    return exactMatched;
  }

  String _normalizeName(String value) {
    return value.replaceAll(RegExp(r'[\s\u3000]+'), '').trim();
  }
}
