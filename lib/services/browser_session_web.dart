import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'web/map_bridge.dart';

String? readSessionValue(String key) {
  try {
    return web.window.sessionStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void writeSessionValue(String key, String value) {
  try {
    web.window.sessionStorage.setItem(key, value);
  } catch (_) {
    /* Private browsing/storage full. */
  }
}

void removeSessionValue(String key) {
  try {
    web.window.sessionStorage.removeItem(key);
  } catch (_) {
    /* Storage disabled. */
  }
}

void clearRouteDrafts() {
  try {
    final storage = web.window.sessionStorage;
    final keys = <String>[];
    for (var i = 0; i < storage.length; i++) {
      final key = storage.key(i);
      if (key != null && key.startsWith('sageroute.draft.')) keys.add(key);
    }
    for (final key in keys) {
      storage.removeItem(key);
    }
  } catch (_) {
    /* Storage disabled. */
  }
}

void setMapsBlocked(bool blocked) => mapBridge.block(blocked.toJS);

void cleanAuthParameters() {
  web.window.history.replaceState(null, '', web.window.location.pathname);
}
