import 'package:flutter_test/flutter_test.dart';
import 'package:lavaexpress/models/estado_pedido.dart';
import 'package:lavaexpress/models/pedido.dart';
import 'package:lavaexpress/services/avisos_pedidos.dart';
import 'package:lavaexpress/utils/textos_pedido.dart';

Pedido p(int folio, EstadoPedido estado) => Pedido(
      id: 'id$folio', folio: folio, clienteId: 'c', clienteNombre: 'Yolotzin', clienteEmail: '', clienteTelefono: '',
      servicioId: 's', servicioNombre: '', precioPorKg: 30, domicilio: false, direccion: null,
      fecha: DateTime(2026, 10, 16), horario: '09:00 - 11:00', estado: estado,
      pesoKg: null, total: null, historial: const [], creadoEn: null,
    );

void main() {
  group('DetectorCambios (cliente)', () {
    test('La primera lista solo sirve de referencia', () {
      final d = DetectorCambios(esPersonal: false);
      expect(d.revisar([p(1, EstadoPedido.enProceso)]), isEmpty);
    });

    test('Avisa cuando un pedido cambia de estado', () {
      final d = DetectorCambios(esPersonal: false)..revisar([p(1, EstadoPedido.enProceso)]);
      final avisos = d.revisar([p(1, EstadoPedido.listaParaEntregar)]);
      expect(avisos, hasLength(1));
      expect(avisos.first.titulo, 'Pedido #001: ${EstadoPedido.listaParaEntregar.etiqueta}');
      expect(avisos.first.cuerpo, mensajeEstado(EstadoPedido.listaParaEntregar));
    });

    test('No avisa si el estado no cambia ni por pedidos nuevos', () {
      final d = DetectorCambios(esPersonal: false)..revisar([p(1, EstadoPedido.enProceso)]);
      expect(d.revisar([p(1, EstadoPedido.enProceso), p(2, EstadoPedido.solicitudRecibida)]), isEmpty);
    });

    test('Compara siempre con la lista inmediata anterior', () {
      final d = DetectorCambios(esPersonal: false)..revisar([p(1, EstadoPedido.enProceso)]);
      expect(d.revisar([p(1, EstadoPedido.enCamino)]), hasLength(1));
      expect(d.revisar([p(1, EstadoPedido.enCamino)]), isEmpty);
    });
  });

  group('DetectorCambios (personal)', () {
    test('La primera lista no avisa aunque haya solicitudes', () {
      final d = DetectorCambios(esPersonal: true);
      expect(d.revisar([p(1, EstadoPedido.solicitudRecibida)]), isEmpty);
    });

    test('Avisa cuando llega una solicitud nueva', () {
      final d = DetectorCambios(esPersonal: true)..revisar([]);
      final avisos = d.revisar([p(7, EstadoPedido.solicitudRecibida)]);
      expect(avisos, hasLength(1));
      expect(avisos.first.titulo, 'Nueva solicitud #007');
      expect(avisos.first.cuerpo, 'Yolotzin · 09:00 - 11:00');
    });

    test('No avisa por cambios de estado ni por pedidos nuevos en otro estado', () {
      final d = DetectorCambios(esPersonal: true)..revisar([p(1, EstadoPedido.solicitudRecibida)]);
      expect(d.revisar([p(1, EstadoPedido.ropaRecibida), p(2, EstadoPedido.enProceso)]), isEmpty);
    });
  });
}
