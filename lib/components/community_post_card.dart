import 'package:flutter/material.dart';
import '../models/community_post.dart';
import '../theme/color_schemes.dart';

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onOpen,
    required this.onLike,
    required this.onShare,
    this.onDelete,
    this.onOpenRoute,
    this.onComment,
    this.busy = false,
  });
  final CommunityPost post;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenRoute;
  final VoidCallback? onComment;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final route = post.route;
    final date = post.createdAt.toLocal();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.sageBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.brandWash,
                  foregroundColor: AppColors.brandDark,
                  child: Text(
                    post.authorName.isEmpty
                        ? '旅'
                        : post.authorName.characters.first,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${date.month}月${date.day}日 · ${route == null ? '随手记' : '路线分享'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.sageMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    onPressed: busy ? null : onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '删除我的动态',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  post.body,
                  style: const TextStyle(fontSize: 15, height: 1.85),
                ),
              ),
            ),
            if (route != null) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: onOpenRoute ?? onOpen,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandWash,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.route_outlined,
                            color: AppColors.sageAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              route.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${route.waypoints.length} 个地点${route.figureName == null ? '' : ' · ${route.figureName}'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.sageMuted,
                        ),
                      ),
                      if (route.waypoints.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          route.waypoints
                              .take(4)
                              .map((p) => p.name)
                              .join(' → '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: busy ? null : onLike,
                  icon: Icon(
                    post.liked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                  ),
                  label: Text('${post.likeCount}'),
                ),
                TextButton.icon(
                  onPressed: onComment ?? onOpen,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('${post.commentCount}'),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_outlined, size: 19),
                  tooltip: '分享动态链接',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
