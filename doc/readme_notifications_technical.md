# 🔔 Calm Notifications — Technical Architecture & Implementation Guide (`readme_notifications_technical.md`)

> **Belong on the Spectrum** (powered by Refuge)  
> **Repository Target**: `lib/src/features/notifications/` & `lib/src/features/messages/presentation/`  
> **Related Issues & ADRs**: Issue #327 (Epic), #328 (E2E Tests), #329 (Docs & Bugfix), #330 (Deep Linking), #331 (Badge Channel), ADR-0010 (Local vs FCM)

---

## 1. Architectural Overview

The Calm Notifications system delivers unhurried, digestible, and sensory-safe notifications to neurodivergent adults across Mobile PWA, Android APK, and iOS. It deliberately avoids traditional attention-hijacking mechanics (such as aggressive red badges, audible chimes, and urgent banner popups) in favor of **Calm Technology** principles.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           BELONG NOTIFICATIONS ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   [Bottom Nav Bar] ─────────► unreadNotificationsCountProvider                          │
│   (BelongBottomTab.notifications)         ▲                                             │
│                                           │ (count > 0 shows soft pill badge)           │
│                                           │                                             │
│   [Notifications Controller] ─────────────┴──────────► BelongNotificationsNotifier      │
│   (StateNotifierProvider)                               (State: List<BelongNotification>)│
│           ▲                                                      │                      │
│           ├─► markAsRead(id)                                     ▼                      │
│           ├─► markAllAsRead() ────────────────────────► AppLauncherBadgeService         │
│           └─► setFilter(BelongNotificationFilter)         (MethodChannel: badge count)   │
│                                                                  │                      │
│   [NotificationPermissionsService] ──────────────────────────────┼──────────────────────┤
│   (CalmNotificationPreferences: FCM Token, Schedule)             ▼                      │
│           ▲                                            [CalmNotificationsView]          │
│           ├─► setSchedule(CalmDigestSchedule)           - Filter Chips (Inbox, Mentions)│
│           └─► requestPushPermission()                   - Action Badges on Avatars      │
│                                                         - "Mark all read" Checkbox      │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Directory & Component Structure

```
lib/src/features/
├── notifications/
│   ├── data/
│   │   ├── app_launcher_badge_service.dart          # Native MethodChannel badge synchronization
│   │   └── notification_permissions_service.dart    # FCM permission & calm schedule management
│   ├── domain/
│   │   ├── belong_notification.dart                 # BelongNotification, Types, Filters, Initials & Time formatting
│   │   └── calm_notification_preferences.dart       # CalmDigestSchedule, sensory preferences model
│   └── presentation/
│       ├── calm_notification_preferences_sheet.dart # Modal sheet for scheduling quiet digest hours
│       └── notifications_controller.dart            # Riverpod state notifiers, unread counts & filters
└── messages/
    └── presentation/
        └── calm_notifications_view.dart             # Full notification screen with chips, list tiles & badges
```

---

## 3. Core Domain Models

