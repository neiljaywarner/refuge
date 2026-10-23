# 📡 Observability, Analytics & Crash Reporting Architecture

> **Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge)  
> **Primary Components**: `ErrorReporterService`, `CommunityAnalyticsService`, `Talker`  
> **Key ADRs**: [ADR-0006](docs/adr/0006-flavor-configuration-and-build-matrix.md), [ADR-0007](docs/adr/0007-neurodivergent-first-ux-and-feedback-evaluation.md), [ADR-0010](docs/wiki/ADR-0010-Notifications-Local-Awesome-vs-FCM.md)  
> **Status**: Production & Alpha Ready (`v0.8.1+`)

---

## 🎯 Architecture Overview: Dual/Triple-Observability

Belong on the Spectrum employs a **fail-safe dual-channel telemetry model**:
1. **Cloud Observability (Firebase Crashlytics & Analytics)**:
   - Symbolicated crash logs on Android (`Google Pixel 9a`) and iOS.
   - Real-time privacy-preserving event stream (`app_error`, `space_navigated`, `feedback_submitted`, `reflection_published`).
2. **Local / Fallback Observability (Serverpod & Talker Ring Buffer)**:
   - Operates **100% offline with zero cloud credentials required**.
   - Accessible to developers in local terminals via Talker CLI output and to automated tests via `recordedErrorsForTesting`.
   - Guaranteed visibility even if Firebase is disabled, unconfigured, or blocked by local firewalls.

```
                   ┌────────────────────────────────────────┐
                   │        Application Exception           │
                   │  (FlutterError.onError / root onError) │
                   └───────────────────┬────────────────────┘
                                       │
                        ┌──────────────▼──────────────┐
                        │    ErrorReporterService     │
                        │    (Strict Zero-PII Regex)  │
                        └───────┬──────────────┬──────┘
                                │              │
            ┌───────────────────┴────────┐     └────────────────────────┐
            ▼                            ▼                              ▼
 ┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
 │ Firebase Crashlytics │    │  Firebase Analytics  │    │  Talker & Diagnostic │
 │  (Symbolicated crash │    │   (Categorized event │    │  Ring Buffer / Local │
 │   logs on devices)   │    │      telemetry)      │    │  Serverpod fallback) │
 └──────────────────────┘    └──────────────────────┘    └──────────────────────┘
```

---

## 🔍 Where to Check Telemetry Under the Hood

### 1. In Real Time on Local Machine (Guaranteed to Work Offline)
- **Talker Console**: When running `flutter run` or `refuge_cli.dart`, all errors and warning traces are color-coded in stdout with structured context.
- **In-Memory Diagnostic Buffer**:
  ```dart
  final errorReporter = container.read(errorReporterServiceProvider);
  final errors = errorReporter.recordedErrorsForTesting;
  // Each error contains: timestamp, flavor, error, reason, fatal, stack, sanitized context
  ```
- **Talker UI Monitor**: Debug builds can mount `TalkerScreen` to inspect recorded network requests and exceptions interactively without connecting external profilers.

### 2. In Firebase Console (Cloud Telemetry)
- **Crashlytics**: Navigate to `Firebase Console -> Quality -> Crashlytics`. Filter by App Flavor (`dev` vs. `prod`).
- **Analytics Events**: Navigate to `Firebase Console -> Analytics -> Events` or `DebugView` during testing to observe events in real time.

---

## 🛡️ Strict Zero-PII Sanitization

`ErrorReporterService` guarantees no member personal identifiers or credentials leave the client device:
- **Email Addresses**: Automatically scrubbed to `[SCRUBBED_EMAIL]` via RFC-compliant regex matching.
- **Auth Tokens & Secrets**: Any parameter containing `token`, `password`, `key`, or `secret` is replaced with `[SCRUBBED_SECRET]`.
- **Reason Strings**: Truncated to a safe maximum length (`takeFirst(100)`) to prevent buffer overflows or unintended leakages.

---

## 🧪 Verification & Automated Testing

Observability logic is strictly verified with unit tests in `test/features/observability/error_reporter_service_test.dart`:
- Records handled non-fatal exceptions and logs to analytics.
- Captures unhandled fatal exceptions gracefully.
- Verifies automatic PII scrubbing on sample payloads containing emails and Bearer tokens.

---

## ⚖️ Post-Cutover Architecture Analysis: Crashlytics vs. PostHog vs. Appwrite Functions (Issue #269)

### 1. Executive Summary & The Core Question
> *"Once the October 31 cutover is stable, should we consolidate strictly onto Firebase Crashlytics + Analytics, or migrate error logs to self-hosted Appwrite Functions / PostHog?"*

