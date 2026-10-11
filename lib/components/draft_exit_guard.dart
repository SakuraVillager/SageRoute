import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

/// Includes the browser back button. Draft storage is cleared only on discard.
class DraftExitGuard extends StatefulWidget {
  static _DraftExitGuardState? _active;
  static Future<bool> confirmExit() async =>
      await _active?._confirmExit() ?? true;
  const DraftExitGuard({
    super.key,
    required this.child,
    required this.dirty,
    required this.onDiscard,
  });
  final Widget child;
  final bool dirty;
  final VoidCallback onDiscard;
  @override
  State<DraftExitGuard> createState() => _DraftExitGuardState();
}

class _DraftExitGuardState extends State<DraftExitGuard> {
  bool _leaving = false;
  Future<bool>? _confirmation;
  @override
  void initState() {
    super.initState();
    if (kIsWeb) DraftExitGuard._active = this;
  }

  @override
  void dispose() {
    if (identical(DraftExitGuard._active, this)) DraftExitGuard._active = null;
    super.dispose();
  }

  Future<bool> _confirmExit() async {
    if (!widget.dirty || _leaving) return true;
    return _confirmation ??= _askToExit();
  }

  Future<bool> _askToExit() async {
    var discarded = false;
    await requestDraftDiscard(context, widget.onDiscard, () {
      discarded = true;
      if (mounted) setState(() => _leaving = true);
    });
    _confirmation = null;
    return discarded;
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !widget.dirty || _leaving,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || _leaving) return;
      await requestDraftDiscard(context, widget.onDiscard, () {
        setState(() => _leaving = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (kIsWeb) {
            if (context.canPop()) {
              context.pop(result);
            } else {
              context.go('/home');
            }
          } else {
            Navigator.of(context).pop(result);
          }
        });
      });
    },
    child: widget.child,
  );
}

Future<void> requestDraftDiscard(
  BuildContext context,
  VoidCallback onDiscard,
  VoidCallback leave,
) async {
  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('放弃未保存的修改？'),
      content: const Text('离开后将清除当前草稿。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('继续编辑'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('放弃修改'),
        ),
      ],
    ),
  );
  if (discard == true && context.mounted) {
    onDiscard();
    leave();
  }
}
