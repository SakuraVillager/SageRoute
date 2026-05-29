import '../models/poi_celebrity_relation_record.dart';
import 'supabase_table_repository.dart';

typedef RelationFetcher = Future<List<PoiCelebrityRelationRecord>> Function();

/// `poi_celebrity_relatian` 表仓储。
class PoiCelebrityRelationRepository {
  const PoiCelebrityRelationRepository({
    RelationFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
  }) : _fetcher = fetcher,
       _tableRepository = tableRepository ??
           const SupabaseTableRepository(tableName: 'poi_celebrity_relatian');

  final RelationFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;

  /// 获取全部人物-地点关系。
  Future<List<PoiCelebrityRelationRecord>> fetchRelations({int? limit}) {
    if (_fetcher != null) {
      return _fetcher();
    }
    return _tableRepository.fetchAll<PoiCelebrityRelationRecord>(
      mapper: PoiCelebrityRelationRecord.fromMap,
      limit: limit,
    );
  }

  /// 按人物名过滤关系。
  Future<List<PoiCelebrityRelationRecord>> fetchRelationsByCelebrity(
    String celebrityName,
  ) {
    return _tableRepository.fetchAll<PoiCelebrityRelationRecord>(
      mapper: PoiCelebrityRelationRecord.fromMap,
      equals: {'celebrity_name': celebrityName},
    );
  }

  /// 按地点名过滤关系。
  Future<List<PoiCelebrityRelationRecord>> fetchRelationsByLocation(
    String locationName,
  ) {
    return _tableRepository.fetchAll<PoiCelebrityRelationRecord>(
      mapper: PoiCelebrityRelationRecord.fromMap,
      equals: {'location_name': locationName},
    );
  }
}
