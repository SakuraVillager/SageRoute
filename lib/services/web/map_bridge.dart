import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('sageMaps')
external MapBridge get mapBridge;

extension type MapBridge(JSObject _) implements JSObject {
  external JSPromise<JSNumber> create(
    web.HTMLElement host,
    JSAny options,
    JSFunction tap,
  );
  external void update(JSNumber id, JSAny data);
  external void camera(JSNumber id, JSAny data);
  external void destroy(JSNumber id);
  external void block(JSBoolean value);
  external JSPromise<JSAny?> route(JSAny options);
  external JSPromise<JSAny?> locate(JSAny config);
}
