import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'route_draft_storage.dart';

/// A local browsing preference, never an authenticated account or user ID.
class GuestSession {
  static const preferenceKey = 'sageroute.guest';
  static const draftUserId = 'guest';
  static final active = ValueNotifier<bool>(false);
  static bool get isActive => active.value;

  static Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    active.value = preferences.getBool(preferenceKey) ?? false;
  }

  static Future<void> enter() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('hasSeenOnboarding', true);
    await preferences.setBool(preferenceKey, true);
    active.value = true;
  }

  static Future<void> leave() async {
    if (!isActive) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(preferenceKey);
    active.value = false;
  }

  static Future<void> completeSignIn(String userId) async {
    if (!isActive) return;
    const guestDraft = RouteDraftStorage(userId: draftUserId, draftId: 'new');
    final data = guestDraft.load();
    if (data != null) {
      RouteDraftStorage(userId: userId, draftId: 'new').save(data);
      guestDraft.clear();
    }
    await leave();
  }
}

/// Personal saved routes and account details still require a real session.
bool guestCanVisit(String path) =>
    const {
      '/home',
      '/figures',
      '/saved',
      '/profile',
      '/routes/new',
      '/dongpo',
      '/settings',
      '/settings/travel',
      '/settings/language',
    }.contains(path) ||
    RegExp(r'^/(figures|locations|articles)/[^/]+$').hasMatch(path);
