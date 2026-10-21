# 📡 Observability: Firebase Crashlytics, Analytics & Serverpod Diagnostics

> **Audience**: Maintainers, Mentors, Contributors & Community Organizers  
> **Repository Link**: [`docs/OBSERVABILITY_AND_ANALYTICS.md`](https://github.com/neiljaywarner/refuge/blob/main/docs/OBSERVABILITY_AND_ANALYTICS.md)  
> **Source Code**: [`lib/src/core/observability/error_reporter_service.dart`](https://github.com/neiljaywarner/refuge/blob/main/lib/src/core/observability/error_reporter_service.dart)  
> **Backup Service**: [`lib/src/core/observability/serverpod_telemetry_backup.dart`](https://github.com/neiljaywarner/refuge/blob/main/lib/src/core/observability/serverpod_telemetry_backup.dart)  
> **Review Script**: [`tool/review_telemetry.dart`](https://github.com/neiljaywarner/refuge/blob/main/tool/review_telemetry.dart)

---

## 💡 Why Dual / Triple Observability Matters
When deploying a community application for autistic and neurodivergent adults, **reliability and calm responsiveness are paramount**:
- Silent failures or unresponsive buttons cause intense friction and sensory disorientation.
- Cloud tools (Firebase) can be blocked by corporate firewalls, DNS filters, or offline subway conditions.
- By providing **triple-destination observability**, telemetry is never lost:
  1. **Firebase Crashlytics**: Native crash symbolication & fatal error aggregation.
  2. **Firebase Analytics**: Sane default user journey & conversion funnel tracking (`app_error`, `space_viewed`, `sensory_theme_changed`, `vote_cast`).
  3. **Serverpod & Local Ring Buffer**: Continuous fallback telemetry stream with FIFO eviction and local offline inspection via `tool/review_telemetry.dart`.

---

## 🛠️ Step-by-Step Inspection & Audit Guide

### 1. Fast CLI Telemetry Review (Zero Setup)
Run the dedicated pure-Dart telemetry review utility:
```bash
dart run tool/review_telemetry.dart --simulate-error --simulate-event
```
Outputs:
- Active flavor (`DEV` or `PROD`).
- Simulated conversion funnels (`space_viewed`, `sensory_theme_changed`, `vote_cast`).
- Simulated handled exceptions and fatal crash reports.
- Formatted ring buffer dump with timestamps, parameter maps, and sanitized stack traces.

### 2. Live Serverpod & Local Diagnostics
When running the Flutter app locally or in dev mode:
```bash
flutter run -t lib/main_dev.dart
```
Watch the console stream for real-time tags:
- 🚨 `[ErrorReporter FATAL]`: Indicates an unhandled Flutter or asynchronous exception.
- ⚠️ `[ErrorReporter HANDLED]`: Indicates a handled exception gracefully recovered from.
- 📡 `[Serverpod Backup Analytics]`: Mirrored user journey events.
- 🚨 `[Serverpod Backup Crash]`: Mirrored crash payloads.

### 3. Firebase Console Inspection
1. Open the [Firebase Console](https://console.firebase.google.com/project/belongonthespectrum/overview).
2. **Crash Analysis**:
   - Navigate to **Quality → Crashlytics**.
   - Inspect active crash-free user percentages (target: >99.5%).
   - Review stack traces symbolicated against native debug symbols.
3. **Analytics & Funnels**:
   - Navigate to **Analytics → Events**.
   - Monitor conversion funnels: `space_viewed`, `sensory_theme_changed`, `vote_cast`, `feedback_intent_selected`, `reflection_published`.

### 4. On-Device 7-Tap Observability Easter Egg
To verify Crashlytics and Serverpod error reporting directly on physical hardware (e.g. Google Pixel 9a):
1. Launch Belong on the Spectrum.
2. Rapidly tap the **Belong logo in the top app bar 7 times**.
3. An administrative dialog opens with buttons to:
   - Trigger a **Handled NFE (Non-Fatal Exception)**.
   - Trigger a **Fatal Crash** test.
   - View the active in-memory Talker & Serverpod ring buffer logs.

---

## 🔒 Security & Privacy Guarantee (Zero-PII)
All logs pass through client-side regex sanitization before transmission:
- Member email addresses are replaced with `[SCRUBBED_EMAIL]`.
- Auth session tokens and headers are replaced with `[SCRUBBED_SECRET]`.
- Complies strictly with community privacy rules (`.agents/rules/open_public_repo_zero_pii.md`).
