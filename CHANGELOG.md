# Changelog & Release Roadmap (`Belong on the Spectrum` / `refuge`)

All notable changes and planned release milestones leading up to the **October 31, 2026 Circle.so Cutover** are documented in this file.

---

## [Unreleased / Active Tonight — `v0.6.0-alpha` -> `v0.9.0-rc` (Oct 20, 2026)]

### Added
- **Alpha Self-Testing Brief, Multi-Method Verification Guide & Google Sign-In Preview Mode Gating (`#163`)**:
  - Gated 1-Tap Google Sign-In behind `previewFeaturesEnabledProvider` so the public default authentication flow is rock-solid Email & Password sign-in/registration (with required ICOC church affiliation selection) and passwordless magic link, while Google Sign-In can be safely toggled in Preview Mode without exposing non-technical Alpha members to unfinished OAuth redirects.
  - Added `docs/ascii_email_for_self_testing_alpha_verification.txt` containing the complete testing briefing and 8-step self-testing checklist referencing the real-device Pixel 9a walkthrough video (`doc/videos/pwa_walkthrough_pixel9a.mp4`).
  - Added BDD widget test coverage verifying Google Sign-In visibility adheres to `previewModeUserOverrideProvider`.
- **Web Push & Native FCM Evaluation with Calm-Tech Digest Ethics (`#154`)**:
  - Background Service Worker (`web/firebase-messaging-sw.js`) implementing W3C Web Push and Firebase Cloud Messaging with calm-tech tags, non-intrusive sound policies, and single-instance digest deduplication.
  - `CalmNotificationPreferences` domain model and `NotificationPermissionsService` StateNotifier (`calmNotificationPreferencesProvider`) featuring 4 predictable schedules (Twice Daily Digest, Morning Only, Immediate Gentle, Muted) and transparent permission guards for Mobile Safari.
  - Interactive `CalmNotificationPreferencesSheet` accessible via `CalmNotificationsView` app bar tune button and preferences action card.
  - Comprehensive unit and widget tests in `test/features/notifications/notification_preferences_test.dart` (+145 tests green).
- **PWA Installation Walkthrough, Video Demo & In-App Guide (`#153`)**:
  - Full-resolution physical glass video recording (`doc/videos/pwa_walkthrough_pixel9a.mp4`, 5.0 MB) and real-device step-by-step screenshots (`doc/screenshots/*`) on Google Pixel 9a demonstrating 1-tap Chrome WebAPK install and launcher dock placement.
  - Member-facing educational guides in GitHub Wiki (`PWA-Installation-and-Mobile-Web-Guide.md` and `PWA-Guide-for-Members-and-Organizers.md`) addressing zero storage bloat (< 5 MB), instant updates, and sandboxed calm privacy.
  - Interactive `ComingSoonView` PWA Guide bottom sheet (`showPwaInstallGuide`) wired to the mobile app store placeholder links in `HomeScreen`.
  - Comprehensive BDD widget tests in `test/core/presentation/coming_soon_view_test.dart`.
- **Threaded Comments & Nested Discussion Replies (`#156`)**:
  - Full Circle.so parity for discussion replies under reflections (`Comment` domain model with optional `parentCommentId`).
  - Pluggable `CommentRepository` seam with in-memory broadcast streams (`LocalCommentRepository`) and seeded authentic discussion threads.
  - `ThreadedDiscussionSheet` modal presentation with original post context, hierarchical indentation (`↳`), care reactions (`🙏`, `🤍`, `🌱`, `😄`), tone tag chips (`[Comfort Only]`, `[Relatable]`, `[Encouragement]`, `[Prayer]`), and reply-to targeting.
  - `ReflectionCard` live comment count badge (`Key('discussion_button_${post.id}')`).
  - Comprehensive unit and BDD widget test suite with `patrol_finders` (+138 tests green).
