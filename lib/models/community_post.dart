import 'saved_route.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.routeSnapshot,
    this.likeCount = 0,
    this.commentCount = 0,
    this.liked = false,
  });
  final String id;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final Map<String, dynamic>? routeSnapshot;
  final int likeCount;
  final int commentCount;
  final bool liked;

  factory CommunityPost.fromMap(Map<String, dynamic> row) => CommunityPost(
    id: row['id'] as String,
    authorId: row['author_id'] as String,
    authorName: row['author_name'] as String? ?? '旅行者',
    body: row['body'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
    routeSnapshot: row['route_snapshot'] is Map
        ? Map<String, dynamic>.from(row['route_snapshot'] as Map)
        : null,
    likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
    commentCount: (row['comment_count'] as num?)?.toInt() ?? 0,
    liked: row['liked'] == true,
  );

  SavedRoute? get route {
    final snapshot = routeSnapshot;
    if (snapshot == null) return null;
    return SavedRoute.fromMap(
      {...snapshot, 'id': 'post-$id', 'access_role': 'viewer'},
      waypoints: (snapshot['waypoints'] as List? ?? const [])
          .map(
            (row) =>
                RouteWaypoint.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList(),
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorName,
    required this.body,
  });
  final String id;
  final String authorName;
  final String body;
  factory CommunityComment.fromMap(Map<String, dynamic> row) =>
      CommunityComment(
        id: row['id'] as String,
        authorName: row['author_name'] as String? ?? '旅行者',
        body: row['body'] as String,
      );
}
