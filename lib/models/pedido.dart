import 'package:cloud_firestore/cloud_firestore.dart';

import 'direccion.dart';
import 'estado_pedido.dart';

/// Cambio de estado registrado en el historial del pedido.
class RegistroEstado {
  const RegistroEstado(this.estado, this.fecha);
  final EstadoPedido estado;
  final DateTime fecha;
}

/// Pedido de lavandería. El peso y el total los registra el personal.
class Pedido {
  const Pedido({
    required this.id,
    required this.folio,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.clienteTelefono,
    required this.servicioId,
    required this.servicioNombre,
    required this.precioPorKg,
    required this.domicilio,
    required this.direccion,
    required this.fecha,
    required this.horario,
    required this.estado,
    required this.pesoKg,
    required this.total,
    required this.historial,
    required this.creadoEn,
  });

  final String id;
  final int folio;
  final String clienteId;
  final String clienteNombre;
  final String clienteEmail;
  final String clienteTelefono;
  final String servicioId;
  final String servicioNombre;

  /// Tarifa del servicio al momento de crear el pedido.
  final double precioPorKg;

  /// true = recolección y entrega a domicilio.
  final bool domicilio;
  final Direccion? direccion;
  final DateTime fecha;
  final String horario;
  final EstadoPedido estado;

  /// Peso obtenido en la báscula de la lavandería (null hasta que el personal lo registre).
  final double? pesoKg;

  /// Precio final = pesoKg × precioPorKg.
  final double? total;
  final List<RegistroEstado> historial;
  final DateTime? creadoEn;

  bool get activo => estado != EstadoPedido.entregada;
  bool get tienePeso => pesoKg != null;

  List<EstadoPedido> get flujo => EstadoPedido.flujo(domicilio: domicilio);

  EstadoPedido? get siguienteEstado {
    final i = flujo.indexOf(estado);
    return (i >= 0 && i < flujo.length - 1) ? flujo[i + 1] : null;
  }

  DateTime? fechaDe(EstadoPedido e) {
    for (final h in historial) {
      if (h.estado == e) return h.fecha;
    }
    return null;
  }

  /// Momento en que se entregó (o, si falta, cuándo se creó).
  DateTime get fechaCierre => fechaDe(EstadoPedido.entregada) ?? creadoEn ?? fecha;

  /// Orden lógico de las listas:
  /// 1) pedidos activos primero, del más próximo al más lejano según su cita;
  /// 2) después los entregados, del más reciente al más antiguo.
  static int ordenLogico(Pedido a, Pedido b) {
    if (a.activo != b.activo) return a.activo ? -1 : 1;
    if (!a.activo) return b.fechaCierre.compareTo(a.fechaCierre);
    final porFecha = a.fecha.compareTo(b.fecha);
    if (porFecha != 0) return porFecha;
    final porHorario = a.horario.compareTo(b.horario);
    return porHorario != 0 ? porHorario : a.folio.compareTo(b.folio);
  }

  factory Pedido.desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final dir = d['direccion'];
    return Pedido(
      id: doc.id,
      folio: (d['folio'] as num? ?? 0).toInt(),
      clienteId: d['clienteId'] as String? ?? '',
      clienteNombre: d['clienteNombre'] as String? ?? '',
      clienteEmail: d['clienteEmail'] as String? ?? '',
      clienteTelefono: d['clienteTelefono'] as String? ?? '',
      servicioId: d['servicioId'] as String? ?? '',
      servicioNombre: d['servicioNombre'] as String? ?? '',
      precioPorKg: (d['precioPorKg'] as num? ?? 0).toDouble(),
      domicilio: d['domicilio'] as bool? ?? false,
      direccion: dir is Map<String, dynamic> ? Direccion.desdeMapa(dir) : null,
      fecha: (d['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      horario: d['horario'] as String? ?? '',
      estado: EstadoPedido.desdeClave(d['estado'] as String?),
      pesoKg: (d['pesoKg'] as num?)?.toDouble(),
      total: (d['total'] as num?)?.toDouble(),
      historial: [
        for (final h in (d['historial'] as List? ?? const []))
          if (h is Map)
            RegistroEstado(
              EstadoPedido.desdeClave(h['estado'] as String?),
              (h['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
            ),
      ],
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }
}
