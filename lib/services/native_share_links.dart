import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../components/account_action.dart';
import '../views/discovery/community_post_page.dart';
import '../views/route_invitation_page.dart';
import '../views/route_preview/route_preview_page.dart';
import 'share_links.dart';

/// Auth callbacks remain handled by Supabase; only recognised share paths enter here.
class NativeShareLinks {
  NativeShareLinks(this.navigatorKey);
  final GlobalKey<NavigatorState> navigatorKey;
  final _links = AppLinks();
  StreamSubscription<Uri>? _subscription;
  String? _pending;
  String? _last;
  DateTime? _lastAt;
  bool _ready = false;
  bool _disposed = false;

  Future<void> start(Future<Object?> initialization) async {
    _subscription = _links.uriLinkStream.listen(
      _receive,
      onError: (Object _) {},
    );
    try {
      final initial = await _links.getInitialLink();
      if (initial != null) _receive(initial);
      await initialization;
      if (_disposed) return;
      _ready = true;
      _drain();
    } catch (_) {
      // The app's initialization screen already explains startup failures.
    }
  }

  void _receive(Uri uri) {
    final location = ShareLinks.appLocation(uri);
    if (location == null || _disposed) return;
    final now = DateTime.now();
    if (_last == location &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _last = location;
    _lastAt = now;
    _pending = location;
    if (_ready) _drain();
  }

  void _drain() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_disposed || _pending == null) return;
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      final parts = Uri.parse(_pending!).pathSegments;
      _pending = null;
      Widget page;
      if (parts.first == 'invite') {
        page = RouteInvitationPage(token: parts[1]);
      } else if (parts.first == 'discover') {
        page = CommunityPostPage(postId: parts[2]);
      } else {
        if (!await requireAccountForAction(navigator.context) ||
            !navigator.mounted) {
          return;
        }
        page = RoutePreviewPage(routeId: parts[1]);
      }
      if (!_disposed && navigator.mounted) {
        unawaited(
          navigator.push(MaterialPageRoute<void>(builder: (_) => page)),
        );
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
  }
}
