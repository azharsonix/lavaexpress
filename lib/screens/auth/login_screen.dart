import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/iconos.dart';
import '../../utils/ui.dart';
import 'auth_layout.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  bool _ocultar = true;
  bool _cargando = false;

  @override
  void dispose() {
    _email.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AuthService.instance.iniciarSesion(_email.text.trim(), _contrasena.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) mostrarError(context, AuthService.mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return AuthLayout(
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Iniciar sesión', style: t.headlineMedium?.copyWith(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                'Ingresa tus datos para acceder a tu cuenta.',
                style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              const EtiquetaCampo('Correo electrónico'),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(prefixIcon: Icon(Iconos.correo, size: 18)),
                validator: (v) => (v == null || !v.contains('@')) ? 'Escribe un correo válido' : null,
              ),
              const SizedBox(height: 16),
              const EtiquetaCampo('Contraseña'),
              TextFormField(
                controller: _contrasena,
                obscureText: _ocultar,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _entrar(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconos.contrasena, size: 18),
                  suffixIcon: IconButton(
                    tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                    icon: Icon(_ocultar ? Iconos.mostrar : Iconos.ocultar, size: 18),
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Escribe tu contraseña' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _cargando ? null : _entrar,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _cargando
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Iniciar sesión'),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes cuenta?', style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen())),
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
