import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../theme/iconos.dart';

/// Envuelve toda la app y muestra una franja cuando no hay conexión.
/// Sin internet la app sigue funcionando con los datos guardados en el
/// caché de Firestore; los cambios se envían al recuperar la conexión.
class AvisoConexion extends StatefulWidget {
  const AvisoConexion({super.key, required this.child});

  final Widget child;

  @override
  State<AvisoConexion> createState() => _AvisoConexionState();
}

class _AvisoConexionState extends State<AvisoConexion> {
  final _conexion = Connectivity();
  bool _sinConexion = false;

  @override
  void initState() {
    super.initState();
    _conexion.checkConnectivity().then(_actualizar).ignore();
    _conexion.onConnectivityChanged.listen(_actualizar);
  }

  void _actualizar(List<ConnectivityResult> r) {
    final sin = r.every((e) => e == ConnectivityResult.none);
    if (mounted && sin != _sinConexion) setState(() => _sinConexion = sin);
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(child: widget.child),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _sinConexion
              ? Material(
                  color: s.inverseSurface,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconos.sinConexion, size: 16, color: s.onInverseSurface),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Sin conexión · mostrando datos guardados',
                              style: TextStyle(color: s.onInverseSurface, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
