import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../theme/iconos.dart';
import '../../utils/ui.dart';
import '../../widgets/marca.dart';
import 'auth_layout.dart';

/// Registro de clientes.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();
  bool _ocultar = true;
  bool _cargando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _telefono, _email, _contrasena, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AuthService.instance.registrarCliente(
        nombre: _nombre.text.trim(),
        telefono: _telefono.text.trim(),
        email: _email.text.trim(),
        contrasena: _contrasena.text,
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) mostrarError(context, AuthService.mensajeError(e));
    } catch (_) {
      if (mounted) mostrarError(context, 'No se pudo crear la cuenta. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return AuthLayout(
      mostrarRegresar: true,
      foto: Fotos.lavadora,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Crear cuenta', style: t.headlineMedium?.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              'Completa tus datos para registrarte como cliente.',
              style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            const EtiquetaCampo('Nombre completo'),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(prefixIcon: Icon(Iconos.nombre, size: 18)),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Escribe tu nombre' : null,
            ),
            const SizedBox(height: 16),
            const EtiquetaCampo('Teléfono'),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(prefixIcon: Icon(Iconos.telefono, size: 18)),
              validator: (v) => (v == null || v.length != 10) ? 'El teléfono debe tener 10 dígitos' : null,
            ),
            const SizedBox(height: 16),
            const EtiquetaCampo('Correo electrónico'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(prefixIcon: Icon(Iconos.correo, size: 18)),
              validator: (v) => (v == null || !v.contains('@')) ? 'Escribe un correo válido' : null,
            ),
            const SizedBox(height: 16),
            const EtiquetaCampo('Contraseña'),
            TextFormField(
              controller: _contrasena,
              obscureText: _ocultar,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconos.contrasena, size: 18),
                suffixIcon: IconButton(
                  tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                  icon: Icon(_ocultar ? Iconos.mostrar : Iconos.ocultar, size: 18),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 16),
            const EtiquetaCampo('Confirmar contraseña'),
            TextFormField(
              controller: _confirmar,
              obscureText: _ocultar,
              onFieldSubmitted: (_) => _registrar(),
              decoration: const InputDecoration(prefixIcon: Icon(Iconos.contrasena, size: 18)),
              validator: (v) => v != _contrasena.text ? 'Las contraseñas no coinciden' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _cargando ? null : _registrar,
              child: _cargando
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
