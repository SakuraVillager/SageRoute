import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/account_action.dart';
import '../data/route_collaboration_repository.dart';
import '../data/social_gateway.dart';
import '../models/route_invitation.dart';
import '../services/share_links.dart';
import '../theme/color_schemes.dart';
import 'route_preview/route_preview_page.dart';

class RouteInvitationPage extends StatefulWidget {
  const RouteInvitationPage({
    super.key,
    required this.token,
    this.repository = const RouteCollaborationRepository(),
  });
  final String token;
  final RouteCollaborationRepository repository;
  @override
  State<RouteInvitationPage> createState() => _RouteInvitationPageState();
}

class _RouteInvitationPageState extends State<RouteInvitationPage> {
  RouteInvitation? _invite;
  String? _error;
  bool _loading = true;
  bool _accepting = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final invite = await widget.repository.preview(widget.token);
      if (mounted) {
        setState(() {
          _invite = invite;
          _loading = false;
          _error = invite == null ? '邀请不存在或已失效' : null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = socialErrorMessage(error);
        });
      }
    }
  }

  Future<void> _accept() async {
    if (!await requireAccountForAction(context) || !mounted) return;
    setState(() => _accepting = true);
    try {
      final id = await widget.repository.accept(token: widget.token);
      if (!mounted) return;
      if (kIsWeb) {
        context.go('/routes/$id');
      } else {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RoutePreviewPage(routeId: id),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = socialErrorMessage(error));
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _openApp() async {
    try {
      final opened = await launchUrl(
        ShareLinks.appUri('/invite/${widget.token}'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('not installed');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未能打开客户端，你可以继续在网页操作')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.sageBg,
    appBar: AppBar(title: const Text('同行邀请')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.group_add_outlined,
                    size: 40,
                    color: AppColors.sageAccent,
                  ),
                  const SizedBox(height: 20),
                  if (_loading) const LinearProgressIndicator(),
                  if (_invite != null) ...[
                    Text(
                      '${_invite!.ownerName} 邀请你同行',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _invite!.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_invite!.roleLabel),
                    const SizedBox(height: 8),
                    Text(
                      _invite!.role == 'editor'
                          ? '加入后可以共同调整地点与交通方式，行程也会出现在你的列表中。'
                          : '加入后可查看此行程，并在自己的行程列表中找到它。',
                      style: const TextStyle(
                        height: 1.8,
                        color: AppColors.sageMuted,
                      ),
                    ),
                    if (_invite!.available) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _accepting ? null : _accept,
                        child: Text(_accepting ? '正在加入…' : '接受邀请'),
                      ),
                    ] else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('邀请已过期或撤销，请让创建者重新邀请。'),
                      ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('重新加载')),
                  ],
                  if (kIsWeb) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openApp,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('在客户端打开'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
