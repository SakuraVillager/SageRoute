import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/article_repository.dart';
import 'package:sageroute/models/article_record.dart';

void main() {
  test(
    'fetchArticles returns deterministic injected Article records',
    () async {
      final repository = ArticleRepository(
        fetcher: () async => const <ArticleRecord>[
          ArticleRecord(
            id: 1,
            createdAt: null,
            topic: '诗词',
            title: '钱塘湖春行',
            summary: '湖光山色',
            content: '正文',
            coverImageUrl: '',
          ),
        ],
      );

      final articles = await repository.fetchArticles();

      expect(articles, hasLength(1));
      expect(articles.single.title, '钱塘湖春行');
    },
  );

  test('searchByTitle finds a substring in injected article titles', () async {
    final repository = ArticleRepository(
      fetcher: () async => const <ArticleRecord>[
        ArticleRecord(
          id: 1,
          createdAt: null,
          topic: '诗词',
          title: '钱塘湖春行',
          summary: '',
          content: '',
          coverImageUrl: '',
        ),
        ArticleRecord(
          id: 2,
          createdAt: null,
          topic: '游记',
          title: '赤壁夜游',
          summary: '',
          content: '',
          coverImageUrl: '',
        ),
      ],
    );

    final articles = await repository.searchByTitle('钱塘');

    expect(articles.map((article) => article.title), <String>['钱塘湖春行']);
  });
}
