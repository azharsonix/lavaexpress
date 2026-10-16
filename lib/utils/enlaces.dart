import 'package:url_launcher/url_launcher.dart';

/// Dirección pública de la app en Firebase Hosting.
const urlApp = 'https://lavaexpress-a35d3.web.app';

/// Página de seguimiento generada en el servidor (Cloud Function `seguimiento`).
/// Se identifica con el id del documento, que no se puede adivinar.
Uri urlSeguimiento(String pedidoId) => Uri.parse('$urlApp/seguimiento/$pedidoId');

Future<void> abrirEnlace(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);
