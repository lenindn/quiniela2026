// ============================================================
// Service Worker — Quiniela Mundial 2026
// BUILD: 2026-05-30
// ============================================================

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});

// No cacheamos — solo usamos el SW para detectar actualizaciones
self.addEventListener('fetch', event => {
  event.respondWith(
    fetch(event.request).catch(() => new Response('', { status: 503 }))
  );
});

// Recibir señal de la página para activar inmediatamente
self.addEventListener('message', event => {
  if (event.data?.type === 'SKIP_WAITING') self.skipWaiting();
});