import '../models/route_invitation.dart';
import '../services/route_changes.dart';
import 'social_gateway.dart';

class RouteCollaborationRepository {
  const RouteCollaborationRepository({this.gateway = const SocialGateway()});
  final SocialGateway gateway;

  Future<RouteInvitation> createInvite(
    String routeId, {
    required String role,
    String? email,
  }) async {
    gateway.requireAccount();
    if (!const ['editor', 'viewer'].contains(role)) {
      throw ArgumentError.value(role);
    }
    final value = await gateway.call('sr_create_invite', {
      'p_route_id': routeId,
      'p_role': role,
      'p_email': email == null || email.trim().isEmpty
          ? null
          : email.trim().toLowerCase(),
    });
    return RouteInvitation.fromMap(Map<String, dynamic>.from(value as Map));
  }

  Future<RouteInvitation?> preview(String token) async {
    final value = await gateway.call('sr_invite_info', {'p_token': token});
    return value == null
        ? null
        : RouteInvitation.fromMap(Map<String, dynamic>.from(value as Map));
  }

  Future<String> accept({String? token, String? invitationId}) async {
    gateway.requireAccount();
    if (token == null && invitationId == null) {
      throw ArgumentError('Missing invitation');
    }
    final routeId =
        await gateway.call('sr_accept_invite', {
              'p_token': token,
              'p_invite_id': invitationId,
            })
            as String;
    routeListChanges.value++;
    return routeId;
  }

  Future<List<RouteInvitation>> incoming() async {
    if (gateway.userId == null) return const [];
    return socialRows(
      await gateway.call('sr_my_invitations'),
    ).map(RouteInvitation.fromMap).toList();
  }

  Future<Map<String, dynamic>> sharing(String routeId) async =>
      Map<String, dynamic>.from(
        await gateway.call('sr_route_sharing', {'p_route_id': routeId}) as Map,
      );
  Future<void> revoke(String id) async {
    gateway.requireAccount();
    await gateway.call('sr_revoke_invite', {'p_id': id});
  }

  Future<void> removeMember(String routeId, String userId) async {
    gateway.requireAccount();
    await gateway.call('sr_remove_member', {
      'p_route_id': routeId,
      'p_user_id': userId,
    });
    routeListChanges.value++;
  }
}
