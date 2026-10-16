import 'package:flutter/material.dart';

import '../services/dispositivo.dart';
import '../services/preferencias.dart';
import '../utils/ui.dart';
import 'comunes.dart';

/// Tema de la app y avisos de pedidos. Se guardan en el dispositivo.
class SeccionPreferencias extends StatelessWidget {
  const SeccionPreferencias({super.key, required this.textoAvisos});

  /// Qué se avisa (cambia entre cliente y personal).
  final String textoAvisos;

  Future<void> _cambiarAvisos(BuildContext context, bool activar) async {
    if (activar && !Dispositivo.notificacionesPermitidas) {
      final ok = await Dispositivo.pedirPermisoNotificaciones();
      if (!ok) {
        if (context.mounted) {
          mostrarError(context, 'El navegador bloqueó las notificaciones. Actívalas en la configuración del sitio.');
        }
        return;
      }
    }
    await Preferencias.instance.cambiarAvisos(activar);
    if (activar) await Dispositivo.notificar('Avisos activados', 'Te avisaremos aquí cuando haya cambios.');
  }

  @override
  Widget build(BuildContext context) {
    final p = Preferencias.instance;
    final t = Theme.of(context).textTheme;
    final s = Theme.of(context).colorScheme;
    return Seccion(
      titulo: 'Preferencias de este dispositivo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tema', style: t.labelLarge),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: p.tema,
            builder: (context, tema, _) => SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
              ],
              selected: {tema},
              onSelectionChanged: (v) => p.cambiarTema(v.first),
            ),
          ),
          if (Dispositivo.admiteNotificaciones) ...[
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: p.avisos,
              builder: (context, activos, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notificaciones'),
                subtitle: Text(textoAvisos, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                value: activos && Dispositivo.notificacionesPermitidas,
                onChanged: (v) => _cambiarAvisos(context, v),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Abre las preferencias en una hoja inferior (panel del personal).
void abrirPreferencias(BuildContext context, {required String textoAvisos}) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SeccionPreferencias(textoAvisos: textoAvisos),
    ),
  );
}
