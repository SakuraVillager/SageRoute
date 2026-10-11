import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/article_image_repository.dart';
import 'package:sageroute/models/article_image_record.dart';

void main() {
  test('fetchArticleImages returns deterministic injected media', () async {
    final repository = ArticleImageRepository(
      fetcher: () async => const <ArticleImageRecord>[
        ArticleImageRecord(
          id: 1,
          articleId: 7,
          role: ArticleImageRole.cover,
          url: 'https://images.unsplash.com/photo-1',
          altText: '文章封面',
          source: 'unsplash',
          photographerName: null,
          attributionUrl: null,
          sortOrder: 0,
          createdAt: null,
        ),
      ],
    );

    final images = await repository.fetchArticleImages(articleId: 7);

    expect(images, hasLength(1));
    expect(images.single.articleId, 7);
  });
}
