export 'image_capture_stub.dart'
    if (dart.library.js_interop) 'image_capture_web.dart'
    if (dart.library.io) 'image_capture_io.dart';
