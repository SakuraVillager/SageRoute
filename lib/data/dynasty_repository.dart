import '../models/dynasty_record.dart';
import 'supabase_table_repository.dart';

/// `Dynasty` 表仓储。
class DynastyRepository {
  const DynastyRepository({
    SupabaseTableRepository? tableRepository,
  }) : _tableRepository =
           tableRepository ?? const SupabaseTableRepository(tableName: 'Dynasty');

  final SupabaseTableRepository _tableRepository;

  /// 获取全部朝代。
  Future<List<DynastyRecord>> fetchDynasties({int? limit}) {
    return _tableRepository.fetchAll<DynastyRecord>(
      mapper: DynastyRecord.fromMap,
      limit: limit,
    );
  }
}
