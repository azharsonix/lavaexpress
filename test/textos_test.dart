import 'package:flutter_test/flutter_test.dart';
import 'package:lavaexpress/models/estado_pedido.dart';
import 'package:lavaexpress/utils/enlaces.dart';
import 'package:lavaexpress/utils/textos_pedido.dart';

void main() {
  test('Cada estado tiene un mensaje para el cliente', () {
    for (final e in EstadoPedido.values) {
      expect(mensajeEstado(e).trim(), isNotEmpty, reason: e.name);
    }
  });

  test('Los mensajes de estado no se repiten', () {
    expect(EstadoPedido.values.map(mensajeEstado).toSet().length, EstadoPedido.values.length);
  });

  test('El enlace de seguimiento apunta a la página del servidor', () {
    expect(urlSeguimiento('abc123').toString(), 'https://lavaexpress-seguimiento.vercel.app/seguimiento/abc123');
    expect(urlSeguimiento('abc123').scheme, 'https');
  });
}
