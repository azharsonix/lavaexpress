{{flutter_js}}
{{flutter_build_config}}

// Se carga Flutter sin serviceWorkerSettings: el service worker de Flutter 3.47
// solo se desregistra a sí mismo. El modo sin conexión lo da sw.js (ver index.html).
_flutter.loader.load();
