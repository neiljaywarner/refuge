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
