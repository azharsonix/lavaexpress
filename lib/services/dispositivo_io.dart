import 'package:flutter/services.dart';

/// Versión para Android y escritorio.
class Dispositivo {
  Dispositivo._();

  /// Las notificaciones del sistema solo están implementadas en la PWA (web).
  static bool get admiteNotificaciones => false;

  static bool get notificacionesPermitidas => false;

  static Future<bool> pedirPermisoNotificaciones() async => false;

  static Future<void> notificar(String titulo, String cuerpo) async {}

  /// Vibración corta con el motor del teléfono.
  static void vibrar() => HapticFeedback.vibrate();
}
