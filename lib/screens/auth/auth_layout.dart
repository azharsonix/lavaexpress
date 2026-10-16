import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/iconos.dart';
import '../../utils/ui.dart';
import '../../widgets/marca.dart';

/// Estructura de las pantallas de acceso.
/// En web/escritorio: formulario a la izquierda y fotografía de la marca a la
/// derecha. En móvil: fotografía como encabezado y el formulario debajo.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.mostrarRegresar = false,
    this.foto = Fotos.ropaDoblada,
  });

  final Widget child;
  final bool mostrarRegresar;
  final String foto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= anchoExpandido ? _escritorio(context, c.maxWidth) : _movil(context),
      ),
    );
  }

  Widget _botonRegresar(BuildContext context, {Color? color}) => IconButton(
    tooltip: 'Regresar',
    color: color,
    onPressed: () => Navigator.maybePop(context),
    icon: const Icon(Iconos.regresar, size: 20),
  );

  Widget _pie(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Text(
      '© ${DateTime.now().year} LavaExpress',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
    );
  }

  // ---------- Web / escritorio ----------
  Widget _escritorio(BuildContext context, double ancho) {
    final s = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Formulario
        Expanded(
          flex: 5,
          child: ColoredBox(
            color: s.surface,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      children: [
                        if (mostrarRegresar) ...[_botonRegresar(context), const SizedBox(width: 4)],
                        const MarcaCompleta(tamano: 32),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: child),
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(28, 8, 28, 20), child: _pie(context)),
                ],
              ),
            ),
          ),
        ),
        // Fotografía
        Expanded(
          flex: ancho >= 1240 ? 6 : 5,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FotoMarca(
              foto: foto,
              radio: AppTheme.radio + 8,
              velo: const [0.05, 0.9],
              child: const _MensajeMarca(),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Móvil ----------
  Widget _movil(BuildContext context) {
    final alto = MediaQuery.paddingOf(context).top + 190;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: alto,
            child: FotoMarca(
              foto: foto,
              velo: const [0.35, 0.85],
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
                        child: mostrarRegresar ? _botonRegresar(context, color: Colors.white) : null,
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: MarcaCompleta(tamano: 36, claro: true, subtitulo: 'Lavandería a domicilio'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
            child: Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: child),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Center(child: _pie(context)),
          ),
        ],
      ),
    );
  }
}

/// Texto sobre la fotografía en web/escritorio.
class _MensajeMarca extends StatelessWidget {
  const _MensajeMarca();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Text(
              'Lavandería a domicilio',
              style: t.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              'Tu ropa limpia sin salir de casa',
              style: t.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Ventaja(icono: Iconos.domicilio, texto: 'Recolección y entrega'),
              _Ventaja(icono: Iconos.peso, texto: 'Pagas por kilo'),
              _Ventaja(icono: Iconos.pedidos, texto: 'Sigue tu pedido'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ventaja extends StatelessWidget {
  const _Ventaja({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: AppTheme.agua),
        const SizedBox(width: 8),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Etiqueta que va sobre cada campo de los formularios de acceso.
class EtiquetaCampo extends StatelessWidget {
  const EtiquetaCampo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(texto, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
