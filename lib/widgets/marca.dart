import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/iconos.dart';

/// Color institucional; igual en tema claro y oscuro.
const azulMarca = AppTheme.semilla;

/// Degradado de la marca (logotipo y fondos de fotos).
const degradadoMarca = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0B63CE), azulMarca],
);

/// Fotografías de la marca (assets/fotos, créditos en assets/CREDITOS.txt).
abstract final class Fotos {
  static const ropaDoblada = 'assets/fotos/ropa_doblada.jpg';
  static const lavadora = 'assets/fotos/lavadora.jpg';
  static const canasta = 'assets/fotos/canasta.jpg';
}

/// Logotipo de LavaExpress.
class LogoLava extends StatelessWidget {
  const LogoLava({super.key, this.tamano = 40, this.claro = false});

  final double tamano;

  /// Versión para fondos de color.
  final bool claro;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tamano * 0.26),
        color: claro ? Colors.white : null,
        gradient: claro ? null : degradadoMarca,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Iconos.marca, size: tamano * 0.56, color: claro ? azulMarca : Colors.white),
          // Gota de agua: acento de la marca.
          Positioned(
            top: tamano * 0.14,
            right: tamano * 0.14,
            child: Container(
              width: tamano * 0.16,
              height: tamano * 0.16,
              decoration: const BoxDecoration(color: AppTheme.agua, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nombre en dos tonos: "Lava" en el color del texto y "Express" en azul.
class NombreMarca extends StatelessWidget {
  const NombreMarca({super.key, this.estilo, this.claro = false});

  final TextStyle? estilo;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final base = (estilo ?? Theme.of(context).textTheme.titleLarge)!.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Lava', style: TextStyle(color: claro ? Colors.white : s.onSurface)),
          TextSpan(text: 'Express', style: TextStyle(color: claro ? AppTheme.agua : s.primary)),
        ],
      ),
      style: base,
    );
  }
}

/// Logotipo y nombre juntos.
class MarcaCompleta extends StatelessWidget {
  const MarcaCompleta({super.key, this.tamano = 36, this.claro = false, this.subtitulo});

  final double tamano;
  final bool claro;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoLava(tamano: tamano, claro: claro),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            NombreMarca(claro: claro, estilo: t.titleMedium),
            if (subtitulo != null)
              Text(subtitulo!, style: t.labelSmall?.copyWith(color: claro ? Colors.white70 : s.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

/// Fotografía con un velo azul marino para que el texto blanco encima se lea.
class FotoMarca extends StatelessWidget {
  const FotoMarca({
    super.key,
    required this.foto,
    this.child,
    this.alineacion = Alignment.center,
    this.velo = const [0.15, 0.85],
    this.direccionVelo = Alignment.bottomCenter,
    this.radio = 0,
  });

  final String foto;
  final Widget? child;

  /// Parte de la foto que se conserva al recortar.
  final Alignment alineacion;

  /// Opacidad del velo al inicio y al final del degradado.
  final List<double> velo;

  /// Hacia dónde se oscurece la foto.
  final Alignment direccionVelo;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(foto, fit: BoxFit.cover, alignment: alineacion),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: -direccionVelo,
                end: direccionVelo,
                colors: [
                  AppTheme.marino.withValues(alpha: velo[0]),
                  AppTheme.marino.withValues(alpha: velo[1]),
                ],
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}
