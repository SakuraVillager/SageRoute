import '../models/celebrity_profile.dart';
import 'supabase_table_repository.dart';

typedef CelebrityFetcher = Future<List<CelebrityProfile>> Function();

/// 人物仓储：
/// - 对外提供强类型 `CelebrityProfile`
/// - 底层复用通用 `SupabaseTableRepository`
class CelebrityRepository {
  const CelebrityRepository({
    CelebrityFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
  }) : _fetcher = fetcher,
       _tableRepository =
           tableRepository ??
           const SupabaseTableRepository(tableName: 'Celebrity');

  final CelebrityFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;

  Future<List<CelebrityProfile>> fetchCelebrities() async {
    if (_fetcher != null) {
      return _fetcher();
    }

    return _tableRepository.fetchAll<CelebrityProfile>(
      mapper: CelebrityProfile.fromMap,
    );
  }

  /// 按 id 取单个人物；不存在时返回 null。
  Future<CelebrityProfile?> fetchById(int id) async {
    if (_fetcher != null) {
      final celebrities = await _fetcher();
      for (final celebrity in celebrities) {
        if (celebrity.id == id) return celebrity;
      }
      return null;
    }

    final rows = await _tableRepository.fetchAllRaw(
      limit: 1,
      equals: <String, dynamic>{'id': id},
    );
    if (rows.isEmpty) return null;
    return CelebrityProfile.fromMap(rows.first);
  }

  Future<List<CelebrityProfile>> searchByName(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const <CelebrityProfile>[];

    final fetcher = _fetcher;
    if (fetcher != null) {
      final celebrities = await fetcher();
      return celebrities
          .where((celebrity) => celebrity.name.contains(normalizedQuery))
          .toList(growable: false);
    }

    return _tableRepository.fetchWhereIlike<CelebrityProfile>(
      column: 'name',
      pattern: '%$normalizedQuery%',
      mapper: CelebrityProfile.fromMap,
    );
  }
}
