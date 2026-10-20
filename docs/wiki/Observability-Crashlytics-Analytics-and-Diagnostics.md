# 📡 Observability: Firebase Crashlytics, Analytics & Serverpod Diagnostics

> **Audience**: Maintainers, Mentors, Contributors & Community Organizers  
> **Repository Link**: [`docs/OBSERVABILITY_AND_ANALYTICS.md`](https://github.com/neiljaywarner/refuge/blob/main/docs/OBSERVABILITY_AND_ANALYTICS.md)  
> **Source Code**: [`lib/src/core/observability/error_reporter_service.dart`](https://github.com/neiljaywarner/refuge/blob/main/lib/src/core/observability/error_reporter_service.dart)

---

## 💡 Why Dual-Observability Matters
When deploying a community application for neurodivergent adults, **reliability and calm responsiveness are paramount**:
- Silent failures or unresponsive buttons cause intense friction and disorientation.
- Cloud tools (Firebase) can be blocked by firewalls or offline conditions.
- By providing **dual observability**, maintainers can verify telemetry in the cloud *or* completely offline on their laptop via local Talker/Serverpod logs. At least one channel is guaranteed to work!

---

## 🛠️ Step-by-Step Inspection Guide

### Checking Local Diagnostics (Zero Setup Required)
1. Run the app in development mode:
   ```bash
   flutter run -t lib/main_dev.dart
   ```
2. Watch the terminal output:
   - 🚨 `[ErrorReporter FATAL]`: Indicates an unhandled Flutter or asynchronous error.
   - ⚠️ `[ErrorReporter HANDLED]`: Indicates a handled exception gracefully recovered from.
   - 📤 `[Serverpod RPC]` / 📡 `[WebSocket EVENT]`: Network telemetry.

### Checking Firebase Crashlytics & Analytics
1. Open [Firebase Console](https://console.firebase.google.com).
2. Select the `belongonthespectrum` project.
3. For crash analysis:
   - Click **Quality -> Crashlytics**.
   - Review stack traces symbolicated against native debug symbols.
4. For user interaction telemetry:
   - Click **Analytics -> Events**.
   - Monitor `app_error`, `space_navigated`, `feedback_submitted`, and `vote_toggled`.

---

## 🔒 Security & Privacy Guarantee
All logs pass through client-side regex sanitization before transmission:
- No real member email addresses appear in Crashlytics issues.
- Auth session tokens and headers are replaced with `[SCRUBBED_SECRET]`.
- Complies fully with strict community privacy standards.
