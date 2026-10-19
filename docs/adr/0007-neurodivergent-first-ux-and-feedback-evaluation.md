# ADR 0007: Neurodivergent-First UX & Simplified "Private Feedback, Public Praise, Feature Voting"

- **Date / Timestamp**: `2026-10-18T19:50:00-05:00`
- **Status**: Accepted
- **Authors**: Neil Warner & Antigravity Architecture Team
- **Related Issues**: `#18`, `#21`, `#47`+ (Observability & Feedback Epic)
- **Wiki Mirror**: [`UX-Evaluation-and-ADRs`](https://github.com/neiljaywarner/refuge/wiki/UX-Evaluation-and-ADRs)

---

## 1. Context & Problem Statement

During the October 24–31, 2026 transition from Circle.so to **Belong on the Spectrum** (`belongonthespectrum.com`), we need a built-in way for neurodivergent community members, organizers, and beta testers to:
1. **See what features are actively Work-In-Progress (WIP)** and **upvote** what matters most to them with 1 tap (zero typing required).
2. **Send constructive feedback or bug/sensory-overload reports privately** to organizers/GitHub issues while routing positive experiences toward **public praise & encouragement**.

We reviewed our sister project (`neiljaywarner/selah_prototype_audio_13sep2026`) for inspiration. While Selah's *"Private Feedback, Public Praise"* goal was spot-on, its UX and engineering implementation had two major pain points:
- **UX Ambiguity for Neurodivergent Brains**: Combining emotional face icons (`😊 / 😐 / 😞`) with numeric 1–5 star ratings (`4–5 stars` vs `3 stars` vs `1–2 stars`) and screenshot-drawing overlays created decision fatigue. Autistic users strongly prefer **literal, unambiguous categories** over arbitrary star ratings.
- **Engineering & Dependency Bloat**: Wiring 5 overlapping telemetry/feedback SDKs (`aptabase_flutter`, `posthog_flutter`, `better_feedback`, `doorbell`, `cloud_firestore`) caused configuration complexity and maintenance overhead.

---

## 2. Decision

We adopt a **2-Tab Neurodivergent-First Feedback & Roadmap Sheet (`BelongFeedbackAndVotingSheet`)** built in pure Flutter (`HookConsumerWidget` + Riverpod `Notifier`):

### A. Tab 1 (Default): 1-Tap Feature Voting & Active WIP Board
- Opens first so members who do not have the spoons/energy to type a paragraph can still participate with a **single tap**.
- Pre-seeded with clear lifecycle badges:
  - `WIP · Shipping Before Oct 31` (*Direct Messages / Msgs Tab*, *Calm Notification Bell*, *Actually Autistic Events Calendar*, *1-Tap Google & Apple Sign-In*)
  - `Planned · Post-Cutover` (*Native iOS App Store & Google Play Apps*)
  - `Community Idea · Vote to Prioritize` (*Camera-Off Voice & Text Hangout Rooms*, *Special Interest Showcase Galleries*, *Single Weekly Calm Digest Email*)

### B. Tab 2: Literal 3-Intent Feedback Cards (Zero Star-Rating Guesswork)
Instead of `1–5 Stars`, users pick one of three literal intents:
1. 💚 **`Works Great` (`Public Praise`)** — *"What feels calm, clear, or welcoming?"* (Celebrates what works so organizers know which spaces and design choices to protect).
2. 💡 **`Idea / Tweak` (`Private Suggestion`)** — *"What would make Belong clearer or calmer for you?"* (Routes privately to organizer/GitHub triage).
3. 🛠️ **`Bug / Confusing` (`Private Triage`)** — *"What felt broken, confusing, or overwhelming?"* (Routes straight to private organizer/GitHub issue triage with zero public review pressure).

---

## 3. Backport Guide for `selah_prototype_audio_13sep2026`

To replace Selah's over-complicated multi-SDK feedback system with this clean architecture:
1. Copy these 2 self-contained files into `selah_prototype_audio_13sep2026`:
   - `lib/src/features/feedback/domain/feedback_and_voting_models.dart`
   - `lib/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart`
2. Replace `kDefaultBelongVotableFeatures` with Selah's contemplative audio roadmap items (*ESV Audio Support*, *Sleep Timer Fade-Out*, *Offline Chapter Caching*).
3. Remove `doorbell`, `aptabase_flutter`, and `posthog_flutter` from `pubspec.yaml`, keeping only `firebase_analytics` + a single private GitHub Issue / Organizer webhook relay for `isPrivateTriage == true` submissions.
