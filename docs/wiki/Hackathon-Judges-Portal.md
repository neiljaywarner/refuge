# 🏆 Hackathon Judges Portal — Sanctuary (Refuge)

> **Evaluator Quick Links**:
> * **Live Web App**: [https://refuge4serverpodhackathon.web.app](https://refuge4serverpodhackathon.web.app)
> * **Serverpod Cloud API**: [`https://refuge4serverpod.api.serverpod.space/`](https://refuge4serverpod.api.serverpod.space/)
> * **Serverpod Cloud Landing**: [`https://refuge4serverpod.serverpod.space/`](https://refuge4serverpod.serverpod.space/) *(HTTP 200, Run mode: `production`)*
> * **Serverpod Insights**: [`https://refuge4serverpod.insights.serverpod.space/`](https://refuge4serverpod.insights.serverpod.space/)
> * **GitHub Release v0.1.0**: [Download APK & Videos](https://github.com/neiljaywarner/refuge4serverpod/releases/tag/v0.1.0)
> * **Automated Test Suite**: `flutter test` (20/20 passing in <4 seconds)

---

## 🎯 Scoring Rubric Alignment (100% Total)

### 1. Does It Work? (30%) — *Flawless, Live, and Multi-Platform*
* **Production Cloud Deployment**: The server is live on **Serverpod Cloud (`scloud`)**, backed by a managed PostgreSQL 16 database and Redis cache.
* **Dual Physical Hardware Verification**: Proven on two real **Google Pixel 9a** smartphones operating across **T-Mobile LTE** with screen-recorded real-time exchanges ([Left Pixel MP4](https://github.com/neiljaywarner/refuge4serverpod/releases/download/v0.1.0/sanctuary_pixel_left_scloud.mp4) • [Right Pixel MP4](https://github.com/neiljaywarner/refuge4serverpod/releases/download/v0.1.0/sanctuary_pixel_right_scloud.mp4)).
* **Resilient 800ms Fallback Moat**: The client is engineered with an offline-first architecture. If network connectivity drops or the cloud server is unreachable, the app seamlessly switches to seeded local data within 800ms without crashing, stuttering, or displaying error dialogs.
* **Zero Console / Analyzer Errors**: 0 issues found on `flutter analyze` and `dart analyze`.

### 2. Serverpod Stack (25%) — *Deep, Idiomatic Full-Stack Dart*
* **Protocols Defined via SPI (`.spy.yaml`)**:
  * `ReflectionPost.spy.yaml`: Custom model with fields for `authorName`, `spaceKey`, `intentTag`, `specialInterestTag`, timestamps, and 4 qualitative affirmation counters. Includes composite btree index `space_created_idx` over `("spaceKey", "createdAt")`.
  * `QuietDigest.spy.yaml`: Domain aggregation entity capturing `totalReflections`, `totalCareAffirmations`, `predominantIntent`, `featuredSpecialInterest`, and `summaryMessage`.
* **ReflectionEndpoint (`reflection_endpoint.dart`)**:
  * `publishReflection`: Validates against calm-tech standards (rejects hostile urgency keywords like `urgent`, `asap`, `click here`), commits to PostgreSQL, and broadcasts to real-time WebSocket channels.
  * `affirmCare`: Atomically increments qualitative care reactions (`praying`, `standingWith`, `peace`, `encouraged`, `relatable`) directly in PostgreSQL.
  * `watchSpace`: Implements Serverpod streaming via `session.messages.createStream('space_$spaceKey')`.
  * `getQuietDigest`: Server-side SQL query computing aggregate metrics for peaceful community posture without tracking vanity counts.
* **Automatic Migrations**: Database migrations managed through Serverpod tooling (`migrations/20261014065523421`) and executed during container startup via `--apply-migrations`.

### 3. Craft & User Experience (25%) — *Sensory Accessibility & Calm-Tech*
* **4 WCAG AAA Sensory Modes**:
  * *Sage Botanical*: Calming organic green for nervous system soothing.
  * *Clean Slate*: Minimalist neutral for sensory clarity.
  * *Monastic Dark*: Low blue-light dark mode for evening reflection.
  * *High Contrast*: Black/yellow/white maximum visual legibility.
* **Zero-Badge Architecture**: No red notification dots, no unread badge counters, and no dopamine loops. Content waits patiently; users are never prompted to rush.
* **Belong on the Spectrum Anchor**: Honors the God-given design of autistic believers (*"Fearfully and wonderfully made"* — Psalm 139:14), providing badging for Special Interests (trains, theology, coding, biology) and Autism & Faith Memes.
* **BuilderBase & Serverpod Credits**: Integrated About dialog accessible with one click in the top bar.

### 4. Usefulness & Impact (20%) — *Solving Real-World Problems*
* **Replacing $1,500/Year SaaS**: Mainstream community tools (Circle, Mighty Networks, Discord) charge small faith communities $89–$130/month. Sanctuary replaces this high overhead with low-cost Serverpod compute (<$5/month).
* **Serving an Overlooked Community**: Autistic disciples of Jesus frequently experience sensory overload in conventional church platforms. Sanctuary provides a genuine spiritual refuge.

---

## 🧪 How to Verify Live Endpoints

### Option A: Interactive In-App Verification
1. Open the live web app at [https://refuge4serverpodhackathon.web.app](https://refuge4serverpodhackathon.web.app).
2. Tap the **About (`ℹ️`)** button in the top right to verify release metadata and BuilderBase credits.
3. Switch spaces (`#prayer-sanctuary`, `#weekly-study`, `#special-interests`) to observe space-specific reflections and Quiet Digest aggregation banners.
4. Toggle across all 4 sensory themes (`Clean`, `Sage`, `Dark`, `Contrast`).
5. Compose an unhurried reflection and tap **Publish Reflection** to write directly to Serverpod Cloud.

### Option B: Run the Pre-Configured Dart Client Script
You can query the live Serverpod Cloud backend directly via Dart:
```bash
git clone https://github.com/neiljaywarner/refuge4serverpod.git
cd refuge4serverpod/sanctuary_server/sanctuary_server_client
dart run bin/test_cloud.dart
```
**Expected Output**:
```text
Testing connection to Serverpod Cloud API...
SUCCESS: Received prayer_care digest: {"__className__":"QuietDigest","spaceKey":"prayer_care", ...}
SUCCESS: Published post with ID: <id>
```

### Option C: Run the Full Test Suite
```bash
flutter test
```
**Result**: 20/20 unit, widget, and BDD feature tests pass in ~4 seconds.

---

## 🤖 Section 4 AI & Agentic Tooling Disclosure

In full compliance with **Section 4 of the Serverpod Hackathon Rules**:
* **Autonomous AI Architecture**: Neil Warner directed the architecture, product identity, and testing requirements using Google Antigravity (Advanced Agentic Pair-Programming Assistant).
* **Ticket-Driven Development (TDD)**: Every single change was mapped to a tracked GitHub issue (#1 through #7), developed on an isolated feature branch, validated against automated unit/BDD tests, and merged via conventional squash pull requests.
* **Human Oversight**: Neil personally directed the Belong on the Spectrum positioning, biblical anchoring (Psalm 139:14), mobile device test harness, and video validation.
