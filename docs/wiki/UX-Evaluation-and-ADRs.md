# 🧭 UX Evaluation & Architecture Decision Records (ADRs)

*Last Updated: October 18, 2026 (`2026-10-18T19:55:00-05:00`)*

This page provides a transparent record of our **User Experience (UX) evaluations** and **Architecture Decision Records (ADRs)**. All canonical ADR markdown files live in the repository under [`docs/adr/`](https://github.com/neiljaywarner/refuge/tree/main/docs/adr).

---

## 🧠 Featured UX Evaluation: Simplifying Selah's Feedback & Voting System for Neurodivergent Community Members (ADR-0007)

### 1. Context & Inspiration (`selah_prototype_audio_13sep2026`)
When designing observability, user feedback, and feature voting for **Belong on the Spectrum**, we reviewed our sister contemplative audio project ([`selah_prototype_audio_13sep2026`](https://github.com/neiljaywarner/refuge)).

Selah introduced an admirable **"Private Feedback, Public Praise"** philosophy using a 3-Face Funnel (`😊 Happy` -> 4–5 Stars, `😐 Neutral` -> 3 Stars, `😞 Sad` -> 1–2 Stars) wired to multiple analytics/feedback backends (`Firestore`, `Doorbell.io`, `BetterFeedback` screenshot drawing, `Aptabase`, `PostHog`, and a private GitHub feedback repo).

### 2. What Worked vs. What Was Over-Complicated in Selah

| Dimension | Selah Prototype (`v0.2.4`) | Belong Evaluation & Improvement (`ADR-0007`) |
| :--- | :--- | :--- |
| **Cognitive & Sensory Load** | Combined emotional faces (`😊/😐/😞`) **plus** numeric star ratings (`1–5 stars`) **plus** screenshot drawing modals. Numeric star ratings feel arbitrary and ambiguous to many autistic users (*"What is the difference between 3 stars and 4 stars?"*). | **Literal 3-Intent Cards (Zero Star-Rating Guesswork)**:<br>• 💚 **Works Great** (*Public Praise — What should we protect?*)<br>• 💡 **Idea / Tweak** (*Private Suggestion — What would make Belong clearer/calmer?*)<br>• 🛠️ **Bug / Confusing** (*Private Triage — What felt broken or overwhelming?*) |
| **Zero-Typing Participation** | Required navigating to a separate roadmap view or typing feedback. | **1-Tap Feature Voting Tab First**: Opens directly to **Vote on Features (WIP)** pre-seeded with active `WIP · Shipping Before Oct 31` items so members who don't have energy to type can participate with a single tap. |
| **Engineering Stack** | 5 overlapping telemetry/feedback packages (`aptabase_flutter`, `posthog_flutter`, `better_feedback`, `doorbell`, `cloud_firestore`), creating dependency bloat and configuration churn. | **Single Clean `HookConsumerWidget` + Riverpod `Notifier` (`BelongFeedbackAndVotingSheet`)** + Firebase Analytics + 1-tap private organizer/GitHub issue triage relay. Zero third-party SDK bloat! |

### 3. 🔄 Backport Guide: How `selah_prototype_audio_13sep2026` Can Switch to Belong's System
When updating **Selah** (`selah_prototype_audio_13sep2026`), engineers can replace Selah's multi-SDK feedback plumbing with Belong's clean 2-file module in under 15 minutes:
1. **Copy the 2 pure-Flutter files**:
   - `lib/src/features/feedback/domain/feedback_and_voting_models.dart`
   - `lib/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart`
2. **Replace `kDefaultBelongVotableFeatures`** with Selah's audio meditation roadmap items (e.g., *ESV Audio Support*, *Sleep Timer Fade-Out*, *Offline Chapter Downloads*).
3. **Remove redundant dependencies** (`doorbell`, `aptabase_flutter`, `posthog_flutter`) and route private submissions (`isPrivateTriage == true`) through a single lightweight webhook or router targeting private sibling repo `neiljaywarner/belong_feedback` (similar to Selah's private `selah_feedback` repo).

---

## 📚 Complete ADR Directory (`docs/adr/`)

| ADR | Timestamp (CDT) | Title & Summary | Status |
| :--- | :--- | :--- | :--- |
| **ADR-0001** | `2026-10-18 18:30` | **Calm Technology & Sensory-Safe Design System**: Establishes warm sage/teal palette, zero autoplay media, predictable motion, and person-first / identity-first neurodivergent copywriting. | Accepted |
| **ADR-0002** | `2026-10-18 18:45` | **Feature-First Layered Architecture (`CodeWithAndrea`) & `hooks_riverpod`**: Standardizes `domain/`, `data/`, `application/`, and `presentation/` folders per feature using `HookConsumerWidget`. | Accepted |
| **ADR-0003** | `2026-10-18 19:00` | **White-Label Multi-Tenant Configuration (`CommunityBrandConfig`)**: Enables Belong on the Spectrum as the default tenant while allowing any church or neurodivergent group to launch their own branded instance. | Accepted |
| **ADR-0004** | `2026-10-18 19:15` | **Two-Stage Authentication ("Getting Real" Philosophy)**: Ships Stage 1 Email/Password + Profile immediately for the Oct 24–31 cutover preview, followed by Stage 2 1-Tap Google & Apple Sign-In before `v1.0`. | Accepted |
| **ADR-0005** | `2026-10-18 19:25` | **Circle.so Parity Bottom Navigation (`salomon_bottom_bar`)**: Selects a calm 5-destination navigation bar (`Home`, `Spaces`, `Msgs`, `Notifications`, `Profile`) with honest "Coming Soon" previews for WIP tabs. | Accepted |
| **ADR-0006** | `2026-10-18 19:35` | **Multi-Environment Flavors (`dev`/`prod`) & Unified FlutterFire Suite**: Isolates `dev` and `prod` Firebase environments and empowers non-technical organizers via Firebase Remote Config. | Accepted |
| **ADR-0007** | `2026-10-18 19:50` | **Neurodivergent-First UX & Simplified "Private Feedback, Public Praise, Feature Voting"**: Replaces ambiguous star ratings with literal 3-intent feedback cards, 1-tap WIP voting, and routes private bug triage to confidential sibling repo `neiljaywarner/belong_feedback` (#124). | Accepted |
| **ADR-0008** | `2026-10-18 19:55` | **Post-MVP Backend Evaluation: Serverpod Cloud vs. Appwrite (`migrate_to_appwrite.md`)**: Evaluates why shipping MVP on Firebase/Serverpod now and migrating to Appwrite right after `v1.0` (85% likelihood) maximizes speed and $0 long-term sustainability. | Proposed / Evaluated |
