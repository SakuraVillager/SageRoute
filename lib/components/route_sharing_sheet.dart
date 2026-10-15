import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../data/route_collaboration_repository.dart';
import '../data/social_gateway.dart';
import '../models/saved_route.dart';
import '../services/share_links.dart';
import '../theme/color_schemes.dart';

Future<void> showRouteSharing(BuildContext context, SavedRoute route) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PointerInterceptor(
        child: FractionallySizedBox(
          heightFactor: .88,
          child: RouteSharingSheet(route: route),
        ),
      ),
    );

class RouteSharingSheet extends StatefulWidget {
  const RouteSharingSheet({
    super.key,
    required this.route,
    this.repository = const RouteCollaborationRepository(),
  });
  final SavedRoute route;
  final RouteCollaborationRepository repository;
  @override
  State<RouteSharingSheet> createState() => _RouteSharingSheetState();
}

class _RouteSharingSheetState extends State<RouteSharingSheet> {
  final _email = TextEditingController();
  String _role = 'editor';
  String? _link;
  String? _error;
  bool _busy = false;
  bool _loading = true;
  Map<String, dynamic> _sharing = const {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.sharing(widget.route.id);
      if (mounted) {
        setState(() {
          _sharing = data;
          _error = null;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = socialErrorMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = socialErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() => _run(() async {
    final email = _email.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw StateError('请输入有效的邀请邮箱');
    }
    final invite = await widget.repository.createInvite(
      widget.route.id,
      role: _role,
      email: email.isEmpty ? null : email,
    );
    final link = ShareLinks.invite(invite.token!).toString();
    if (mounted) setState(() => _link = link);
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(email.isEmpty ? '邀请链接已复制' : '站内邀请已创建，链接也已复制')),
      );
    }
  });
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.sageCard,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '分享与同行',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: '关闭分享',
                ),
              ],
            ),
            Text(
              widget.route.title,
              style: const TextStyle(color: AppColors.sageMuted),
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Row(
                children: [
                  Expanded(child: Text(_error!)),
                  TextButton(onPressed: _load, child: const Text('重试')),
                ],
              ),
            if (widget.route.canManage) ...[
              const Text(
                '邀请同行者',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'editor',
                    label: Text('共同编辑'),
                    icon: Icon(Icons.edit_outlined),
                  ),
                  ButtonSegment(
                    value: 'viewer',
                    label: Text('只读查看'),
                    icon: Icon(Icons.visibility_outlined),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: _busy
                    ? null
                    : (value) => setState(() => _role = value.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _email,
                maxLength: 254,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '邀请邮箱（选填）',
                  hintText: '填写邮箱发送站内邀请；留空生成通用链接',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '链接 7 天有效。通用链接的持有者可登录加入；填写邮箱后，仅该已验证邮箱可以接受。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  color: AppColors.sageMuted,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _invite,
                icon: const Icon(Icons.link),
                label: Text(_busy ? '正在创建…' : '创建邀请并复制链接'),
              ),
              if (_link != null) ...[
                const SizedBox(height: 12),
                SelectableText(_link!, style: const TextStyle(fontSize: 12)),
              ],
              const SizedBox(height: 24),
            ] else
              const Text('你可以查看同行成员；邀请与成员管理由行程创建者负责。'),
            const Text(
              '同行成员',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline),
              title: Text('行程创建者'),
              subtitle: Text('负责邀请与管理此行程'),
            ),
            for (final member in socialRows(_sharing['members']))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(member['name'] as String? ?? '同行者'),
                subtitle: Text(member['role'] == 'editor' ? '可编辑' : '只读'),
                trailing: widget.route.canManage
                    ? TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => widget.repository.removeMember(
                                  widget.route.id,
                                  member['user_id'] as String,
                                ),
                              ),
                        child: const Text('移除'),
                      )
                    : null,
              ),
            if (widget.route.canManage) ...[
              const SizedBox(height: 16),
              const Text('有效邀请', style: TextStyle(fontWeight: FontWeight.w600)),
              const Text(
                '撤销会阻止继续加入；已加入的用户请从成员列表移除。',
                style: TextStyle(fontSize: 12, color: AppColors.sageMuted),
              ),
              for (final invite in socialRows(_sharing['invitations']))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(invite['invited_email'] as String? ?? '通用邀请链接'),
                  subtitle: Text(invite['role'] == 'editor' ? '共同编辑' : '只读查看'),
                  trailing: TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => widget.repository.revoke(
                              invite['id'] as String,
                            ),
                          ),
                    child: const Text('撤销'),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
