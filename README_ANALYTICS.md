# Multi-Vendor Analytics & Telemetry Architecture: Refuge

Refuge employs a **3-tiered, privacy-hardened, zero-PII telemetry pipeline**:

1. **Firebase Analytics (Google Analytics 4 & DebugView)**: Ecosystem telemetry and Play Store conversion tracking.
2. **Aptabase (Open-Source Privacy-First Analytics)**: Lightweight, zero-cookie, transparent event metrics.
3. **PostHog (Product Analytics & Session Insights)**: Funnel analysis, retention cohorts, and user journey tracking.
4. **Serverpod Telemetry Backup**: In-memory ring buffer for resilient offline fallback.

---

## 🔒 Zero-Secret Architecture

API keys and tokens are **never** committed to git repositories. They are injected at compile time or launch time via `--dart-define`:

| Variable | Environment Var (`~/.zshrc`) | Dart Define Parameter | Fallback |
| :--- | :--- | :--- | :--- |
| **Aptabase App Key** | `APTABASE_BELONG_KEY` | `--dart-define=APTABASE_KEY=...` | Safe In-Memory Mock |
| **PostHog Project Token** | `POSTHOG_BELONG_PROJECT_TOKEN` | `--dart-define=POSTHOG_KEY=...` | Safe In-Memory Mock |
| **PostHog Ingestion Host**| `POSTHOG_HOST` | `--dart-define=POSTHOG_HOST=...` | `https://us.i.posthog.com` |

When keys are omitted or empty (e.g. in unit tests or open-source community contributor builds), `CommunityAnalyticsService` automatically falls back to **in-memory recording and Talker debug logs** without throwing network or SSL errors.

---

## ⚡ Fire-and-Forget `unawaited` Dispatch

All network calls to Firebase, Aptabase, and PostHog are wrapped in `dart:async`'s `unawaited(...)`:
- UI interactions and widget frame rates remain 100% fluid at 120Hz/60Hz.
- Network latency or intermittent offline states never block community interactions.
- Errors are gracefully captured and recorded to `Talker` logger.

---

## 🚀 Running with Telemetry

### Option 1: VS Code Launch Profiles (`.vscode/launch.json`)
Open the **Run & Debug** pane in VS Code / Antigravity IDE and pick:
- **Refuge (Dev with Analytics)**
- **Refuge (Pixel 1 - Dev)**
- **Refuge (Pixel 2 - Dev)**
- **Refuge (Medium Phone Emulator)**
- **Refuge (Web Chrome - Dev)**

### Option 2: Flutter CLI
```bash
flutter run \
  --dart-define=APTABASE_KEY=$APTABASE_BELONG_KEY \
  --dart-define=POSTHOG_KEY=$POSTHOG_BELONG_PROJECT_TOKEN \
  --dart-define=POSTHOG_HOST=https://us.i.posthog.com
```

Product events stay off when those defines are omitted ([#410](https://github.com/neiljaywarner/refuge/issues/410)).

---

## 📊 Real-Time Verification Procedures

### 1. Firebase Analytics DebugView (Instant Streaming)
By default, Firebase Analytics batches events on mobile devices for up to 1 hour. To see events in **DebugView** within 2–5 seconds on Android:

```bash
adb shell setprop debug.firebase.analytics.app com.belongonthespectrum.sanctuary
adb shell setprop log.tag.FA VERBOSE
adb shell setprop log.tag.FA-SVC VERBOSE
```
Inspect logs live:
```bash
adb logcat -v time -s FA FA-SVC flutter
```

### 2. Aptabase Dashboard
1. Open [Aptabase Console](https://aptabase.com).
2. Select your Belong project (`A-US-1296849393`).
3. Events appear in Real-time under **Events** within 5–10 seconds.

### 3. PostHog
Debug launch profiles already pass `POSTHOG_KEY` and `APTABASE_KEY` from the shell. Release and web builds now forward the same names from the process environment (`tool/deploy_release.dart`, `tool/deploy_dev_web.dart`, and `.github/workflows/deploy.yml`). Empty secrets stay in mock mode. Calm view events also send an anonymous `$pageview` companion so PostHog web analytics can see traffic. Distinct ids stay `belong-anon-<flavor>`. Session replay stays off until [#367](https://github.com/neiljaywarner/refuge/issues/367). [Issue #410](https://github.com/neiljaywarner/refuge/issues/410) tracks the remaining ingest check after the next keyed deploy.

---

## 🤖 MCP Servers Integration (`.agents/mcp_config.json`)

To query analytics and Firebase resources directly via AI agents:

```json
{
  "mcpServers": {
    "firebase": {
      "command": "/opt/homebrew/bin/firebase",
      "args": ["mcp", "--dir", "."]
    },
    "posthog": {
      "command": "/opt/homebrew/bin/npx",
      "args": ["-y", "@posthog/mcp-server"],
      "env": {
        "POSTHOG_API_KEY": "${POSTHOG_BELONG_PROJECT_TOKEN}",
        "POSTHOG_HOST": "https://us.i.posthog.com"
      }
    }
  }
}
```

---

## 🔐 GitHub Actions Secrets Note (For Future CI Deployments)
When deploying web builds or running automated release pipelines via GitHub Actions, add the following secrets to repository settings (`https://github.com/neiljaywarner/refuge/settings/secrets/actions`):
- `APTABASE_KEY`: `$APTABASE_BELONG_KEY`
- `POSTHOG_KEY`: `$POSTHOG_BELONG_PROJECT_TOKEN`
- `POSTHOG_HOST`: `https://us.i.posthog.com`
