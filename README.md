# LavaExpress

Aplicación web progresiva (PWA) para una lavandería con recolección y entrega a domicilio. Los clientes solicitan servicios y siguen el estado de su pedido; el personal de la lavandería registra el peso y avanza cada pedido.

- **App publicada:** https://lavaexpress-a35d3.web.app
- **Vista generada en el servidor (seguimiento):** https://lavaexpress-seguimiento.vercel.app/seguimiento/&lt;id-del-pedido&gt;

## Tecnologías

| Parte | Herramienta |
|---|---|
| Cliente (PWA) | Flutter 3.47 / Dart (compilado a web) |
| Autenticación | Firebase Authentication (correo y contraseña) |
| Datos remotos | Cloud Firestore |
| Publicación de la app | Firebase Hosting |
| Vista del servidor | Función de Vercel en Node.js 22 + Firebase Admin SDK (`servidor/`) |
| Offline | Service worker propio (`web/sw.js`) y caché de Firestore |
| Datos locales | `shared_preferences` (tema y avisos) |
| Dispositivo | GPS (`geolocator` + Nominatim) y vibración |

## Requisitos PWA cubiertos

| Requisito | Dónde |
|---|---|
| Pantallas de Splash y Home | `web/index.html` (splash), `lib/screens/auth_gate.dart`, `lib/screens/cliente/inicio_cliente.dart` |
| Vista generada en el cliente | Pantallas de Flutter en `lib/screens/` |
| Vista generada en el servidor | `servidor/api/seguimiento.js` y `servidor/lib/pagina.js` |
| Datos locales | `lib/services/preferencias.dart` |
| Datos remotos | `lib/services/firestore_service.dart` |
| Datos offline | `web/sw.js`, `web/flutter_bootstrap.js`, `lib/widgets/aviso_conexion.dart` |
| Notificaciones | `lib/services/avisos_pedidos.dart`, `lib/services/dispositivo_web.dart` |
| Elementos físicos del dispositivo | `lib/services/ubicacion.dart`, `lib/widgets/direccion_sheet.dart` (GPS) y vibración en `lib/services/dispositivo*.dart` |

## Ejecutar y probar

```powershell
flutter pub get
flutter run -d chrome          # desarrollo
flutter test                   # pruebas de la app
cd servidor; npm install; npm test   # pruebas de la vista del servidor
```

## Publicar

```powershell
pwsh -NoProfile -File ./construir_web.ps1   # compila build/web con el service worker propio
firebase deploy --only hosting              # app en Firebase Hosting
cd servidor; npx vercel deploy --prod       # vista del servidor en Vercel
```

La función de Vercel necesita la variable de entorno secreta `FIREBASE_SERVICE_ACCOUNT` con el JSON de la cuenta de servicio de Firebase. Las claves no se guardan en el repositorio.
