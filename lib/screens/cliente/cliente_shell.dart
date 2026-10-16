import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/auth_service.dart';
import '../../services/avisos_pedidos.dart';
import '../../services/firestore_service.dart';
import '../../theme/iconos.dart';
import '../../utils/ui.dart';
import '../../widgets/plataforma.dart';
import '../auth_gate.dart';
import 'inicio_cliente.dart';
import 'mis_pedidos.dart';
import 'nuevo_pedido.dart';
import 'perfil_cliente.dart';

/// Navegación principal del cliente: barra inferior en móvil y barra lateral en web/escritorio.
class ClienteShell extends StatefulWidget {
  const ClienteShell({super.key});

  @override
  State<ClienteShell> createState() => _ClienteShellState();
}

class _ClienteShellState extends State<ClienteShell> {
  int _indice = 0;
  late final Stream<Usuario?> _perfil = FirestoreService.instance.perfil(AuthService.instance.usuario!.uid);

  /// Avisa (notificación y vibración) cuando uno de sus pedidos cambia de estado.
  late final _avisos = AvisosPedidos(
    FirestoreService.instance.pedidosDeCliente(AuthService.instance.usuario!.uid),
    esPersonal: false,
    alAvisar: (a) {
      if (mounted) mostrarMensaje(context, a.titulo, icono: Iconos.pedidos);
    },
  );

  @override
  void initState() {
    super.initState();
    _avisos;
  }

  @override
  void dispose() {
    _avisos.cancelar();
    super.dispose();
  }

  static const _destinos = [(Iconos.inicio, 'Inicio'), (Iconos.pedidos, 'Mis pedidos'), (Iconos.perfil, 'Perfil')];

  /// Al terminar una solicitud se muestra "Mis pedidos", donde aparece el pedido nuevo.
  Future<void> _nuevoPedido(Usuario perfil) async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => NuevoPedidoScreen(cliente: perfil)),
    );
    if (creado == true && mounted) setState(() => _indice = 1);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Usuario?>(
      stream: _perfil,
      builder: (context, snap) {
        final perfil = snap.data;
        if (perfil == null) return const PantallaCarga();

        final paginas = [
          InicioCliente(
            perfil: perfil,
            onNuevoPedido: () => _nuevoPedido(perfil),
            onVerPedidos: () => setState(() => _indice = 1),
          ),
          MisPedidos(uid: perfil.uid, onNuevoPedido: () => _nuevoPedido(perfil)),
          PerfilCliente(perfil: perfil),
        ];

        final contenido = AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          child: KeyedSubtree(key: ValueKey(_indice), child: paginas[_indice]),
        );

        final boton = FloatingActionButton.extended(
          onPressed: () => _nuevoPedido(perfil),
          icon: const Icon(Iconos.agregar, size: 18),
          label: const Text('Nueva solicitud'),
        );

        return LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= anchoExpandido) {
              return Scaffold(
                body: Row(
                  children: [
                    BarraLateral(
                      subtitulo: 'Portal del cliente',
                      nombreUsuario: perfil.nombre,
                      detalleUsuario: perfil.email,
                      iniciales: perfil.iniciales,
                      onCerrarSesion: () => AuthService.instance.cerrarSesion(),
                      accion: FilledButton.icon(
                        onPressed: () => _nuevoPedido(perfil),
                        icon: const Icon(Iconos.agregar, size: 18),
                        label: const Text('Nueva solicitud'),
                      ),
                      opciones: [
                        const GrupoLateral('MENÚ'),
                        for (final (i, d) in _destinos.indexed)
                          OpcionLateral(
                            texto: d.$2,
                            icono: d.$1,
                            seleccionada: _indice == i,
                            onTap: () => setState(() => _indice = i),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: contenido),
                  ],
                ),
              );
            }
            return Scaffold(
              body: contenido,
              // En Inicio ya está el botón "Nueva solicitud" del encabezado.
              floatingActionButton: _indice == 1 ? boton : null,
              bottomNavigationBar: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                ),
                child: NavigationBar(
                  selectedIndex: _indice,
                  onDestinationSelected: (i) => setState(() => _indice = i),
                  destinations: [
                    for (final d in _destinos) NavigationDestination(icon: Icon(d.$1, size: 20), label: d.$2),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
