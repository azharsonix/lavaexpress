import 'package:flutter/material.dart';

import '../models/direccion.dart';
import '../services/dispositivo.dart';
import '../services/firestore_service.dart';
import '../services/ubicacion.dart';
import '../theme/iconos.dart';
import '../utils/ui.dart';

/// Hoja inferior para registrar una dirección. Devuelve la dirección guardada.
Future<Direccion?> mostrarFormularioDireccion(BuildContext context, String uid) {
  return showModalBottomSheet<Direccion>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FormularioDireccion(uid: uid),
  );
}

class _FormularioDireccion extends StatefulWidget {
  const _FormularioDireccion({required this.uid});

  final String uid;

  @override
  State<_FormularioDireccion> createState() => _FormularioDireccionState();
}

class _FormularioDireccionState extends State<_FormularioDireccion> {
  final _form = GlobalKey<FormState>();
  final _alias = TextEditingController(text: 'Casa');
  final _calle = TextEditingController();
  final _colonia = TextEditingController();
  final _referencias = TextEditingController();
  bool _guardando = false;
  bool _localizando = false;
  UbicacionActual? _ubicacion;

  /// Llena calle y colonia con el GPS del dispositivo.
  Future<void> _usarUbicacion() async {
    setState(() => _localizando = true);
    try {
      final u = await Ubicacion.leer();
      if (!mounted) return;
      Dispositivo.vibrar();
      setState(() {
        _ubicacion = u;
        if (u.calle.isNotEmpty) _calle.text = u.calle;
        if (u.colonia.isNotEmpty) _colonia.text = u.colonia;
      });
      mostrarMensaje(
        context,
        u.calle.isEmpty ? 'Ubicación guardada; escribe la calle y colonia.' : 'Revisa que la dirección sea correcta.',
        icono: Iconos.ubicacion,
      );
    } on UbicacionError catch (e) {
      if (mounted) mostrarError(context, e.mensaje);
    } catch (_) {
      if (mounted) mostrarError(context, 'No se pudo obtener tu ubicación.');
    } finally {
      if (mounted) setState(() => _localizando = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_alias, _calle, _colonia, _referencias]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final guardada = await FirestoreService.instance.agregarDireccion(
        widget.uid,
        Direccion(
          alias: _alias.text.trim(),
          calle: _calle.text.trim(),
          colonia: _colonia.text.trim(),
          referencias: _referencias.text.trim(),
          latitud: _ubicacion?.latitud,
          longitud: _ubicacion?.longitud,
        ),
      );
      if (mounted) Navigator.pop(context, guardada);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        mostrarError(context, 'No se pudo guardar la dirección.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nueva dirección', style: t.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Domicilio para la recolección y entrega de tu ropa.',
                style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _localizando ? null : _usarUbicacion,
                icon: _localizando
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_ubicacion == null ? Iconos.ubicacion : Iconos.exito, size: 18),
                label: Text(_ubicacion == null ? 'Usar mi ubicación actual' : 'Ubicación guardada'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alias,
                decoration: const InputDecoration(labelText: 'Nombre (ej. Casa, Trabajo)'),
                validator: _requerido,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _calle,
                decoration: const InputDecoration(labelText: 'Calle y número'),
                validator: _requerido,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colonia,
                decoration: const InputDecoration(labelText: 'Colonia'),
                validator: _requerido,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referencias,
                decoration: const InputDecoration(labelText: 'Referencias (opcional)'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Iconos.guardar, size: 18),
                label: const Text('Guardar dirección'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
