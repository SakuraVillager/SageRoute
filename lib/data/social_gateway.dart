import '../services/database_service.dart';

typedef SocialRpc =
    Future<dynamic> Function(String name, Map<String, dynamic> params);
typedef SocialUserId = String? Function();

class SocialServiceUnavailable implements Exception {
  const SocialServiceUnavailable();
  @override
  String toString() => '服务暂时不可用，请稍后重试';
}

class RouteEditConflict implements Exception {
  const RouteEditConflict();
  @override
  String toString() => '同行者已经更新了这条行程，请加载最新版本后再编辑。当前改动尚未保存。';
}

bool isMissingSocialSchema(Object error) =>
    RegExp(r'PGRST20[25]|42P01|42883').hasMatch(error.toString());

/// Mutations are never retried automatically: a lost response can still mean
/// the server committed a post, comment or invitation.
class SocialGateway {
  const SocialGateway({SocialRpc? rpc, SocialUserId? userId})
    : _rpc = rpc,
      _userId = userId;
  final SocialRpc? _rpc;
  final SocialUserId? _userId;

  String? get userId {
    if (_userId != null) return _userId();
    try {
      return DatabaseService.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  void requireAccount() {
    if (userId == null) throw StateError('请先登录后再操作');
  }

  Future<dynamic> call(
    String name, [
    Map<String, dynamic> params = const {},
  ]) async {
    try {
      return await (_rpc?.call(name, params) ??
          DatabaseService.client.rpc(name, params: params));
    } catch (error) {
      if (isMissingSocialSchema(error)) throw const SocialServiceUnavailable();
      final message = error.toString();
      if (message.contains('route_conflict')) throw const RouteEditConflict();
      const messages = {
        'invite_expired': '邀请已过期，请让创建者重新邀请',
        'invite_revoked': '此邀请已被撤销',
        'invite_not_found': '邀请不存在或已失效',
        'email_mismatch': '请使用收到邀请的已验证邮箱登录',
        'not_authorized': '你暂时没有权限进行此操作，请刷新后重试',
        'only_owner_can_publish': '只有行程创建者可以将路线公开到发现',
        'invalid_email': '请输入有效的邀请邮箱',
      };
      for (final entry in messages.entries) {
        if (message.contains(entry.key)) throw StateError(entry.value);
      }
      rethrow;
    }
  }
}

List<Map<String, dynamic>> socialRows(dynamic value) =>
    (value as List? ?? const [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

String socialErrorMessage(Object error) => error is StateError
    ? error.message.toString()
    : error is SocialServiceUnavailable || error is RouteEditConflict
    ? error.toString()
    : '暂时无法完成操作，请检查网络后重试';
