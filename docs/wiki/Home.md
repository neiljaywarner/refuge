# 🌱 Welcome to the Belong on the Spectrum & Refuge Wiki

> **Belong on the Spectrum** (powered by Refuge)  
> *A calm, sensory-safe, unhurried community platform for neurodivergent adults, autistic believers, friends, families, and pastoral care ministries.*  
> **Production Live Web**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)  
> **Source Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge)

---

## 🧭 Fast Navigation: Start Here

If you are new to the community or leading a transition from Circle.so, select your role below:

### 🌱 For Community Organizers, Pastors & Leaders
* **Zero coding needed**: You can manage announcements, update guidelines, and welcome members directly without touching terminal code or cloud databases.

| Essential Guide | Who It's For | Key Takeaways |
| :--- | :--- | :--- |
| **[❓ Maintainer & Alpha Tester Questions](Questions-for-Product-Users-and-Alpha-Testers)** | **Community Leadership** | High-level non-technical roadmap, pricing rationale, and FAQs. |
| **[📅 October 31st Circle.so Cutover Plan & 7-Day Overlap](Non-Technical-Roadmap-to-Oct-31)** | **Non-Technical Organizers & Leaders** | How we save **~$1,000+/year** over [Circle.so Pricing](https://circle.so/pricing), why we launch by **Oct 24** for a calm 7-day overlap before **Oct 31**, and what works on Day 1. |
| **[📱 Why No App Store App? (And Why You Don't Need One)](Why-No-App-Store-App)** | **All Members & Disciples** | Empathetic guide with real Pixel 9a screenshots explaining why Belong avoids store passwords, storage bloat, and ad traps. |
| **[📱 PWA Guide: Install on Your Phone & Store Timeline](PWA-Guide-for-Members-and-Organizers)** | **Members & Organizers** | Step-by-step instructions to add Belong to your iPhone/Android Home Screen today + why we can stay on PWA for months before needing Apple/Google stores. |
| **[🎛️ Organizer Control Without Coding (Remote Config)](Organizer-Remote-Config-Guide)** | **Community Organizers** | How to update welcome banners and feature announcements instantly using [Firebase Remote Config](https://firebase.google.com/products/remote-config) ([Watch 3-Min Video](https://www.youtube.com/watch?v=_CXXVFPO6f0)). |
| **[📥 Bringing Over Past Posts (Spreadsheet / CSV Guide)](Circle-CSV-Migration-Guide)** | **Organizers & Volunteers** | Plain-English explanation of how past introductions, prayer requests, and discussions are safely imported from Circle spreadsheets into Belong with zero data loss. |
| **[🏘️ Belong Community Spaces & Guidelines](Belong-Community-Guide)** | **All Community Members** | Tour of our familiar rooms (*Start Here*, *Announcements*, *General Chat*, *Memes*, *Online Resources / Videos*, *Actually Autistic Chat*, *Friends Chat*, *Family Chat*, and *Links*). |
| **[🧪 Manual Testing & UAT Playbook ("How Can I Help Test?")](Manual-Testing-and-UAT-Flows)** | **Community Testers & Organizers** | Complete, non-technical step-by-step checklist to test Belong across Web PWA, Android, and iOS — zero coding knowledge required! |
| **[🌿 Calm Technology & Sensory Safety](Calm-Tech-and-Accessibility)** | **Members & Designers** | Why Belong has zero autoplay video, predictable navigation, literal feedback cards, and neurodivergent-affirming design. |
| **[🌸 Calm Notifications: Member & Product Guide](Notifications-Product-Guide)** | **All Members & Leaders** | Unhurried notification batching, quiet hours, gentle interaction badges, and eliminating sensory notification overload. |

---

## 🛠️ Engineering, Architecture & Mentoring Portals

| Technical Resource | Summary |
| :--- | :--- |
| **[⭐ App Review Sentiment Audit, Competitive Benchmark & PWA/Mobile Star Rating UX](App-Review-Sentiment-Audit-and-Action-Plan)** | Findings from our 60-review Circle audit & 20-review Belong audit, our custom 1–5 Star + 3-Intent UX for PWA/Web/Mobile (#386), and the December v1.0 Android/iOS launch runbook (#385). |
| **[🎨 Circle Post Creation Pattern & Calm Improvements](Circle-Post-Creation-Pattern-Improvement)** | Benchmarks Circle.so's `+` creation pattern, confirms strengths, and details calm-tech upgrades (intent tags, alt-text, autosave). |
| **[⚙️ Android APK vs. Web PWA Technical Breakdown](Android-APK-vs-Web-PWA-Details)** | Comprehensive comparison of FCM channels vs Web Push, SQLite vs IndexedDB, cold starts, and WorkManager. |
| **[🧭 UX Evaluation & Architecture Decision Records (ADRs 0001–0010)](UX-Evaluation-and-ADRs)** | Complete index of architectural ADRs, repository seams, and the calm-tech feedback model. |
| **[⚖️ Backend Strategy: Appwrite Core + Firebase Edge (ADR-0009)](Backend-Migration-Strategy-Serverpod-Appwrite-Firebase)** | Graded proposal only. Live posts are still Serverpod. Firestore is the second copy. Appwrite is not on `main` ([PR #412](https://github.com/neiljaywarner/refuge/pull/412)). |
| **[🔔 Calm Notifications Architecture (ADR-0010)](ADR-0010-Notifications-Local-Awesome-vs-FCM)** | Hybrid local notifications + silent background FCM payloads to prevent auditory startle and sensory overload. |
| **[🔔 Notifications Technical Architecture & State](Notifications-Technical-Architecture)** | In-app bell and Riverpod state. The launcher-dot MethodChannel has no native handler. Device matrix [#411](https://github.com/neiljaywarner/refuge/issues/411) is open. |
| **[🗄️ Backend & Database Architecture](Backend-and-Database-Architecture)** | Under-the-hood map of Firestore collections (`users`, `posts`, `feedback`), indexes, security rules, and Serverpod RPC mapping. |
| **[📡 Dual Observability & Diagnostics](Observability-Crashlytics-Analytics-and-Diagnostics)** | Dual-channel error reporting across Firebase Crashlytics & Analytics (cloud) and Talker ring buffers (100% offline fallback) with automated PII scrubbing. |
| **[🎓 Engineering Lessons Learned & Accomplishments](Engineering-Lessons-Learned-and-Accomplishments)** | Public-safe reference on physical device glass testing (Pixel 9a), zero-PII discipline, and token quota routing. |
| **[🎓 Apprentice, Mentee & Free-Tier Token Optimization Guide](Apprentice-and-Token-Optimization-Guide)** | How students and mentees use `hooks_riverpod`, CodeWithAndrea architecture, git worktrees, BDD, and smart AI model routing without burning LLM token quotas. |
| **[📿 Agent Harness 2.0 & Token Quota Preservation](Agent-Harness-and-Token-Orchestration)** | Multi-model quota preservation, subagent orchestrator topology, beads execution DAG, and local 48GB Mac fallback. |
| **[🤝 Contributor Guide & Ticket-Driven Workflow](Contributor-Guide)** | How to pick an issue, spin up a worktree branch, run tests locally, and open a clean Pull Request (`1 Issue = 1 Worktree = 1 PR`). |
| **[🧪 QA, BDD & Beta Testing Guide](QA-and-Beta-Testing-Guide)** | How we verify every release with Gherkin BDD widget tests, Marionette MCP, and Patrol MCP on physical hardware. |
| **[🛠️ Refuge CLI Developer Tool](Refuge-CLI)** | Pure-Dart CLI helper (`tool/refuge_cli.dart`) for CodeRabbit-gated merges, privacy scans, and wiki publishing. |
| **[🏋️ Weeknights Low-Touch Execution Plan](weeknights_week_of_oct19th.md)** | Daily 5–10 minute human check-in protocol allowing autonomous agents to deliver milestones while maintainers attend to health & gym. |

---

## 🏛️ Historical Archives & Early Prototypes

These documents preserve early hackathon explorations and initial proof-of-concept prototypes for historical reference:
* **[📜 Early Fellowship Rooms (Prototype 1)](User-Journeys-and-Fellowship-Rooms)** — Initial 4-room prototype concept preceding the Circle.so parity layout.
* **[📜 Early Calm-Tech Standard (Prototype 1)](Product-Vision-and-Calm-Tech)** — Early 5-pillar manifesto.
* **[📜 Dual Pixel Hardware LTE Demo (Serverpod Hackathon)](Dual-Pixel-Cloud-Demo)** — Original multi-device testing over Serverpod Cloud and T-Mobile LTE.
* **[📜 Serverpod Architecture Deep Dive](Serverpod-Architecture-Deep-Dive)** — Initial Serverpod server configuration.
* **[📜 Appwrite vs. Serverpod Initial Evaluation](Migrate-to-Appwrite-Evaluation)** — Initial exploration notes preceding ADR-0009.
* **[📜 Screenshot & Video Planning Document](Plan-for-Videos-and-Screenshots)** — Initial visual media capture strategy.