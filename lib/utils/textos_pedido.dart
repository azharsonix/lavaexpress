import 'package:flutter/widgets.dart';

import '../models/estado_pedido.dart';
import '../models/pedido.dart';
import '../theme/iconos.dart';
import 'formato.dart';

/// Textos e iconos de un pedido en un solo lugar, para que todas las
/// pantallas usen exactamente las mismas palabras.

const textoDomicilio = 'Recolección y entrega a domicilio';
const textoLavanderia = 'Entrega y recogida en la lavandería';

String textoEntrega(bool domicilio) => domicilio ? textoDomicilio : textoLavanderia;

String textoEntregaCorto(bool domicilio) => domicilio ? 'A domicilio' : 'En lavandería';

IconData iconoEntrega(bool domicilio) => domicilio ? Iconos.domicilio : Iconos.lavanderia;

/// Qué ocurre en la cita agendada.
String tituloCita(bool domicilio) => domicilio ? 'Recolección de tu ropa' : 'Entrega de tu ropa en la lavandería';

/// "Hoy", "Mañana" o la fecha corta.
String diaRelativo(DateTime dia, {DateTime? ahora}) {
  final hoy = ahora ?? DateTime.now();
  final d = DateTime(dia.year, dia.month, dia.day);
  final h = DateTime(hoy.year, hoy.month, hoy.day);
  final diferencia = d.difference(h).inDays;
  if (diferencia == 0) return 'Hoy';
  if (diferencia == 1) return 'Mañana';
  return fechaCorta(dia);
}

/// "Hoy · 09:00 - 11:00"
String citaCorta(Pedido p) => '${diaRelativo(p.fecha)} · ${p.horario}';

/// Mensaje para el cliente cuando su pedido llega a un estado (avisos y página de seguimiento).
String mensajeEstado(EstadoPedido e) => switch (e) {
  EstadoPedido.solicitudRecibida => 'Recibimos tu solicitud.',
  EstadoPedido.ropaRecibida => 'Ya tenemos tu ropa y registramos su peso.',
  EstadoPedido.enProceso => 'Tu ropa se está lavando.',
  EstadoPedido.listaParaEntregar => 'Tu ropa está limpia y lista.',
  EstadoPedido.enCamino => 'Vamos en camino a entregarte tu ropa.',
  EstadoPedido.entregada => 'Pedido entregado. ¡Gracias por elegir LavaExpress!',
};
