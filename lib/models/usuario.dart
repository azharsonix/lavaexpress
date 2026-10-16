import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil guardado en la colección "usuarios".
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.rol,
  });

  final String uid;
  final String nombre;
  final String email;
  final String telefono;

  /// "cliente" o "personal".
  final String rol;

  String get primerNombre => nombre.trim().split(' ').first;

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }

  factory Usuario.desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Usuario(
      uid: doc.id,
      nombre: d['nombre'] as String? ?? '',
      email: d['email'] as String? ?? '',
      telefono: d['telefono'] as String? ?? '',
      rol: d['rol'] as String? ?? 'cliente',
    );
  }
}
