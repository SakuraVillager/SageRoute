import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/article_record.dart';

void main() {
  test('ArticleRecord maps the initial Article table contract', () {
    final article = ArticleRecord.fromMap(const <String, dynamic>{
      'id': 7,
      'created_at': '2026-08-26T09:30:00.000Z',
      'topic': '唐诗',
      'title': '白居易的江南行记',
      'summary': '从诗文走进江南山水。',
      'content': '文章正文',
      'cover_image_url': 'https://example.com/cover.jpg',
    });

    expect(article.id, 7);
    expect(article.topic, '唐诗');
    expect(article.title, '白居易的江南行记');
    expect(article.summary, '从诗文走进江南山水。');
    expect(article.coverImageUrl, 'https://example.com/cover.jpg');
    expect(article.createdAt, DateTime.parse('2026-08-26T09:30:00.000Z'));
    expect(article.toMap()['title'], '白居易的江南行记');
  });

  test('ArticleRecord accepts empty optional article content', () {
    final article = ArticleRecord.fromMap(const <String, dynamic>{
      'id': 8,
      'title': '未命名文章',
    });

    expect(article.topic, isEmpty);
    expect(article.summary, isEmpty);
    expect(article.content, isEmpty);
    expect(article.coverImageUrl, isEmpty);
    expect(article.createdAt, isNull);
  });
}
