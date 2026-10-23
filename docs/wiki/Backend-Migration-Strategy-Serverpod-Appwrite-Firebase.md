# ⚖️ Backend Migration Strategy: Grading Serverpod, Appwrite & Firebase Hybrid (`v1.0` – `v2.0`)

> **Companion ADR**: [`ADR-0009: Piece-by-Piece vs. One-Shot Backend Migration`](https://github.com/neiljaywarner/refuge/blob/main/docs/adr/0009-piece-by-piece-vs-one-shot-appwrite-firebase-hybrid.md)
> **Live Web / PWA**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)
> **Deployment Runbook**: [`DEPLOYMENT.md`](https://github.com/neiljaywarner/refuge/blob/main/DEPLOYMENT.md)

> **Proposal only (22 October 2026).** The grades below are a future migration sketch. They are not the live stack. Serverpod is still the default post backend. Cloud Firestore is still the second copy. Appwrite has not replaced either. Appwrite is on `main` ([PR #412](https://github.com/neiljaywarner/refuge/pull/412), `fc71fd4`) and stays off unless both `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` are set. [#384](https://github.com/neiljaywarner/refuge/issues/384) is not closed.

---

## 1. Executive Summary: Why "Appwrite Core + Firebase Edge" (`Grade: A+ / 9.7/10`) Wins for `v1.0`, `v1.1` & `v2.0`

When building **Belong on the Spectrum**, we do **not** have to choose an "all-or-nothing" single cloud vendor. Instead, splitting along the **Core Community Data (Appwrite)** vs. **Edge Delivery & Growth (Firebase)** boundary gives us an **A+ (`9.7/10`)** architecture:

| Capability | Provider (`v1.0` – `v2.0`) | Grade | Score | Rationale |
| :--- | :--- | :---: | :---: | :--- |
| **Web / PWA Hosting & Preview Channels** | **Firebase Hosting (`belongonthespectrum.web.app`)** | **A+** | `9.9/10` | Instant global CDN, automatic SSL, and 1-command PR preview channels (`firebase hosting:channel:deploy`). |
| **Push Notifications (Web, Android, iOS)** | **Firebase Cloud Messaging (FCM)** | **A+** | `9.8/10` | Native cross-platform push delivery (Appwrite Push itself uses FCM under the hood!). |
| **Audience Segmentation & Organizer Live Banner** | **Firebase Analytics Audiences + Remote Config** | **A+** | `9.6/10` | Organizers update announcements & segments from the Firebase Console with zero code deploys. |
| **1-Tap Google & Apple Sign-In + Magic Links** | **Appwrite Auth** | **A+** | `9.7/10` | Zero-friction OAuth2 + Teams (`Actually Autistic`, `Moderator`, `Organizer`) mapped directly to Circle spaces. |
| **Spaces, Posts, Comments & 1-Tap Feature Voting** | **Appwrite Databases + Realtime** | **A** | `9.4/10` | Structured collections with row-level Team permissions and automatic WebSocket channels. |
| **Memes, Avatars & Audio MP3 Release Notes** | **Appwrite Storage** | **A** | `9.3/10` | Built-in bucket permissions and image transformations. |

---

## 2. Piece-by-Piece (`Strangler Fig`) vs. One-Shot (`Big Bang`) Grading Matrix

Because all data access in `lib/src/features/` sits behind **Riverpod Repository Interfaces** (`FeatureVotingRepository`, `AuthRepository`), we can switch from Serverpod to Appwrite either **Piece-by-Piece** or **All-at-Once**:

| Migration Approach | Grade | Speed | Safety | Verdict |
| :--- | :---: | :---: | :---: | :--- |
| **1. Piece-by-Piece via Riverpod Providers (*Recommended*)** | **🏆 A+ (`9.6/10`)** | `9.5/10` | `9.8/10` | **Best choice**: Flip `AuthRepository` + `FeatureVotingRepository` in PR 1 (~2 hrs), then `Posts` + `Spaces` in PR 2 (~2 hrs). Zero downtime and 1-line rollback per feature! |
| **2. One-Shot Swap (*All-at-Once*)** | **B+ (`8.4/10`)** | `8.8/10` | `7.5/10` | Viable (~3–4 hrs total since our schema has 4 core tables), but carries higher PR diff and merge-conflict risk. |
| **3. Pure Firestore (No Appwrite)** | **B (`7.9/10`)** | `8.2/10` | `8.0/10` | Single console, but Circle-style Space Team/Role permissions are more awkward in NoSQL rules than Appwrite Teams. |

---

## 3. Clean Repository Adapter Code Architecture

Every feature module exposes 4 pluggable adapters verified by the exact same Unit, Widget BDD (`patrolWidgetTest`), Integration, and Maestro E2E tests:
1. **`InMemory*Repository`**: Deterministic offline/test adapter.
2. **`Serverpod*Repository`**: Still the default post backend on `main` (22 October 2026).
3. **`Appwrite*Repository`**: On `main` via [PR #412](https://github.com/neiljaywarner/refuge/pull/412) (`fc71fd4`). Stays off unless both `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` are set. It has not replaced Serverpod. [#384](https://github.com/neiljaywarner/refuge/issues/384) is not closed.
4. **`Firebase*Repository`**: Cloud Firestore remains the second copy of posts, plus Analytics where a build is configured.
