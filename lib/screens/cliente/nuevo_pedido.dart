import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/direccion.dart';
import '../../models/servicio.dart';
import '../../models/usuario.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/iconos.dart';
import '../../utils/formato.dart';
import '../../utils/horarios.dart';
import '../../utils/textos_pedido.dart';
import '../../utils/ui.dart';
import '../../widgets/comunes.dart';
import '../../widgets/direccion_sheet.dart';

/// Solicitud de servicio en 4 pasos: servicio → entrega → fecha y horario → confirmar.
/// El cliente NO indica el peso: lo registra el personal al recibir la ropa.
class NuevoPedidoScreen extends StatefulWidget {
  const NuevoPedidoScreen({super.key, required this.cliente});

  final Usuario cliente;

  @override
  State<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}

class _NuevoPedidoScreenState extends State<NuevoPedidoScreen> {
  static const _titulos = ['Servicio', 'Entrega', 'Fecha', 'Confirmar'];

  late final _servicios = FirestoreService.instance.servicios();
  late final _direcciones = FirestoreService.instance.direcciones(widget.cliente.uid);
  final _fechas = fechasDisponibles();

  int _paso = 0;
  Servicio? _servicio;
  bool _domicilio = true;
  Direccion? _direccion;
  DateTime? _fecha;
  String? _horario;
  bool _enviando = false;
  int? _folioCreado;

  // Cupo por horario (se actualiza en vivo mientras el cliente elige).
  StreamSubscription<int>? _subMaximo;
  StreamSubscription<Map<String, int>>? _subOcupacion;
  int? _maximo;
  Map<String, int>? _ocupados;

  bool get _cuposCargados => _maximo != null && _ocupados != null;

  int _libres(DateTime dia, String horario) => (_maximo ?? 0) - (_ocupados?[idCupo(claveDia(dia), horario)] ?? 0);

  /// Horarios que aún no inician (si es hoy).
  List<String> _horariosDe(DateTime dia) => horariosDisponibles(dia);

  bool _diaLleno(DateTime dia) => _cuposCargados && _horariosDe(dia).every((h) => _libres(dia, h) <= 0);

  @override
  void initState() {
    super.initState();
    _subMaximo = FirestoreService.instance.cupoPorHorario().listen((m) {
      setState(() => _maximo = m);
      _validarSeleccion();
    });
    if (_fechas.isNotEmpty) {
      _subOcupacion = FirestoreService.instance.ocupacion(_fechas.first, _fechas.last).listen((o) {
        setState(() => _ocupados = o);
        _validarSeleccion();
      });
    } else {
      _ocupados = const {};
    }
  }

  /// Si el horario elegido se llenó mientras el cliente decidía, se quita la selección.
  void _validarSeleccion() {
    if (_enviando || _fecha == null || _horario == null || !_cuposCargados) return;
    if (_libres(_fecha!, _horario!) <= 0) {
      setState(() => _horario = null);
      if (_paso >= 2) mostrarError(context, 'El horario que elegiste se llenó. Elige otro.');
      if (_paso == 3) setState(() => _paso = 2);
    }
  }

  @override
  void dispose() {
    _subMaximo?.cancel();
    _subOcupacion?.cancel();
    super.dispose();
  }

  bool get _hayDatos => _folioCreado == null && (_servicio != null || _paso > 0);

  bool get _puedeContinuar => switch (_paso) {
    0 => _servicio != null,
    1 => !_domicilio || _direccion != null,
    2 => _fecha != null && _horario != null,
    _ => !_enviando,
  };

