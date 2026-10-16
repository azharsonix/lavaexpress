import 'package:flutter/material.dart';

import '../theme/iconos.dart';

/// En pantallas anchas los avisos no ocupan todo el ancho.
double? _anchoAviso(BuildContext context) => MediaQuery.sizeOf(context).width >= 600 ? 440 : null;

void mostrarMensaje(BuildContext context, String mensaje, {IconData icono = Iconos.exito}) {
  final s = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        width: _anchoAviso(context),
        content: Row(
          children: [
            Icon(icono, size: 18, color: s.onInverseSurface),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
      ),
    );
}

void mostrarError(BuildContext context, String mensaje) {
  final s = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        width: _anchoAviso(context),
        backgroundColor: s.errorContainer,
        content: Row(
          children: [
            Icon(Iconos.error, size: 18, color: s.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(mensaje, style: TextStyle(color: s.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
}

/// Ancho a partir del cual se usa el diseño de escritorio/web.
const anchoExpandido = 840.0;