- **White-Label Multi-Tenant Architecture (`#17`)**: `CommunityBrandConfig` domain model and `hooks_riverpod` provider with **Belong on the Spectrum** (`belongonthespectrum.com`, partnered with `dfwchurch.org`) as default flagship tenant.
- **Official Multi-Platform Belong Branding & PWA Manifest (`#19`)**: Android API 26+ Adaptive Icons with 66% safe-zone padding, opaque `RGB24` iOS App Store icons, macOS icons, and installable Web PWA manifest.
- **Circle.so Parity Navigation & 6 Belong Spaces (`#18`, `#22`, `#23`)**:
  - 5-tab `salomon_bottom_bar` (`Home`, `Spaces`, `Msgs`, `Notifications`, `Profile`).
  - All 6 Belong spaces grouped into *Welcome & Connection*, *Neurodivergent Life & Special Interests*, and *Faith, Prayer & Encouragement*.
  - Real-time Community Search & Media/Meme attachment tags.
  - Interactive Member Profile & Neurodivergent Identity Badges sheet.
- **Simplified Neurodivergent-First Feedback & 1-Tap Feature Voting (`ADR-0007`)**:
  - Replaces ambiguous 1–5 star ratings with **Literal 3-Intent Cards** (💚 *Works Great / Public Praise*, 💡 *Idea / Tweak*, 🛠️ *Bug / Confusing*) + a **1-Tap Feature Voting Board** pre-seeded with `WIP · Shipping Before Oct 31` items.
- **Unified FlutterFire Suite & `dev`/`prod` Flavors (`#20`, `ADR-0006`)**:
  - Installed all 9 Firebase packages (`firebase_core`, `firebase_analytics`, `firebase_remote_config`, `firebase_in_app_messaging`, `firebase_crashlytics`, `firebase_auth`, `firebase_messaging`, `firebase_performance`, `firebase_app_check`).
  - Added `OrganizerRemoteConfigService` so non-technical organizers can update the *"Message from the Organizer"* banner without coding.
- **Live GitHub Wiki & Engineering ADRs (`#21`, `#39`)**:
  - Published 19 approachable Wiki pages at [`https://github.com/neiljaywarner/refuge/wiki`](https://github.com/neiljaywarner/refuge/wiki), including a ready-to-copy Circle.so invitation message, the Oct 24–31 7-day overlap plan, PWA installation guide, `patrol_finders` BDD testing guide, and `docs/migrate_to_appwrite.md`.

---

## [Planned Next — `v0.8.5` / `v0.9.0-beta` (Between Alpha & Beta — Target Oct 20–23, 2026)]

### High-Value User Experience & Auth Upgrade
- **1-Tap Google Sign-In & Appwrite Evaluation Cutover (`#33`, `ADR-0008` — 90% Likelihood Window)**:
  - Introduce **1-Tap Google Sign-In** (and Apple Sign-In) between Alpha and Beta so neurodivergent community members never have to deal with "Forgot Password" links during the October 24–31 Circle transition week!
  - Evaluate/connect `AppwriteAuthRepository` and `AppwritePostRepository` (`appwrite.io` $0/month free tier + Realtime + FCM integration).
- **Direct Messages (`Msgs` Tab) & Calm Notification Bell (`#27`)**.
- **Actually Autistic Events Calendar & RSVP (`#28`)**.
- **Circle.so CSV Member & Post Migration Importer (`#41`)**.
- **70% Automated Test Coverage (`patrol_finders` BDD + Domain TDD, `#32`)**.

---

## [Planned Production Cutover — `v1.0.0` (Oct 24 – Oct 31, 2026)]
- **7-Day Calm Overlap Window (Oct 24 – Oct 31, 2026)** welcoming all existing Circle.so Belong members into the new Web/PWA and mobile beta apps before turning off the $1,000+/year Circle subscription on October 31.
- **90% BDD/Widget Test Coverage (`#34`)**, **TestFlight & Google Play Beta (`#44`)**, and **App Store / Play Store Submissions (`#45`, `#46`)**.
