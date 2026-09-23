import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays the original persistence exception and stack trace so users can
/// share the actual failure instead of a generic network-error message.
Future<bool?> showRouteSaveDiagnostics(
  BuildContext context, {
  required Object error,
  required StackTrace stackTrace,
}) {
  final rawLog =
      'error_type: ${error.runtimeType}\n'
      'error: $error\n\n'
      'stack_trace:\n$stackTrace';

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('保存失败 · 原始错误日志'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请复制下方完整日志，便于继续定位问题。'),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.5,
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  rawLog,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: rawLog));
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(true);
            }
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('复制完整日志'),
        ),
      ],
    ),
  );
}
