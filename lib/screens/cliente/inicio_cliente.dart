import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import '../../models/servicio.dart';
import '../../models/usuario.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/iconos.dart';
import '../../utils/formato.dart';
import '../../utils/textos_pedido.dart';
import '../../utils/ui.dart';
import '../../widgets/comunes.dart';
import '../../widgets/marca.dart';
import '../../widgets/pedido_card.dart';
import '../../widgets/plataforma.dart';
import '../pedido_detalle.dart';

class InicioCliente extends StatefulWidget {
  const InicioCliente({super.key, required this.perfil, required this.onNuevoPedido, required this.onVerPedidos});

  final Usuario perfil;
  final VoidCallback onNuevoPedido;
  final VoidCallback onVerPedidos;

  @override
  State<InicioCliente> createState() => _InicioClienteState();
}

class _InicioClienteState extends State<InicioCliente> {
  late final _pedidos = FirestoreService.instance.pedidosDeCliente(widget.perfil.uid);
  late final _servicios = FirestoreService.instance.servicios();

  void _abrir(Pedido p) => abrirDetallePedido(context, p.id, esPersonal: false);

  /// Resumen de los pedidos del cliente.
  List<Indicador> _indicadores(List<Pedido> todos, {required bool completo}) {
    final activos = todos.where((p) => p.activo).toList();
    return [
      Indicador(etiqueta: 'Pedidos activos', valor: '${activos.length}'),
      Indicador(etiqueta: 'Pendientes de peso', valor: '${activos.where((p) => !p.tienePeso).length}'),
      if (completo) ...[
        // La lista ya viene ordenada: el primer activo es la cita más próxima.
        Indicador(etiqueta: 'Próxima cita', valor: activos.isEmpty ? '—' : citaCorta(activos.first)),
        Indicador(etiqueta: 'Pedidos entregados', valor: '${todos.length - activos.length}'),
      ],
    ];
  }

  Widget _tablaServicios() => StreamBuilder<List<Servicio>>(
    stream: _servicios,
    builder: (context, snap) {
      if (!snap.hasData) return const LinearProgressIndicator(minHeight: 2);
      return _TablaServicios(servicios: snap.data!);
    },
  );

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    return ancho >= anchoExpandido ? _escritorio(ancho) : _movil();
  }

  // ---------- Web / escritorio ----------
  Widget _escritorio(double ancho) {
    final dosColumnas = ancho >= 1240;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarraSuperior(titulo: 'Hola, ${widget.perfil.primerNombre}', detalle: fechaLarga(DateTime.now())),
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
              final todos = snap.data!;
              final activos = todos.where((p) => p.activo).take(5).toList();

              final pedidos = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TituloSeccion(
                    'Pedidos activos',
                    accion: TextButton(onPressed: widget.onVerPedidos, child: const Text('Ver todos')),
                  ),
                  TablaPedidos(lista: activos, onSeleccionar: _abrir, mensajeVacio: 'No tienes pedidos activos'),
                ],
              );
              final servicios = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [const TituloSeccion('Servicios y tarifas'), _tablaServicios()],
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  _BannerSolicitud(onNuevoPedido: widget.onNuevoPedido, alto: 168),
                  const SizedBox(height: 20),
                  FilaIndicadores(_indicadores(todos, completo: true)),
                  if (dosColumnas)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: pedidos),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: servicios),
                      ],
                    )
                  else ...[
                    pedidos,
                    servicios,
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------- Móvil ----------
  Widget _movil() {
    final s = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          EncabezadoPagina(
            titulo: 'Hola, ${widget.perfil.primerNombre}',
            descripcion: fechaLarga(DateTime.now()),
            accion: Iniciales(widget.perfil.iniciales),
          ),
          const SizedBox(height: 20),
          _BannerSolicitud(onNuevoPedido: widget.onNuevoPedido, alto: 184),
          StreamBuilder<List<Pedido>>(
            stream: _pedidos,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(padding: EdgeInsets.only(top: 28), child: LinearProgressIndicator(minHeight: 2));
              }
              final activos = snap.data!.where((p) => p.activo).take(3).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  FilaIndicadores(_indicadores(snap.data!, completo: false)),
                  TituloSeccion(
                    'Pedidos activos',
                    accion: TextButton(onPressed: widget.onVerPedidos, child: const Text('Ver todos')),
                  ),
                  if (activos.isEmpty)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Icon(Iconos.vacio, size: 20, color: s.outline),
                        title: const Text('No tienes pedidos activos'),
                        subtitle: const Text('Cuando solicites un servicio aparecerá aquí.'),
                      ),
                    )
                  else
                    for (final p in activos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PedidoCard(pedido: p, onTap: () => _abrir(p)),
                      ),
                ],
              );
            },
          ),
          const TituloSeccion('Servicios y tarifas'),
          _tablaServicios(),
        ],
      ),
    );
  }
}

class _TablaServicios extends StatelessWidget {
  const _TablaServicios({required this.servicios});

  final List<Servicio> servicios;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final cabecera = t.labelSmall?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.6);
    return Card(
      child: Column(
        children: [
          Container(
            color: s.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Expanded(child: Text('SERVICIO', style: cabecera)),
                Text('TARIFA', style: cabecera),
              ],
            ),
          ),
          for (final sv in servicios) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(Fotos.lavadora, width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sv.nombre, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        if (sv.descripcion.isNotEmpty)
                          Text(sv.descripcion, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${moneda(sv.precioPorKg)} / kg', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Encabezado con fotografía e invitación a solicitar un servicio.
class _BannerSolicitud extends StatelessWidget {
  const _BannerSolicitud({required this.onNuevoPedido, required this.alto});

  final VoidCallback onNuevoPedido;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      height: alto,
      child: FotoMarca(
        foto: Fotos.canasta,
        alineacion: const Alignment(0.6, 0.4),
        radio: AppTheme.radio + 4,
        direccionVelo: Alignment.centerLeft,
        velo: const [0.15, 0.92],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Ropa pendiente?',
                style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Pasamos por ella y te la regresamos limpia.',
                style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: azulMarca,
                  minimumSize: const Size(0, 42),
                ),
                onPressed: onNuevoPedido,
                icon: const Icon(Iconos.agregar, size: 18),
                label: const Text('Nueva solicitud'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
