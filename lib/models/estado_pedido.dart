import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Estados por los que pasa un pedido de LavaExpress.
enum EstadoPedido {
  solicitudRecibida('solicitud_recibida', 'Solicitud recibida', LucideIcons.clipboardList),
  ropaRecibida('ropa_recibida', 'Ropa recibida', LucideIcons.scale),
  enProceso('en_proceso', 'En proceso', LucideIcons.washingMachine),
  listaParaEntregar('lista_para_entregar', 'Lista para entregar', LucideIcons.package),
  enCamino('en_camino', 'En camino', LucideIcons.truck),
  entregada('entregada', 'Entregada', LucideIcons.circleCheck);

  const EstadoPedido(this.clave, this.etiqueta, this.icono);

  /// Valor que se guarda en Firestore.
  final String clave;
  final String etiqueta;
  final IconData icono;

  static EstadoPedido desdeClave(String? clave) =>
      values.firstWhere((e) => e.clave == clave, orElse: () => solicitudRecibida);

  /// Orden de estados de un pedido. "En camino" solo aplica al servicio a domicilio.
  static List<EstadoPedido> flujo({required bool domicilio}) =>
      domicilio ? values : values.where((e) => e != enCamino).toList();
}
