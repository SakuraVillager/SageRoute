import 'package:flutter/material.dart';
import '../data/route_collaboration_repository.dart';
import '../data/social_gateway.dart';
import '../models/route_invitation.dart';
import '../theme/color_schemes.dart';

class RouteInvitationInbox extends StatefulWidget {
  const RouteInvitationInbox({
    super.key,
    required this.onAccepted,
    this.repository = const RouteCollaborationRepository(),
  });
  final Future<void> Function() onAccepted;
  final RouteCollaborationRepository repository;
  @override
  State<RouteInvitationInbox> createState() => _RouteInvitationInboxState();
}

class _RouteInvitationInboxState extends State<RouteInvitationInbox>
    with WidgetsBindingObserver {
  List<RouteInvitation> _invites = const [];
  String? _working;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final rows = await widget.repository.incoming();
      if (mounted) setState(() => _invites = rows);
    } catch (_) {
      /* Invitations are optional on older deployments; route listing still works. */
    }
  }

  Future<void> _accept(RouteInvitation invite) async {
    setState(() => _working = invite.id);
    try {
      await widget.repository.accept(invitationId: invite.id);
      if (!mounted) return;
      setState(() => _invites.removeWhere((item) => item.id == invite.id));
      await widget.onAccepted();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(socialErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  @override
  Widget build(BuildContext context) => _invites.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandWash,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '同行邀请',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                for (final invite in _invites)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.group_add_outlined),
                    title: Text(invite.title),
                    subtitle: Text('${invite.ownerName} · ${invite.roleLabel}'),
                    trailing: FilledButton(
                      onPressed: _working != null
                          ? null
                          : () => _accept(invite),
                      child: Text(_working == invite.id ? '加入中…' : '接受'),
                    ),
                  ),
              ],
            ),
          ),
        );
}