**The TL;DR Answer**:
- **Keep Firebase Crashlytics** for all mobile fatal crashes, native NDK exceptions, and ANRs. It is free, maintenance-free, and irreplaceable for native mobile symbolication.
- **PostHog is not live product analytics yet.** A smoke event was ingested. The app does not send product events unless `POSTHOG_KEY` or `POSTHOG_BELONG_PROJECT_TOKEN` is passed at build time ([#410](https://github.com/neiljaywarner/refuge/issues/410)). Product conversion analytics are not live.
- **Use Appwrite Functions for Backend Automation, NOT Crash Logging**. Appwrite Functions are serverless compute workers (like AWS Lambda); they cannot capture low-level native OS crashes and introduce an unnecessary self-hosting failure risk if used for telemetry ingestion.

---

### 2. Side-by-Side Architectural Matrix

| Capability / Dimension | Firebase Crashlytics | PostHog (Cloud / Self-Hosted) | Appwrite Functions (Self-Hosted / Cloud) |
| :--- | :--- | :--- | :--- |
| **Primary Purpose** | Real-time crash diagnostics, ANRs, native stacktraces | Product analytics, user journey funnels, retention | Event-driven serverless compute (backend workers) |
| **Native Crash Symbolication** | 🏆 **Best-in-Class**: Automated dSYM & ProGuard/R8 deobfuscation | ⚠️ Web/JS source maps only; basic mobile exception tracing | ❌ **None**: No native mobile crash symbolication engine |
| **Low-Level Crash Capture** | ✅ Captures C++/NDK segfaults, OOM kills, and OS terminations | ⚠️ Only catches handled Flutter/Dart runtime errors | ❌ Only logs if the client successfully completes an HTTP POST |
| **Product Funnels & UX Insights** | ❌ Poor (GA4 is cumbersome, slow, and sampled) | 🏆 **Best-in-Class**: 1-click funnels, paths, and retention graphs | ❌ None (Requires custom SQL/schema development) |
| **Maintenance Burden** | 🟢 **Zero**: Fully managed Google Cloud infrastructure | 🟢 **Zero** (on Cloud free tier) to 🟡 **Moderate** (if self-hosted) | 🔴 **High**: Requires Docker, server maintenance, and backups |
| **Cost Profile** | 🆓 **100% Free** (unlimited crash reports on Spark/Blaze) | 🆓 **1 Million events/month free** | 💲 Host server costs ($5–$20/mo) + disk storage for logs |

---

### 3. Understanding Appwrite Functions: What Are They?

**Appwrite Functions** are isolated, containerized execution environments running on top of Docker. They allow developers to execute custom code in response to:
1. **HTTP Requests**: Calling a REST or GraphQL webhook endpoint.
2. **Database Events**: Automatically executing when a document is created or updated in Appwrite Database.
3. **Cron Schedules**: Running recurring jobs (e.g., every morning at 9:00 AM).

#### ❌ Why Appwrite Functions Should NOT Be Used for Mobile Crash Reporting:
1. **Startup Crash Blindness**: If the Flutter engine crashes on cold start (e.g. native library load failure or corrupted asset), Dart code never executes, meaning no HTTP call to your Appwrite Function will ever be dispatched.
2. **Obfuscated Stack Traces**: Production Android release builds are obfuscated with R8; iOS release builds use dSYMs. Crashlytics automatically maps obfuscated memory addresses (`at a.b.c(Unknown Source:12)`) back to human-readable code (`at MemberProfileDialog.save(member_profile_dialog.dart:84)`). Appwrite Functions have no built-in deobfuscation engine.
3. **Single Point of Failure (SPOF)**: If your self-hosted Appwrite server experiences high load or restarts, incoming crash logs are permanently dropped. In contrast, Crashlytics buffers crash reports on device flash memory and uploads them automatically upon network reconnect.

#### ✅ Where Appwrite Functions Excel in Belong on the Spectrum:
- **Calm Digest Batching (ADR-0010)**: A scheduled Appwrite Function executing at 9:00 AM & 6:00 PM local time to aggregate unread discussions and dispatch the batch push payload.
- **Weekly Community Summaries**: Generating plain-text email digests for senior members or parents who prefer email over mobile apps.
- **Automated Data Maintenance**: Purging temporary preview media, pruning rate-limit counters, or syncing backups.

---

### 4. Recommended Post-Cutover Telemetry Architecture

```
                                  Belong Client Application (Flutter)
                                                  │
                 ┌────────────────────────────────┼────────────────────────────────┐
                 │                                │                                │
                 ▼                                ▼                                ▼
    [ Fatal & Native Crashes ]       [ User Funnels & Product UX ]    [ Scheduled Backend Automation ]
                 │                                │                                │
                 ▼                                ▼                                ▼
       Firebase Crashlytics                    PostHog                     Appwrite Functions
     (Symbolicated stacktraces,          (Sensory theme usage,           (Cron-triggered 9 AM & 6 PM
      ANRs, zero maintenance,             room discovery funnels,         calm digests, email summaries,
      100% free forever)                  1M events/month free)           database maintenance)
```

By following this clean division of responsibilities, Belong on the Spectrum achieves enterprise-grade reliability and zero vendor lock-in without incurring unnecessary server maintenance costs.
