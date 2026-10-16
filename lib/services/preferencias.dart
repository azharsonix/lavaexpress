import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias guardadas en el propio dispositivo (datos locales).
/// En web se guardan en el localStorage del navegador; en Android, en
/// SharedPreferences. No dependen de la conexión ni de la cuenta.
class Preferencias {
  Preferencias._();
  static final instance = Preferencias._();

  static const _claveTema = 'tema';
  static const _claveAvisos = 'avisos_pedidos';

  SharedPreferences? _prefs;

  /// Tema elegido; la app se redibuja al cambiarlo.
  final tema = ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Si el usuario activó los avisos de cambios en sus pedidos.
  final avisos = ValueNotifier<bool>(false);

  Future<void> cargar() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      tema.value = temaDesdeTexto(_prefs!.getString(_claveTema));
      avisos.value = _prefs!.getBool(_claveAvisos) ?? false;
    } catch (_) {
      // Sin almacenamiento (por ejemplo, navegación privada): valores por defecto.
    }
  }

  Future<void> cambiarTema(ThemeMode modo) async {
    tema.value = modo;
    await _prefs?.setString(_claveTema, modo.name);
  }

  Future<void> cambiarAvisos(bool activos) async {
    avisos.value = activos;
    await _prefs?.setBool(_claveAvisos, activos);
  }

  static ThemeMode temaDesdeTexto(String? texto) =>
      ThemeMode.values.firstWhere((m) => m.name == texto, orElse: () => ThemeMode.system);
}
