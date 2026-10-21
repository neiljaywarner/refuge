// web/firebase-messaging-sw.js
// Firebase Cloud Messaging (FCM) & W3C Web Push Background Service Worker
// Belong on the Spectrum — Adaptive Notification Delivery (Real-Time vs. Calm Digest)
// Issue #243: Decoupled hardcoded silent digests to support member delivery preferences.

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Production Firebase configuration for background message processing
const firebaseConfig = {
  apiKey: "AIzaSyBtW8uQckI88rT1TPng459EVC9ynnm2twU",
  authDomain: "belongonthespectrum.firebaseapp.com",
  projectId: "belongonthespectrum",
  storageBucket: "belongonthespectrum.firebasestorage.app",
  messagingSenderId: "207506875171",
  appId: "1:207506875171:web:5a5917af04e2540ab96296"
};

try {
  firebase.initializeApp(firebaseConfig);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    console.log('[Belong PWA] Background push notification received:', payload);

    const isHighUrgency = payload.data?.urgency === 'high' || payload.data?.type === 'direct_message' || payload.data?.type === 'prayer_urgent';
    const notificationTitle = payload.notification?.title || payload.data?.title || (isHighUrgency ? 'Belong Message' : 'Belong Community Digest');

    const notificationOptions = {
      body: payload.notification?.body || payload.data?.body || 'New calm reflections are waiting in your spaces.',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-maskable-192.png',
      // Real-time notifications use unique tags so each message is visible.
      // Calm digests use shared tag for deduplication without notification spam.
      tag: isHighUrgency ? (payload.data?.messageId || `belong-alert-${Date.now()}`) : (payload.data?.tag || 'belong-calm-digest'),
      renotify: isHighUrgency,
      silent: !isHighUrgency, // Audible/haptic for high urgency; silent for digests
      data: {
        click_action: payload.data?.click_action || '/',
        spaceSlug: payload.data?.spaceSlug || 'welcome',
        urgency: payload.data?.urgency || 'normal',
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
      const isUrgent = data.urgency === 'high' || data.type === 'direct_message';
      const title = data.title || (isUrgent ? 'Belong Alert' : 'Belong on the Spectrum');
      const options = {
        body: data.body || 'A new calm update is available.',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-maskable-192.png',
        tag: isUrgent ? (data.id || `push-${Date.now()}`) : (data.tag || 'belong-update'),
        silent: !isUrgent,
        renotify: isUrgent,
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