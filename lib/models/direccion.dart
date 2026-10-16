/// Dirección del cliente para la recolección y entrega a domicilio.
class Direccion {
  const Direccion({
    this.id = '',
    required this.alias,
    required this.calle,
    required this.colonia,
    this.referencias = '',
    this.latitud,
    this.longitud,
  });

  final String id;
  final String alias;
  final String calle;
  final String colonia;
  final String referencias;

  /// Coordenadas tomadas con el GPS del dispositivo (opcionales).
  final double? latitud;
  final double? longitud;

  bool get tieneUbicacion => latitud != null && longitud != null;

  /// Enlace para abrir la ubicación en un mapa.
  Uri? get enlaceMapa => tieneUbicacion
      ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitud,$longitud')
      : null;

  String get resumen => '$calle, $colonia';

  Map<String, dynamic> aMapa() => {
        'alias': alias,
        'calle': calle,
        'colonia': colonia,
        'referencias': referencias,
        if (tieneUbicacion) 'latitud': latitud,
        if (tieneUbicacion) 'longitud': longitud,
      };

  factory Direccion.desdeMapa(Map<String, dynamic> d, {String id = ''}) => Direccion(
        id: id,
        alias: d['alias'] as String? ?? '',
        calle: d['calle'] as String? ?? '',
        colonia: d['colonia'] as String? ?? '',
        referencias: d['referencias'] as String? ?? '',
        latitud: (d['latitud'] as num?)?.toDouble(),
        longitud: (d['longitud'] as num?)?.toDouble(),
      );

  Direccion conId(String nuevoId) => Direccion(
        id: nuevoId,
        alias: alias,
        calle: calle,
        colonia: colonia,
        referencias: referencias,
        latitud: latitud,
        longitud: longitud,
      );
}
