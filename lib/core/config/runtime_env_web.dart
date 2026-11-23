import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Reads `window.__ENV__` (web/env-config.js).
///
/// `@JS('window.__ENV__')` does not work: dart:js_interop looks up a global
/// named "window.__ENV__", not `window["__ENV__"]`.
String? runtimeEnv(String key) {
  final raw = globalContext.getProperty('__ENV__'.toJS);
  if (raw == null || raw.isUndefinedOrNull) return null;

  final dartEnv = raw.dartify();
  if (dartEnv is Map) {
    final value = dartEnv[key];
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty || text == 'null' || text == 'undefined') return null;
      return text;
    }
  }

  if (raw is JSObject) {
    final value = raw.getProperty(key.toJS);
    if (value == null || value.isUndefinedOrNull) return null;
    if (value.isA<JSString>()) {
      final text = (value as JSString).toDart.trim();
      return text.isEmpty ? null : text;
    }
  }
  return null;
}
