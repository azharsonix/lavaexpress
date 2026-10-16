import 'package:flutter_test/flutter_test.dart';
import 'package:lavaexpress/models/direccion.dart';

void main() {
  const sinUbicacion = Direccion(alias: 'Casa', calle: 'Juárez 10', colonia: 'Centro');
  const conUbicacion = Direccion(alias: 'Casa', calle: 'Juárez 10', colonia: 'Centro', latitud: 19.5, longitud: -99.25);

  test('Sin coordenadas no tiene ubicación ni enlace al mapa', () {
    expect(sinUbicacion.tieneUbicacion, isFalse);
    expect(sinUbicacion.enlaceMapa, isNull);
    expect(const Direccion(alias: '', calle: '', colonia: '', latitud: 1).tieneUbicacion, isFalse);
  });

  test('Con coordenadas genera el enlace a Google Maps', () {
    expect(conUbicacion.tieneUbicacion, isTrue);
    expect(conUbicacion.enlaceMapa.toString(), 'https://www.google.com/maps/search/?api=1&query=19.5,-99.25');
  });

  test('aMapa solo incluye las coordenadas cuando existen', () {
    expect(sinUbicacion.aMapa().containsKey('latitud'), isFalse);
    expect(sinUbicacion.aMapa().containsKey('longitud'), isFalse);
    expect(conUbicacion.aMapa(), containsPair('latitud', 19.5));
    expect(conUbicacion.aMapa(), containsPair('longitud', -99.25));
  });

  test('desdeMapa convierte enteros a double y tolera datos faltantes', () {
    final d = Direccion.desdeMapa(
      {'alias': 'Trabajo', 'calle': 'Hidalgo 5', 'colonia': 'Norte', 'latitud': 19, 'longitud': -99},
      id: 'x',
    );
    expect(d.id, 'x');
    expect(d.latitud, 19.0);
    expect(d.longitud, isA<double>());
    expect(d.resumen, 'Hidalgo 5, Norte');
    final vacia = Direccion.desdeMapa({});
    expect(vacia.alias, '');
    expect(vacia.tieneUbicacion, isFalse);
  });

  test('Ida y vuelta por aMapa/desdeMapa conserva los datos', () {
    expect(Direccion.desdeMapa(conUbicacion.aMapa()).aMapa(), conUbicacion.aMapa());
  });

  test('conId conserva las coordenadas', () {
    final d = conUbicacion.conId('nuevo');
    expect(d.id, 'nuevo');
    expect(d.latitud, 19.5);
    expect(d.longitud, -99.25);
    expect(d.alias, 'Casa');
  });
}
