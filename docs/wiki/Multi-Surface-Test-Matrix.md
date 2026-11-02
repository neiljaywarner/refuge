# Multi-Surface & Multi-Build Test Matrix (`test_matrix.md`)

> **Belong on the Spectrum Engineering Verification Standard**
> **Current Version**: Updated for `v0.9.6` (Reaction Toggle & Attribution) & `v0.9.7` (Bruce QA-Ready Production Release)
> **Authoritative Locations**:
> - Local Workspace: `/Users/neil/belongonthespectrum/test_matrix.md`
> - Repo Docs: `refuge/docs/test_matrix.md`
> - Public Wiki: `refuge/docs/wiki/Multi-Surface-Test-Matrix.md` (Auto-synced to GitHub Wiki)

---

## 1. Executive Purpose & Scope

To ensure every release (`v0.9.5`, `v0.9.6`, `v0.9.7`) functions flawlessly without visual defects, performance drops, or auth/data regressions, Belong on the Spectrum is validated across **8 distinct platform surfaces** and **7 core functional scenarios** before any cut to production.

```
                      ┌──────────────────────────────────────────────┐
                      │    Belong Multi-Surface Verification Core    │
                      └──────────────────────┬───────────────────────┘
                                             │
      ┌──────────────────┬───────────────────┼───────────────────┬──────────────────┐
      ▼                  ▼                   ▼                   ▼                  ▼
┌───────────┐      ┌───────────┐       ┌───────────┐       ┌───────────┐      ┌───────────┐
│ Pixel 9a  │      │ Firebase  │       │ Android   │       │ Localhost │      │ Live Dev  │
│ Hardware  │      │ Release   │       │ Chrome    │       │ PWA /     │      │ Preview   │
│ Debug APK │      │ APK       │       │ WebAPK    │       │ Desktop   │      │ Channel   │
└───────────┘      └───────────┘       └───────────┘       └───────────┘      └───────────┘
```

---

## 2. The 8 Validated Surfaces & Environments

| ID | Surface / Target | Identifier / Package / URL | How It Is Executed & Driven | Primary Invariants Verified |
| :---: | :--- | :--- | :--- | :--- |
| **S1** | **Physical Pixel Hardware (Debug APK)** | Pixel 9a `58221JEBF20835` / `56091JEBF14039`<br>`com.belongonthespectrum.refuge.dev` | `flutter run -d 58221JEBF20835 --flavor dev`<br>Driven via **Maestro MCP** & **Patrol MCP** | Instant hot-reload, native platform channel bindings, memory leaks, touch responsiveness |
| **S2** | **Physical Pixel Hardware (Release APK)** | Firebase App Distribution<br>`com.belongonthespectrum.refuge.dev` | Distributed via `tool/deploy_dev_web.dart --flavor dev`<br>Tested on real Pixel 9a | Release code shrinking (R8/ProGuard), release signing, startup cold-launch time (< 1.5s) |
| **S3** | **Android Standalone WebAPK (Installed PWA)** | Installed PWA from Chrome<br>Standalone display mode | Chrome Menu -> "Install Belong" or "Add to Home Screen"<br>Driven via Maestro Chromium / Marionette | Zero browser URL bar, splash screen rendering, Web Push service worker registration, home screen icon clarity |
| **S4** | **Mobile Chrome Browser (Live Web)** | Google Chrome on Pixel 9a<br>`https://dev-belongonthespectrum--walk-*.web.app` | Open URL in Chrome mobile<br>Maestro MCP `inspect_screen` & `take_screenshot` | Viewport scaling, touch target sizes (>= 48x48dp), mobile bottom navigation bar clearance |
| **S5** | **Localhost Web PWA** | `http://localhost:8080` (or `http://127.0.0.1:8080`)<br>Port-forwarded: `adb reverse tcp:8080 tcp:8080` | `flutter run -d chrome --web-port 8080`<br>Driven via Marionette MCP & Playwright | Rapid cycle UI iteration, Chrome DevTools network throttles (Slow 3G, Offline), local state inspection |
| **S6** | **Live Dev Hosting Preview Channel** | `https://dev-belongonthespectrum--walk-v0-9-5-erkolayd.web.app`<br>Dev Target: `dev-belongonthespectrum.web.app` | Firebase Hosting ephemeral preview channel (`firebase hosting:channel:deploy walk-*`) | ETag caching, CORS headers, `/version.json` payload match, Firestore security rules enforcement |
| **S7** | **Production Web Target** | `https://belongonthespectrum.web.app` | Production Hosting deploy (`deploy_release.dart --version v0.9.7 --prod`) | Multi-tenant isolation, CDN edge caching, SEO calm meta tags, production Google Analytics / PostHog |
| **S8** | **iOS Mobile Safari PWA (Standalone & Browser)** | Mobile Safari (iOS 16.4+ standalone)<br>Emulated via Chrome Device Mode (iPhone 14/15 Pro) | Chrome Device Mode + WebKit inspection | Safe area insets (Dynamic Island / Notch), iOS bottom home indicator clearance, Giphy REST/JS fallback |

---

## 3. The 7 Core Verification Scenarios (Release Audit Checklist)

Every release candidate must pass all 7 scenarios across the target surfaces:

