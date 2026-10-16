import 'package:flutter_test/flutter_test.dart';
import 'package:lavaexpress/models/estado_pedido.dart';
import 'package:lavaexpress/models/pedido.dart';
import 'package:lavaexpress/utils/horarios.dart';

void main() {
  test('El flujo a domicilio incluye "En camino"', () {
    expect(EstadoPedido.flujo(domicilio: true), contains(EstadoPedido.enCamino));
    expect(EstadoPedido.flujo(domicilio: true).length, 6);
  });

  test('El flujo en lavandería omite "En camino"', () {
    expect(EstadoPedido.flujo(domicilio: false), isNot(contains(EstadoPedido.enCamino)));
    expect(EstadoPedido.flujo(domicilio: false).last, EstadoPedido.entregada);
  });

  test('Hoy solo se ofrecen horarios que aún no inician', () {
    final ahora = DateTime(2026, 10, 2, 14, 30);
    expect(horariosDisponibles(ahora, ahora: ahora), ['15:00 - 17:00', '17:00 - 19:00']);
    expect(horariosDisponibles(DateTime(2026, 10, 3), ahora: ahora).length, horariosLavanderia.length);
  });

  test('Orden lógico: activos por cita más próxima, luego entregados más recientes', () {
    Pedido p(int folio, DateTime fecha, String horario, {DateTime? entregado}) => Pedido(
          id: '$folio', folio: folio, clienteId: 'c', clienteNombre: '', clienteEmail: '', clienteTelefono: '',
          servicioId: 's', servicioNombre: '', precioPorKg: 30, domicilio: false, direccion: null,
          fecha: fecha, horario: horario,
          estado: entregado == null ? EstadoPedido.solicitudRecibida : EstadoPedido.entregada,
          pesoKg: null, total: null,
          historial: [if (entregado != null) RegistroEstado(EstadoPedido.entregada, entregado)],
          creadoEn: null,
        );
    final lista = [
      p(1, DateTime(2026, 10, 1), '09:00 - 11:00', entregado: DateTime(2026, 10, 1)),
      p(2, DateTime(2026, 10, 5), '09:00 - 11:00'),
      p(3, DateTime(2026, 10, 3), '13:00 - 15:00'),
      p(4, DateTime(2026, 10, 3), '09:00 - 11:00'),
      p(5, DateTime(2026, 10, 2), '09:00 - 11:00', entregado: DateTime(2026, 10, 2)),
    ]..sort(Pedido.ordenLogico);
    expect(lista.map((e) => e.folio), [4, 3, 2, 5, 1]);
  });

  test('Clave de día e id de cupo (deben coincidir con firestore.rules)', () {
    expect(claveDia(DateTime(2026, 3, 7)), '2026-03-07');
    expect(idCupo('2026-03-07', '09:00 - 11:00'), '2026-03-07_09:00 - 11:00');
  });
}
