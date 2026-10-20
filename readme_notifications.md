# 🔔 Neurodivergent-First Calm Notifications Architecture (`readme_notifications.md`)

> **Architectural Evaluation & ADR-0010 Companion**  
> **Applies to**: Belong on the Spectrum (`refuge4serverpod`)  
> **Live Web**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)  
> **Wiki Documentation**: [`docs/wiki/ADR-0010-Notifications-Local-Awesome-vs-FCM.md`](docs/wiki/ADR-0010-Notifications-Local-Awesome-vs-FCM.md)

---

## 🧘 1. The Neurodivergent Challenge: Why "Normal" Push Fails

Traditional mobile push notifications are engineered for engagement maximization:
* **Urgent red dot badges** triggering anxiety and urgency.
* **Loud default notification chimes** causing auditory startle responses.
* **Instant interruptions** fragmenting focus, deep work, or regulation periods.

For neurodivergent adults (particularly autistic individuals and ADHDers), aggressive push notifications lead directly to **app muting or complete uninstallation**. 

**Our Calm Tech Commitment**:
1. **Never use bright urgent red dots** for unread counts (use soft forest green `#2E6B56` or neutral badges).
2. **Never play default auditory chimes** without explicit opt-in.
3. **Default to "Calm Batched Digest"**: Messages and space updates are held gently and delivered as an unhurried single digest at the user's preferred quiet hours (e.g., 10:00 AM and 6:00 PM).

---

## ⚖️ 2. Architectural Comparison: Local Notifications vs. Regular FCM

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        CALM HYBRID NOTIFICATION ARCHITECTURE                          │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                        │
│   [Cloud Backend]                                                                     │
│   (Appwrite Realtime / Firestore / Serverpod)                                         │
│          │                                                                             │
│          ▼ Silent Background Push (Data-Only Payload)                                 │
│   [Firebase Cloud Messaging (FCM)]                                                     │
│          │                                                                             │
│          ▼ Wakes up device in background without displaying an alert                   │
│   [Client Notification Gate]                                                           │
│          │                                                                             │
│          ├─► If Member is in "Calm Digest" mode ──▶ Queue in local DB                  │
│          │                                          Display batched digest at 10 AM/6 PM│
│          │                                          via `awesome_notifications`        │
│          │                                                                             │
│          └─► If Urgent Organizer Alert ───────────▶ Deliver gentle silent card         │
│                                                     with soft vibration only           │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Detailed Trade-Off Matrix

| Dimension | Option A: Pure Local (`awesome_notifications`) | Option B: Pure Cloud Push (Standard FCM) | Option C: The Calm Hybrid (**A+ `9.7/10`**) |
| :--- | :--- | :--- | :--- |
| **Transport** | Client listens to DB snapshots / Appwrite Realtime WebSocket | FCM server sends display notification directly | Silent FCM data payload wakes app; local engine displays notification |
| **Delivery when App is Killed** | ❌ Fails on Android 13+ battery doze without foreground service | ✅ Succeeds (OS handles push wake-up) | ✅ Succeeds (FCM wakes background isolate, local engine handles display) |
| **Calm Batching Control** | ✅ 100% controlled on device (zero server cron needed) | ❌ Requires server-side batching database & cron jobs | ✅ Device buffers incoming payloads and fires digest at exact local quiet window |
| **Sensory Customization** | ✅ Rich calm cards, custom soft icons, no jarring sounds | ⚠️ Limited by standard OS notification templates | ✅ Full `awesome_notifications` layout & action buttons |
| **Offline Resilience** | ✅ Works completely offline for scheduled event reminders | ❌ Requires internet connection for all alerts | ✅ Scheduled local reminders work offline; cloud updates sync when online |
| **Backend Cost & Lock-in** | ✅ $0 (works with Appwrite, Serverpod, or Firestore) | ⚠️ Requires FCM / Apple APNs configuration | ✅ FCM free tier ($0) for transport; backend-agnostic payload |

---

## 🏆 3. Decision: The Calm Hybrid (`Grade: A+ / 9.7`)

1. **Stage 1 (Shipped in `v0.8.0-alpha`)**:
   - In-app **Calm Notification Bell view** ([`CalmNotificationsView`](lib/src/features/messages/presentation/calm_notifications_view.dart)).
   - In-app **Calm Batched Digest toggle** on Direct Messages ([`BelongMessagesView`](lib/src/features/messages/presentation/belong_messages_view.dart)).
   - Zero intrusive push alerts until user explicitly opts into notifications.
2. **Stage 2 (`v0.8.5` – `v0.9.0-beta`)**:
   - Integrate `awesome_notifications` (or `flutter_local_notifications`) for local scheduled event reminders (e.g. 15 minutes before an *Actually Autistic* online gathering).
   - Wire silent data-only FCM push payloads so messages wake the device without making a sound.
   - The local engine buffers notifications and presents the gentle daily digest card.

---

## 📱 4. Sensory Event Notification Flow (Example)

```dart
// Scheduled Calm Reminder for Actually Autistic Events
await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: event.id.hashCode,
    channelKey: 'calm_events_channel',
    title: 'Upcoming: ${event.title}',
    body: 'Starts in 15 mins · Lighting: ${event.lightingLevel} · Quiet room available',
    notificationLayout: NotificationLayout.Default,
    backgroundColor: const Color(0xFFF3F7F5),
    color: const Color(0xFF2E6B56),
  ),
  schedule: NotificationCalendar.fromDate(
    date: event.startDateTime.subtract(const Duration(minutes: 15)),
    preciseAlarm: true,
  ),
);
```

---

## 📚 5. Documentation & Wiki Links
- [**GitHub Wiki: ADR-0010 Notifications**](https://github.com/neiljaywarner/refuge/wiki/ADR-0010-Notifications-Local-Awesome-vs-FCM)
- [**Wiki: Calm Tech and Accessibility**](https://github.com/neiljaywarner/refuge/wiki/Calm-Tech-and-Accessibility)
- [**Wiki: UX Evaluation and ADRs**](https://github.com/neiljaywarner/refuge/wiki/UX-Evaluation-and-ADRs)
