import 'package:flutter/material.dart';

import '../navigation/app_navigation.dart';
import '../services/guest_session.dart';
import '../services/auth_service.dart';

class GuestEntryButton extends StatefulWidget {
  const GuestEntryButton({super.key});

  @override
  State<GuestEntryButton> createState() => _GuestEntryButtonState();
}

class _GuestEntryButtonState extends State<GuestEntryButton> {
  bool _loading = false;

  Future<void> _enter() async {
    setState(() => _loading = true);
    try {
      final auth = AuthService();
      var hasSession = false;
      try {
        hasSession = auth.currentSession != null;
      } catch (_) {
        // A local entry can also be rendered before auth is initialized.
      }
      if (hasSession) await auth.signOut();
      await GuestSession.enter();
      if (mounted) completeGuestEntry(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂时无法进入游客模式，请重试')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: _loading ? null : _enter,
    icon: const Icon(Icons.explore_outlined, size: 18),
    label: Text(_loading ? '正在进入…' : '游客进入'),
  );
}
