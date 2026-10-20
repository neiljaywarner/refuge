# 🧪 Multi-Tier Test Coverage & Gap Analysis (`rest_of_coverage.md`)

> **Milestone Target**: **`v0.8.5` (70%–90% Combined Test Coverage)**  
> **Last Updated**: Monday, October 19, 2026 @ 7:05 PM CDT  
> **Current Baseline**: 82 automated tests passing (Dart MCP `run_tests`) + 1 on-device integration test passing on Pixel 9a  
> **Companion Executive Review**: [`human_to_review_after_session.md`](human_to_review_after_session.md)  
> **Companion Unattended Plan**: [`unattended_session_908pm.md`](unattended_session_908pm.md)

---

## 🎯 Coverage Strategy: Core-First Multi-Tier Redundancy

To achieve reliable 70%–90% combined coverage without wasting tokens or writing brittle tests that break on minor styling changes, we utilize a 4-tier testing hierarchy:

```
┌──────────────────────────────────────────────────────────────────┐
│ Tier 4: Native Device & PWA Install (Pixel 9a + Patrol Native)    │  ◀── End-to-end user sanity
├──────────────────────────────────────────────────────────────────┤
│ Tier 3: BDD Widget Tests (patrol_finders `$` + sub-2s execution) │  ◀── Fast UI interaction & layouts
├──────────────────────────────────────────────────────────────────┤
│ Tier 2: Pragmatic Unit TDD (Riverpod Notifiers & State Machines) │  ◀── Business logic & seam adapters
├──────────────────────────────────────────────────────────────────┤
│ Tier 1: Pure Domain Models & Config (Zero dependency)            │  ◀── BrandConfig, remote config, parsing
└──────────────────────────────────────────────────────────────────┘
```

---

## 📊 Combined Coverage Scorecard by Subsystem

| Domain / Subsystem | Files Covered | Unit Tests | BDD Widget (`$`) | Device Integration | Combined Coverage Est. | Target for `v0.8.5` |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Brand & Configuration** | `community_brand_config.dart`, `app_config.dart` | ✅ 8 tests | ✅ 3 tests | — | **95%** | **95%+** |
| **Organizer Remote Config** | `organizer_remote_config_service.dart`, banner widget | ✅ 7 tests | ✅ 4 tests | — | **90%** | **90%+** |
| **Feature Voting Seam** | `feature_voting_repository.dart` (4 adapters), `feature_voting_notifier.dart` | ✅ 12 tests | ✅ 6 tests | ✅ 1 on Pixel 9a | **88%** | **90%+** |
| **Authentication ("Any Auth")** | `auth_repository.dart` (adapters), `belong_sign_in_dialog.dart`, avatar | ✅ 8 tests | ✅ 5 tests | — | **82%** | **85%+** |
| **Circle Navigation & Layout** | `circle_home_navigation.dart`, bottom bar, spaces drawer | — | ✅ 9 tests | ✅ 1 on Pixel 9a | **75%** | **85%+** |
| **Sensory Feedback Sheet** | `belong_feedback_and_voting_sheet.dart` (3 intent cards) | — | ✅ 6 tests | ✅ 1 on Pixel 9a | **80%** | **85%+** |
| **Direct Messages (`Msgs`)** | `belong_messages_view.dart`, conversation threads, unread badge | ✅ 4 tests | ✅ 3 tests | ⏳ Queued | **80%** | **85%+** |
| **Sensory Events Calendar** | `actually_autistic_events_view.dart`, sensory tags, RSVP | ✅ 4 tests | ✅ 3 tests | ⏳ Queued | **80%** | **85%+** |
| **Circle CSV Importer** | `tool/import_circle_csv.dart`, `circle_csv_importer.dart` | ✅ 11 tests | — | — | **92%** | **90%+** |
| **PWA Web & Offline Service Worker** | `web/index.html`, `flutter_service_worker.js` | — | — | ⏳ Patrol Web | *Pending* | **70%+** |

---

## ❓ The "Rest of Coverage" (Things We Have Questions / Edge-Case Notes About)

These are specific edge cases, platform boundaries, and UX behaviors where we need explicit maintainer guidance before locking in permanent test assertions:

### 1. Push Notification Permission Denial (Android 13+)
- **Scenario**: When a member taps "Enable Notifications" or when the app requests `POST_NOTIFICATIONS` runtime permission on Android 13+ (Pixel 9a), what should happen if they tap **"Don't allow"**?
- **Current Assumption**: Fail silently and show an in-app toggle: *"Notifications muted in system settings — tap to open settings"*.
- **Question for Neil**: Does Marty or the community prefer an educational calm prompt explaining *why* notifications exist (e.g. quiet digest once daily), or should we never nag?

### 2. Live Firestore Offline Queueing vs. InMemory Fallback
- **Scenario**: When a member is on an airplane or has zero connectivity, `cloud_firestore` caches reads/writes in local IndexedDB (Web) or SQLite (Mobile).
- **Question**: Should the app indicate *"Working offline — changes will sync when connected"* with a subtle status pill in the top bar, or remain completely quiet ("calm tech")?

### 3. Circle CSV Importer Conflict Resolution
- **Scenario**: A user already signed in via Google Sign-In as `neil@example.com`, but the Circle export contains `neil@example.com` with a slightly different display name (`Neil Warner` vs `Neil J. Warner`).
- **Question**: Should the Circle CSV importer overwrite the local profile, create an alias, or preserve the existing signed-in profile? (Recommended: preserve existing signed-in profile, link Circle historical posts by email).

