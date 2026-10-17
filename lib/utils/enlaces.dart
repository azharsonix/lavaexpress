import 'package:url_launcher/url_launcher.dart';

/// Dirección pública de la app en Firebase Hosting.
const urlApp = 'https://lavaexpress-a35d3.web.app';

/// Página de seguimiento generada en el servidor (función de Vercel en `servidor/`).
/// Se identifica con el id del documento, que no se puede adivinar.
const urlServidor = 'https://lavaexpress-seguimiento.vercel.app';

Uri urlSeguimiento(String pedidoId) => Uri.parse('$urlServidor/seguimiento/$pedidoId');

Future<void> abrirEnlace(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);
