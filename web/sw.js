// Service worker propio de LavaExpress: permite abrir la app sin conexión.
// Al publicar cambios grandes en esta lógica, sube VERSION para limpiar cachés viejas.
const VERSION = 'v1';
const CACHE = `lavaexpress-${VERSION}`;
const CACHE_CDN = `lavaexpress-cdn-${VERSION}`;

// Esqueleto mínimo de la app que se guarda al instalar.
const BASICOS = [
  '.',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
];

// Archivos que cambian en cada compilación: primero red, caché si no hay conexión.
const PRIMERO_RED = /\/(index\.html|flutter_bootstrap\.js|main\.dart\.js)$/;

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE)
      .then((c) => c.addAll(BASICOS.map((u) => new Request(u, { cache: 'reload' }))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((claves) => Promise.all(claves
        .filter((k) => k !== CACHE && k !== CACHE_CDN)
        .map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // CDN de Google (CanvasKit y SDK de Firebase): URLs con versión, no cambian.
  if (url.origin === 'https://www.gstatic.com' &&
      (url.pathname.startsWith('/flutter-canvaskit/') || url.pathname.startsWith('/firebasejs/'))) {
    e.respondWith(primeroCache(req, CACHE_CDN));
    return;
  }

  // Todo lo demás de otros orígenes (Firestore, Auth, googleapis, nominatim...) va directo a la red.
  if (url.origin !== self.location.origin) return;
  // Páginas de seguimiento generadas por la función: siempre frescas.
  if (url.pathname.startsWith('/seguimiento/')) return;

  if (req.mode === 'navigate') {
    e.respondWith(primeroRed(req, '.'));
    return;
  }
  if (PRIMERO_RED.test(url.pathname)) {
    e.respondWith(primeroRed(req));
    return;
  }
  e.respondWith(revalidando(e));
});

function guardable(res) {
  return res && (res.ok || res.type === 'opaque');
}

async function primeroRed(req, respaldo) {
  const cache = await caches.open(CACHE);
  try {
    const res = await fetch(req);
    if (res.ok) {
      // Las navegaciones se guardan como '.' para servir la app en cualquier ruta.
      cache.put(respaldo || req, res.clone());
    }
    return res;
  } catch (err) {
    const guardada = await cache.match(respaldo || req, { ignoreSearch: true });
    if (guardada) return guardada;
    throw err;
  }
}

async function revalidando(e) {
  const req = e.request;
  const cache = await caches.open(CACHE);
  const guardada = await cache.match(req);
  const red = fetch(req)
    .then((res) => {
      if (res.ok) cache.put(req, res.clone());
      return res;
    })
    .catch(() => undefined);
  e.waitUntil(red);
  if (guardada) return guardada;
  const res = await red;
  return res || Response.error();
}

async function primeroCache(req, nombre) {
  const cache = await caches.open(nombre);
  const guardada = await cache.match(req);
  if (guardada) return guardada;
  const res = await fetch(req);
  if (guardable(res)) cache.put(req, res.clone());
  return res;
}

// Toque en una notificación mostrada con registration.showNotification():
// enfoca una pestaña abierta de la app o abre una nueva.
self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  const destino = new URL((e.notification.data && e.notification.data.url) || '.', self.registration.scope).href;
  e.waitUntil((async () => {
    const pestanas = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const p of pestanas) {
      if (p.url.startsWith(self.registration.scope) && 'focus' in p) return p.focus();
    }
    if (self.clients.openWindow) return self.clients.openWindow(destino);
  })());
});
