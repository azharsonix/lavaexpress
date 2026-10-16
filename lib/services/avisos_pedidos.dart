import 'dart:async';

import '../models/estado_pedido.dart';
import '../models/pedido.dart';
import '../utils/formato.dart';
import '../utils/textos_pedido.dart';
import 'dispositivo.dart';
import 'preferencias.dart';

/// Un cambio que merece aviso.
class Aviso {
  const Aviso(this.titulo, this.cuerpo);
  final String titulo;
  final String cuerpo;
}

/// Compara cada lista de pedidos con la anterior y decide qué avisar.
///  - Cliente: cuando uno de sus pedidos cambia de estado.
///  - Personal: cuando llega una solicitud nueva.
/// La primera lista solo sirve de referencia (no se avisa lo que ya existía).
class DetectorCambios {
  DetectorCambios({required this.esPersonal});

  final bool esPersonal;
  Map<String, EstadoPedido>? _anterior;

  List<Aviso> revisar(List<Pedido> pedidos) {
    final actual = {for (final p in pedidos) p.id: p.estado};
    final anterior = _anterior;
    _anterior = actual;
    if (anterior == null) return const [];

    final avisos = <Aviso>[];
    for (final p in pedidos) {
      final antes = anterior[p.id];
      if (esPersonal) {
        if (antes == null && p.estado == EstadoPedido.solicitudRecibida) {
          avisos.add(Aviso('Nueva solicitud ${folio(p.folio)}', '${p.clienteNombre} · ${p.horario}'));
        }
      } else if (antes != null && antes != p.estado) {
        avisos.add(Aviso('Pedido ${folio(p.folio)}: ${p.estado.etiqueta}', mensajeEstado(p.estado)));
      }
    }
    return avisos;
  }
}

/// Escucha los pedidos mientras la app está abierta (o en segundo plano en
/// otra pestaña) y lanza la notificación del sistema y la vibración.
class AvisosPedidos {
  AvisosPedidos(Stream<List<Pedido>> pedidos, {required bool esPersonal, this.alAvisar})
    : _detector = DetectorCambios(esPersonal: esPersonal) {
    _sub = pedidos.listen(_revisar, onError: (_) {});
  }

  final DetectorCambios _detector;

  /// Para mostrar también el aviso dentro de la app.
  final void Function(Aviso aviso)? alAvisar;
  late final StreamSubscription<List<Pedido>> _sub;

  void _revisar(List<Pedido> pedidos) {
    for (final a in _detector.revisar(pedidos)) {
      alAvisar?.call(a);
      Dispositivo.vibrar();
      if (Preferencias.instance.avisos.value) Dispositivo.notificar(a.titulo, a.cuerpo);
    }
  }

  void cancelar() => _sub.cancel();
}
