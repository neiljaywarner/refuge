# Changelog & Release Roadmap (`Belong on the Spectrum` / `refuge`)

All notable changes, accomplishments, and planned release milestones leading up to the **October 24–31, 2026 Circle.so Cutover & Overlap Window** are documented in this file.

---

## [Current Release — `v0.9.0-rc` / Soft Launch Candidate (Oct 20, 2026)]

### 🚀 Major Accomplishments in the Last 30 Hours (Oct 19–20, 2026)

#### 1. Calm Push Notifications & Permissions (PR #159, PR #168)
- **FCM Web Push & Android 13+ Runtime Permissions (`#53`, `#166`)**:
  - Added `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` in `android/app/src/main/AndroidManifest.xml` for Android 13+ (API 33+) / Android 15 on Google Pixel 9a.
  - Wired `NotificationPermissionsService.requestPushPermission()` to `FirebaseMessaging.instance.requestPermission()` with calm-tech defaults (alert: true, badge: false, sound: false) and web VAPID key support.
  - Created background Service Worker (`web/firebase-messaging-sw.js`) implementing W3C Web Push with calm-tech digest deduplication.
  - Interactive `CalmNotificationPreferencesSheet` offering 4 predictable schedules: Twice Daily Digest, Morning Only, Immediate Gentle, and Muted.
  - Deferred iOS FCM / APNs to mid-November milestone (tracked in dedicated Issue `#165`).

#### 2. Authentication & Alpha Self-Testing Gating (PR #120, PR #152, PR #164)
- **Solid Dual-Mode Firebase Auth (`#119`, PR #120)**:
  - Email & Password (`signInWithPassword`, `registerWithPassword`) + 1-Click Passwordless Magic Link (`sendMagicLink`, `signInWithMagicLink`).
  - Neurodivergent-friendly `BelongAuthSheet` modal dialog with clear reassurance banners and translated error messages (no scary raw error codes).
  - Preserves Marty the Organizer's required ICOC church affiliation question (*"Which ICOC church do you attend?"*) with explicit non-member option, validated on profile save (PR #94, PR #97).
- **1-Tap Google Sign-In & Preview Mode Gating (`#117`, `#163`, PR #152, PR #164)**:
  - 1-Tap Google Sign-In implemented and safely gated behind `previewFeaturesEnabledProvider` so public alpha testers use rock-solid email/password while Google Sign-In is previewed risk-free.
  - Published self-testing briefing (`docs/ascii_email_for_self_testing_alpha_verification.txt`) with 8-step verification checklist and physical glass Pixel 9a walkthrough video.

#### 3. Community Discussions & Circle.so Migration Parity (PR #98, PR #110, PR #157)
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

#### 4. Testing, BDD & Zero-Boilerplate Standardization (PR #162)
- **100% Patrol Finders Standardization (`#161`, PR #162)**:
  - Replaced verbose `tester.widget(...)` and `waitUntilExists` boilerplate with concise, robust `$` syntax from `package:patrol_finders` across all widget and integration tests.
  - **147/147 Automated Tests Passing Green (100%)** via Dart MCP `run_tests`.
  - **0 Static Analysis Errors** across `lib/` and `test/` via Dart MCP `analyze_files`.
- **Physical Glass & Marionette Driving**:
  - Live VM Service RPC driving on connected Google Pixel 9a (Android 15) auditing interactive elements and navigation flows.

#### 5. DevOps Velocity & Zero-Terminal-Push Enforcement (PR #160, PR #170)
- **Mandatory GitHub MCP Server Rule (`#160`)**:
  - Strictly enforced GitHub MCP API (`push_files`, `create_pull_request`, `merge_pull_request`) eliminating 100% of interactive terminal push popups.
- **Dashboards & Soft Launch Report Card (`#169`, PR #170)**:
  - Published Soft Launch Readiness Report Card (**Overall A- 91%**) and Maintainer Private Review Note in `status.md`.
  - 35 atomic Pull Requests merged to `main` with continuous CodeRabbit triage.

---

## [Soft Launch & Overlap Window — `v0.9.5` / `v1.0.0-rc` (Oct 24 – Oct 30, 2026)]

### 🎯 Goal: 7-Day Calm Community Overlap Before Circle Deprecation
- **Saturday, Oct 24, 2026**: Soft Launch begins! Real Belong on the Spectrum members are invited into the Web/PWA and mobile apps.
- **Oct 24 – Oct 30**: Dual-system calm overlap. Circle.so remains accessible while members create profiles, explore spaces, and share reflections in Belong.
- **Saturday, Oct 31, 2026**: Circle.so subscription ends cleanly, saving $1,000+/year.

### 📋 Checklist Before Oct 24th Launch:
1. [x] **Core Auth**: Email/password, magic link, and required church affiliation question verified.
2. [x] **Spaces & Discussions**: All 8 Circle spaces mapped, threaded replies and care reactions active.
3. [x] **Calm Push Notifications**: FCM active on Web, PWA, and Android with quiet default schedules.
4. [x] **PWA Installability**: Installable WebAPK verified with full video walkthrough on real Pixel 9a.
5. [x] **Test Suite**: 147/147 tests green with Patrol Finders.
6. [ ] **Maintainer Private Review**: Neil checks personal Circle community spaces and member cards side-by-side.
7. [ ] **Circle CSV Migration Execution**: Run `tool/import_circle_csv.dart` against official export.
8. [ ] **Firebase Remote Config**: Publish official launch welcome greeting from organizer.
9. [ ] **Community Invitation**: Post launch announcement in Circle `#announcements` with link to `belongonthespectrum.com`.

---

## [Post-Launch Fast-Follows — `v1.1.0` (Mid-November 2026)]
- **iOS FCM & APNs Verification (`#165`)**: Complete end-to-end device testing of APNs push tokens on physical iOS hardware.
- **Public Google & Apple 1-Tap Sign-In**: Graduate 1-Tap OAuth from preview flag to default auth sheet.
- **Expanded Church Affiliation Directory**: Additional congregation filters requested by organizers.