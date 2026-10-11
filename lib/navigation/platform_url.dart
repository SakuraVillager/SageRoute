import 'platform_url_native.dart'
    if (dart.library.js_interop) 'platform_url_web.dart'
    as platform;

void configureUrlStrategy() => platform.configureUrlStrategy();
