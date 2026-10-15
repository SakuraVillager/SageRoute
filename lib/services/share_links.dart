class ShareLinks {
  static const publicUrl = String.fromEnvironment(
    'APP_PUBLIC_URL',
    defaultValue: 'https://sageroute.jijiz.cn',
  );
  static final _token = RegExp(r'^[a-f0-9]{64}$');
  static final _id = RegExp(
    r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$',
  );
  static Uri invite(String token) {
    if (!_token.hasMatch(token)) {
      throw ArgumentError('Invalid invitation token');
    }
    return Uri.parse(publicUrl).resolve('/invite/$token');
  }

  static Uri post(String id) {
    if (!_id.hasMatch(id)) throw ArgumentError('Invalid post ID');
    return Uri.parse(publicUrl).resolve('/discover/posts/$id');
  }

  static String? appLocation(Uri uri) {
    String path;
    if (uri.scheme == 'sageroute') {
      path = '/${uri.host}${uri.path}';
    } else if (uri.scheme == 'https' && uri.host == Uri.parse(publicUrl).host) {
      path = uri.path;
    } else {
      return null;
    }
    final parts = Uri.tryParse(path)?.pathSegments ?? const <String>[];
    if (parts.length == 2 &&
        parts[0] == 'invite' &&
        _token.hasMatch(parts[1])) {
      return path;
    }
    if (parts.length == 2 && parts[0] == 'routes' && _id.hasMatch(parts[1])) {
      return path;
    }
    if (parts.length == 3 &&
        parts[0] == 'discover' &&
        parts[1] == 'posts' &&
        _id.hasMatch(parts[2])) {
      return path;
    }
    return null;
  }

  static Uri appUri(String location) {
    final parts = Uri.parse(location).pathSegments;
    return Uri(
      scheme: 'sageroute',
      host: parts.first,
      pathSegments: parts.skip(1),
    );
  }
}
