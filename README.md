# ♾️ Refuge — Powering Belong on the Spectrum

> *"I praise you because I am fearfully and wonderfully made."* — **Psalm 139:14**  
> **Current Release**: **`v0.9.5-rc` (Release Readiness Gate)** · **Live Web & PWA**: **[`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)**  
> **First Community**: **[Belong on the Spectrum](https://www.belongonthespectrum.com/)** (partnered with **[DFW Church](https://dfwchurch.org)**)  
> **Circle.so Overlap Window**: **October 24 – October 31, 2026** · **Final Cutover**: **Saturday, October 31, 2026**

---

## 🔗 Quick Executive & Engineering Links
- 📱 **[Real Device Driving & Maestro Automation (`docs/real_device_driving_and_automation.md`)](docs/real_device_driving_and_automation.md)**: Real hardware fleet (Pixel 9a, Pixel 8, emulator), Maestro MCP Server, live screen viewer (`http://127.0.0.1:9999/`), and Patrol BDD tests.
- 🧠 **[Community Leader & Pastoral Brainstorms (`docs/wiki/Community-Leader-Brainstorms.md`)](docs/wiki/Community-Leader-Brainstorms.md)**: Thoughtful calm-tech design trade-offs, church affiliation badge placement (Feed vs. Directory), notification cadence, and autistic-first norms ([Issue #265](https://github.com/neiljaywarner/refuge/issues/265)).
- 🚀 **[Release Readiness Gate & Progress Dashboard (`#261`)](https://github.com/neiljaywarner/refuge/issues/261)**: Real-time and async launch gate covering Web, PWA (WebAPK), Android APK, and documentation synchronization.
- 📣 **[Circle Migration Overlap Welcome Post (`docs/circle_migration_invitation_post.md`)](docs/circle_migration_invitation_post.md)**: Ready-to-copy announcement post for Circle.so to initiate the Oct 24–31 overlap week ([Issue #249](https://github.com/neiljaywarner/refuge/issues/249)).
- 📊 **[Circle App Store Review Learnings (`docs/benchmarks/circle_app_store_review_learnings.md`)](docs/benchmarks/circle_app_store_review_learnings.md)**: Competitive sentiment audit, pitfalls to avoid (notification spam, webview latency, back-stack bugs), and beloved patterns to replicate.
- 🧭 **[Careful Maestro Driving Guide (`docs/benchmarks/circle_maestro_driving_guide.md`)](docs/benchmarks/circle_maestro_driving_guide.md)**: Non-destructive, read-only device discovery on Google Pixel 9a (`so.circle.circle`) with Zero-PII clean-framing protocol.
- 🎨 **[Golden Testing & Visual Regression Guide (`docs/wiki/Golden-Testing-and-Visual-Regression-Guide.md`)](docs/wiki/Golden-Testing-and-Visual-Regression-Guide.md)**: Headless font loading (`TestFontLoader`), Martin Fowler sociable widget goldens, and pixel-fidelity regression verification.
- 📋 **[Maintainer Review After Session (`human_to_review_after_session.md`)](human_to_review_after_session.md)**: Executive breakdown of Milestones, Live Releases, ADRs (`0001`–`0010`), and verified device metrics.
- 📡 **[Observability & Analytics (`docs/OBSERVABILITY_AND_ANALYTICS.md`)](docs/OBSERVABILITY_AND_ANALYTICS.md)**: Dual/Triple-observability across Firebase Crashlytics/Analytics & local Serverpod/Talker diagnostics.
- 🗄️ **[Backend & Database Architecture (`docs/DATABASE_ARCHITECTURE.md`)](docs/DATABASE_ARCHITECTURE.md)**: Under-the-hood map, Firestore collection schemas (`users`, `posts`, `feedback`), indexes, security rules, and Serverpod RPC mapping.
- 🎓 **[Engineering Lessons Learned & Accomplishments](docs/wiki/Engineering-Lessons-Learned-and-Accomplishments.md)**: Mentee reference covering real device testing, MCP tooling, and zero-PII architecture.
- 🌙 **[Unattended Session Execution Plan & LLM Troubleshooting (`unattended_session_908pm.md`)](unattended_session_908pm.md)**: Live Mini-Milestones tracker, FAQ, and zero-stall troubleshooting guide for lighter LLMs.
- 🚀 **[Deployment & Release Runbook (`DEPLOYMENT.md`)](DEPLOYMENT.md)**: 1-command pure-Dart release pipeline (`tool/deploy_release.dart`) for `belongonthespectrum.web.app`, Firebase Hosting Preview Channels, and GitHub Releases.
- 📿 **[Agent Harness 2.0 & Token Quota Preservation (`docs/AGENT_HARNESS_AND_ORCHESTRATION.md`)](docs/AGENT_HARNESS_AND_ORCHESTRATION.md)**: Multi-model quota routing, orchestrator-subagent topology, beads state DAG, and local 48GB Mac fallback.
- ⚖️ **[ADR-0009: Serverpod → Appwrite Core + Firebase Edge Hybrid Strategy](docs/adr/0009-piece-by-piece-vs-one-shot-appwrite-firebase-hybrid.md)**: Graded comparison (**A+ / `9.7/10`**) of Piece-by-Piece vs. One-Shot migration and permanent Firebase Hosting/FCM/Audiences coexistence.

---

## 🌟 About Belong on the Spectrum & Refuge

**Refuge** is an open, white-labelable, calm-technology community platform built with **Flutter**, **Riverpod (`hooks_riverpod`)**, **Serverpod** (default post backend), **Cloud Firestore** (second copy), and **Firebase** edge services. Appwrite is on `main` ([PR #412](https://github.com/neiljaywarner/refuge/pull/412), `fc71fd4`) and stays off unless both `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` are set. It has not replaced Serverpod. [#384](https://github.com/neiljaywarner/refuge/issues/384) is not closed. The Flutter package name is still `refuge4serverpod` ([#233](https://github.com/neiljaywarner/refuge/issues/233)).

Its flagship community is **[Belong on the Spectrum](https://www.belongonthespectrum.com/)** — a welcoming Christian & neurodivergent/autistic fellowship community.

### Key Features
- **Familiar Circle.so-Style Navigation**:
  - **Top Bar**: Official **Belong** cross & gold neurodiversity infinity (`∞`) logo in the upper-left, **"Feedback & Vote"** pill + Sensory Theme switcher + **Member Profile Avatar** in the upper-right, and **`Feed`** | **`Spaces`** selector below the logo.
  - **Spaces Hierarchy**:
    - 📌 **Pinned**: `General Chat`
    - 👋 **Welcome**: `Start Here & Introduce Yourself`, `Announcements`
    - 🤝 **Community**: `General Chat`, `Memes`, `Online Resources / Videos`, `Actually Autistic Chat`, `Friends Chat`, `Family Chat`
    - 📅 **Actually Autistic**: `Actually Autistic Events`
    - 🔗 **Links**: `Community Guidelines`, `DFW Church` (`dfwchurch.org`), `Download the Android App`, `Download the iOS App`
  - **4-Tab Bottom Navigation Bar**: `Feed`, `Spaces`, `Search`, and `Msgs`.
- **Neurodivergent-First Feedback & 1-Tap Feature Voting (`ADR-0007`)**:
  - Literal 3-Intent Cards (💚 *Works Great*, 💡 *Idea / Tweak*, 🛠️ *Bug / Confusing*) + 1-Tap Feature Voting Board backed by pluggable `InMemory`, `Serverpod`, `Appwrite`, and `Firebase` repository adapters (`ADR-0009`).
- **Non-Technical Organizer Control (`Firebase Remote Config`)**:
  - Community organizers can update the **"Message from the Organizer"** welcome card, announcements, and store links anytime from the Firebase Console without code changes.
- **4 Neurodivergent-Affirming Sensory Themes (WCAG AAA)**:
  - *High Clarity*, *Warm Calm*, *Low Stimulus Dark*, and *Low Motion* (zero surprise pop-ups or auto-playing media).

---

## 📚 Documentation & Wiki Portals (`docs/wiki/`)

| Guide | Audience | Description |
| :--- | :--- | :--- |
| **[🧠 Leadership & Pastoral Brainstorms](docs/wiki/Community-Leader-Brainstorms.md)** | **Pastors & Organizers** | Open design questions: church badge placement (Feed vs. Directory), calm notification digests, and icebreaker prompts. |
| **[📅 Oct 31 Circle.so Cutover Schedule](docs/wiki/Non-Technical-Roadmap-to-Oct-31.md)** | **Organizers & Pastors** | Plain-English day-by-day schedule from Oct 18 to Oct 31, 2026 (final day of Circle.so subscription). |
| **[⚖️ Backend Migration & Hybrid Grading (ADR-0009)](docs/wiki/Backend-Migration-Strategy-Serverpod-Appwrite-Firebase.md)** | **Engineers & Architects** | Why Appwrite Core (Auth/DB/Realtime) + Firebase Edge (Hosting/FCM/Audiences) scores **A+ (`9.7/10`)**, and Piece-by-Piece vs. One-Shot grading. |
| **[🛠️ Refuge CLI (`tool/refuge_cli.dart`)](docs/wiki/Refuge-CLI.md)** | **Engineers & Mentees** | `ship-pr` (CodeRabbit-gated merges), `privacy-scan`, `sync-wiki`, exit codes & FAQ. Run `dart run tool/refuge_cli.dart help`. |
| **[🚀 Deployment & Release Runbook](DEPLOYMENT.md)** | **Engineers & Release Ops** | Pure-Dart deployment script (`tool/deploy_release.dart`) + `week1` Audio MP3 Release Notes roadmap. |
| **[📣 Organizer Remote Config Guide](docs/wiki/Organizer-Remote-Config-Guide.md)** | **Organizers & Leaders** | How to edit the *"Message from the Organizer"* banner without needing a developer. |
| **[📱 PWA & App Store Guide](docs/wiki/PWA-Guide-for-Members-and-Organizers.md)** | **Members & Organizers** | How members install Belong to their iPhone/Android Home Screen in 10 seconds. |
| **[🗄️ Backend & Database Architecture](docs/DATABASE_ARCHITECTURE.md)** | **Engineers & Organizers** | Under-the-hood map, Firestore collection schemas (`users`, `posts`, `feedback`), indexes, security rules, and Serverpod RPC mapping. |
| **[🤝 Contributor Guide](docs/wiki/Contributor-Guide.md)** | **Volunteers & Developers** | How to contribute via Ticket-Driven Development (`1 Issue = 1 Worktree = 1 PR`). |
| **[🎓 Student, Mentee & Apprentice Guide](docs/wiki/Apprentice-and-Token-Optimization-Guide.md)** | **Students & Mentees** | Clean architecture walkthrough, BDD testing, pure-Dart CLI tools (`tool/refuge_cli.dart`), and **Free-Tier AI Token Optimization**. |
| **[🤖 Local LLMs & Token Quota Preservation Strategy](docs/wiki/Local-LLMs-and-Token-Quota-Preservation.md)** | **Engineers & AI Agents** | Hardware benchmarks (48GB Apple Silicon unified RAM), Ollama + Qwen 2.5 Coder 32B/14B setup, and mechanical task delegation taxonomy. |
| **[📿 Agent Harness 2.0 & Token Quota Preservation](docs/wiki/Agent-Harness-and-Token-Orchestration.md)** | **Engineers & Mentees** | Preserving Gemini Pro weekly caps, Flash subagent delegation, beads execution DAG, and local 48GB Mac Ollama fallback. |

---

## 🛠️ Quick Start & One-Command Deployment

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis & BDD/widget test suite
dart analyze
flutter test

# 3. Deploy to Firebase Preview Channel + Live Production (https://belongonthespectrum.web.app)
dart run tool/deploy_release.dart --version v0.8.0-alpha --channel v0-8-0-alpha --prod --github-release
```
