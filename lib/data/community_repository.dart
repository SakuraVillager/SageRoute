import '../models/community_post.dart';
import 'social_gateway.dart';

class CommunityRepository {
  const CommunityRepository({this.gateway = const SocialGateway()});
  final SocialGateway gateway;
  Future<List<CommunityPost>> feed({DateTime? before, String? kind}) async =>
      socialRows(
        await gateway.call('sr_feed', {
          'p_before': before?.toUtc().toIso8601String(),
          'p_limit': 20,
          'p_kind': kind,
        }),
      ).map(CommunityPost.fromMap).toList();
  Future<CommunityPost?> post(String id) async {
    final value = await gateway.call('sr_post', {'p_id': id});
    return value == null
        ? null
        : CommunityPost.fromMap(Map<String, dynamic>.from(value as Map));
  }

  Future<String> publish(String body, {String? routeId}) async {
    gateway.requireAccount();
    final text = body.trim();
    if (text.isEmpty || text.length > 2000) {
      throw StateError('请填写 1–2000 字的分享内容');
    }
    return await gateway.call('sr_create_post', {
          'p_body': text,
          'p_route_id': routeId,
        })
        as String;
  }

  Future<void> like(String id, bool liked) async {
    gateway.requireAccount();
    await gateway.call('sr_set_like', {'p_post_id': id, 'p_liked': liked});
  }

  Future<List<CommunityComment>> comments(String id) async => socialRows(
    await gateway.call('sr_comments', {'p_post_id': id}),
  ).map(CommunityComment.fromMap).toList();
  Future<void> comment(String id, String body) async {
    gateway.requireAccount();
    if (body.trim().isEmpty || body.trim().length > 500) {
      throw StateError('请填写 1–500 字的评论');
    }
    await gateway.call('sr_add_comment', {
      'p_post_id': id,
      'p_body': body.trim(),
    });
  }

  Future<void> delete(String id) async {
    gateway.requireAccount();
    await gateway.call('sr_delete_post', {'p_id': id});
  }
}
