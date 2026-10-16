import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pedido.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';

/// Diálogo donde el personal captura el peso obtenido en la báscula.
/// Muestra el precio calculado con la tarifa del servicio para confirmarlo.
Future<double?> mostrarDialogoPeso(BuildContext context, Pedido pedido) {
  return showDialog<double>(
    context: context,
    builder: (_) => _DialogoPeso(pedido: pedido),
  );
}

class _DialogoPeso extends StatefulWidget {
  const _DialogoPeso({required this.pedido});

  final Pedido pedido;

  @override
  State<_DialogoPeso> createState() => _DialogoPesoState();
}

class _DialogoPesoState extends State<_DialogoPeso> {
  late final _control = TextEditingController(
    text: widget.pedido.pesoKg != null ? widget.pedido.pesoKg!.toString() : '',
  );

  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    // En web, autofocus a veces se pierde mientras el diálogo se anima;
    // se pide el foco explícitamente cuando el diálogo ya está en pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _foco.requestFocus();
    });
  }

  double? get _peso {
    final v = double.tryParse(_control.text.replaceAll(',', '.'));
    return (v != null && v > 0 && v <= 500) ? v : null;
  }

  @override
  void dispose() {
    _control.dispose();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = widget.pedido;
    final peso = _peso;
    final total = peso == null ? null : peso * p.precioPorKg;

    return AlertDialog(
      title: Text(p.tienePeso ? 'Corregir peso' : 'Registrar peso'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pedido ${folio(p.folio)} · ${p.servicioNombre}\nIngresa el peso que marcó la báscula de la lavandería.',
              style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _control,
              focusNode: _foco,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              textAlign: TextAlign.center,
              style: t.headlineMedium,
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: 'kg',
                errorText: _control.text.isNotEmpty && peso == null
                    ? 'Escribe un peso mayor que 0 y hasta 500 kg'
                    : null,
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_peso != null) Navigator.pop(context, _peso);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: s.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radio),
                border: Border.all(color: s.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Tarifa', style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
                      ),
                      Text('${moneda(p.precioPorKg)} por kg', style: t.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text('Total', style: t.titleMedium)),
                      Text(
                        total == null ? '—' : moneda(total),
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: total == null ? s.outline : s.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: peso == null ? null : () => Navigator.pop(context, peso),
          child: const Text('Confirmar precio'),
        ),
      ],
    );
  }
}