### Scenario 1: Reactions Single-Toggle & "Who Reacted" Attribution (#838 / #839)
- [ ] **Single Toggle Enforced**: Tapping a care reaction (🫂 Praying, 🤝 Support, 😄 Relatable, ✨ Encouraged) increments by exactly 1 and visibly highlights the button with filled tonal accent.
- [ ] **Untoggle / No-Spam**: Tapping that same reaction a second time decrements by 1 and unhighlights the button. Repeated tapping never allows spam increments (> 1 per member).
- [ ] **"Who Reacted" Sheet**: Tapping or long-pressing the reaction count surfaces `ReactionDetailsSheet` displaying avatar initials and display names of all reacting members.
- [ ] **Empty / Multi-User States**: Correctly displays "1 person prayed" vs "Neil, Carina, and 2 others prayed".

### Scenario 2: Direct Messages, "Who's Here" Directory & Group DMs (#818)
- [ ] **Real Directory**: "Who's Here" displays real fellowship members (no dummy placeholder names). Banned or unlisted profiles are cleanly excluded.
- [ ] **Multi-Select Compose**: Tapping member checkboxes allows selecting 2–5 recipients.
- [ ] **Named Group Conversations**: Creating a group DM allows assigning a custom group name (e.g., *Parents Prayer Circle*).
- [ ] **Sender Attribution**: In group threads, speech bubbles display the sender's display name above the message.
- [ ] **Durable Replies**: Replies persist to Firestore (`sendReply()`) and reload immediately upon refresh.

### Scenario 3: Outbox Durability & Offline Resilience (#804)
- [ ] **Offline Composition**: Composing a reflection while network is disconnected saves locally with `PostPublishStatus.pending`.
- [ ] **Reconnection Sync**: When network reconnects, background outbox flushes to Firestore and updates status to `confirmed`.
- [ ] **Zero Data Loss**: Closing or reloading the app during offline status never discards draft or pending posts.

### Scenario 4: Sensory Themes, Contrast & Soundscapes
- [ ] **4 Theme Switching**: Smooth switching between `Clean` (light), `Sage` (warm neutral), `Dark` (calm night), and `Contrast` (WCAG AAA high contrast).
- [ ] **Reading Scale**: Text scaling slider (0.85x to 1.3x) adjusts typography without clipping or RenderFlex overflow.
- [ ] **Audio Soundscapes**: Nature sound generator (Rain, Forest, Ocean) streams cleanly with audio asset caching and emergency pause.

### Scenario 5: Vote & Feedback Bridge + Screen Scribble (#808 / #811)
- [ ] **Curated Feature Voting**: Members can upvote roadmap items; voting semantics are idempotent.
- [ ] **Screen Scribble Markup**: Member feedback sheet allows drawing calm annotations over the screen.
- [ ] **Honest Error Handling**: If network is unavailable during submit, displays honest inline error banner without silent data drops.

### Scenario 6: Auth State Transitions & Account Gate (#807)
- [ ] **Calm Guest Onboarding**: First visit prompts for friendly display name; instant access to community rooms without high-friction forms.
- [ ] **Email Sign-In**: Credentialed login seamlessly links existing profile, bookmarks, and direct messages.
- [ ] **Security Token Refresh**: Appwrite and Firebase JWTs refresh silently without interrupting active reading.

### Scenario 7: Organizer Administration & Ban Enforcement (#804 / #807)
- [ ] **Admin Verification**: Live Firestore `rules_admins/{uid}` validates organizer privilege.
- [ ] **Circle-Style Soft Ban**: Banned UIDs are immediately added to `banned_uids`, blocking further writes, hiding active posts, and excluding them from direct message suggestions.

---

## 4. Automation & Tooling Execution Commands

### 1. Static Analysis & Sound Null Safety (Tier 1)
```bash
# Must return 0 errors, 0 warnings
dart analyze --fatal-infos refuge/lib/ refuge/test/ refuge/tool/
```

### 2. Fast Widget & BDD Regression Test Suite (Tier 4)
```bash
# Runs full unit, BDD widget, and Patrol finders suite in < 15 seconds
flutter test refuge/test/features/messages/
flutter test refuge/test/features/reflections/
flutter test refuge/test/features/feedback/
```

### 3. Physical Device Driving via Maestro MCP (Tier 6)
```bash
# Discover connected hardware
maestro devices

# Execute sanity flow on Pixel 9a
maestro test .maestro/sanity_flow.yaml --device 58221JEBF20835

# Capture clean-framed zero-PII screenshot
/Users/neil/belongonthespectrum/refuge/tool/capture_device.sh screenshot /tmp/pixel9a_screen.png
```

### 4. Ephemeral Web Preview Deploy & Verification (Tier 7)
```bash
# Deploy ephemeral preview channel for live verification
dart refuge/tool/deploy_dev_web.dart --channel walk-v0-9-6

# Verify HTTP status and version payload
curl -s -i https://dev-belongonthespectrum--walk-v0-9-6-*.web.app/version.json | grep '"git_sha"'
```

---

## 5. Session Release Sign-Off Matrix

| Release Candidate | Target Audience | Primary Focus | Sign-Off Criteria | Status |
| :---: | :--- | :--- | :--- | :--- |
| **`v0.9.5`** | Neil & Carina (Walk Preview) | DM Groups, Who's Here Directory, live `rules_admins` | 15/15 tests green, live dev URL HTTP 200 | **SHIPPED & VERIFIED** |
| **`v0.9.6`** | Internal Beta (Dev Channel) | 1-Reaction Toggle (#838) & Who Reacted Sheet (#839) + Should-Fix | Zero reaction spam, Who Reacted sheet verified on Pixel 9a | **IN-PROGRESS (SOON)** |
| **`v0.9.7`** | Bruce (QA Playtest) + Prod | 7-Hr CodeRabbit audit triage, doc cleanup, Giphy iOS PWA | CodeRabbit 0 blockers, prod URL `belongonthespectrum.web.app` | **SCHEDULED (7 HRS)** |
