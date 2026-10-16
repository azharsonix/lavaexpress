import 'package:flutter/material.dart';

import '../../models/estado_pedido.dart';
import '../../models/pedido.dart';
import '../../services/auth_service.dart';
import '../../services/avisos_pedidos.dart';
import '../../services/firestore_service.dart';
import '../../theme/iconos.dart';
import '../../utils/formato.dart';
import '../../utils/ui.dart';
import '../../widgets/comunes.dart';
import '../../widgets/estado_visual.dart';
import '../../widgets/marca.dart';
import '../../widgets/pedido_card.dart';
import '../../widgets/plataforma.dart';
import '../../widgets/seccion_preferencias.dart';
import '../pedido_detalle.dart';

/// Panel del personal de la lavandería: consulta y filtra todos los pedidos.
///  - Web/escritorio: barra lateral con filtros, indicadores, tabla y detalle a la derecha.
///  - Móvil: buscador, filtros y lista de tarjetas.
class PanelPersonal extends StatefulWidget {
  const PanelPersonal({super.key});

  @override
  State<PanelPersonal> createState() => _PanelPersonalState();
}

class _PanelPersonalState extends State<PanelPersonal> {
  final _pedidos = FirestoreService.instance.todosLosPedidos();
  final _busqueda = TextEditingController();

  /// null = pedidos activos; otro valor = solo ese estado.
  EstadoPedido? _filtro;
  String? _seleccionado;

  /// Avisa (notificación y vibración) cuando llega una solicitud nueva.
  late final _avisos = AvisosPedidos(
    FirestoreService.instance.todosLosPedidos(),
    esPersonal: true,
    alAvisar: (a) {
      if (mounted) mostrarMensaje(context, '${a.titulo} · ${a.cuerpo}', icono: Iconos.pedidos);
    },
  );

  static const _textoAvisos = 'Recibe un aviso cuando llegue una solicitud nueva.';

  @override
  void initState() {
    super.initState();
    _avisos;
  }

  @override
  void dispose() {
    _avisos.cancelar();
    _busqueda.dispose();
    super.dispose();
  }

  List<Pedido> _filtrar(List<Pedido> lista) {
    final q = _busqueda.text.trim().toLowerCase().replaceAll('#', '');
    return lista.where((p) {
      if (_filtro == null && !p.activo) return false;
      if (_filtro != null && p.estado != _filtro) return false;
      if (q.isEmpty) return true;
      return p.folio.toString().padLeft(3, '0').contains(q) || p.clienteNombre.toLowerCase().contains(q);
    }).toList();
  }

