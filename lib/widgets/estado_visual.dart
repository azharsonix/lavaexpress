import 'package:flutter/material.dart';

import '../models/estado_pedido.dart';
import '../models/pedido.dart';
import '../utils/formato.dart';

/// Color de cada estado. Tonos sobrios que se leen bien en claro y oscuro.
Color colorEstado(BuildContext context, EstadoPedido estado) {
  final oscuro = Theme.of(context).brightness == Brightness.dark;
  return switch (estado) {
    EstadoPedido.solicitudRecibida => oscuro ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
    EstadoPedido.ropaRecibida => oscuro ? const Color(0xFF7DB3F0) : const Color(0xFF1D4ED8),
    EstadoPedido.enProceso => oscuro ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
    EstadoPedido.listaParaEntregar => oscuro ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
    EstadoPedido.enCamino => oscuro ? const Color(0xFF67E8F9) : const Color(0xFF0E7490),
    EstadoPedido.entregada => oscuro ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
  };
}

/// Etiqueta de estado: punto de color y texto.
class EstadoChip extends StatelessWidget {
  const EstadoChip(this.estado, {super.key, this.grande = false});

  final EstadoPedido estado;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final c = colorEstado(context, estado);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: grande ? 10 : 8, vertical: grande ? 5 : 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            estado.etiqueta,
            style: TextStyle(fontSize: grande ? 13 : 12, fontWeight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}

/// Línea de tiempo vertical con el avance del pedido.
class LineaTiempoPedido extends StatelessWidget {
  const LineaTiempoPedido({super.key, required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final flujo = pedido.flujo;
    final actual = flujo.indexOf(pedido.estado);

    return Column(
      children: [
        for (var i = 0; i < flujo.length; i++)
          Builder(
            builder: (context) {
              final e = flujo[i];
              final hecho = i <= actual;
              final esActual = i == actual;
              final fecha = pedido.fechaDe(e);
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hecho ? s.primary : s.surface,
                              border: Border.all(color: hecho ? s.primary : s.outline, width: 1.5),
                            ),
                          ),
                          if (i < flujo.length - 1)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                color: i < actual ? s.primary : s.outlineVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                e.etiqueta,
                                style: t.bodyMedium?.copyWith(
                                  fontWeight: esActual ? FontWeight.w700 : FontWeight.w500,
                                  color: hecho ? s.onSurface : s.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              fecha != null ? fechaHora(fecha) : 'Pendiente',
                              style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
