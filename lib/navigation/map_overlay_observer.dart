import 'package:flutter/widgets.dart';
import '../services/browser_session.dart';

/// Popup barriers must also stop the DOM map from receiving pointer events.
class MapOverlayObserver extends NavigatorObserver {
  static final Set<Route<dynamic>> _allPopups = {};
  final Set<Route<dynamic>> _popups = {};
  void release() {
    _allPopups.removeAll(_popups);
    _popups.clear();
    setMapsBlocked(_allPopups.isNotEmpty);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      _popups.add(route);
      _allPopups.add(route);
      setMapsBlocked(true);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _remove(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _remove(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      _popups.remove(oldRoute);
      _allPopups.remove(oldRoute);
    }
    if (newRoute is PopupRoute) {
      _popups.add(newRoute);
      _allPopups.add(newRoute);
    }
    setMapsBlocked(_allPopups.isNotEmpty);
  }

  void _remove(Route<dynamic> route) {
    if (_popups.remove(route)) {
      _allPopups.remove(route);
      setMapsBlocked(_allPopups.isNotEmpty);
    }
  }
}