### 4. PWA Installation Prompt (`BeforeInstallPromptEvent` & Add to Home Screen)
- **Problem Statement**:
  When users access Belong as a Progressive Web App (PWA) on mobile (Android Chrome, iOS Safari) or desktop (Chrome, Edge, Brave), how should installation be offered, detected, and tested without causing sensory disruption or cognitive overload?

- **Browser Platform Behavior Matrix**:
  | Platform / Browser | Native Hook (`beforeinstallprompt`) | Default Browser Behavior | Our Recommended UX Handling |
  | :--- | :---: | :--- | :--- |
  | **Android Chrome / Edge** | ✅ Yes | Shows automatic mini-infobar at bottom unless intercepted via `preventDefault()`. | **Intercept and suppress mini-infobar**. Expose calm opt-in in Member Profile drawer & subtle App Bar chip. |
  | **Desktop Chrome / Edge** | ✅ Yes | Shows omnibox "Install" icon in URL bar. | **Intercept event**, store reference; user can click either omnibox or in-app Profile tile. |
  | **iOS / iPadOS Safari** | ❌ No (WebKit rejects API) | Zero prompt; requires user to tap **Share icon** (`⎋`) ➔ **"Add to Home Screen"**. | Detect iOS WebKit; show an educational step-by-step calm tooltip only if member taps "Install on iOS" in settings. |
  | **Android Firefox / Samsung Internet** | ⚠️ Partial | Address bar badge icon; does not fire standard `beforeinstallprompt` consistently. | Gracefully degrade; rely on browser UI and clear instructions. |

- **Neurodivergent Sensory UX Principles & "Best Guesses"**:
  1. **Strict "Zero-Jank, Zero-Modal" Policy**:
     Never trigger an automatic pop-up dialog, bottom sheet takeover, or layout-shifting banner upon page load or tab navigation. Autistic users visiting the app to check quiet hours or unread messages should never experience attention-hijacking prompts.
  2. **Calm Discovery Surfaces (Two-Touch Opt-In)**:
     - **Primary Surface**: A dedicated tile inside the **Member Profile Drawer / Settings** (`lib/src/features/profile/belong_profile_drawer.dart`):
       - Label: *"Install Sanctuary App (PWA)"*
       - Subtitle: *"Add to home screen for offline calm, fullscreen view, and faster launch."*
       - Tapping triggers `deferredPrompt.prompt()`.
     - **Secondary Surface (Subtle Ambient Chip)**: When `beforeinstallprompt` is active, display a quiet, muted icon button in the top app bar (`Icons.install_mobile_rounded`) with tooltip *"Install App"*. Clicking triggers the prompt once. If dismissed, the icon remains quiet and does not nag.
  3. **Preserve User Choice on Dismissal**:
     If the user dismisses the browser's install dialog (`outcome === 'dismissed'`), store a `pwa_prompt_dismissed_timestamp` in `SharedPreferences`. Do not surface any badge for at least 14 days.

- **Technical Architecture (Flutter 3.47.7 & Dart 3.7+ Interop)**:
  - **Step A (`web/index.html`)**:
    Capture the event and prevent default mini-infobar popup:
    ```javascript
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      window.deferredPwaPrompt = e;
      window.dispatchEvent(new CustomEvent('pwa-prompt-available'));
    });
    window.addEventListener('appinstalled', () => {
      window.deferredPwaPrompt = null;
      window.dispatchEvent(new CustomEvent('pwa-installed'));
    });
    ```
  - **Step B (Dart `PwaInstallService` in `lib/src/features/pwa/`)**:
    Provide a Riverpod service exposing `pwaInstallStateProvider`:
    ```dart
    enum PwaInstallStatus { unavailable, readyToPrompt, installed }
    ```
    With `promptInstall()` invoking `window.deferredPwaPrompt.prompt()` and awaiting user outcome.

- **Automated Verification Strategy (Patrol + Unit Mocks)**:
  1. **Unit / Widget Tier**:
     Mock `PwaInstallService` using `Mocktail` in `test/features/pwa/pwa_install_widget_test.dart`.
     Verify that when status is `readyToPrompt`, the profile tile appears and tapping triggers `promptInstall()`.
  2. **Patrol Native Android Tier (`Pixel 9a`)**:
     Launch Chrome on Pixel 9a via `patrolTest`:
     - Open Chrome with URL `https://belongonthespectrum.web.app`.
     - Verify PWA manifest and service worker registration via Chrome DevTools / native selector.
     - Assert native "Add Belong to Home screen" dialog handling.

---

## 🛠️ Mocktail & Patrol Test Plan for `v0.8.5`

When writing the next tier of tests to elevate coverage from ~55% to 75%–90%:

1. **Mocktail Mock Definitions (`test/mocks/`)**:
   ```dart
   class MockAuthRepository extends Mock implements AuthRepository {}
   class MockFeatureVotingRepository extends Mock implements FeatureVotingRepository {}
   class MockPostRepository extends Mock implements PostRepository {}
   class MockOrganizerRemoteConfigService extends Mock implements OrganizerRemoteConfigService {}
   ```
2. **Patrol Finder Widget Tests (`test/features/`)**:
   - Use `patrolWidgetTest` with `$` selectors:
     ```dart
     patrolWidgetTest('tapping RSVP updates button to Confirmed state', ($) async {
       await $.pumpWidgetAndSettle(const SanctuaryApp());
       await $(#eventsCalendarTab).tap();
       await $(#rsvpButton).first.tap();
       expect($('Sensory RSVP Confirmed'), findsOneWidget);
     });
     ```
3. **Patrol Native PWA Verification**:
   - Use Patrol MCP or CLI to launch Chrome, navigate to `https://belongonthespectrum.web.app`, inspect the DOM tree, and verify PWA service worker installation.
