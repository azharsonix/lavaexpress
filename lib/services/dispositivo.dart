/// Funciones del dispositivo físico: notificaciones del sistema y vibración.
/// En web se usan las APIs del navegador (Notification, Service Worker y
/// navigator.vibrate); en las demás plataformas, las de Flutter.
library;

export 'dispositivo_io.dart' if (dart.library.js_interop) 'dispositivo_web.dart';
