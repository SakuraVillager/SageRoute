import 'dart:convert';
import 'browser_session.dart';

/// Drafts live only in the current browser tab and are partitioned by user.
class RouteDraftStorage {
  const RouteDraftStorage({required this.userId, required this.draftId});
  final String userId;
  final String draftId;
  String get key => 'sageroute.draft.$userId.$draftId';
  Map<String, dynamic>? load() {
    final raw = readSessionValue(key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic> && data['version'] == 1) return data;
    } catch (_) {
      /* A damaged draft cannot block the page. */
    }
    clear();
    return null;
  }

  void save(Map<String, dynamic> data) =>
      writeSessionValue(key, jsonEncode({...data, 'version': 1}));
  void clear() => removeSessionValue(key);
}
