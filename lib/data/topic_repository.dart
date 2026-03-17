import '../models/topic_record.dart';
import 'supabase_table_repository.dart';

/// `Topic` 表仓储。
class TopicRepository {
  const TopicRepository({
    SupabaseTableRepository? tableRepository,
  }) : _tableRepository =
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
  Future<List<TopicRecord>> fetchTopicsByCelebrity(String celebrityName) {
    return _tableRepository.fetchAll<TopicRecord>(
      mapper: TopicRecord.fromMap,
      equals: {'celebrity': celebrityName},
    );
  }
}
