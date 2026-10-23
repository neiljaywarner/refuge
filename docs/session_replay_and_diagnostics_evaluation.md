# Session Replay & Diagnostics SDK Architectural Evaluation

## Executive Summary
This document provides a comprehensive technical evaluation of session replay and observability SDKs for **Belong on the Spectrum** (Refuge), comparing reputable third-party cloud platforms (PostHog, Sentry, LogRocket, Bugfender) with our built-in zero-cost **Firebase Cloud Storage + Talker** diagnostic bundle architecture.

---

## Evaluation Matrix

| Platform | Free Tier Quotas | Mobile (Android/iOS) | Flutter Web | Privacy / PII Masking | Setup Complexity | Self-Hostable |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Built-in Cloud Storage + Talker** | 5 GB Storage / Unlimited logs (Firebase Spark) | Full Native support | Full Web support | Built-in regex redactor (emails, tokens) | **Zero (Already active)** | Yes (Firebase / Serverpod) |
| **PostHog** (`posthog_flutter`) | **1,000,000 events/mo** + **5,000 replays/mo** | Android & iOS | Web (DOM replay) | Automatic input & text masking | Low (Configured via `--dart-define`) | Yes (Open-source) |
| **Sentry** (`sentry_flutter`) | **5,000 errors/mo** + **50 replays/mo** | Full Mobile Canvas / Wireframe | Full Web | Strict visual masking & opt-in capture | Low (DSN configuration) | Yes (Self-hosted Sentry) |
| **LogRocket** (`logrocket_flutter`) | 1,000 sessions/mo | Web + Android | Web only | Redaction by default | Medium | No (SaaS only) |
| **Bugfender** (`flutter_bugfender`) | 100k log lines/day, 24h retention | Mobile | Web / Mobile | Custom log levels | Low | No |

---

## 1. Built-in Production-Safe Solution (Current Implementation)

### Architecture
- **In-App Engine**: `DiagnosticLogService` + `talker_flutter`.
- **Unique Identifier**: `FirebaseInstallationsService` queries the unauthenticated Firebase Installation ID (`installationsId` / FID).
- **Session Breadcrumbs**: Chronological timeline of navigation routes, community interactions, and error states.
- **Data Scrubbing**: Automatic PII redactor scrubs emails (`[REDACTED_EMAIL]`) and secrets (`token=[REDACTED]`).
- **Cloud Storage Upload**:
  - Compiles `DiagnosticSessionReplay` into structured JSON.
  - Uploads directly to Firebase Cloud Storage bucket (`belongonthespectrum.firebasestorage.app/diagnostics/logs/session_<id>.json`).
  - Generates a shareable URL directly accessible in the Easter Egg dialog and support logs.

### Advantages
1. **Zero Registration Barrier**: Leverages existing Firebase project credentials (`belongonthespectrum`).
2. **Deterministic Privacy**: Guaranteed zero telemetry leaks to third parties; 100% compliant with neurodivergent safe-space principles.
3. **No External App Bloat**: Adds zero unnecessary binary size or background battery drain.

---

## 2. PostHog Evaluation & Recommendation (Top External Choice)

### Why PostHog is Recommended
1. **Extremely Generous Free Tier**: 1,000,000 events/month and 5,000 session recordings/month free forever.
2. **Existing Credentials**: A project token is already provisioned in the user environment:
   ```bash
   export POSTHOG_BELONG_PROJECT_TOKEN="phc_o3EbCUmwutDFNEbnHe8LFUwVTjooVAK2DuZRNM6gUgVU"
   export POSTHOG_BELONG_PROJECT_ID="677583"
   ```
3. **Session Replay Capability**:
   - Replays UI interactions, scroll behaviors, and taps visually.
   - Built-in text and sensitive input masking protects community members.

### Activation Guide (When Ready)
To enable PostHog Session Replay in production builds:
1. Pass the token via `--dart-define`:
   ```bash
   flutter run --dart-define=POSTHOG_KEY=$POSTHOG_BELONG_PROJECT_TOKEN \
               --dart-define=POSTHOG_HOST=https://us.i.posthog.com
   ```
2. Enable session recording in the PostHog project settings:
   - Navigate to `https://us.posthog.com/project/677583/settings/project-recordings`.
   - Toggle **Record user sessions** to `ON`.
   - Verify **Mask all text inputs** is enabled.

---

## 3. Sentry Evaluation

### Why Sentry is a Strong Secondary Choice
1. **Industry Benchmark for Crash Symbols**: Exceptional native stack symbolication across Android NDK and iOS crash dumps.
2. **Session Replay (Mobile & Web)**:
   - Mobile canvas wireframing captures layout structure without transmitting personal text or media.
3. **Drawback**: Free tier includes only 50 session replays per month, which may exhaust quickly under active community testing.

---

## 4. Verification & Testing Checklist

- [x] In-memory fallback and unit test suite passing 100% green.
- [x] PII redaction verified with regex tests for emails and bearer tokens.
- [x] Unique Firebase Installation ID exposed in Easter Egg for troubleshooting without personal user accounts.
- [x] In-App Messaging mobile conditional imports verified with graceful web stub.
- [x] Cloud Storage upload contract integrated into `StorageRepository`.
