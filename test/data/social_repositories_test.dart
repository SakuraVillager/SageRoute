import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/community_repository.dart';
import 'package:sageroute/data/route_collaboration_repository.dart';
import 'package:sageroute/data/social_gateway.dart';
import 'package:sageroute/models/community_post.dart';
import 'package:sageroute/models/saved_route.dart';
import 'package:sageroute/route_planning/models/transport_type.dart';

void main() {
  test(
    'anonymous reads are allowed while every mutation requires an account',
    () async {
      final calls = <String>[];
      final gateway = SocialGateway(
        userId: () => null,
        rpc: (name, params) async {
          calls.add(name);
          return name == 'sr_feed' ? [] : null;
        },
      );
      final community = CommunityRepository(gateway: gateway);
      final collaboration = RouteCollaborationRepository(gateway: gateway);
      expect(await community.feed(), isEmpty);
      expect(await collaboration.preview('token'), isNull);
      expect(await collaboration.incoming(), isEmpty);
      await expectLater(community.publish('a note'), throwsStateError);
      await expectLater(community.like('post', true), throwsStateError);
      await expectLater(community.comment('post', 'comment'), throwsStateError);
      await expectLater(community.delete('post'), throwsStateError);
      await expectLater(collaboration.accept(token: 'token'), throwsStateError);
      await expectLater(
        collaboration.createInvite('route', role: 'editor'),
        throwsStateError,
      );
      expect(calls, ['sr_feed', 'sr_invite_info']);
    },
  );

  test(
    'publishing validates and trims content without automatic retries',
    () async {
      var calls = 0;
      final repository = CommunityRepository(
        gateway: SocialGateway(
          userId: () => 'user',
          rpc: (name, params) async {
            calls++;
            expect(name, 'sr_create_post');
            expect(params, {'p_body': '湖边的见闻', 'p_route_id': 'route'});
            throw Exception('SocketException');
          },
        ),
      );
      await expectLater(repository.publish('   '), throwsStateError);
      await expectLater(repository.publish('a' * 2001), throwsStateError);
      expect(calls, 0);
      await expectLater(
        repository.publish(' 湖边的见闻 ', routeId: 'route'),
        throwsException,
      );
      expect(calls, 1);
    },
  );

  test(
    'invites normalize recipient and preserve role; acceptance sends exactly one identity',
    () async {
      final calls = <Map<String, dynamic>>[];
      final repository = RouteCollaborationRepository(
        gateway: SocialGateway(
          userId: () => 'user',
          rpc: (name, params) async {
            calls.add(params);
            if (name == 'sr_accept_invite') return 'route';
            return {
              'id': 'invite',
              'route_id': 'route',
              'role': params['p_role'],
              'token': 'abc',
            };
          },
        ),
      );
      final invite = await repository.createInvite(
        'route',
        role: 'viewer',
        email: ' A@Example.COM ',
      );
      expect(invite.roleLabel, '只读查看');
      expect(calls.first['p_email'], 'a@example.com');
      expect(await repository.accept(invitationId: 'invite'), 'route');
      expect(calls.last, {'p_token': null, 'p_invite_id': 'invite'});
      await expectLater(
        repository.createInvite('route', role: 'owner'),
        throwsArgumentError,
      );
    },
  );

  test(
    'missing RPCs and route conflicts are actionable typed errors',
    () async {
      for (final message in ['PGRST202 sr_feed', '42P01 community_posts']) {
        final gateway = SocialGateway(
          rpc: (_, _) async => throw Exception(message),
        );
        await expectLater(
          gateway.call('sr_feed'),
          throwsA(isA<SocialServiceUnavailable>()),
        );
      }
      final gateway = SocialGateway(
        rpc: (_, _) async => throw Exception('40001 route_conflict'),
      );
      await expectLater(
        gateway.call('sr_replace_waypoints'),
        throwsA(isA<RouteEditConflict>()),
      );
    },
  );

  test(
    'public route snapshot remains read only and contains transport choices',
    () {
      final post = CommunityPost.fromMap({
        'id': 'post',
        'author_id': 'author',
        'body': 'walk',
        'created_at': '2026-10-15T00:00:00Z',
        'route_snapshot': {
          'title': '西湖',
          'waypoints': [
            {
              'name': '苏堤',
              'latitude': 30.25,
              'longitude': 120.14,
              'transport_to_next': 'walking',
            },
          ],
        },
      });
      expect(post.route!.canEdit, isFalse);
      expect(post.route!.canManage, isFalse);
      expect(post.route!.dateRange, isEmpty);
      expect(post.route!.ownerId, isNull);
      expect(
        post.route!.waypoints.single.transportToNext,
        TransportType.walking,
      );
    },
  );

  test(
    'shared roles survive copying and never serialize ownership for writes',
    () {
      final route = SavedRoute.fromMap({
        'id': 'route',
        'user_id': 'owner',
        'access_role': 'editor',
        'revision': 5,
        'member_count': 3,
      });
      final copy = route.copyWith(title: 'new');
      expect(copy.canEdit, isTrue);
      expect(copy.canManage, isFalse);
      expect(copy.revision, 5);
      expect(copy.memberCount, 3);
      expect(copy.toMap(userId: 'current')['user_id'], 'current');
      expect(copy.toMap(userId: 'current'), isNot(contains('access_role')));
    },
  );
}