  void _cambiarFiltro(EstadoPedido? f) => setState(() {
    _filtro = f;
    _seleccionado = null;
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pedido>>(
      stream: _pedidos,
      builder: (context, snap) {
        return LayoutBuilder(
          builder: (context, c) {
            final escritorio = c.maxWidth >= 1000;
            final todos = snap.data;
            final Widget contenido;
            if (snap.hasError) {
              contenido = const EstadoVacio(icono: Iconos.sinConexion, titulo: 'No se pudieron cargar los pedidos');
            } else if (todos == null) {
              contenido = const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator(minHeight: 2));
            } else if (escritorio) {
              contenido = _Escritorio(
                todos: todos,
                lista: _filtrar(todos),
                busqueda: _busqueda,
                filtro: _filtro,
                seleccionado: _seleccionado,
                conDetalle: c.maxWidth >= 1280,
                onBuscar: () => setState(() {}),
                onSeleccionar: (p) {
                  if (c.maxWidth >= 1280) {
                    setState(() => _seleccionado = _seleccionado == p.id ? null : p.id);
                  } else {
                    abrirDetallePedido(context, p.id, esPersonal: true);
                  }
                },
                onCerrarDetalle: () => setState(() => _seleccionado = null),
              );
            } else {
              contenido = _ListaMovil(
                todos: todos,
                lista: _filtrar(todos),
                busqueda: _busqueda,
                filtro: _filtro,
                onBuscar: () => setState(() {}),
                onFiltro: _cambiarFiltro,
                onAbrir: (p) => abrirDetallePedido(context, p.id, esPersonal: true),
              );
            }

            if (!escritorio) {
              return Scaffold(
                appBar: AppBar(
                  titleSpacing: 16,
                  title: const MarcaCompleta(tamano: 30, subtitulo: 'Panel del personal'),
                  actions: [
                    IconButton(
                      tooltip: 'Preferencias',
                      onPressed: () => abrirPreferencias(context, textoAvisos: _textoAvisos),
                      icon: const Icon(Iconos.preferencias, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      onPressed: () => AuthService.instance.cerrarSesion(),
                      icon: const Icon(Iconos.salir, size: 20),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: contenido,
              );
            }
            return Scaffold(
              body: Row(
                children: [
                  _BarraLateral(todos: todos ?? const [], filtro: _filtro, onFiltro: _cambiarFiltro),
                  const VerticalDivider(width: 1),
                  Expanded(child: contenido),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Escritorio
// ---------------------------------------------------------------------------

class _BarraLateral extends StatelessWidget {
  const _BarraLateral({required this.todos, required this.filtro, required this.onFiltro});

  final List<Pedido> todos;
  final EstadoPedido? filtro;
  final void Function(EstadoPedido?) onFiltro;

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.usuario?.email ?? '';
    return BarraLateral(
      subtitulo: 'Panel del personal',
      nombreUsuario: 'Personal',
      detalleUsuario: email,
      iniciales: email.isEmpty ? 'P' : email[0].toUpperCase(),
      onCerrarSesion: () => AuthService.instance.cerrarSesion(),
      opciones: [
        const GrupoLateral('PEDIDOS'),
        OpcionLateral(
          texto: 'Activos',
          icono: Iconos.pedidos,
          cantidad: todos.where((p) => p.activo).length,
          seleccionada: filtro == null,
          onTap: () => onFiltro(null),
        ),
        const SizedBox(height: 16),
        const GrupoLateral('POR ESTADO'),
        for (final e in EstadoPedido.values)
          OpcionLateral(
            texto: e.etiqueta,
            punto: colorEstado(context, e),
            cantidad: todos.where((p) => p.estado == e).length,
            seleccionada: filtro == e,
            onTap: () => onFiltro(e),
          ),
        const SizedBox(height: 16),
        const GrupoLateral('AJUSTES'),
        OpcionLateral(
          texto: 'Preferencias',
          icono: Iconos.preferencias,
          seleccionada: false,
          onTap: () => abrirPreferencias(context, textoAvisos: _PanelPersonalState._textoAvisos),
        ),
      ],
    );
  }
}

class _Escritorio extends StatelessWidget {
  const _Escritorio({
    required this.todos,
    required this.lista,
    required this.busqueda,
    required this.filtro,
    required this.seleccionado,
    required this.conDetalle,
    required this.onBuscar,
    required this.onSeleccionar,
    required this.onCerrarDetalle,
  });

  final List<Pedido> todos;
  final List<Pedido> lista;
  final TextEditingController busqueda;
  final EstadoPedido? filtro;
  final String? seleccionado;
  final bool conDetalle;
  final VoidCallback onBuscar;
  final void Function(Pedido) onSeleccionar;
  final VoidCallback onCerrarDetalle;

  @override
  Widget build(BuildContext context) {
    final activos = todos.where((p) => p.activo).toList();
    final hoy = DateTime.now();
    bool esHoy(DateTime f) => f.year == hoy.year && f.month == hoy.month && f.day == hoy.day;

    final principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarraSuperior(
          titulo: filtro?.etiqueta ?? 'Pedidos activos',
          detalle: fechaLarga(hoy),
          acciones: [
            SizedBox(
              width: 300,
              child: SearchBar(
                controller: busqueda,
                hintText: 'Buscar por folio o cliente',
                leading: const Icon(Iconos.buscar, size: 16),
                constraints: const BoxConstraints(minHeight: 38),
                onChanged: (_) => onBuscar(),
                trailing: [
                  if (busqueda.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpiar',
                      icon: const Icon(Iconos.cerrar, size: 16),
                      onPressed: () {
                        busqueda.clear();
                        onBuscar();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              // Indicadores (conteos de los pedidos registrados)
              FilaIndicadores([
                Indicador(etiqueta: 'Pedidos activos', valor: '${activos.length}'),
                Indicador(etiqueta: 'Por pesar', valor: '${activos.where((p) => !p.tienePeso).length}'),
                Indicador(etiqueta: 'Citas de hoy', valor: '${activos.where((p) => esHoy(p.fecha)).length}'),
                Indicador(
                  etiqueta: 'Entregados hoy',
                  valor: '${todos.where((p) => !p.activo && esHoy(p.fechaCierre)).length}',
                ),
              ]),
              const SizedBox(height: 20),
              TablaPedidos(
                lista: lista,
                mostrarCliente: true,
                seleccionado: seleccionado,
                onSeleccionar: onSeleccionar,
              ),
            ],
          ),
        ),
      ],
    );

    if (!conDetalle || seleccionado == null) return principal;
    return Row(
      children: [
        Expanded(child: principal),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 440,
          // Messenger propio: los avisos aparecen sobre los botones del detalle.
          child: ScaffoldMessenger(
            child: PedidoDetalle(
              key: ValueKey(seleccionado),
              pedidoId: seleccionado!,
              esPersonal: true,
              incrustado: true,
              onCerrar: onCerrarDetalle,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Móvil
// ---------------------------------------------------------------------------

class _ListaMovil extends StatelessWidget {
  const _ListaMovil({
    required this.todos,
    required this.lista,
    required this.busqueda,
    required this.filtro,
    required this.onBuscar,
    required this.onFiltro,
    required this.onAbrir,
  });

  final List<Pedido> todos;
  final List<Pedido> lista;
  final TextEditingController busqueda;
  final EstadoPedido? filtro;
  final VoidCallback onBuscar;
  final void Function(EstadoPedido? filtro) onFiltro;
  final void Function(Pedido) onAbrir;

  @override
  Widget build(BuildContext context) {
    int contar(EstadoPedido e) => todos.where((p) => p.estado == e).length;
    final activos = todos.where((p) => p.activo).length;

    Widget chip(String texto, int n, bool sel, VoidCallback onTap) => FilterChip(
      label: Text('$texto  $n'),
      selected: sel,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: SearchBar(
            controller: busqueda,
            hintText: 'Buscar por folio o cliente',
            leading: const Icon(Iconos.buscar, size: 18),
            onChanged: (_) => onBuscar(),
            trailing: [
              if (busqueda.text.isNotEmpty)
                IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Iconos.cerrar, size: 18),
                  onPressed: () {
                    busqueda.clear();
                    onBuscar();
                  },
                ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              chip('Activos', activos, filtro == null, () => onFiltro(null)),
              for (final e in EstadoPedido.values) ...[
                const SizedBox(width: 6),
                chip(e.etiqueta, contar(e), filtro == e, () => onFiltro(e)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Divider(),
        Expanded(
          child: lista.isEmpty
              ? const EstadoVacio(icono: Iconos.vacio, titulo: 'Sin pedidos en este filtro')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      PedidoCard(pedido: lista[i], mostrarCliente: true, onTap: () => onAbrir(lista[i])),
                ),
        ),
      ],
    );
  }
}
