import 'article_image_record.dart';
import 'article_record.dart';

/// Resolves article image roles while preserving the table-level fallback.
class ArticleMedia {
  const ArticleMedia({required this.article, required this.images});

  final ArticleRecord article;
  final List<ArticleImageRecord> images;

  ArticleImageRecord? imageFor(ArticleImageRole role) {
    final requested = _firstWithRole(role);
    if (requested != null) return requested;

    final fallbackRole = switch (role) {
      ArticleImageRole.featured ||
      ArticleImageRole.poster => ArticleImageRole.cover,
      ArticleImageRole.cover => ArticleImageRole.featured,
    };
    return _firstWithRole(fallbackRole);
  }

  String urlFor(ArticleImageRole role) =>
      imageFor(role)?.url ?? article.coverImageUrl;

  String? altTextFor(ArticleImageRole role) => imageFor(role)?.altText;

  ArticleImageRecord? _firstWithRole(ArticleImageRole role) {
    final matching =
        images
            .where((image) => image.role == role && image.url.isNotEmpty)
            .toList(growable: false)
          ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return matching.isEmpty ? null : matching.first;
  }
}
