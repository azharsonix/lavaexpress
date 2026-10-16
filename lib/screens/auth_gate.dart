import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/marca.dart';
import 'auth/login_screen.dart';
import 'cliente/cliente_shell.dart';
import 'personal/panel_personal.dart';

/// Decide qué mostrar según la sesión y el rol del usuario.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.cambios,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const PantallaCarga();
        final usuario = snap.data;
        if (usuario == null) return const LoginScreen();
        return FutureBuilder<String>(
          key: ValueKey(usuario.uid),
          future: AuthService.instance.rol(),
          builder: (context, rol) {
            if (!rol.hasData) return const PantallaCarga();
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: rol.data == 'personal' ? const PanelPersonal() : const ClienteShell(),
            );
          },
        );
      },
    );
  }
}

class PantallaCarga extends StatelessWidget {
  const PantallaCarga({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MarcaCompleta(tamano: 40),
            SizedBox(height: 24),
            SizedBox(width: 140, child: LinearProgressIndicator(minHeight: 2)),
          ],
        ),
      ),
    );
  }
}
