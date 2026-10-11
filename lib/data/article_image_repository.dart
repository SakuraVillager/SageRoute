import '../models/article_image_record.dart';
import 'supabase_table_repository.dart';

typedef ArticleImageFetcher = Future<List<ArticleImageRecord>> Function();

/// Read-only access to media assigned to `Article` records.
class ArticleImageRepository {
  const ArticleImageRepository({
    ArticleImageFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
  }) : _fetcher = fetcher,
       _tableRepository =
           tableRepository ??
           const SupabaseTableRepository(tableName: 'article_images');

  final ArticleImageFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;

  Future<List<ArticleImageRecord>> fetchArticleImages({int? articleId}) async {
    final fetcher = _fetcher;
    if (fetcher != null) {
      final images = await fetcher();
      if (articleId == null) return images;
      return images
          .where((image) => image.articleId == articleId)
          .toList(growable: false);
    }

    return _tableRepository.fetchAll<ArticleImageRecord>(
      mapper: ArticleImageRecord.fromMap,
      equals: articleId == null
          ? null
          : <String, dynamic>{'article_id': articleId},
    );
  }
}
