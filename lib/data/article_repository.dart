import '../models/article_record.dart';
import 'supabase_table_repository.dart';

typedef ArticleFetcher = Future<List<ArticleRecord>> Function();

/// `Article` 表仓储。
class ArticleRepository {
  const ArticleRepository({
    ArticleFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
  }) : _fetcher = fetcher,
       _tableRepository =
           tableRepository ??
           const SupabaseTableRepository(tableName: 'Article');

  final ArticleFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;

  Future<ArticleRecord?> fetchById(int id) async {
    final fetcher = _fetcher;
    if (fetcher != null) {
      for (final record in await fetcher()) {
        if (record.id == id) return record;
      }
      return null;
    }
    final records = await _tableRepository.fetchAll<ArticleRecord>(
      mapper: ArticleRecord.fromMap,
      equals: {'id': id},
      limit: 1,
    );
    return records.isEmpty ? null : records.first;
  }

  Future<List<ArticleRecord>> fetchArticles({int? limit}) async {
    final fetcher = _fetcher;
    if (fetcher != null) {
      final articles = await fetcher();
      if (limit != null && limit < articles.length) {
        return articles.sublist(0, limit);
      }
      return articles;
    }

    return _tableRepository.fetchAll<ArticleRecord>(
      mapper: ArticleRecord.fromMap,
      limit: limit,
    );
  }

  Future<List<ArticleRecord>> searchByTitle(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const <ArticleRecord>[];

    final fetcher = _fetcher;
    if (fetcher != null) {
      final articles = await fetcher();
      return articles
          .where((article) => article.title.contains(normalizedQuery))
          .toList(growable: false);
    }

    return _tableRepository.fetchWhereIlike<ArticleRecord>(
      column: 'title',
      pattern: '%$normalizedQuery%',
      mapper: ArticleRecord.fromMap,
    );
  }
}
