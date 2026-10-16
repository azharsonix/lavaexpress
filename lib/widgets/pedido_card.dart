import 'package:flutter/material.dart';

import '../models/pedido.dart';
import '../theme/app_theme.dart';
import '../theme/iconos.dart';
import '../utils/formato.dart';
import '../utils/textos_pedido.dart';
import 'estado_visual.dart';

class PedidoCard extends StatelessWidget {
  const PedidoCard({
    super.key,
    required this.pedido,
    required this.onTap,
    this.mostrarCliente = false,
    this.seleccionado = false,
  });

  final Pedido pedido;
  final VoidCallback onTap;
  final bool mostrarCliente;
  final bool seleccionado;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = pedido;
    final secundario = t.bodySmall?.copyWith(color: s.onSurfaceVariant);

    return Card(
      color: seleccionado ? s.primary.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radio),
        side: BorderSide(color: seleccionado ? s.primary : s.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          folio(p.folio),
                          style: t.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            mostrarCliente ? p.clienteNombre : p.servicioNombre,
                            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        EstadoChip(p.estado),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (mostrarCliente) p.servicioNombre,
                        p.activo ? citaCorta(p) : 'Entregado el ${fechaCorta(p.fechaCierre)}',
                        textoEntregaCorto(p.domicilio),
                      ].join('  ·  '),
                      style: secundario,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    p.total != null ? moneda(p.total!) : '—',
                    style: t.titleSmall?.copyWith(color: p.total != null ? s.onSurface : s.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(p.tienePeso ? kilos(p.pesoKg!) : 'Sin pesar', style: secundario),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Iconos.siguiente, size: 18, color: s.outline),
            ],
          ),
        ),
      ),
    );
  }
}
