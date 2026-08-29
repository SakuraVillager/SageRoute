import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/article_image_record.dart';

void main() {
  test('ArticleImageRecord maps the article_images table contract', () {
    final image = ArticleImageRecord.fromMap(const <String, dynamic>{
      'id': 9,
      'article_id': 3,
      'role': 'featured',
      'image_url': 'https://images.unsplash.com/photo-1',
      'alt_text': '湖边春日柳树',
      'source': 'unsplash',
      'photographer_name': 'Jane Doe',
      'attribution_url': 'https://unsplash.com/@janedoe',
      'sort_order': 2,
      'created_at': '2026-08-26T09:30:00.000Z',
    });

    expect(image.id, 9);
    expect(image.articleId, 3);
    expect(image.role, ArticleImageRole.featured);
    expect(image.url, 'https://images.unsplash.com/photo-1');
    expect(image.sortOrder, 2);
    expect(image.toMap()['role'], 'featured');
  });
}
