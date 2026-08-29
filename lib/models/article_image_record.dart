/// The semantic display purpose of an image attached to an article.
enum ArticleImageRole {
  cover('cover'),
  featured('featured'),
  poster('poster');

  const ArticleImageRole(this.databaseValue);

  final String databaseValue;

  static ArticleImageRole fromDatabaseValue(Object? value) => switch (value) {
    'featured' => ArticleImageRole.featured,
    'poster' => ArticleImageRole.poster,
    _ => ArticleImageRole.cover,
  };
}

/// An image record from the `article_images` table.
class ArticleImageRecord {
  const ArticleImageRecord({
    required this.id,
    required this.articleId,
    required this.role,
    required this.url,
    required this.altText,
    required this.source,
    required this.photographerName,
    required this.attributionUrl,
    required this.sortOrder,
    required this.createdAt,
  });

  final int id;
  final int articleId;
  final ArticleImageRole role;
  final String url;
  final String? altText;
  final String? source;
  final String? photographerName;
  final String? attributionUrl;
  final int sortOrder;
  final DateTime? createdAt;

  factory ArticleImageRecord.fromMap(Map<String, dynamic> map) =>
      ArticleImageRecord(
        id: (map['id'] as num?)?.toInt() ?? 0,
        articleId: (map['article_id'] as num?)?.toInt() ?? 0,
        role: ArticleImageRole.fromDatabaseValue(map['role']),
        url: (map['image_url'] ?? '').toString(),
        altText: map['alt_text']?.toString(),
        source: map['source']?.toString(),
        photographerName: map['photographer_name']?.toString(),
        attributionUrl: map['attribution_url']?.toString(),
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'article_id': articleId,
    'role': role.databaseValue,
    'image_url': url,
    'alt_text': altText,
    'source': source,
    'photographer_name': photographerName,
    'attribution_url': attributionUrl,
    'sort_order': sortOrder,
    'created_at': createdAt?.toIso8601String(),
  };
}
