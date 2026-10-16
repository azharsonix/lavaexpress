import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/direccion.dart';
import '../models/estado_pedido.dart';
import '../models/pedido.dart';
import '../models/servicio.dart';
import '../models/usuario.dart';
import '../utils/horarios.dart';

/// El horario elegido ya no tiene lugar (otro cliente tomó el último).
class CupoLlenoException implements Exception {
  const CupoLlenoException();
}

/// Acceso a Cloud Firestore.
///
/// Colecciones:
///  - servicios/{id}                    nombre, descripcion, precioPorKg, activo
///  - usuarios/{uid}                    nombre, email, telefono, rol
///  - usuarios/{uid}/direcciones/{id}   alias, calle, colonia, referencias, latitud, longitud (GPS, opcional)
///  - pedidos/{id}                      ver [Pedido]
///  - contadores/pedidos                ultimo (folio consecutivo)
///  - cupos/{dia_horario}               dia, horario, ocupados, ultimoPedido
///  - configuracion/general             cupoPorHorario
class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pedidos => _db.collection('pedidos');
  DocumentReference<Map<String, dynamic>> _usuario(String uid) => _db.collection('usuarios').doc(uid);

  // ---------- Usuarios ----------

  Future<void> crearPerfilCliente({
    required String uid,
    required String nombre,
    required String email,
    required String telefono,
  }) =>
      _usuario(uid).set({
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'rol': 'cliente',
        'creadoEn': FieldValue.serverTimestamp(),
      });

  Stream<Usuario?> perfil(String uid) =>
      _usuario(uid).snapshots().map((d) => d.exists ? Usuario.desdeDoc(d) : null);

  // ---------- Servicios ----------

  Stream<List<Servicio>> servicios() => _db
      .collection('servicios')
      .where('activo', isEqualTo: true)
      .snapshots()
      .map((q) => q.docs.map(Servicio.desdeDoc).toList()..sort((a, b) => a.nombre.compareTo(b.nombre)));

  // ---------- Direcciones ----------

  Stream<List<Direccion>> direcciones(String uid) => _usuario(uid)
      .collection('direcciones')
      .snapshots()
      .map((q) => q.docs.map((d) => Direccion.desdeMapa(d.data(), id: d.id)).toList());

  Future<Direccion> agregarDireccion(String uid, Direccion direccion) async {
    final ref = await _usuario(uid).collection('direcciones').add(direccion.aMapa());
    return direccion.conId(ref.id);
  }

  // ---------- Cupos por horario ----------

  /// Máximo de pedidos por bloque de horario (configurable desde Admin SDK).
  Stream<int> cupoPorHorario() => _db.collection('configuracion').doc('general').snapshots().map(
        (d) => (d.data()?['cupoPorHorario'] as num? ?? cupoPorHorarioPredeterminado).toInt(),
      );

  /// Pedidos ya agendados por bloque, para los días entre [desde] y [hasta].
  /// Llave: id del cupo ("2026-10-03_09:00 - 11:00").
  Stream<Map<String, int>> ocupacion(DateTime desde, DateTime hasta) => _db
      .collection('cupos')
      .where('dia', isGreaterThanOrEqualTo: claveDia(desde))
      .where('dia', isLessThanOrEqualTo: claveDia(hasta))
      .snapshots()
      .map((q) => {for (final d in q.docs) d.id: (d.data()['ocupados'] as num? ?? 0).toInt()});

  // ---------- Pedidos ----------

  /// Crea el pedido con un folio consecutivo y ocupa un lugar del horario elegido.
  /// Todo ocurre en una sola transacción: si el horario se llenó mientras el
  /// cliente confirmaba, lanza [CupoLlenoException] y no se crea nada.
  /// El cliente NO envía peso ni precio: los registra el personal.
  Future<int> crearPedido({
    required Usuario cliente,
    required Servicio servicio,
    required bool domicilio,
    required Direccion? direccion,
    required DateTime fecha,
    required String horario,
  }) {
    final dia = claveDia(fecha);
    final contador = _db.collection('contadores').doc('pedidos');
    final config = _db.collection('configuracion').doc('general');
    final cupo = _db.collection('cupos').doc(idCupo(dia, horario));
    final nuevo = _pedidos.doc();
    return _db.runTransaction((tx) async {
      final snapContador = await tx.get(contador);
      final snapConfig = await tx.get(config);
      final snapCupo = await tx.get(cupo);

      final maximo = (snapConfig.data()?['cupoPorHorario'] as num? ?? cupoPorHorarioPredeterminado).toInt();
      final ocupados = (snapCupo.data()?['ocupados'] as num? ?? 0).toInt();
      if (ocupados >= maximo) throw const CupoLlenoException();

      final folio = (snapContador.data()?['ultimo'] as num? ?? 0).toInt() + 1;
      tx.update(contador, {'ultimo': folio});
      tx.set(cupo, {'dia': dia, 'horario': horario, 'ocupados': ocupados + 1, 'ultimoPedido': nuevo.id});
      tx.set(nuevo, {
        'folio': folio,
        'clienteId': cliente.uid,
        'clienteNombre': cliente.nombre,
        'clienteEmail': cliente.email,
        'clienteTelefono': cliente.telefono,
        'servicioId': servicio.id,
        'servicioNombre': servicio.nombre,
        'precioPorKg': servicio.precioPorKg,
        'domicilio': domicilio,
        'direccion': domicilio ? direccion?.aMapa() : null,
        'fecha': Timestamp.fromDate(fecha),
        'dia': dia,
        'horario': horario,
        'estado': EstadoPedido.solicitudRecibida.clave,
        'pesoKg': null,
        'total': null,
        'historial': [
          {'estado': EstadoPedido.solicitudRecibida.clave, 'fecha': Timestamp.now()},
        ],
        'creadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      return folio;
    });
  }

  Stream<List<Pedido>> pedidosDeCliente(String uid) => _pedidos
      .where('clienteId', isEqualTo: uid)
      .snapshots()
      .map((q) => q.docs.map(Pedido.desdeDoc).toList()..sort(Pedido.ordenLogico));

  Stream<List<Pedido>> todosLosPedidos() => _pedidos
      .snapshots()
      .map((q) => q.docs.map(Pedido.desdeDoc).toList()..sort(Pedido.ordenLogico));

  Stream<Pedido?> pedido(String id) =>
      _pedidos.doc(id).snapshots().map((d) => d.exists ? Pedido.desdeDoc(d) : null);

  /// El personal registra el peso de la báscula; el total se calcula con la tarifa del servicio.
  /// Si el pedido apenas se recibió, pasa a "Ropa recibida".
  Future<double> registrarPeso(Pedido pedido, double pesoKg) async {
    final total = double.parse((pesoKg * pedido.precioPorKg).toStringAsFixed(2));
    final datos = <String, dynamic>{
      'pesoKg': pesoKg,
      'total': total,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
    if (pedido.estado == EstadoPedido.solicitudRecibida) {
      datos['estado'] = EstadoPedido.ropaRecibida.clave;
      datos['historial'] = FieldValue.arrayUnion([
        {'estado': EstadoPedido.ropaRecibida.clave, 'fecha': Timestamp.now()},
      ]);
    }
    await _pedidos.doc(pedido.id).update(datos);
    return total;
  }

  Future<void> avanzarEstado(Pedido pedido) async {
    final siguiente = pedido.siguienteEstado;
    if (siguiente == null || !pedido.tienePeso) return;
    await _pedidos.doc(pedido.id).update({
      'estado': siguiente.clave,
      'historial': FieldValue.arrayUnion([
        {'estado': siguiente.clave, 'fecha': Timestamp.now()},
      ]),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }
}
