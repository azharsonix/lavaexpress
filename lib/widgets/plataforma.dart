import 'package:flutter/material.dart';

import '../models/pedido.dart';
import '../theme/app_theme.dart';
import '../theme/iconos.dart';
import '../utils/formato.dart';
import '../utils/textos_pedido.dart';
import 'comunes.dart';
import 'estado_visual.dart';
import 'marca.dart';

/// Componentes del diseño web/escritorio que comparten el panel del cliente
/// y el panel del personal.

/// Ancho de la barra lateral.
const anchoBarraLateral = 248.0;

/// Barra lateral: marca arriba, opciones en medio y usuario abajo.
class BarraLateral extends StatelessWidget {
  const BarraLateral({
    super.key,
    required this.subtitulo,
    required this.opciones,
    required this.nombreUsuario,
    required this.detalleUsuario,
    required this.iniciales,
    required this.onCerrarSesion,
    this.accion,
  });

  final String subtitulo;
  final List<Widget> opciones;
  final String nombreUsuario;
  final String detalleUsuario;
  final String iniciales;
  final VoidCallback onCerrarSesion;

  /// Botón principal debajo de la marca (por ejemplo, "Nueva solicitud").
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      width: anchoBarraLateral,
      color: s.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.centerLeft,
            child: MarcaCompleta(tamano: 30, subtitulo: subtitulo),
          ),
          const Divider(),
          if (accion != null) Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: accion),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(10, 16, 10, 16), children: opciones),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Iniciales(iniciales, radio: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreUsuario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        detalleUsuario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: onCerrarSesion,
                  icon: const Icon(Iconos.salir, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de grupo dentro de la barra lateral ("PEDIDOS", "POR ESTADO"...).
class GrupoLateral extends StatelessWidget {
  const GrupoLateral(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Opción de la barra lateral con icono o punto de color y número opcional.
class OpcionLateral extends StatelessWidget {
  const OpcionLateral({
    super.key,
    required this.texto,
    required this.seleccionada,
    required this.onTap,
    this.icono,
    this.punto,
    this.cantidad,
  });

  final String texto;
  final bool seleccionada;
  final VoidCallback onTap;
  final IconData? icono;
  final Color? punto;
  final int? cantidad;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final color = seleccionada ? s.primary : s.onSurface;
    final radio = BorderRadius.circular(AppTheme.radio - 2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: seleccionada ? s.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: radio,
        child: InkWell(
          borderRadius: radio,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                if (punto != null)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 4, right: 14),
                    decoration: BoxDecoration(color: punto, shape: BoxShape.circle),
                  )
                else if (icono != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(icono, size: 18, color: seleccionada ? s.primary : s.onSurfaceVariant),
                  ),
                Expanded(
                  child: Text(
                    texto,
                    style: t.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: seleccionada ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (cantidad != null)
                  Text(
                    '$cantidad',
                    style: t.labelMedium?.copyWith(
                      color: seleccionada ? s.primary : s.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

/// Encabezado de 64 px de cada página en escritorio.
class BarraSuperior extends StatelessWidget {
  const BarraSuperior({super.key, required this.titulo, this.detalle, this.acciones = const []});

  final String titulo;
  final String? detalle;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(bottom: BorderSide(color: s.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(titulo, style: t.titleLarge),
          if (detalle != null) ...[
            const SizedBox(width: 10),
            Text(detalle!, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
          ],
          const Spacer(),
          for (final (i, a) in acciones.indexed) ...[if (i > 0) const SizedBox(width: 8), a],
        ],
      ),
    );
  }
}

/// Tarjeta con un dato resumido (número o texto corto).
class Indicador extends StatelessWidget {
  const Indicador({super.key, required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de indicadores del mismo ancho.
class FilaIndicadores extends StatelessWidget {
  const FilaIndicadores(this.indicadores, {super.key});

  final List<Indicador> indicadores;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, ind) in indicadores.indexed) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: ind)],
      ],
    );
  }
}

/// Tabla de pedidos para pantallas anchas.
class TablaPedidos extends StatelessWidget {
  const TablaPedidos({
    super.key,
    required this.lista,
    required this.onSeleccionar,
    this.seleccionado,
    this.mostrarCliente = false,
    this.mensajeVacio = 'Sin pedidos en esta vista',
  });

  final List<Pedido> lista;
  final void Function(Pedido) onSeleccionar;
  final String? seleccionado;
  final bool mostrarCliente;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final cabecera = t.labelSmall?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.6);
    final celda = t.bodyMedium;
    final secundaria = t.bodyMedium?.copyWith(color: s.onSurfaceVariant);

    // (título, proporción de ancho, alineado a la derecha)
    final columnas = [
      ('FOLIO', 7, false),
      if (mostrarCliente) ('CLIENTE', 18, false),
      ('SERVICIO', 15, false),
      ('CITA', 16, false),
      ('ENTREGA', 11, false),
      ('PESO', 8, true),
      ('TOTAL', 9, true),
      ('ESTADO', 16, false),
    ];

    Widget texto(String v, TextStyle? estilo, {bool derecha = false}) => Text(
      v,
      style: estilo,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: derecha ? TextAlign.right : TextAlign.left,
    );

    Widget fila(List<Widget> celdas) => Row(
      children: [
        for (var i = 0; i < celdas.length; i++)
          Expanded(
            flex: columnas[i].$2,
            child: Padding(padding: const EdgeInsets.only(right: 12), child: celdas[i]),
          ),
      ],
    );

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: s.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: fila([for (final c in columnas) texto(c.$1, cabecera, derecha: c.$3)]),
          ),
          const Divider(),
          if (lista.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: EstadoVacio(icono: Iconos.vacio, titulo: mensajeVacio),
            )
          else
            for (final (i, p) in lista.indexed) ...[
              if (i > 0) const Divider(),
              Material(
                color: p.id == seleccionado ? s.primary.withValues(alpha: 0.07) : Colors.transparent,
                child: InkWell(
                  onTap: () => onSeleccionar(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: fila([
                      texto(folio(p.folio), celda?.copyWith(fontWeight: FontWeight.w600)),
                      if (mostrarCliente) texto(p.clienteNombre, celda?.copyWith(fontWeight: FontWeight.w500)),
                      texto(p.servicioNombre, mostrarCliente ? secundaria : celda),
                      texto(p.activo ? citaCorta(p) : fechaCorta(p.fechaCierre), secundaria),
                      texto(textoEntregaCorto(p.domicilio), secundaria),
                      texto(p.tienePeso ? kilos(p.pesoKg!) : '—', p.tienePeso ? celda : secundaria, derecha: true),
                      texto(
                        p.total != null ? moneda(p.total!) : '—',
                        p.total != null ? celda?.copyWith(fontWeight: FontWeight.w600) : secundaria,
                        derecha: true,
                      ),
                      Align(alignment: Alignment.centerLeft, child: EstadoChip(p.estado)),
                    ]),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
