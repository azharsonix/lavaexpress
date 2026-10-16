/// Horarios de atención para recolección o recepción de ropa.
/// Se pueden ajustar aquí según el horario real de la lavandería.
/// IMPORTANTE: si se cambian, actualizar también horarioValido() en firestore.rules
/// y desplegar las reglas (firebase deploy --only firestore:rules).
const horariosLavanderia = [
  '09:00 - 11:00',
  '11:00 - 13:00',
  '13:00 - 15:00',
  '15:00 - 17:00',
  '17:00 - 19:00',
];

/// Días que el cliente puede elegir (a partir de hoy).
const diasDisponibles = 14;

DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);

/// Horarios disponibles para un día: si es hoy, solo los que aún no inician.
List<String> horariosDisponibles(DateTime dia, {DateTime? ahora}) {
  final hoy = ahora ?? DateTime.now();
  if (_soloFecha(dia) != _soloFecha(hoy)) return horariosLavanderia;
  return horariosLavanderia.where((h) => int.parse(h.substring(0, 2)) > hoy.hour).toList();
}

List<DateTime> fechasDisponibles({DateTime? ahora}) {
  final hoy = _soloFecha(ahora ?? DateTime.now());
  return [
    for (var i = 0; i < diasDisponibles; i++) hoy.add(Duration(days: i)),
  ].where((d) => horariosDisponibles(d, ahora: ahora).isNotEmpty).toList();
}

/// Cupo usado si todavía no existe configuracion/general en Firestore.
const cupoPorHorarioPredeterminado = 5;

String _dosDigitos(int n) => n.toString().padLeft(2, '0');

/// Día en formato "2026-10-03" (se guarda en el pedido y en el cupo).
String claveDia(DateTime f) => '${f.year}-${_dosDigitos(f.month)}-${_dosDigitos(f.day)}';

/// Id del documento de cupo: "2026-10-03_09:00 - 11:00".
/// Debe coincidir con la regla de pedidos en firestore.rules.
String idCupo(String dia, String horario) => '${dia}_$horario';
