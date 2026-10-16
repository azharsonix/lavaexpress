import 'package:flutter/material.dart';

import '../models/estado_pedido.dart';
import '../models/pedido.dart';
import '../services/firestore_service.dart';
import '../theme/iconos.dart';
import '../utils/enlaces.dart';
import '../utils/formato.dart';
import '../utils/textos_pedido.dart';
import '../utils/ui.dart';
import '../widgets/comunes.dart';
import '../widgets/estado_visual.dart';
import '../widgets/peso_dialog.dart';

void abrirDetallePedido(BuildContext context, String id, {required bool esPersonal}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PedidoDetalle(pedidoId: id, esPersonal: esPersonal),
    ),
  );
}

/// Detalle de un pedido. El cliente solo consulta; el personal registra peso y cambia el estado.
class PedidoDetalle extends StatefulWidget {
  const PedidoDetalle({
    super.key,
    required this.pedidoId,
    required this.esPersonal,
    this.incrustado = false,
    this.onCerrar,
  });

  final String pedidoId;
  final bool esPersonal;

  /// true cuando se muestra al lado de la lista (pantallas anchas).
  final bool incrustado;

  /// Cierra el detalle cuando se muestra junto a la lista.
  final VoidCallback? onCerrar;

  @override
  State<PedidoDetalle> createState() => _PedidoDetalleState();
}

class _PedidoDetalleState extends State<PedidoDetalle> {
  late final _pedido = FirestoreService.instance.pedido(widget.pedidoId);
  bool _guardando = false;

