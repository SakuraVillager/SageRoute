import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/components/route_invitation_inbox.dart';
import 'package:sageroute/components/route_sharing_sheet.dart';
import 'package:sageroute/data/community_repository.dart';
import 'package:sageroute/data/route_collaboration_repository.dart';
import 'package:sageroute/data/social_gateway.dart';
import 'package:sageroute/data/user_route_repository.dart';
import 'package:sageroute/models/saved_route.dart';
import 'package:sageroute/views/discovery/community_compose_sheet.dart';
import 'package:sageroute/views/discovery/discovery_page.dart';
import 'package:sageroute/views/discovery/community_post_page.dart';
import 'package:sageroute/views/route_invitation_page.dart';

const _route = SavedRoute(
  id: 'route',
  title: '西湖同行',
  dateRange: '',
  duration: '一天',
  distance: '3km',
  waypoints: [],
);
Map<String, dynamic> _post() => {
  'id': '20000000-0000-0000-0000-000000000001',
  'author_id': 'other',
  'author_name': '同行者',
  'body': '苏堤的傍晚很美',
  'created_at': '2026-10-15T00:00:00Z',
};

void main() {
  testWidgets(
    'post comment action focuses the editor instead of opening its route',
    (tester) async {
      final repository = CommunityRepository(
        gateway: SocialGateway(
          userId: () => 'me',
          rpc: (name, _) async => name == 'sr_comments'
              ? []
              : {
                  ..._post(),
                  'route_snapshot': {'title': '西湖同行', 'waypoints': []},
                },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityPostPage(
            postId: _post()['id'] as String,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();
      expect(find.byType(CommunityRoutePage), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
    },
  );

  testWidgets('owner invitation controls fit a narrow phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = RouteCollaborationRepository(
      gateway: SocialGateway(
        userId: () => 'owner',
        rpc: (_, _) async => {'members': [], 'invitations': []},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteSharingSheet(route: _route, repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('共同编辑'), findsOneWidget);
    expect(find.text('只读查看'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'discovery renders real repository data, filters and like updates',
    (tester) async {
      bool liked = false;
      final filters = <String?>[];
      final repository = CommunityRepository(
        gateway: SocialGateway(
          userId: () => 'me',
          rpc: (name, params) async {
            if (name == 'sr_feed') {
              filters.add(params['p_kind'] as String?);
              return [_post()];
            }
            if (name == 'sr_set_like') {
              liked = params['p_liked'] as bool;
              return null;
            }
            return {..._post(), 'liked': liked, 'like_count': liked ? 1 : 0};
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: DiscoveryPage(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.text('苏堤的傍晚很美'), findsOneWidget);
      await tester.tap(find.text('随手记').first);
      await tester.pumpAndSettle();
      expect(filters, [null, 'note']);
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      expect(liked, isTrue);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unavailable backend shows retry without fake posts', (
    tester,
  ) async {
    final repository = CommunityRepository(
      gateway: SocialGateway(rpc: (_, _) async => throw Exception('PGRST202')),
    );
    await tester.pumpWidget(
      MaterialApp(home: DiscoveryPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('服务暂时不可用，请稍后重试'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
    expect(find.text('苏堤的傍晚很美'), findsNothing);
  });

  testWidgets('email inbox accepts by invitation ID and refreshes route list', (
    tester,
  ) async {
    var accepted = false;
    var refreshed = false;
    final repository = RouteCollaborationRepository(
      gateway: SocialGateway(
        userId: () => 'me',
        rpc: (name, params) async {
          if (name == 'sr_my_invitations') {
            return [
              {
                'id': 'invite',
                'route_id': 'route',
                'title': '西湖同行',
                'role': 'editor',
              },
            ];
          }
          expect(name, 'sr_accept_invite');
          expect(params, {'p_token': null, 'p_invite_id': 'invite'});
          accepted = true;
          return 'route';
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteInvitationInbox(
            repository: repository,
            onAccepted: () async {
              refreshed = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('西湖同行'), findsOneWidget);
    await tester.tap(find.text('接受'));
    await tester.pumpAndSettle();
    expect(accepted && refreshed, isTrue);
    expect(find.text('西湖同行'), findsNothing);
  });

  testWidgets('read-only members cannot create or revoke invitations', (
    tester,
  ) async {
    final repository = RouteCollaborationRepository(
      gateway: SocialGateway(
        userId: () => 'viewer',
        rpc: (_, _) async => {'members': [], 'invitations': []},
      ),
    );
    final viewer = SavedRoute.fromMap({
      ..._route.toMap(userId: 'owner'),
      'id': 'route',
      'access_role': 'viewer',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteSharingSheet(route: viewer, repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('同行成员'), findsOneWidget);
    expect(find.text('创建邀请并复制链接'), findsNothing);
    expect(find.text('撤销'), findsNothing);
  });

  testWidgets('expired invitation preview disables acceptance', (tester) async {
    final repository = RouteCollaborationRepository(
      gateway: SocialGateway(
        rpc: (_, _) async => {
          'id': 'invite',
          'route_id': 'route',
          'title': '西湖同行',
          'role': 'viewer',
          'available': false,
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RouteInvitationPage(token: 'a' * 64, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('西湖同行'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('邀请已过期或撤销，请让创建者重新邀请。'), findsOneWidget);
  });

  testWidgets('composer only offers owned routes and rejects an empty post', (
    tester,
  ) async {
    var writes = 0;
    final repository = CommunityRepository(
      gateway: SocialGateway(
        userId: () => 'me',
        rpc: (_, _) async {
          writes++;
          return 'post';
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommunityComposeSheet(
            repository: repository,
            routes: _Routes(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('西湖同行').last, findsOneWidget);
    expect(find.text('其他人的路线'), findsNothing);
    await tester.tap(find.text('不附带路线 · 发布随手记').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('发布到发现'));
    await tester.tap(find.text('发布到发现'));
    await tester.pumpAndSettle();
    expect(find.text('请填写 1–2000 字的分享内容'), findsOneWidget);
    expect(writes, 0);
  });
}

class _Routes extends UserRouteRepository {
  @override
  Future<List<SavedRoute>> fetchUserRoutes() async => [
    _route,
    SavedRoute.fromMap({
      'id': 'shared',
      'title': '其他人的路线',
      'access_role': 'editor',
    }),
  ];
}
