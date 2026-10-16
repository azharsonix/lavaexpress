import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import '../../services/firestore_service.dart';
import '../../theme/iconos.dart';
import '../../utils/ui.dart';
import '../../widgets/comunes.dart';
import '../../widgets/pedido_card.dart';
import '../../widgets/plataforma.dart';
import '../pedido_detalle.dart';

/// Pedidos activos y anteriores del cliente.
class MisPedidos extends StatefulWidget {
  const MisPedidos({super.key, required this.uid, required this.onNuevoPedido});

  final String uid;
  final VoidCallback onNuevoPedido;

  @override
  State<MisPedidos> createState() => _MisPedidosState();
}

class _MisPedidosState extends State<MisPedidos> {
  late final _pedidos = FirestoreService.instance.pedidosDeCliente(widget.uid);
  bool _activos = true;

  Widget _filtro() => SegmentedButton<bool>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(value: true, label: Text('Activos')),
      ButtonSegment(value: false, label: Text('Anteriores')),
    ],
    selected: {_activos},
    onSelectionChanged: (v) => setState(() => _activos = v.first),
  );

  /// Web/escritorio: encabezado con el filtro y tabla de pedidos.
  Widget _escritorio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarraSuperior(titulo: 'Mis pedidos', detalle: 'Peso, precio y estado de cada pedido', acciones: [_filtro()]),
        Expanded(
          child: StreamBuilder<List<Pedido>>(
            stream: _pedidos,
            builder: (context, snap) {
              if (snap.hasError) {
                return const EstadoVacio(icono: Iconos.sinConexion, titulo: 'No se pudieron cargar tus pedidos');
              }
              if (!snap.hasData) {
                return const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator(minHeight: 2));
              }
              final lista = snap.data!.where((p) => p.activo == _activos).toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  TablaPedidos(
                    lista: lista,
                    onSeleccionar: (p) => abrirDetallePedido(context, p.id, esPersonal: false),
                    mensajeVacio: _activos ? 'Sin pedidos activos' : 'Aún no tienes pedidos entregados',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= anchoExpandido) return _escritorio();
    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            sliver: SliverToBoxAdapter(
              child: AnchoMaximo(
                ancho: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const EncabezadoPagina(titulo: 'Mis pedidos', descripcion: 'Peso, precio y estado de cada pedido.'),
                    const SizedBox(height: 16),
                    _filtro(),
                  ],
                ),
              ),
            ),
          ),
        ),
        StreamBuilder<List<Pedido>>(
          stream: _pedidos,
          builder: (context, snap) {
            if (snap.hasError) {
              return const SliverFillRemaining(
                child: EstadoVacio(icono: Iconos.sinConexion, titulo: 'No se pudieron cargar tus pedidos'),
              );
            }
            if (!snap.hasData) {
              return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
            }
            final lista = snap.data!.where((p) => p.activo == _activos).toList();
            if (lista.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EstadoVacio(
                  icono: _activos ? Iconos.vacio : Iconos.historial,
                  titulo: _activos ? 'Sin pedidos activos' : 'Aún no tienes pedidos entregados',
                  mensaje: _activos ? 'Solicita un servicio y síguelo desde aquí.' : null,
                  accion: _activos
                      ? OutlinedButton.icon(
                          onPressed: widget.onNuevoPedido,
                          icon: const Icon(Iconos.agregar, size: 18),
                          label: const Text('Nueva solicitud'),
                        )
                      : null,
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.separated(
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => AnchoMaximo(
                  ancho: 900,
                  child: PedidoCard(
                    pedido: lista[i],
                    onTap: () => abrirDetallePedido(context, lista[i].id, esPersonal: false),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
