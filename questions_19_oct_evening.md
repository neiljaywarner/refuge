# ❓ Questions & Decisions for Neil & Organizers (October 19 Evening)

> **Context**: Compiled during repository audit and milestone verification on Monday, October 19, 2026.  
> **Linked Review**: [`human_to_review_after_session.md`](human_to_review_after_session.md)  
> **Status**: Open for maintainer input before October 31 cutover.

---

### 1. Circle.so CSV Data Migration Cutover (`#41`)
- **Background**: The pure-Dart CLI importer (`tool/import_circle_csv.dart`) is built, tested with 11 unit tests, and verified with `--dry-run`. All 8 canonical spaces (`start_here`, `announcements`, `general_chat`, `memes`, `resources_videos`, `actually_autistic_chat`, `friends_chat`, `family_chat`) map cleanly.
- **Questions**:
  1. **Staging vs. Direct Prod**: When Marty provides the raw Circle.so export ZIP, do you want us to run the import into `dev` Firestore first for organizer sign-off, or directly into `prod` (`belongonthespectrum.com`)?
  2. **Account Linking Strategy**: When importing past posts from `member@example.com`, should we create "unclaimed member profiles" in Firestore so when that member signs in with Google using that same email, their past reflections automatically attach to their account?

---

### 2. ICOC Church Affiliation Badge Placement (`#93`)
- **Background**: Per Marty's SMS spec, the required question *"Which ICOC church do you attend?"* (with the explicit *"I am not a member of an ICOC church"* option) is live in the Member Profile Sheet and Members Directory.
- **Questions**:
  1. Should the church affiliation badge (e.g. `⛪ DFW Church` or `🌱 Welcoming Visitor`) also be displayed next to author names on **Reflection Cards in the main Feed**, or should it remain strictly inside the **Members Directory and Profile Sheet** to keep the feed visual noise low?
  2. Does Marty want any additional congregations added to the default dropdown list beyond `DFW Church`, `Austin Christian Church`, `Boston Church of Christ`, and `Greater Long Beach Church`?

---

### 3. Push Notifications & Calm Permission Defaults (`ADR-0010`, `#53`)
- **Background**: Firebase Cloud Messaging (`firebase_messaging`) is prepared for Android, iOS, and Web PWA.
- **Questions**:
  1. If a member taps "Don't allow" on the Android 13+ permission dialog, should the app remain completely silent and never mention notifications again, or show a gentle toggle in the Spaces drawer (*"Notifications muted in system settings"* for those who want to re-enable later)?
  2. For the "Quiet Daily Digest", what default time of day is calmest for the community? (e.g., 7:00 PM evening wind-down vs. 9:00 AM morning anchor).
- **Decision & TL;DR Guidance (Maintainer Consensus)**:
  - **Spaces Drawer Gentle Toggle**: Show a gentle toggle in the Spaces drawer (*"Notifications muted in system settings"*) allowing members who initially tapped "Don't allow" to comfortably re-enable notifications later without nagging popups or pressure.
  - **Quiet Daily Digest Default**: 7:00 PM evening wind-down summary.

---

### 4. Telemetry & Error Reporting Consolidation (`#86`, `#293`)
- **Background**: Dual/triple observability is active across Firebase Crashlytics, Firebase Analytics, and local Serverpod/Talker ring buffers with automated PII regex scrubbing.
- **Question**:
  1. Once the October 31 cutover is stable, should we consolidate strictly onto Firebase Crashlytics + Analytics, or migrate error logs to self-hosted Appwrite Functions / PostHog?
- **Decision & TL;DR Guidance (Maintainer Consensus)**:
  - **Keep Firebase Crashlytics**: Crashlytics has zero ingestion quotas on the free Firebase Spark plan and provides unrivaled native Android (NDK/JVM) and iOS symbolication and crash aggregation that no general-purpose tool can match.
  - **Adopt PostHog for Analytics & User Journeys**: Use PostHog for product telemetry, sensory mode adoption, and navigation funnels. PostHog provides generous free quotas (1M events/month), session replay, and privacy-preserving self-hosting options.
  - **Appwrite Functions Role & Status**: Appwrite Functions are serverless compute runtimes (executing Dart/Node/Python functions in response to webhooks or cron). Because **Serverpod** already serves as our primary Dart backend, ORM, and database interface, introducing Appwrite Functions solely for error ingestion would duplicate infrastructure. We will rely on Serverpod's PostgreSQL ring buffer as the self-hosted fallback.
  - **Architecture Reference**: Detailed comparison documented in [`Observability-Crashlytics-Analytics-and-Diagnostics.md`](docs/wiki/Observability-Crashlytics-Analytics-and-Diagnostics.md#post-october-31-telemetry-architecture-analysis-issue-293) and tracking Issue [#293](https://github.com/neiljaywarner/refuge/issues/293).

---

### 5. Local Offline LLM Setup for 48GB Apple Silicon (`#92`, `#271`, `#272`)
- **Background**: With 48GB unified RAM, ~36GB VRAM is comfortably available for local GPU inference via Metal shaders with zero cloud token limits.
- **Question**:
  1. Shall we proceed with installing Ollama (`brew install ollama`) and pulling `qwen2.5-coder:32b` (~20GB VRAM) for local offline coding fallbacks when you return to your terminal?
- **Decision & Implementation Plan (Maintainer Consensus)**:
  - **Yes, approved with two distinct phases**:
    - **Phase 1 (Completed in `#271` / PR `#273`)**: Turnkey shell installer (`tool/setup_ollama.sh`), Metal health check CLI (`tool/verify_ollama.dart`), and getting started guide ([`Local-LLMs-Phase-1-Getting-Started.md`](docs/wiki/Local-LLMs-Phase-1-Getting-Started.md)) targeting `qwen2.5-coder:14b` and `qwen2.5-coder:32b`.
    - **Phase 2 (Tracked in `#272`)**: Heuristic task routing ("How do we know when to use Ollama wisely vs cloud models?"), benchmark suite (`tool/benchmark_local_llm.dart`), and multi-model quota preservation.
