import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de lavandería con su tarifa por kilogramo.
class Servicio {
  const Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioPorKg,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final double precioPorKg;

  factory Servicio.desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Servicio(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      descripcion: d['descripcion'] as String? ?? '',
      precioPorKg: (d['precioPorKg'] as num? ?? 0).toDouble(),
    );
  }
}
