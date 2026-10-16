import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Resultado de leer el GPS: coordenadas y, si se pudo, la dirección aproximada.
class UbicacionActual {
  const UbicacionActual({required this.latitud, required this.longitud, this.calle = '', this.colonia = ''});

  final double latitud;
  final double longitud;
  final String calle;
  final String colonia;
}

/// Lee la ubicación con el GPS del dispositivo (elemento físico) y la
/// convierte en calle y colonia con el servicio gratuito Nominatim de
/// OpenStreetMap.
class Ubicacion {
  Ubicacion._();

  /// Lanza [UbicacionError] con un mensaje listo para mostrar.
  static Future<UbicacionActual> leer() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const UbicacionError('Activa la ubicación del dispositivo.');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      throw const UbicacionError('Sin permiso para usar tu ubicación.');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
    );

    try {
      final r = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'format': 'jsonv2',
              'lat': '${pos.latitude}',
              'lon': '${pos.longitude}',
              'accept-language': 'es',
              'zoom': '18',
            }),
          )
          .timeout(const Duration(seconds: 8));
      final d = (jsonDecode(r.body) as Map<String, dynamic>)['address'] as Map<String, dynamic>? ?? const {};
      final calle = [d['road'], d['house_number']].whereType<String>().join(' ');
      final colonia = (d['neighbourhood'] ?? d['suburb'] ?? d['quarter'] ?? d['city_district'] ?? '') as String;
      return UbicacionActual(latitud: pos.latitude, longitud: pos.longitude, calle: calle, colonia: colonia);
    } catch (_) {
      // Sin internet o el servicio no respondió: se guardan solo las coordenadas.
      return UbicacionActual(latitud: pos.latitude, longitud: pos.longitude);
    }
  }
}

class UbicacionError implements Exception {
  const UbicacionError(this.mensaje);
  final String mensaje;
}
