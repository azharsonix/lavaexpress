import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/iconos.dart';

/// Mensaje para listas vacías.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.icono, required this.titulo, this.mensaje, this.accion});

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 32, color: s.outline),
            const SizedBox(height: 14),
            Text(titulo, style: t.titleMedium, textAlign: TextAlign.center),
            if (mensaje != null) ...[
              const SizedBox(height: 4),
              Text(
                mensaje!,
                style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (accion != null) ...[const SizedBox(height: 16), accion!],
          ],
        ),
      ),
    );
  }
}

/// Encabezado de página: título, descripción opcional y acción a la derecha.
class EncabezadoPagina extends StatelessWidget {
  const EncabezadoPagina({super.key, required this.titulo, this.descripcion, this.accion});

  final String titulo;
  final String? descripcion;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: t.headlineMedium),
              if (descripcion != null) ...[
                const SizedBox(height: 2),
                Text(descripcion!, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        if (accion != null) ...[const SizedBox(width: 12), accion!],
      ],
    );
  }
}

/// Título de sección con acción opcional a la derecha.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion});

  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleLarge)),
            ?accion,
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con encabezado y contenido separados por una línea.
class Seccion extends StatelessWidget {
  const Seccion({super.key, required this.titulo, required this.child, this.accion, this.relleno = true});

  final String titulo;
  final Widget child;
  final Widget? accion;

  /// false cuando el contenido ya trae su propio margen (por ejemplo, listas).
  final bool relleno;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, accion == null ? 14 : 6, accion == null ? 16 : 6, accion == null ? 14 : 6),
            child: Row(
              children: [
                Expanded(child: Text(titulo, style: Theme.of(context).textTheme.titleSmall)),
                ?accion,
              ],
            ),
          ),
          const Divider(),
          relleno ? Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: child) : child,
        ],
      ),
    );
  }
}

/// Fila "etiqueta · valor" para tarjetas de detalle.
class FilaDato extends StatelessWidget {
  const FilaDato({super.key, required this.etiqueta, required this.valor, this.destacado = false});

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(etiqueta, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor,
              style: (destacado ? t.titleMedium : t.bodyMedium)?.copyWith(
                fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso informativo con borde y acento lateral.
class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.texto, this.icono = Iconos.info});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: s.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(color: s.primary.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: s.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: TextStyle(color: s.onSurface, height: 1.4, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

/// Avatar con iniciales.
class Iniciales extends StatelessWidget {
  const Iniciales(this.texto, {super.key, this.radio = 18});

  final String texto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radio,
      backgroundColor: s.surfaceContainerHighest,
      child: Text(
        texto,
        style: TextStyle(color: s.onSurface, fontWeight: FontWeight.w600, fontSize: radio * 0.75),
      ),
    );
  }
}

/// Limita el ancho del contenido en pantallas grandes.
class AnchoMaximo extends StatelessWidget {
  const AnchoMaximo({super.key, required this.child, this.ancho = 900});

  final Widget child;
  final double ancho;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ancho),
      child: child,
    ),
  );
}
