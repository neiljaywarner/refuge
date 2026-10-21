# Changelog & Release Roadmap (`Belong on the Spectrum` / `refuge`)

All notable changes, accomplishments, and planned release milestones leading up to the **October 24–31, 2026 Circle.so Cutover & Overlap Window** are documented in this file.

---

## [Current Release — `v0.9.0-rc` / Soft Launch Candidate (Oct 20, 2026)]

### 🚀 Major Accomplishments in the Last 30 Hours (Oct 19–20, 2026)

#### 1. Resilient Authentication & Cloud Credentials Fallback (PR #203 / #199)
- **`FirebaseAuthRepository` Resilient Seam**:
  - Implemented `_hasRealCredentials` guard to seamlessly detect placeholder vs production Firebase keys.
  - When running in offline or test mode, automatically delegates to in-memory accounts without hard-crashing or throwing raw API key exceptions.
  - Verified user creation and sign-in with test account (`neilwarner+2026Oct20+954pm@gmail.com`) with automated unit test (#199).
  - 171/171 tests green across the complete suite.

#### 2. Comprehensive Maestro User Journey & Auth Driving (PR #204 / #198)
- **Maestro End-to-End Flows (`.maestro/`)**:
  - Added `.maestro/belong_full_journey.yaml` driving Welcome Anchor $\rightarrow$ Sensory Theme Switcher $\rightarrow$ Spaces Directory $\rightarrow$ Scripture Anchor dialog $\rightarrow$ Auth Modal.
  - Added `.maestro/belong_auth_journey.yaml` validating account registration, ICOC church affiliation selection (`DFW Church`), and sign-in.
  - Built `tool/run_maestro_verification.sh` for 1-command driving across physical Pixels and emulators.

#### 3. Dynamic Dual Pixel Cloud Demo & Zero-PII Auto-Cropping (PR #196 / #195)
- **Dynamic Hardware Auto-Discovery**:
  - Scripts dynamically detect connected physical Pixels and emulators with zero hardcoded serial numbers.
  - Automated 1080x2160 status-bar auto-cropping via `sips` to strip clock, battery, and notifications.
  - Formalized 5 zero-prompt screenshot allowlist rules in `AGENTS.md` and `GEMINI.md` to guarantee unattended execution without terminal permission popups.

#### 4. Antigravity Autonomous Automated Testing Strategy (PR #202 / #201)
- **Autonomous Testing Use-Case Evaluation**:
  - Evaluated official Google Antigravity automated testing paradigms for 2026.
  - Documented scheduled 2:00 AM regression runner, flakiness stress hunter, and browser-in-the-loop PWA QA in `docs/wiki/Antigravity-Automated-Testing-and-Overnight-QA-Strategy.md`.
  - Created `.agents/skills/antigravity-overnight-qa/SKILL.md`.

#### 5. Calm Memes & Sensory GIF Attachments (PR #174, PR #176, PR #178)
- **Calm Meme & GIF Feature Engine (`#173`, `#177`)**:
  - Enhanced `CalmMeme` and `Post` domain models with optional `imageUrl` property, serialization, and equality checks.
  - Dual-mode `MemeGalleryModal` featuring curated calm memes and custom GIF/image URL attachment with instant live preview.
  - Neurodivergent low-motion safety guidelines with calm presets (`🍞 Elijah Rest & Nap`, `🧩 Special Interest Deep Dive`, `🌊 Quiet Waters & Stillness`).
  - Added attached meme thumbnail banner in `ReflectionComposer` and rounded media card rendering with loading states and graceful error fallback in `ReflectionCard`.
  - 8 unit and BDD tests passing via `patrol_finders` (`test/features/memes/calm_meme_and_gif_test.dart`).

#### 2. Triple Observability, Firebase Lifecycle & Serverpod Telemetry Backup (PR #148, PR #180, PR #184, PR #186)
- **Firebase Lifecycle Initializer & Error Forwarding (`#183`, PR #184)**:
  - Resolved root cause of silent telemetry bypass by building `FirebaseInitializer` (`lib/src/core/firebase/firebase_initializer.dart`) with public `webOptions`, platform fallback, and automatic Crashlytics & Analytics collection activation.
  - Guarded Crashlytics with `!kIsWeb` across core services and `main.dart` to prevent web invocation exceptions.
  - Wired `main_dev.dart`, `main_prod.dart`, and `runWithFlavor` as async with `await FirebaseInitializer.initialize(flavor: flavor)`.
  - Added 4 automated tests verifying `FlutterError.onError` and `PlatformDispatcher.onError` forwarding to the error reporter.
- **Main Re-exports Clean-up & Easter Egg ADB Copy (`#185`, PR #186)**:
  - Re-exported `reflections_providers.dart` in `lib/main.dart` and eliminated legacy/duplicate symbols for 100% CodeWithAndrea feature-first cleanliness.
  - Added 1-tap clipboard copy button (`Key('easter_egg_copy_adb_button')`) for `adb shell setprop debug.firebase.analytics.app com.belongonthespectrum.sanctuary` in the 7-Tap Developer Easter Egg dialog.
  - Verified 165/165 tests pass green across the entire test suite via Dart MCP server.
- **Serverpod Telemetry Backup & CLI Audit (`#179`, PR #180)**:
  - Built `ServerpodTelemetryBackup` ring buffer service with FIFO eviction ensuring conversion funnels and error logs are safely preserved even if Firebase is unreachable.
  - Dual-dispatched all user journey analytics and error reports into Serverpod backup from `ErrorReporterService` and `CommunityAnalyticsService`.
  - Created pure-Dart review utility `tool/review_telemetry.dart` to audit and simulate telemetry events with Zero-PII regex scrubbing (`[SCRUBBED_EMAIL]`, `[SCRUBBED_SECRET]`).
  - Fixed Maestro E2E `appId` across `.maestro/` (`com.belongonthespectrum.sanctuary`) and updated test spaces to canonical 8 Circle spaces.
  - Comprehensive unit and integration tests (`test/core/observability/serverpod_telemetry_backup_test.dart`).

#### 3. Calm Push Notifications & Permissions (PR #159, PR #168)
- **FCM Web Push & Android 13+ Runtime Permissions (`#53`, `#166`)**:
  - Added `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` in `android/app/src/main/AndroidManifest.xml` for Android 13+ (API 33+) / Android 15 on Google Pixel 9a.
  - Wired `NotificationPermissionsService.requestPushPermission()` to `FirebaseMessaging.instance.requestPermission()` with calm-tech defaults (alert: true, badge: false, sound: false) and web VAPID key support.
  - Created background Service Worker (`web/firebase-messaging-sw.js`) implementing W3C Web Push with calm-tech digest deduplication.
  - Interactive `CalmNotificationPreferencesSheet` offering 4 predictable schedules: Twice Daily Digest, Morning Only, Immediate Gentle, and Muted.
  - Deferred iOS FCM / APNs to mid-November milestone (tracked in dedicated Issue `#165`).

#### 4. Authentication & Alpha Self-Testing Gating (PR #120, PR #152, PR #164)
- **Solid Dual-Mode Firebase Auth (`#119`, PR #120)**:
  - Email & Password (`signInWithPassword`, `registerWithPassword`) + 1-Click Passwordless Magic Link (`sendMagicLink`, `signInWithMagicLink`).
  - Neurodivergent-friendly `BelongAuthSheet` modal dialog with clear reassurance banners and translated error messages (no scary raw error codes).
  - Preserves Marty the Organizer's required ICOC church affiliation question (*"Which ICOC church do you attend?"*) with explicit non-member option, validated on profile save (PR #94, PR #97).
- **1-Tap Google Sign-In & Preview Mode Gating (`#117`, `#163`, PR #152, PR #164)**:
  - 1-Tap Google Sign-In implemented and safely gated behind `previewFeaturesEnabledProvider` so public alpha testers use rock-solid email/password while Google Sign-In is previewed risk-free.
  - Published self-testing briefing (`docs/ascii_email_for_self_testing_alpha_verification.txt`) with 8-step verification checklist and physical glass Pixel 9a walkthrough video.

#### 5. Community Discussions & Circle.so Migration Parity (PR #98, PR #110, PR #157)
- **Threaded Comments & Nested Discussion Replies (`#156`, PR #157)**:
  - Added full discussion reply support under reflections (`Comment` domain model, hierarchical indentation `↳`, tone tags `[Comfort Only]`, `[Relatable]`, `[Encouragement]`, `[Prayer]`, and reactions `🙏`, `🤍`, `🌱`, `😄`).
- **Circle.so CSV Data Migration Importer CLI (`#41`, PR #98)**:
  - Pure-Dart CLI `tool/import_circle_csv.dart` with RFC 4180 parser and `--dry-run` validation mapping 8 canonical Circle spaces (`start_here`, `announcements`, `general_chat`, `memes`, `resources_videos`, `actually_autistic_chat`, `friends_chat`, `family_chat`).
- **Calm Sensory Ambient Soundscapes & Brown Noise Generator (`#109`, PR #110)**:
  - Added low-frequency brown noise and ambient soundscapes for sensory regulation.
- **Direct Messages (`Msgs`) & Actually Autistic Events Calendar (`#27`, `#28`, PR #76)**:
  - Active messaging tabs and community events RSVP.
- **Accessible Dialog Close Actions (`#167`, PR #168)**:
  - Added `profile_sheet_close_button` to `MemberProfileDialog` for web/desktop accessibility.

#### 6. Testing, BDD & Zero-Boilerplate Standardization (PR #162, PR #174, PR #180)
- **100% Patrol Finders Standardization (`#161`, PR #162)**:
  - Replaced verbose `tester.widget(...)` and `waitUntilExists` boilerplate with concise, robust `$` syntax from `package:patrol_finders` across all widget and integration tests.
  - **165/165 Automated Tests Passing Green (100%)** via Dart MCP `run_tests`.
  - **0 Static Analysis Errors** across `lib/`, `test/`, and `tool/` via Dart MCP `analyze_files`.
- **Physical Glass & Marionette Driving**:
  - Live VM Service RPC driving on connected Google Pixel 9a (Android 15) auditing interactive elements and navigation flows.

#### 7. DevOps Velocity & Zero-Terminal-Push Enforcement (PR #160, PR #170, PR #180, PR #184, PR #186)
- **Mandatory GitHub MCP Server Rule (`#160`)**:
  - Strictly enforced GitHub MCP API (`push_files`, `create_pull_request`, `merge_pull_request`) eliminating 100% of interactive terminal push popups.
