// web/firebase-messaging-sw.js
// Firebase Cloud Messaging (FCM) & W3C Web Push Background Service Worker
// Belong on the Spectrum — Calm-Tech Notification Handler

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Firebase configuration for background message processing
const firebaseConfig = {
  apiKey: "AIzaSyDummyKeyForBackgroundWorkerRefuge4Serverpod",
  projectId: "belong-on-the-spectrum",
  messagingSenderId: "1056581413812",
  appId: "1:1056581413812:web:calmnotificationsbelong"
};

try {
  firebase.initializeApp(firebaseConfig);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    console.log('[Belong PWA] Background push notification received:', payload);

    const notificationTitle = payload.notification?.title || payload.data?.title || 'Belong Community Digest';
    const notificationOptions = {
      body: payload.notification?.body || payload.data?.body || 'New calm reflections are waiting in your spaces.',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-maskable-192.png',
      tag: payload.data?.tag || 'belong-calm-digest',
      renotify: false, // Calm-tech: never chime multiple times for batched digests
      silent: true,   // Sensory-friendly: default silent
      data: {
        click_action: payload.data?.click_action || '/',
        spaceSlug: payload.data?.spaceSlug || 'welcome',
      }
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  });
} catch (e) {
  console.log('[Belong PWA] Firebase messaging compat fallback:', e);
}

// Standard W3C Web Push event listener fallback
self.addEventListener('push', (event) => {
  if (event.data) {
    try {
      const data = event.data.json();
      const title = data.title || 'Belong on the Spectrum';
      const options = {
        body: data.body || 'A new calm update is available.',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-maskable-192.png',
        tag: data.tag || 'belong-update',
        silent: true,
        data: data.data || {}
      };
      event.waitUntil(self.registration.showNotification(title, options));
    } catch (_) {
      const title = 'Belong on the Spectrum';
      const options = {
        body: event.data.text() || 'New calm community update.',
        icon: '/icons/Icon-192.png',
        silent: true
      };
      event.waitUntil(self.registration.showNotification(title, options));
    }
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const urlToOpen = event.notification.data?.click_action || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if (client.url.includes(urlToOpen) && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
