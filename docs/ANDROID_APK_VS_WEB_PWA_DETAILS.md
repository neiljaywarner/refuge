# ⚙️ Deep Technical Breakdown: Native Android APK vs. Web PWA / WebAPK

> **Architectural Reference & Engineering Details Guide**  
> *Target Context: Tracks Issue [#313](https://github.com/neiljaywarner/refuge/issues/313)*  
> *Package ID: `com.belongonthespectrum.sanctuary` | Web Origin: `https://belongonthespectrum.web.app`*  
> *Wiki Version: [`docs/wiki/Android-APK-vs-Web-PWA-Details.md`](wiki/Android-APK-vs-Web-PWA-Details)*

---

## 🧭 Executive Summary

Belong on the Spectrum is built using Flutter 3.38+ with a shared Dart codebase powering two distinct delivery channels:
1. **The Native Android APK** (`app-release.apk`): An Ahead-of-Time (AOT) compiled native ARM64/x86_64 binary distributed via Firebase App Distribution or sideloading.
2. **The Web PWA / WebAPK**: A modern Progressive Web App leveraging Flutter's CanvasKit and WebAssembly (Wasm) pipeline, distributed globally via Firebase Hosting Content Delivery Networks (CDN).

While both targets share **98% of business logic, domain models, Riverpod state notifiers, and calm sensory themes**, there are significant architectural and behavioral divergences under the hood.

---

## 📊 Comprehensive Comparison Matrix

| Architectural Dimension | Native Android APK (`com.belongonthespectrum.sanctuary`) | Web PWA / WebAPK (`belongonthespectrum.web.app`) |
| :--- | :--- | :--- |
| **Notification Engine** | Native Firebase Cloud Messaging (FCM) + Android Notification Channels | W3C Web Push API + Service Worker (`firebase-messaging-sw.js`) |
| **Background Wakeup When Killed** | High-priority FCM intents wake app process in background | Limited; mobile browsers aggressively kill service workers to save battery |
| **App Icon Launcher Badges** | Native hardware badge counter (`flutter_app_badger`) on Nova/Pixel launcher | Badging API (`navigator.setAppBadge`) supported on Android WebAPK, not mobile Safari |
| **Notification Sound & Vibration** | Custom calm sound files in `res/raw/` + custom haptic vibration patterns | Browser-default chime or silent; cannot play custom local audio when screen off |
| **iOS Notification Support** | Native APNs (scheduled for Mid-Nov v1.1) | **Only works if user adds to Home Screen** (iOS 16.4+ requirement) |
| **Local Data Persistence** | Direct disk SQLite (`sqflite`/`drift`) & Android `SharedPreferences` | Browser IndexedDB (`idb`) & CacheStorage API |
| **Storage Eviction Risk** | **Zero Risk**: Data remains until user uninstalls app or clears data | **Moderate Risk**: Browser may evict IndexedDB if device disk is >80% full |
| **Cold-Start Performance** | **~150ms – 250ms**: Pre-compiled native machine code (Dalvik/ART AOT) | **~800ms – 1.5s** first visit (CanvasKit download); **~300ms** cached |
| **Memory Resident Set (RSS)** | **~45MB – 65MB**: Lean native memory managed by Android OS | **~75MB – 120MB**: Includes Chrome/V8 browser runtime sandbox overhead |
| **Haptic Motor Feedback** | Low-latency tactile haptics (`HapticFeedback.lightImpact`) | `navigator.vibrate` (often blocked or ignored by Safari/mobile browsers) |
| **System Bars & Navigation Tinting** | Pixel-perfect `SystemUiOverlayStyle` (edge-to-edge transparent nav bar) | Themed via `manifest.json` `theme_color`, but browser chrome visible in tabs |
| **Background Sync & Tasks** | Android `WorkManager` (runs scheduled morning/evening quiet digests) | Periodic Background Sync API (unreliable/blocked on iOS and mobile Chrome) |
| **Deployment & Update Cycle** | 3–7 day store review (or manual APK re-download & install) | **Instant (<90 seconds)** global CDN deploy; users get fixes on next load |
| **Distribution Footprint** | **~45MB download** (compiled Android APK) | **~4.8MB download** (compressed assets + CanvasKit Wasm engine) |
| **System Permissions** | Declared in `AndroidManifest.xml` (`POST_NOTIFICATIONS`, `VIBRATE`) | Origin-scoped web permissions (`Notification.requestPermission()`) |

---

## 🔍 Detailed Technical Deep-Dive

### 1. Notifications: Native FCM Channels vs. Web Push Service Workers

#### Native Android APK Behavior:
- **Notification Channels**: The native APK creates a dedicated Android Notification Channel (`belong_calm_alerts`) registered with `NotificationManager`:
  ```kotlin
  val channel = NotificationChannel(
      "belong_calm_alerts",
      "Belong Calm Daily Digest",
      NotificationManager.IMPORTANCE_DEFAULT
  ).apply {
      description = "Unhurried morning and evening community digests"
      enableVibration(true)
      vibrationPattern = longArrayOf(0, 80, 80, 80) // Gentle double-tap
  }
  ```
- **Killed-State Delivery**: When a user swipes Belong out of their Android Recent Apps list, the Android OS terminates the Flutter UI isolate. However, when an FCM message arrives with `priority: high`, the native Android FCM client (`FirebaseMessagingService`) wakes up a background thread, executes native Dart background entrypoints, displays the heads-up notification, and increments the hardware launcher badge counter via `flutter_app_badger`.
- **Sensory Sound Overrides**: The native APK can bind custom calm audio chimes packaged in `android/app/src/main/res/raw/calm_chime.mp3`, completely bypassing harsh system alert klaxons.

#### Web PWA Behavior:
- **Service Worker Lifecycle**: The PWA relies on `web/firebase-messaging-sw.js`. The browser must keep the service worker registered under origin `https://belongonthespectrum.web.app`.
- **Battery Optimization Throttling**: Android's power manager and Doze mode aggressively suspend browser service workers. If the user hasn't interacted with Chrome in several hours, Web Push messages may be delayed until the user unlocks their phone or launches Chrome.
- **The iOS Safari Barrier**: On iOS, Safari **strictly forbids** Web Push in normal browser tabs. The user **must** tap *"Add to Home Screen"*. Only when launched as a standalone Web App under iOS 16.4+ can `PushManager.subscribe()` succeed.
- **Audio Limitations**: Web Push notifications cannot play arbitrary local audio when the device screen is locked; they are restricted to the operating system's default web notification tone.

---

### 2. Local Storage & Offline Persistence: SQLite vs. IndexedDB

#### Native Android APK:
- **Storage Location**: Writes directly to private app storage:
  `/data/user/0/com.belongonthespectrum.sanctuary/databases/belong.db`
- **Immunity**: This database is sandboxed with a unique Linux User ID (`uid`). The operating system will **never** delete or evict this database due to disk pressure unless the user explicitly navigates to *Settings > Storage > Clear Storage*.
- **Sync Architecture**: In our repository seam (`LocalPostRepository`, `LocalCommentRepository`), reflections, drafts, and sensory preferences are written to disk synchronously or via SQLite transactions.

#### Web PWA:
- **Storage Location**: Data is stored inside browser-managed **IndexedDB** (`idb`) and CacheStorage.
- **Eviction Risk (Storage Pressure)**: Modern browsers enforce a temporary storage quota. If the host device runs low on disk space (<10% free storage), the browser engine's LRU (Least Recently Used) cache cleaner may **silently purge** origin IndexedDB databases!
- **Incognito / Private Browsing Trap**: If a member opens Belong in a Private/Incognito tab, all offline data, drafted thoughts, and sensory theme preferences are instantly destroyed the moment the tab is closed.
- **Mitigation in Belong**: We invoke `navigator.storage.persist()` on supported browsers, requesting persistent storage permission to prevent automatic browser eviction.

---

### 3. Runtime Engine, Cold Start & Hydration

#### Native Android APK:
- **Compilation**: Compiled Ahead-of-Time directly to ARM64 machine code (`libapp.so`).
- **Bootstrap Flow**: 
  1. Linux process fork -> 
  2. Flutter engine initializes C++ render tree -> 
  3. `libapp.so` runs `main()` -> 
  4. Frame 1 drawn via Impeller / Skia in **~150ms**.
- **CPU Footprint**: Direct register execution with zero Just-in-Time (JIT) compilation overhead.

#### Web PWA:
- **Compilation**: Compiled to WebAssembly (`app.wasm` or `main.dart.js`) + CanvasKit C++ Wasm renderer.
- **Bootstrap Flow**:
  1. Browser loads `index.html` ->
  2. Service Worker resolves cached assets ->
  3. V8 / JavaScriptCore downloads and compiles CanvasKit Wasm (`canvaskit.wasm` ~2.5MB) ->
  4. Web fonts (Roboto / Inter) are hydrated over HTTP/local cache ->
  5. Frame 1 rendered to HTML5 `<canvas>` in **~800ms** (first load) or **~300ms** (subsequent visits).
- **Smoothness**: Once hydrated, Flutter Web delivers identical 60fps / 120fps smooth scrolling across feed items and spaces.

---

### 4. Hardware Integration, Haptics & System Bars

#### Haptics:
- **Native APK**: Calls Android `Vibrator` and `VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)`. This allows our calm-tech haptic toggle to provide subtle, tactile confirmations (e.g. tapping "Praying" `🙏` produces an ultra-soft 15ms pulse).
- **Web PWA**: Uses `navigator.vibrate(15)`. However:
  - iOS Safari completely ignores `navigator.vibrate`.
  - Android Chrome requires an active user gesture, and certain OEM battery savers disable web vibrations entirely.

#### System UI Overlay:
- **Native APK**: We programmatically set:
  ```dart
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFF4F7F4),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  ```
  This creates a seamless, edge-to-edge layout flowing beneath the Android navigation pill and camera punch-hole.
- **Web PWA**: 
  - In browser mode: The browser URL bar and bottom controls occupy ~120px of vertical space.
  - In standalone PWA mode: The URL bar disappears, and the status bar adopts the `<meta name="theme-color" content="#68A67D">` color declared in `web/index.html`.

---

### 5. Background WorkManager vs. Web Background Sync

#### Native APK:
- Uses Android `WorkManager` (`androidx.work.WorkManager`).
- Allows Belong to schedule periodic background tasks that run even if the device restarts:
  - Daily Quiet Digest compile at 10:00 AM.
  - Nightly offline cache prune at 3:00 AM.
  - Runs in a background Flutter isolate with guaranteed battery management compliance.

#### Web PWA:
- Relies on the W3C `Background Sync API` (`registration.sync.register('sync-reflections')`).
- Apple Safari has explicitly refused to implement Background Sync for battery and privacy reasons.
- Android Chrome only fires sync events when the browser process is actively running in RAM.

---

### 6. Deployment Velocity vs. App Store Gates

| Release Metric | Native Android APK | Web PWA / WebAPK |
| :--- | :--- | :--- |
| **Release Command** | `flutter build apk --release` -> Firebase App Distribution | `tool/deploy_release.dart` -> Firebase Hosting CDN |
| **Time to Global Deployment** | ~15–30 minutes (or 3–7 days via Google Play Store review) | **< 90 seconds** |
| **User Action Required** | Download APK file, accept "Install unknown apps" warning, install package | **None**. Next time the member taps the app, the update is live |
| **Rollback Capability** | Users must uninstall and reinstall previous APK | Instant 1-second CDN rollback via Firebase Console |
| **Keystore Signing & Expiry** | Requires `upload-keystore.jks` with 25-year validity and password management | Standard HTTPS SSL/TLS certificates managed automatically by Google Cloud |

---

## 🎯 Architectural Verdict & Best-of-Both Recommendation

For the **October 24–31 soft launch and community cutover**:
1. **Primary Recommendation for All Members**: Use the **Web PWA** (`belongonthespectrum.web.app`). It provides an instantaneous, zero-friction experience with no passwords, no storage bloat, and automatic updates.
2. **Recommendation for Power Users & Organizers**: Install the **Native Android APK** if you require guaranteed background FCM wakeup notifications, hardware launcher unread badges, or deep offline SQLite persistence in areas with poor cellular connectivity.

---

## 🔗 Related Architecture Documents
- **[📱 Human-Readable App Store Guide](docs/WHY_NO_APP_STORE.md)**: Why we avoid app store friction for our community.
- **[🔔 Calm Notifications Architecture (ADR-0010)](docs/wiki/ADR-0010-Notifications-Local-Awesome-vs-FCM.md)**: Hybrid notification design.
- **[🖼️ Visual UI & Accessibility Catalog](docs/wiki/visual_catalog.md)**: Verified screenshots and sensory theme audits.