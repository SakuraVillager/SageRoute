import '../models/dynasty_record.dart';
import 'supabase_table_repository.dart';

typedef DynastyFetcher = Future<List<DynastyRecord>> Function();

/// `Dynasty` 表仓储。
class DynastyRepository {
  const DynastyRepository({
    DynastyFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
  }) : _fetcher = fetcher,
       _tableRepository =
           tableRepository ?? const SupabaseTableRepository(tableName: 'Dynasty');

  final DynastyFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;

  /// 获取全部朝代。
  Future<List<DynastyRecord>> fetchDynasties({int? limit}) {
    if (_fetcher != null) {
      return _fetcher();
    }
    return _tableRepository.fetchAll<DynastyRecord>(
      mapper: DynastyRecord.fromMap,
      limit: limit,
    );
  }
}
