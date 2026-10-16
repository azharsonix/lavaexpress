import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Versión para la PWA (navegador).
class Dispositivo {
  Dispositivo._();

  static bool get admiteNotificaciones => web.window.has('Notification');

  static bool get notificacionesPermitidas =>
      admiteNotificaciones && web.Notification.permission == 'granted';

  /// Pide permiso al navegador. Debe llamarse desde un toque del usuario.
  static Future<bool> pedirPermisoNotificaciones() async {
    if (!admiteNotificaciones) return false;
    final r = await web.Notification.requestPermission().toDart;
    return r.toDart == 'granted';
  }

  /// Muestra una notificación del sistema. Se usa el service worker cuando
  /// existe, porque en Chrome para Android `new Notification()` no funciona.
  static Future<void> notificar(String titulo, String cuerpo) async {
    if (!notificacionesPermitidas) return;
    final opciones = web.NotificationOptions(
      body: cuerpo,
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
      tag: titulo,
    );
    try {
      final registro = await web.window.navigator.serviceWorker.ready.toDart;
      await registro.showNotification(titulo, opciones).toDart;
    } catch (_) {
      web.Notification(titulo, opciones);
    }
  }

  /// Vibración corta (solo en navegadores de teléfono que la admiten).
  static void vibrar() {
    try {
      web.window.navigator.vibrate([120, 60, 120].map((e) => e.toJS).toList().toJS);
    } catch (_) {}
  }
}
