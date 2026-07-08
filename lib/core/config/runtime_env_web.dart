import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window.__ENV__')
external JSObject? get _env;

String? runtimeEnv(String key) {
  final env = _env;
  if (env == null) return null;
  final value = env[key];
  if (value == null || !value.isA<JSString>()) return null;
  return (value as JSString).toDart;
}
