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

---

## 📊 Post-October 31 Telemetry Architecture Analysis (Issue #293)

### The Core Architectural Question
> *"Once the October 31 cutover is stable, should we consolidate strictly onto Firebase Crashlytics + Analytics, or migrate error logs to self-hosted Appwrite Functions / PostHog?"*

### Maintainer Recommendation & Decision
1. **Retain Firebase Crashlytics indefinitely**:
   - **Zero Free Tier Bill Shock**: Crashlytics ingestion has no event caps on the Firebase Spark (free) plan.
   - **Native Device Diagnostics**: Crashlytics provides automatic native symbol mapping (ProGuard/R8 mapping files on Android, dSYMs on iOS), NDK crash unwinding, battery/thermal telemetry, and background crash grouping across physical hardware (Pixels, iPhones). Neither PostHog nor generic serverless functions replicate native mobile crash symbolication.
2. **Adopt PostHog for Product Analytics & Sensory Funnels**:
   - **Product Insight**: PostHog is purpose-built for user session paths, conversion funnels (e.g. `reflection_published`, `sensory_theme_changed`, `vote_cast`), and cohort analysis.
   - **Privacy & Autonomy**: PostHog provides generous cloud tiers (1M events/month free) with one-click export or self-hosted deployment on Docker/Kubernetes.
   - **Action**: Keep Google Analytics as a baseline, but use PostHog (`POSTHOG_KEY`) as our primary deep product analytics collector.
3. **Appwrite Functions Role Assessment**:
   - **What are Appwrite Functions?** Appwrite Functions are containerized serverless runtimes (similar to AWS Lambda or Google Cloud Functions) executing code snippets (Node, Dart, Python, PHP, Ruby) triggered by HTTP requests, cron schedules, or database events.
   - **Why Serverpod Already Fulfills This Role**: Belong on the Spectrum is built natively with **Serverpod** as its backend architecture. Serverpod endpoints, database models, and streaming sockets are written in 100% typed Dart. Deploying Appwrite Functions strictly as a secondary log ingestion webhook would introduce operational fragmentation, double maintenance, and redundant container overhead.
   - **Conclusion**: We will not introduce Appwrite Functions for error logging. Instead, Serverpod's PostgreSQL `error_log` table and client ring buffer will remain our self-hosted, zero-quota telemetry fallback.

### Technology Comparison Matrix

| Capability | Firebase Crashlytics | Firebase Analytics | PostHog | Appwrite Functions | Serverpod Backup (Existing) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Primary Focus** | Native fatal & non-fatal crash symbolication | High-level user journeys & Google Ads/Play attribution | Product funnels, session analytics, feature flags | Serverless event-driven compute | Typed Dart RPC, ORM, streaming & ring buffers |
| **Pricing & Quota** | **100% Free** on Spark plan (no event ingestion limits) | **100% Free** (unlimited reporting, 500 event types) | **1M events/mo free**; self-hostable | Depends on compute; self-hostable | **Included in Serverpod VPS** ($5-10/mo flat) |
| **Mobile Symbolication** | **Superior** (NDK, ProGuard, dSYM automated uploads) | N/A | Basic JS/Flutter sourcemaps (requires manual API) | None (must build custom symbolicator) | Dart stack trace string preservation |
| **Privacy / PII** | Closed cloud; relies on client scrubbing | Closed cloud | Open-source, GDPR-compliant, EU or self-hosted | Open-source, self-hosted | 100% owned PostgreSQL database |
| **Recommended Verdict** | **Keep as primary crash reporter** | **Keep as passive baseline** | **Adopt for feature & sensory analytics** | **Defer / Unnecessary with Serverpod** | **Retain as offline & server fallback** |

---

## 🚀 Post-October 31 Implementation Roadmap
- [x] Client-side Talker ring buffer with PII regex scrubbing ([`error_reporter_service.dart`](https://github.com/neiljaywarner/refuge/blob/main/lib/src/core/observability/error_reporter_service.dart)).
- [x] Passive dual-reporting to Serverpod backup stream ([`serverpod_telemetry_backup.dart`](https://github.com/neiljaywarner/refuge/blob/main/lib/src/core/observability/serverpod_telemetry_backup.dart)).
- [x] Dedicated CLI inspection utility ([`tool/review_telemetry.dart`](https://github.com/neiljaywarner/refuge/blob/main/tool/review_telemetry.dart)).
- [ ] Connect PostHog Flutter SDK (`posthog_flutter`) using `--dart-define=POSTHOG_KEY=...` for production sensory usage tracking.
- [ ] Evaluate long-term archiving of Serverpod error buffer into self-hosted Grafana / Loki if community member count exceeds 10,000 active members.
