import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';

/// Registro, inicio de sesión y rol del usuario (Firebase Authentication).
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;

  Stream<User?> get cambios => _auth.authStateChanges();
  User? get usuario => _auth.currentUser;

  Future<void> iniciarSesion(String email, String contrasena) =>
      _auth.signInWithEmailAndPassword(email: email, password: contrasena);

  /// Solo los clientes se registran desde la app.
  /// Las cuentas del personal se crean con Firebase Admin SDK.
  Future<void> registrarCliente({
    required String nombre,
    required String telefono,
    required String email,
    required String contrasena,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: contrasena);
    await cred.user!.updateDisplayName(nombre);
    await FirestoreService.instance.crearPerfilCliente(
      uid: cred.user!.uid,
      nombre: nombre,
      email: email,
      telefono: telefono,
    );
  }

  /// Lee el rol asignado con Admin SDK (custom claim "rol").
  Future<String> rol() async {
    // El rol se asigna antes de que el personal inicie sesión,
    // así que el token recién emitido ya lo incluye.
    final token = await _auth.currentUser!.getIdTokenResult();
    return token.claims?['rol'] as String? ?? 'cliente';
  }

  Future<void> cerrarSesion() => _auth.signOut();

  static String mensajeError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta de nuevo más tarde.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Ocurrió un error (${e.code}).';
    }
  }
}
