// ============================================================
// Service Worker — Quiniela Mundial 2026
// BUILD: 2026-07-20
// ============================================================

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', event => {
  event.waitUntil(
    self.clients.claim().then(() =>
      self.clients.matchAll({ type: 'window' }).then(clients =>
        Promise.all(clients.map(c => c.navigate(c.url)))
      )
    )
  );
});

// Navegaciones siempre desde red (sin caché) para evitar HTML desactualizado
self.addEventListener('fetch', event => {
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request, { cache: 'no-store' })
        .catch(() => new Response('', { status: 503 }))
    );
  } else {
    event.respondWith(
      fetch(event.request).catch(() => new Response('', { status: 503 }))
    );
  }
});

// Recibir señal de la página para activar inmediatamente
self.addEventListener('message', event => {
  if (event.data?.type === 'SKIP_WAITING') self.skipWaiting();
});