import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavaexpress/services/preferencias.dart';
import 'package:lavaexpress/widgets/seccion_preferencias.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final prefs = Preferencias.instance;

  test('temaDesdeTexto reconoce los tres temas', () {
    expect(Preferencias.temaDesdeTexto('light'), ThemeMode.light);
    expect(Preferencias.temaDesdeTexto('dark'), ThemeMode.dark);
    expect(Preferencias.temaDesdeTexto('system'), ThemeMode.system);
  });

  test('temaDesdeTexto usa el del sistema si el texto es nulo o desconocido', () {
    expect(Preferencias.temaDesdeTexto(null), ThemeMode.system);
    expect(Preferencias.temaDesdeTexto('morado'), ThemeMode.system);
  });

  test('Sin datos guardados se cargan los valores por defecto', () async {
    SharedPreferences.setMockInitialValues({});
    await prefs.cargar();
    expect(prefs.tema.value, ThemeMode.system);
    expect(prefs.avisos.value, isFalse);
  });

  test('El tema y los avisos guardados sobreviven a una nueva carga', () async {
    SharedPreferences.setMockInitialValues({});
    await prefs.cargar();
    await prefs.cambiarTema(ThemeMode.dark);
    await prefs.cambiarAvisos(true);
    // Simula reiniciar la app: se pierden los valores en memoria.
    prefs.tema.value = ThemeMode.system;
    prefs.avisos.value = false;
    await prefs.cargar();
    expect(prefs.tema.value, ThemeMode.dark);
    expect(prefs.avisos.value, isTrue);
  });

  test('Lee los valores ya guardados en el dispositivo', () async {
    SharedPreferences.setMockInitialValues({'tema': 'light', 'avisos_pedidos': true});
    await prefs.cargar();
    expect(prefs.tema.value, ThemeMode.light);
    expect(prefs.avisos.value, isTrue);
  });

  testWidgets('Al tocar "Oscuro" se cambia y guarda el tema', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await prefs.cargar();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SeccionPreferencias(textoAvisos: 'Cambios en tus pedidos')),
    ));
    expect(find.text('Preferencias de este dispositivo'), findsOneWidget);
    // Fuera de la web no hay notificaciones del sistema: el interruptor no aparece.
    expect(find.text('Notificaciones'), findsNothing);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    expect(prefs.tema.value, ThemeMode.dark);
    expect((await SharedPreferences.getInstance()).getString('tema'), 'dark');
  });
}
