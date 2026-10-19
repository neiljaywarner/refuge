# Changelog & Release Roadmap (`Belong on the Spectrum` / `refuge`)

All notable changes and planned release milestones leading up to the **October 31, 2026 Circle.so Cutover** are documented in this file.

---

## [Unreleased / Active Tonight — `v0.6.0-alpha` -> `v0.8.0-alpha` (Oct 18, 2026)]

### Added
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
