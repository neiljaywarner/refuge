# 🔌 Serverpod Deprecation, Teardown & $0/Mo Cost Savings Guide

> **Issue Reference**: [#383: refactor(backend): Serverpod deprecation roadmap, turn-off checklist & greeting_endpoint removal](https://github.com/neiljaywarner/refuge/issues/383)  
> **Related Issue**: [#384: feat(backend): Appwrite migration architecture, client provider and MCP tooling integration](https://github.com/neiljaywarner/refuge/issues/384)  
> **Target Cost**: **\$0.00/month** (Eliminate \$5.00/mo Serverpod Cloud billing before the 20-day renewal)

> **Not started (22 October 2026).** Do not run this teardown for the overlap week. Serverpod is still the default post backend. Cloud Firestore is still the second copy. Appwrite has not replaced either. The opt-in client seam is [PR #412](https://github.com/neiljaywarner/refuge/pull/412) and stays off unless both `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` are set. That pull request is not merged. The Flutter package name is still `refuge4serverpod` ([#233](https://github.com/neiljaywarner/refuge/issues/233)).

---

## 1. Executive Summary & Readiness Assessment

| Metric | Evaluation | Rationale |
| :--- | :---: | :--- |
| **Likelihood of Success** | **98% (Extremely High)** | Belong already has dual-redundancy with Firestore, in-memory repositories, and repository abstraction interfaces (`PostRepository`, `CommentRepository`, `FeatureVotingRepository`). |
| **Estimated LOE** | **4 – 8 Hours** | Low effort. All business logic and UI widgets interact exclusively with Riverpod repository interfaces, never with raw Serverpod client instances. |
| **Current Cloud Cost** | **\$5.00 / month** | Serverpod Cloud starter cluster subscription renewing in ~20 days. |
| **Post-Teardown Cost** | **\$0.00 / month** | Firebase Free Spark Tier + Local/Appwrite Free Tier. |
| **Target Audience** | Junior Devs & LLMs | Every step below is structured with copy-pasteable commands and verification checks. |

---

## 2. Architecture Decoupling: How Belong Avoids Vendor Lock-In

Belong uses the **Abstract Repository Pattern** via Riverpod:

```
[UI Widgets: HomeScreen, SpacesView, ReflectionCard]
                         │
                         ▼
             [postRepositoryProvider]
                         │
       ┌─────────────────┼─────────────────┐
       ▼                 ▼                 ▼
[ServerpodPostRepo] [LocalPostRepo]  [AppwritePostRepo]
  (WebSocket stream)  (Firestore +     (Appwrite Realtime
   Active in v0.8      offline cache)   Planned v0.9)
```

By toggling `--dart-define=ENABLE_SERVERPOD=false` or `--dart-define=BACKEND=local`, the Flutter application completely skips Serverpod client initialization, WebSocket subscriptions, and cloud telemetry.

---

## 3. Step-by-Step Junior Developer & LLM Execution Plan

Follow these 5 atomic subtasks in exact sequence:

### Subtask 1: Run the App in Serverpod-Free Mode
Verify that the mobile app, web build, and test suites run 100% without Serverpod Cloud:
```bash
# Mobile / Simulator run with Serverpod disabled:
flutter run --dart-define=ENABLE_SERVERPOD=false --dart-define=BACKEND=local

# Web release build with Serverpod disabled:
flutter build web --release --dart-define=ENABLE_SERVERPOD=false --dart-define=BACKEND=local
```
**Verification**: Check app console logs. You should see:
```text
[ANALYTICS] Running in local/firestore offline fallback mode.
Serverpod WebSocket connection skipped (--dart-define=ENABLE_SERVERPOD=false).
```

### Subtask 2: Verify Offline-First Firestore Synchronization
1. Open the app on Android device or emulator (`emulator-5554` or Pixel).
2. Compose a new reflection in the `Prayer & Support` space.
3. Verify that the post appears immediately in the reactive list.
4. If Firebase is configured, verify the post is synced to Firestore collection `reflections_dev` or `reflections`.
5. Run the automated test suite:
```bash
flutter test test/features/reflections/post_repository_factory_test.dart
```

### Subtask 3: Cancel Serverpod Cloud Subscription & Delete Project
Before the 20-day billing cycle renews:
1. **Via Serverpod Cloud Web Console**:
   - Navigate to [https://console.serverpod.cloud](https://console.serverpod.cloud).
   - Select project `refuge4serverpod`.
   - Go to **Settings** -> **Billing & Subscription**.
   - Click **Cancel Subscription** and confirm.
   - Select **Danger Zone** -> **Delete Project**.
2. **Via Serverpod CLI (`scloud`)**:
   ```bash
   scloud project list
   scloud project delete --project refuge4serverpod
   ```

### Subtask 4: Clean Up Repository & Dependencies
Once Serverpod Cloud is torn down:
1. In `pubspec.yaml`, remove the local path dependency:
   ```yaml
   # REMOVE THIS LINE:
   # sanctuary_server_client:
   #   path: sanctuary_server/sanctuary_server_client
   ```
2. In `lib/src/features/reflections/data/post_repository_factory.dart`, set `defaultValue: 'local'`:
   ```dart
   const backend = String.fromEnvironment('BACKEND', defaultValue: 'local');
   ```
3. Move `sanctuary_server/` to `archive/sanctuary_server/` or remove from version control (historical commits will preserve it indefinitely).

### Subtask 5: Verification & Pre-Merge Audit
Run full automated validation to guarantee zero regressions:
```bash
# 1. Run all repository and reflection tests:
flutter test test/features/reflections/

# 2. Run static analysis:
flutter analyze lib/ test/
```

---

## 4. Rollback Plan
If for any reason Serverpod needs to be restored:
1. Change `--dart-define=ENABLE_SERVERPOD=true` or `--dart-define=BACKEND=serverpod`.
2. Ensure `SERVERPOD_URL` points to the active cluster URL.
3. Serverpod client gracefully re-attaches to the WebSocket endpoint.
