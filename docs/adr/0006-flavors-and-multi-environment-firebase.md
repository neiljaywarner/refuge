# ADR 0006: Multi-Environment Flavors (`dev`, `stg`, `qa`, `prod`) & FlutterFire Suite Architecture

- **Status**: Accepted (`2026-10-18`)
- **Issue**: [`#20`](https://github.com/neiljaywarner/refuge/issues/20) & [`#40`](https://github.com/neiljaywarner/refuge/issues/40)

---

## 1. Context & Problem Statement

As **Refuge** transitions into the production platform for **[Belong on the Spectrum](https://www.belongonthespectrum.com/)** ahead of the **October 31st Circle.so cutover**, we need:
1. **Strict Environment Isolation**: Developer testing, BDD test runs, and Firebase Hosting preview channels in **`dev`** must **never** pollute or clash with **`prod`** community posts, Firebase Analytics events, or Firebase Remote Config settings.
2. **Non-Technical Organizer Control ("Message from the Organizer")**: Community organizers must be able to update welcome banners, announcements, and store download links live via **Firebase Remote Config** on **Web/PWA, Android, and iOS** without needing a developer or code deployment.
3. **Complete FlutterFire Foundation Installed Up Front**: Installing all core Firebase packages (`firebase_core`, `firebase_analytics`, `firebase_remote_config`, `firebase_in_app_messaging`, `firebase_crashlytics`, `firebase_auth`, `firebase_messaging`, `firebase_performance`, `firebase_app_check`) in one cohesive setup avoids repeated native dependency churn later.
4. **Zero API Keys or PII in Public Git**: Because `neiljaywarner/refuge` is an open teaching reference for students, mentees, and contributors, no raw Firebase configuration files (`firebase_options*.dart`, `google-services.json`, `GoogleService-Info.plist`) or secret keys may ever be committed to Git.

---

## 2. Options Considered for Flavor Architecture

1. **CodeWithAndrea (`codewithandrea.com`) Dart-First Entrypoints (`main_dev.dart`, `main_prod.dart`) + `--dart-define-from-file` + Riverpod `appFlavorProvider`**
2. **Very Good Ventures (`very_good_cli`) Native Xcode Schemes / Android ProductFlavors Only**
3. **Hybrid CodeWithAndrea + VGV Entrypoint Pattern (Selected)**

---

## 3. Decision

We adopt the **Hybrid CodeWithAndrea + VGV Flavor Pattern**:
- Define `enum AppFlavor { dev, stg, qa, prod }` in `lib/src/core/config/app_flavor.dart` exposed via `appFlavorProvider` (`hooks_riverpod`).
- Provide explicit entrypoints:
  - `lib/main_dev.dart` (`AppFlavor.dev` — default for local development, BDD tests, and dev preview channels)
  - `lib/main_prod.dart` (`AppFlavor.prod` — used for `belongonthespectrum.com` production builds)
  - `lib/main.dart` (reads `FLAVOR` from `String.fromEnvironment('FLAVOR', defaultValue: 'dev')` so standard `flutter run` and `flutter build web` work seamlessly).
- Wrap **Firebase Remote Config**, **Firebase Analytics**, and **Firebase In-App Messaging** behind clean, Riverpod-injected interfaces (`OrganizerRemoteConfigService` and `CommunityAnalyticsService`):
  - When Firebase is initialized for the active flavor, values are fetched from live Firebase Remote Config and events are logged to Firebase Analytics (prefixed/isolated by flavor when needed).
  - In unit/BDD widget tests or offline environments where native Firebase is not initialized, the services automatically fall back to deterministic in-memory defaults from `CommunityBrandConfig.belong()` with **zero crashes and zero secret files required in Git**.
- **Web/PWA vs. Mobile In-App Messaging**:
  - `firebase_in_app_messaging` is included for native Android and iOS builds.
  - Because `firebase_in_app_messaging` does not run on Flutter Web, `OrganizerRemoteConfigService` (`firebase_remote_config`) drives the in-app **"Message from the Organizer"** banner and announcement card across **100% of platforms (Web, PWA, Android, and iOS)**.
