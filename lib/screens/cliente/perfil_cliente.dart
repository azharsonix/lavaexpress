import 'package:flutter/material.dart';

import '../../models/direccion.dart';
import '../../models/usuario.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/iconos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/direccion_sheet.dart';
import '../../widgets/plataforma.dart';
import '../../widgets/seccion_preferencias.dart';
import '../../utils/ui.dart';

class PerfilCliente extends StatefulWidget {
  const PerfilCliente({super.key, required this.perfil});

  final Usuario perfil;

  @override
  State<PerfilCliente> createState() => _PerfilClienteState();
}

class _PerfilClienteState extends State<PerfilCliente> {
  late final _direcciones = FirestoreService.instance.direcciones(widget.perfil.uid);

  Future<void> _cerrarSesion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Iconos.salir),
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok == true) await AuthService.instance.cerrarSesion();
  }

  Future<void> _agregarDireccion() async {
    final d = await mostrarFormularioDireccion(context, widget.perfil.uid);
    if (d != null && mounted) mostrarMensaje(context, 'Dirección "${d.alias}" guardada');
  }

  Widget _datos() {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = widget.perfil;
    return Seccion(
      titulo: 'Datos de la cuenta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Iniciales(p.iniciales, radio: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nombre, style: t.titleMedium),
                      Text('Cliente', style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          FilaDato(etiqueta: 'Correo', valor: p.email),
          FilaDato(etiqueta: 'Teléfono', valor: p.telefono),
        ],
      ),
    );
  }

  static const _preferencias = SeccionPreferencias(
    textoAvisos: 'Recibe un aviso cuando tu pedido cambie de estado.',
  );

  Widget _seccionDirecciones() {
    return StreamBuilder<List<Direccion>>(
      stream: _direcciones,
      builder: (context, snap) {
        final lista = snap.data;
        return Seccion(
          titulo: 'Direcciones',
          relleno: false,
          accion: TextButton.icon(
            onPressed: _agregarDireccion,
            icon: const Icon(Iconos.agregar, size: 16),
            label: const Text('Agregar'),
          ),
          child: lista == null
              ? const LinearProgressIndicator(minHeight: 2)
              : lista.isEmpty
              ? const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text('Sin direcciones registradas'),
                  subtitle: Text('Agrega una para solicitar recolección a domicilio.'),
                )
              : Column(
                  children: [
                    for (final (i, d) in lista.indexed) ...[
                      if (i > 0) const Divider(indent: 52),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: const Icon(Iconos.direccion, size: 20),
                        minLeadingWidth: 20,
                        title: Text(d.alias, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([d.resumen, if (d.referencias.isNotEmpty) d.referencias].join('\n')),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  /// Web/escritorio: datos y direcciones lado a lado. Cerrar sesión está en la barra lateral.
  Widget _escritorio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BarraSuperior(titulo: 'Perfil', detalle: 'Datos de tu cuenta y direcciones registradas'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [_datos(), const SizedBox(height: 16), _preferencias],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: _seccionDirecciones()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= anchoExpandido) return _escritorio();
    final s = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          AnchoMaximo(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EncabezadoPagina(titulo: 'Perfil', descripcion: 'Datos de tu cuenta y direcciones registradas.'),
                const SizedBox(height: 20),
                _datos(),
                const SizedBox(height: 16),
                _seccionDirecciones(),
                const SizedBox(height: 16),
                _preferencias,
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: s.error),
                  onPressed: _cerrarSesion,
                  icon: const Icon(Iconos.salir, size: 18),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
