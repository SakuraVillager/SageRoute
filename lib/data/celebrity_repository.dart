import '../models/celebrity_profile.dart';
import 'supabase_table_repository.dart';

typedef _CelebrityFetcher = Future<List<CelebrityProfile>> Function();

/// 人物仓储：
/// - 对外提供强类型 `CelebrityProfile`
/// - 底层复用通用 `SupabaseTableRepository`
class CelebrityRepository {
  const CelebrityRepository({
    _CelebrityFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
  }) : _fetcher = fetcher,
       _tableRepository =
           tableRepository ?? const SupabaseTableRepository(tableName: 'Celebrity');

  final _CelebrityFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;

  Future<List<CelebrityProfile>> fetchCelebrities() async {
    if (_fetcher != null) {
      return _fetcher();
    }

    return _tableRepository.fetchAll<CelebrityProfile>(
      mapper: CelebrityProfile.fromMap,
    );
  }
}