  Future<void> _registrarPeso(Pedido p) async {
    final peso = await mostrarDialogoPeso(context, p);
    if (peso == null || !mounted) return;
    setState(() => _guardando = true);
    try {
      final total = await FirestoreService.instance.registrarPeso(p, peso);
      if (mounted) mostrarMensaje(context, 'Peso registrado: ${kilos(peso)} · Total ${moneda(total)}');
    } catch (_) {
      if (mounted) mostrarError(context, 'No se pudo registrar el peso.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _avanzar(Pedido p) async {
    final siguiente = p.siguienteEstado!;
    if (siguiente == EstadoPedido.entregada) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Marcar ${folio(p.folio)} como entregada?'),
          content: const Text('Confirma que el cliente ya recibió su ropa.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Marcar entregada')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _guardando = true);
    try {
      await FirestoreService.instance.avanzarEstado(p);
      if (mounted) mostrarMensaje(context, 'Pedido ${folio(p.folio)}: ${siguiente.etiqueta}', icono: siguiente.icono);
    } catch (_) {
      if (mounted) mostrarError(context, 'No se pudo cambiar el estado.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pedido?>(
      stream: _pedido,
      builder: (context, snap) {
        final p = snap.data;
        if (p == null) {
          return Scaffold(
            appBar: widget.incrustado ? null : AppBar(),
            body: snap.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const EstadoVacio(icono: Iconos.noEncontrado, titulo: 'Pedido no encontrado'),
          );
        }
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !widget.incrustado,
            title: Text('Pedido ${folio(p.folio)}'),
            actions: [
              if (widget.onCerrar != null)
                IconButton(tooltip: 'Cerrar', onPressed: widget.onCerrar, icon: const Icon(Iconos.cerrar, size: 18)),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AnchoMaximo(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _secciones(p).expand((w) => [w, const SizedBox(height: 12)]).toList()..removeLast(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: widget.esPersonal ? _barraAcciones(p) : null,
        );
      },
    );
  }

  /// Orden de las secciones según quién consulta:
  ///  - Cliente: estado → cita → peso y precio → seguimiento → servicio.
  ///  - Personal: estado → peso y precio (lo que debe capturar) → cliente → servicio y cita → seguimiento.
  List<Widget> _secciones(Pedido p) {
    final encabezado = _Encabezado(pedido: p);
    final pesoPrecio = _PesoPrecio(pedido: p, esPersonal: widget.esPersonal);
    final seguimiento = Seccion(
      titulo: 'Seguimiento',
      accion: TextButton.icon(
        onPressed: () => abrirEnlace(urlSeguimiento(p.id)),
        icon: const Icon(Iconos.enlace, size: 16),
        label: const Text('Página pública'),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LineaTiempoPedido(pedido: p),
      ),
    );
    final direccion = p.direccion == null
        ? null
        : FilaDato(
            etiqueta: 'Dirección',
            valor: [
              '${p.direccion!.alias} · ${p.direccion!.resumen}',
              if (p.direccion!.referencias.isNotEmpty) p.direccion!.referencias,
            ].join('\n'),
          );
    final servicio = Seccion(
      titulo: widget.esPersonal ? 'Servicio y cita' : 'Servicio',
      child: Column(
        children: [
          FilaDato(etiqueta: 'Servicio', valor: p.servicioNombre),
          FilaDato(etiqueta: 'Entrega', valor: textoEntrega(p.domicilio)),
          if (widget.esPersonal) ...[
            ?direccion,
            if (p.direccion?.enlaceMapa case final mapa?)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => abrirEnlace(mapa),
                  icon: const Icon(Iconos.mapa, size: 16),
                  label: const Text('Ver en mapa'),
                ),
              ),
            FilaDato(etiqueta: 'Fecha', valor: fechaLarga(p.fecha)),
            FilaDato(etiqueta: 'Horario', valor: p.horario),
          ],
        ],
      ),
    );

    if (widget.esPersonal) {
      return [
        encabezado,
        pesoPrecio,
        Seccion(
          titulo: 'Cliente',
          child: Column(
            children: [
              FilaDato(etiqueta: 'Nombre', valor: p.clienteNombre),
              FilaDato(etiqueta: 'Teléfono', valor: p.clienteTelefono),
              FilaDato(etiqueta: 'Correo', valor: p.clienteEmail),
            ],
          ),
        ),
        servicio,
        seguimiento,
      ];
    }
    return [
      encabezado,
      Seccion(
        titulo: tituloCita(p.domicilio),
        child: Column(
          children: [
            FilaDato(etiqueta: 'Fecha', valor: fechaLarga(p.fecha)),
            FilaDato(etiqueta: 'Horario', valor: p.horario),
            ?direccion,
          ],
        ),
      ),
      pesoPrecio,
      seguimiento,
      servicio,
    ];
  }

  Widget? _barraAcciones(Pedido p) {
    if (!p.activo) return null;
    final siguiente = p.siguienteEstado;
    final cargando = const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2));
    final s = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(top: BorderSide(color: s.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: AnchoMaximo(
            child: Row(
              children: [
                if (p.tienePeso) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _guardando ? null : () => _registrarPeso(p),
                      icon: const Icon(Iconos.editar, size: 18),
                      label: const Text('Corregir peso'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: !p.tienePeso
                      ? FilledButton.icon(
                          onPressed: _guardando ? null : () => _registrarPeso(p),
                          icon: _guardando ? cargando : const Icon(Iconos.peso, size: 18),
                          label: const Text('Registrar peso'),
                        )
                      : FilledButton.icon(
                          onPressed: _guardando || siguiente == null ? null : () => _avanzar(p),
                          icon: _guardando ? cargando : Icon(siguiente?.icono ?? Iconos.exito, size: 18),
                          label: Text('Cambiar a: ${siguiente?.etiqueta ?? ''}'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = pedido;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Folio ${folio(p.folio)}', style: t.headlineSmall),
                  const SizedBox(height: 2),
                  Text(
                    [
                      p.servicioNombre,
                      if (p.creadoEn != null) 'Solicitado el ${fechaCorta(p.creadoEn!)}',
                    ].join('  ·  '),
                    style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            EstadoChip(p.estado, grande: true),
          ],
        ),
      ),
    );
  }
}

class _PesoPrecio extends StatelessWidget {
  const _PesoPrecio({required this.pedido, required this.esPersonal});

  final Pedido pedido;
  final bool esPersonal;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = pedido;

    Widget fila(String etiqueta, String valor, {bool pendiente = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(etiqueta, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
          ),
          Text(
            valor,
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: pendiente ? s.outline : s.onSurface),
          ),
        ],
      ),
    );

    return Seccion(
      titulo: 'Peso y precio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fila('Peso registrado', p.tienePeso ? kilos(p.pesoKg!) : 'Pendiente', pendiente: !p.tienePeso),
          fila('Tarifa', '${moneda(p.precioPorKg)} por kg'),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text('Total', style: t.titleMedium)),
                Text(
                  p.total != null ? moneda(p.total!) : 'Pendiente',
                  style: t.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: p.total != null ? s.onSurface : s.outline,
                  ),
                ),
              ],
            ),
          ),
          if (!p.tienePeso) ...[
            const SizedBox(height: 8),
            Text(
              esPersonal
                  ? 'Pesa la ropa en la báscula y registra el peso para calcular el precio.'
                  : 'El personal registrará el peso cuando reciba tu ropa en la lavandería.',
              style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
