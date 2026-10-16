import 'dart:js_interop';

@JS('sageStartup')
external _WebStartup? get _startup;

extension type _WebStartup._(JSObject _) implements JSObject {
  external void ready();
  external void fail();
}

// Tests and embedded Flutter hosts may not include the HTML loading screen.
void completeWebStartup() => _startup?.ready();

void failWebStartup() => _startup?.fail();