  Future<void> _continuar() async {
    if (_paso < 3) {
      setState(() => _paso++);
      return;
    }
    setState(() => _enviando = true);
    try {
      final numero = await FirestoreService.instance.crearPedido(
        cliente: widget.cliente,
        servicio: _servicio!,
        domicilio: _domicilio,
        direccion: _direccion,
        fecha: _fecha!,
        horario: _horario!,
      );
      if (!mounted) return;
      setState(() => _folioCreado = numero);
    } on CupoLlenoException {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _horario = null;
        _paso = 2;
      });
      mostrarError(context, 'Ese horario se acaba de llenar. Elige otro, por favor.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarError(context, 'No se pudo registrar la solicitud. Intenta de nuevo.');
    }
  }

  /// "Hoy" y "Mañana" igual que en las tarjetas de pedido; si no, el día de la semana.
  String _etiquetaDia(DateTime f) {
    final relativo = diaRelativo(f);
    return relativo == 'Hoy' || relativo == 'Mañana' ? relativo : diaSemanaCorto(f);
  }

  Future<bool> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin enviar la solicitud?'),
        content: const Text('Los datos que elegiste no se guardarán.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Seguir aquí')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
        ],
      ),
    );
    return salir ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_folioCreado != null) {
      return Scaffold(
        body: _PedidoCreado(numero: _folioCreado!, onEntendido: () => Navigator.pop(context, true)),
      );
    }
    return PopScope(
      canPop: !_hayDatos,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmarSalida() && context.mounted) Navigator.pop(context);
      },
      child: _formulario(),
    );
  }

  Widget _formulario() {
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= _anchoEscritorio ? _formularioEscritorio() : _formularioMovil(),
    );
  }

  static const _anchoEscritorio = 1000.0;

  Widget get _contenidoPaso => switch (_paso) {
    0 => _pasoServicio(),
    1 => _pasoEntrega(),
    2 => _pasoFecha(),
    _ => _pasoConfirmar(),
  };

  Widget get _textoBotonPrincipal => _enviando
      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
      : Text(_paso < 3 ? 'Continuar' : 'Confirmar solicitud');

  // ---------- Web / escritorio: pasos | formulario | resumen ----------
  Widget _formularioEscritorio() {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: s.surface,
              border: Border(bottom: BorderSide(color: s.outlineVariant)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Iconos.cerrar, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 8),
                Text('Nueva solicitud', style: t.titleLarge),
                const SizedBox(width: 10),
                Text(
                  'Paso ${_paso + 1} de ${_titulos.length}',
                  style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PasosVerticales(
                  paso: _paso,
                  titulos: _titulos,
                  descripciones: const [
                    'Tipo de lavado y tarifa',
                    'Recolección o lavandería',
                    'Día y bloque de horario',
                    'Revisión final',
                  ],
                  // Solo se puede regresar a pasos ya completados.
                  onPaso: _enviando ? null : (i) => setState(() => _paso = i),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey(_paso),
                    padding: const EdgeInsets.fromLTRB(40, 16, 40, 40),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: _contenidoPaso),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(width: 360, child: _resumenLateral()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Resumen que se va llenando con lo elegido, con los botones del flujo.
  Widget _resumenLateral() {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final sv = _servicio;

    Widget dato(String etiqueta, String? valor) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(etiqueta, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              valor ?? 'Sin elegir',
              style: t.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valor == null ? s.outline : s.onSurface,
              ),
            ),
          ),
        ],
      ),
    );

    return ColoredBox(
      color: s.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text('Resumen', style: t.titleMedium),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              children: [
                dato('Servicio', sv?.nombre),
                dato('Tarifa', sv == null ? null : '${moneda(sv.precioPorKg)} por kg'),
                dato('Entrega', _paso >= 1 ? textoEntregaCorto(_domicilio) : null),
                if (_domicilio && _paso >= 1) dato('Dirección', _direccion?.resumen),
                dato('Fecha', _fecha == null ? null : fechaLarga(_fecha!)),
                dato('Horario', _horario),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text('Precio final', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Text('Al pesar la ropa', style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sv == null
                      ? 'Se calcula con el peso registrado por el personal y la tarifa del servicio.'
                      : 'Peso registrado × ${moneda(sv.precioPorKg)} por kg.',
                  style: t.bodySmall?.copyWith(color: s.onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(onPressed: _puedeContinuar ? _continuar : null, child: _textoBotonPrincipal),
                if (_paso > 0) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _enviando ? null : () => setState(() => _paso--),
                    child: const Text('Atrás'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Móvil ----------
  Widget _formularioMovil() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Iconos.cerrar, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Nueva solicitud'),
      ),
      body: Column(
        children: [
          _Progreso(paso: _paso, titulos: _titulos),
          const Divider(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              layoutBuilder: (actual, anteriores) =>
                  Stack(alignment: Alignment.topCenter, children: [...anteriores, ?actual]),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: SingleChildScrollView(
                key: ValueKey(_paso),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: AnchoMaximo(ancho: 640, child: _contenidoPaso),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: AnchoMaximo(
              ancho: 640,
              child: Row(
                children: [
                  if (_paso > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _enviando ? null : () => setState(() => _paso--),
                        child: const Text('Atrás'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(onPressed: _puedeContinuar ? _continuar : null, child: _textoBotonPrincipal),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Paso 1: servicio ----------
  Widget _pasoServicio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Encabezado('Servicio', 'El precio se calcula con la tarifa por kilogramo.'),
        StreamBuilder<List<Servicio>>(
          stream: _servicios,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            return Column(
              children: [
                for (final sv in snap.data!)
                  _Opcion(
                    seleccionada: _servicio?.id == sv.id,
                    icono: Iconos.servicio,
                    titulo: sv.nombre,
                    subtitulo: sv.descripcion,
                    trailing: Text(
                      '${moneda(sv.precioPorKg)} / kg',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => setState(() => _servicio = sv),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        const Aviso(
          icono: Iconos.peso,
          texto: 'No necesitas saber cuánto pesa tu ropa. El personal la pesará en la báscula de la lavandería.',
        ),
      ],
    );
  }

  // ---------- Paso 2: entrega y dirección ----------
  Widget _pasoEntrega() {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Encabezado('Tipo de entrega', 'Indica si necesitas recolección a domicilio.'),
        _Opcion(
          seleccionada: _domicilio,
          icono: iconoEntrega(true),
          titulo: 'Recolección a domicilio',
          subtitulo: '$textoDomicilio: pasamos por tu ropa y te la llevamos lista.',
          onTap: () => setState(() => _domicilio = true),
        ),
        _Opcion(
          seleccionada: !_domicilio,
          icono: iconoEntrega(false),
          titulo: 'Entrega en la lavandería',
          subtitulo: '$textoLavanderia: tú llevas y recoges tu ropa.',
          onTap: () => setState(() => _domicilio = false),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: !_domicilio
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text('Dirección', style: t.titleMedium),
                    const SizedBox(height: 10),
                    StreamBuilder<List<Direccion>>(
                      stream: _direcciones,
                      builder: (context, snap) {
                        final lista = snap.data ?? const <Direccion>[];
                        // Con una sola dirección registrada, se elige automáticamente.
                        if (_direccion == null && lista.length == 1) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _direccion == null) setState(() => _direccion = lista.first);
                          });
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final d in lista)
                              _Opcion(
                                seleccionada: _direccion?.id == d.id,
                                icono: Iconos.direccion,
                                titulo: d.alias,
                                subtitulo: d.resumen,
                                onTap: () => setState(() => _direccion = d),
                              ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final nueva = await mostrarFormularioDireccion(context, widget.cliente.uid);
                                if (nueva != null) setState(() => _direccion = nueva);
                              },
                              icon: const Icon(Iconos.agregar, size: 18),
                              label: Text(lista.isEmpty ? 'Registrar dirección' : 'Agregar otra dirección'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ---------- Paso 3: fecha y horario ----------
  Widget _pasoFecha() {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    if (!_cuposCargados) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final horarios = _fecha == null ? const <String>[] : _horariosDe(_fecha!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Encabezado(
          'Fecha y horario',
          _domicilio ? 'Elige cuándo pasamos por tu ropa.' : 'Elige cuándo llevarás tu ropa a la lavandería.',
        ),
        Builder(
          builder: (context) {
            Widget tarjetaFecha(int i) {
              final f = _fechas[i];
              final sel = _fecha == f;
              final lleno = _diaLleno(f);
              final apagado = s.onSurface.withValues(alpha: 0.38);
              return InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radio),
                onTap: lleno
                    ? null
                    : () => setState(() {
                        _fecha = f;
                        if (_horario != null && (!_horariosDe(f).contains(_horario) || _libres(f, _horario!) <= 0)) {
                          _horario = null;
                        }
                      }),
                child: Container(
                  width: 64,
                  decoration: BoxDecoration(
                    color: sel ? s.primary : (lleno ? s.surfaceContainerLow : s.surface),
                    borderRadius: BorderRadius.circular(AppTheme.radio),
                    border: Border.all(color: sel ? s.primary : s.outlineVariant),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _etiquetaDia(f),
                        style: t.labelMedium?.copyWith(
                          color: sel ? s.onPrimary : (lleno ? apagado : s.onSurfaceVariant),
                        ),
                      ),
                      Text(
                        '${f.day}',
                        style: t.titleLarge?.copyWith(color: sel ? s.onPrimary : (lleno ? apagado : s.onSurface)),
                      ),
                      Text(
                        lleno ? 'Lleno' : mesCorto(f),
                        style: t.labelSmall?.copyWith(
                          color: sel ? s.onPrimary : (lleno ? apagado : s.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (MediaQuery.sizeOf(context).width >= _anchoEscritorio) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (var i = 0; i < _fechas.length; i++) SizedBox(height: 76, child: tarjetaFecha(i))],
              );
            }
            return SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fechas.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => tarjetaFecha(i),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Horario', style: t.titleMedium),
        const SizedBox(height: 10),
        if (_fecha == null)
          Text('Primero elige una fecha.', style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in horarios)
                Builder(
                  builder: (context) {
                    final libres = _libres(_fecha!, h);
                    final etiqueta = libres <= 0
                        ? '$h · Lleno'
                        : libres <= 2
                        ? '$h · ${libres == 1 ? 'Queda 1 lugar' : 'Quedan $libres lugares'}'
                        : h;
                    return ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(libres <= 0 ? Iconos.lleno : Iconos.horario, size: 16),
                      label: Text(etiqueta),
                      selected: _horario == h,
                      onSelected: libres <= 0 ? null : (_) => setState(() => _horario = h),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  // ---------- Paso 4: confirmar ----------
  Widget _pasoConfirmar() {
    final sv = _servicio!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Encabezado('Confirmación', 'Revisa que los datos de la solicitud sean correctos.'),
        Seccion(
          titulo: 'Resumen de la solicitud',
          child: Column(
            children: [
              FilaDato(etiqueta: 'Servicio', valor: sv.nombre),
              FilaDato(etiqueta: 'Tarifa', valor: '${moneda(sv.precioPorKg)} por kg'),
              FilaDato(etiqueta: 'Entrega', valor: textoEntrega(_domicilio)),
              if (_domicilio && _direccion != null)
                FilaDato(etiqueta: 'Dirección', valor: '${_direccion!.alias} · ${_direccion!.resumen}'),
              FilaDato(etiqueta: 'Fecha', valor: fechaLarga(_fecha!)),
              FilaDato(etiqueta: 'Horario', valor: _horario!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Aviso(
          icono: Iconos.calculo,
          texto:
              'El precio final se calculará cuando el personal pese tu ropa en la lavandería: '
              'peso × ${moneda(sv.precioPorKg)} por kg. Podrás consultarlo en tu pedido.',
        ),
      ],
    );
  }
}

class _Progreso extends StatelessWidget {
  const _Progreso({required this.paso, required this.titulos});

  final int paso;
  final List<String> titulos;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final angosto = MediaQuery.sizeOf(context).width < 480;

    Widget marcador(int i) {
      final hecho = i < paso;
      final actual = i == paso;
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hecho || actual ? s.primary : s.surface,
          border: Border.all(color: hecho || actual ? s.primary : s.outline),
        ),
        child: hecho
            ? Icon(Iconos.exito, size: 14, color: s.onPrimary)
            : Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: actual ? s.onPrimary : s.onSurfaceVariant,
                ),
              ),
      );
    }

    return Container(
      color: s.surface,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: AnchoMaximo(
        ancho: 640,
        child: Row(
          children: [
            for (var i = 0; i < titulos.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: i <= paso ? s.primary : s.outlineVariant,
                  ),
                ),
              marcador(i),
              // En pantallas angostas solo se muestra el nombre del paso actual.
              if (!angosto || i == paso) ...[
                const SizedBox(width: 6),
                Text(
                  titulos[i],
                  style: t.labelMedium?.copyWith(
                    color: i <= paso ? s.onSurface : s.onSurfaceVariant,
                    fontWeight: i == paso ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Lista vertical de pasos para web/escritorio.
class _PasosVerticales extends StatelessWidget {
  const _PasosVerticales({
    required this.paso,
    required this.titulos,
    required this.descripciones,
    required this.onPaso,
  });

  final int paso;
  final List<String> titulos;
  final List<String> descripciones;
  final void Function(int)? onPaso;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      width: 260,
      color: s.surface,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < titulos.length; i++)
            Builder(
              builder: (context) {
                final hecho = i < paso;
                final actual = i == paso;
                final radio = BorderRadius.circular(AppTheme.radio - 2);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: actual ? s.primary.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: radio,
                    child: InkWell(
                      borderRadius: radio,
                      onTap: hecho && onPaso != null ? () => onPaso!(i) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hecho || actual ? s.primary : s.surface,
                                border: Border.all(color: hecho || actual ? s.primary : s.outline),
                              ),
                              child: hecho
                                  ? Icon(Iconos.exito, size: 14, color: s.onPrimary)
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: actual ? s.onPrimary : s.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titulos[i],
                                    style: t.bodyMedium?.copyWith(
                                      fontWeight: actual ? FontWeight.w700 : FontWeight.w500,
                                      color: actual ? s.primary : (hecho ? s.onSurface : s.onSurfaceVariant),
                                    ),
                                  ),
                                  Text(descripciones[i], style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado(this.titulo, this.subtitulo);

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: t.titleLarge),
          const SizedBox(height: 4),
          Text(subtitulo, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Tarjeta seleccionable.
class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.seleccionada,
    required this.icono,
    required this.titulo,
    required this.onTap,
    this.subtitulo = '',
    this.trailing,
  });

  final bool seleccionada;
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: seleccionada ? s.primary.withValues(alpha: 0.05) : s.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radio),
          side: BorderSide(color: seleccionada ? s.primary : s.outlineVariant, width: seleccionada ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  seleccionada ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 20,
                  color: seleccionada ? s.primary : s.outline,
                ),
                const SizedBox(width: 12),
                Icon(icono, size: 18, color: s.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (subtitulo.isNotEmpty)
                        Text(subtitulo, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmación después de crear el pedido.
class _PedidoCreado extends StatelessWidget {
  const _PedidoCreado({required this.numero, required this.onEntendido});

  final int numero;
  final VoidCallback onEntendido;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Iconos.exito, size: 40, color: s.primary),
                    const SizedBox(height: 16),
                    Text('Solicitud registrada', style: t.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(
                      'Folio ${folio(numero)}',
                      style: t.titleMedium?.copyWith(color: s.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'El peso y el precio se mostrarán en el pedido cuando el personal reciba tu ropa.',
                      style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(onPressed: onEntendido, child: const Text('Ver mis pedidos')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