### 3.1 `BelongNotification`
The central immutable notification entity (`equatable`):
- `id`: Unique identifier (String).
- `authorName`: Full display name of the member generating the activity.
- `authorAvatarUrl`: Optional URL to profile avatar.
- `authorInitials`: Clean 1-2 character initials fallback. **Bug fix (#329)**: Strips bracketed and parenthetical qualifiers (e.g. `"Pastor Thomas (Melbourne)"` correctly generates `"PT"` rather than `"P("`, and `"Dr. Grace Hopper [Admin]"` yields `"DH"`).
- `type`: Interaction classification:
  - `BelongNotificationType.mention` (`@` icon, green `#4CAF50`)
  - `BelongNotificationType.reply` (`reply` icon, blue `#2196F3`)
  - `BelongNotificationType.like` (`heart` icon, pink `#E91E63`)
  - `BelongNotificationType.following` (`person_add` icon, purple `#9C27B0`)
- `postTitle`: Target reflection title or topic.
- `commentSnippet`: Optional text snippet of the reply or mention.
- `timestamp`: Creation timestamp.
- `isRead`: Boolean read status.

### 3.2 Display Formatting Functions
- `displayMessage`: Deterministic message composition matching community specifications:
  - Mention: `"$authorName mentioned you in a comment on \"$postTitle\""`
  - Reply: `"$authorName replied to your comment on \"$postTitle\""`
  - Like: `"$authorName liked your reflection on \"$postTitle\""`
  - Following: `"$authorName posted a new reflection in \"$postTitle\""`
- `formattedTimeAgo([DateTime? clockNow])`:
  - `< 60s` or negative: `"Just now"`
  - `< 60m`: `"$m min ago"` / `"$m mins ago"`
  - `< 24h`: `"$h hr ago"` / `"$h hrs ago"`
  - `< 7d`: `"$d day ago"` / `"$d days ago"`
  - `>= 7d`: Calendar month & ordinal day (e.g. `"Sep 7th"`)

### 3.3 `CalmNotificationPreferences` & `CalmDigestSchedule`
- `CalmDigestSchedule.twiceDaily` (10:00 AM & 6:00 PM batch)
- `CalmDigestSchedule.dailyEvening` (7:00 PM quiet summary)
- `CalmDigestSchedule.weeklyQuietSummary` (Sunday morning fellowship digest)
- `CalmDigestSchedule.muted` (Completely disabled push alerts)

---

## 4. State Management (Riverpod)

The notifications architecture uses hook-compatible Riverpod providers:
1. `belongNotificationsProvider`: `StateNotifierProvider<BelongNotificationsNotifier, List<BelongNotification>>` maintaining the in-app notification list. It also calls `AppLauncherBadgeService`, which has no native handler ([#411](https://github.com/neiljaywarner/refuge/issues/411)).
2. `unreadNotificationsCountProvider`: Derived `Provider<int>` counting notifications where `!isRead`.
3. `notificationActiveFilterProvider`: `StateProvider<BelongNotificationFilter>` controlling active filtering tab (`inbox`, `mentions`, `threads`, `following`).
4. `filteredNotificationsProvider`: Derived `Provider<List<BelongNotification>>` calculating the active subset for rendering.
5. `notificationPermissionsServiceProvider`: `StateNotifierProvider<NotificationPermissionsService, CalmNotificationPreferences>` managing FCM tokens and digest scheduling.
6. `appLauncherBadgeServiceProvider`: `Provider<AppLauncherBadgeService>` abstracting MethodChannel badge calls.

---

## 5. Native Platform Synchronization

### 5.1 App Launcher Badges (`AppLauncherBadgeService`)
- **MethodChannel**: `com.belongonthespectrum.sanctuary/badge`
- **Method**: `setBadgeCount({'count': int})`
- **Android**: `MainActivity` syncs Pixel launcher dots via a silent `calm_launcher_badge_sync` notification (`IMPORTANCE_MIN`, `setNumber`); cancelled when count is 0.
- **Verify**: unread bottom-nav badge → launcher dot; **Mark all as read** → dot clears.
- **FCM**: permission requests set `badge: false` for push payloads; launcher dot uses the badge channel above, not FCM badge flags.

### 5.2 FCM & Mobile Web Push (`NotificationPermissionsService`)
- Mobile Safari on iOS cannot grant Web Push in standard browser tabs. The service detects `isIosWebWithoutPwa` and guides users to Add to Home Screen first.
- Default permission request parameters:
  ```dart
  await messaging.requestPermission(
    alert: true,
    badge: false,       // Calm: zero anxiety red dots
    sound: false,       // Calm: zero loud acoustic chimes
    criticalAlert: false,
    announcement: false,
  );
  ```

---

## 6. Accessibility & Sensory Modes

1. **High Contrast Mode (`SensoryMode.contrast`)**:
   - Background changes to pure obsidian `#000000`.
   - Active accent changes to vibrant yellow `#FFFF00`.
   - Text color turns `#000000` inside yellow chips and `#FFFFFF` on dark cards.
   - Distinct 1px borders separate list cards and filter chips.
2. **Reduced Motion**:
   - SalomonBottomBar transition duration switches to `Duration.zero` when `MediaQuery.maybeDisableAnimationsOf(context)` is true.

---

## 7. Testing Strategy

1. **Unit Tests** (`test/features/notifications/belong_notifications_test.dart`):
   - Author initials parsing across complex international, parenthetical, and bracketed names.
   - Relative timestamp calculations across second, minute, hour, day, and month thresholds.
   - Digest schedule state transitions.
2. **Widget Tests** (`patrol_finders` / `patrolWidgetTest`):
   - Bell badge rendering and automatic dismissal upon "Mark all read".
   - Chip row filtering verification across all 4 categories.
   - High-contrast color verification.
3. **Patrol Native Integration Tests** (#328):
   - Android OS Notification Shade inspection via `$.native.openNotifications()`.
   - Verification that no jarring sounds or intrusive heads-up popups occur.
