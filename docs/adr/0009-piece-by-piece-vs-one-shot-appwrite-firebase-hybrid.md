# ADR-0009: Piece-by-Piece vs. One-Shot Backend Migration — Grading Serverpod, Appwrite & Firebase Hybrid Coexistence

* **Status**: Accepted
* **Date**: October 18, 2026
* **Deciders**: Neil Jay Warner & Engineering Team
* **Related Docs**:
  * [`unattended_session_908pm.md`](file:///Users/neil/belongonthespectrum/unattended_session_908pm.md)
  * [`neil_to_review_sunday_night.md`](file:///Users/neil/belongonthespectrum/neil_to_review_sunday_night.md)
  * [`DEPLOYMENT.md`](file:///Users/neil/belongonthespectrum/refuge/DEPLOYMENT.md)
  * [ADR-0007: Neurodivergent-First Feedback & 1-Tap Feature Voting](file:///Users/neil/belongonthespectrum/refuge/docs/adr/0007-neurodivergent-feedback-and-feature-voting.md)
  * [ADR-0008: Appwrite Migration Timing](file:///Users/neil/belongonthespectrum/refuge/docs/adr/0008-appwrite-migration-timing.md)
  * [Wiki: Backend Migration Strategy (Serverpod, Appwrite & Firebase)](https://github.com/neiljaywarner/refuge/wiki/Backend-Migration-Strategy-Serverpod-Appwrite-Firebase)

---

## 1. Context & Architectural Question

As **Belong on the Spectrum** (`https://belongonthespectrum.web.app`) prepares to replace Circle.so before the **October 31, 2026** cutover (with our 7-day calm overlap window starting **October 24**), we face two coupled strategic decisions:

1. **Long-Term Backend Mix (`v1.0` → `v1.1` → `v2.0`)**:
   - We love **Appwrite** for **1-Tap Google & Apple Sign-In (Auth)**, **Structured Databases (Spaces, Posts, Feature Voting)**, **Realtime Subscriptions**, and **Storage Buckets**.
   - At the same time, we love **Firebase** for **Hosting (`belongonthespectrum.web.app` + PR Preview Channels)**, **Firebase Cloud Messaging (FCM)**, **Firebase Analytics Audiences**, and **Firebase Remote Config** (*"Message from the Organizer"*).
   - **Question A**: *Does an "Appwrite Core + Firebase Edge/Growth" hybrid make sense for `v1.0`, `v1.1`, and `v2.0`?*
2. **Migration Execution Strategy (Serverpod → Appwrite + Firebase)**:
   - Right now in `v0.6.0`–`v0.8.0-alpha`, our app talks to Serverpod (with resilient in-memory/local fallback when offline).
   - **Question B**: *When switching to Appwrite, is it quicker, safer, and cleaner to migrate **Piece-by-Piece (Strangler Fig)** or **All-at-Once (One-Shot Swap)**?*

---

## 2. Executive Answer: Yes to the "Appwrite Core + Firebase Edge" Hybrid (`Grade: A+ / 9.7/10`)

**Yes — combining Appwrite (Core Auth, Database, Realtime & Storage) with Firebase (Web Hosting, FCM Push, Analytics Audiences & Remote Config) for `v1.0`, `v1.1`, and `v2.0` is not only fine, it is the single highest-leverage architecture available for Flutter.**

Why? Because **Appwrite and Firebase have zero conflict when split along the "Core Data vs. Edge/Growth" boundary**:

| Layer / Capability | Chosen Provider (`v1.0` – `v2.0`) | Grade | Score | Why This Provider Wins Here |
| :--- | :--- | :---: | :---: | :--- |
| **Web & PWA Hosting + Preview Channels** | **Firebase Hosting (`belongonthespectrum.web.app`)** | **A+** | `9.9/10` | Instant global CDN, zero-config SSL, atomic rollbacks, and 1-command preview URLs (`firebase hosting:channel:deploy`). |
| **Push Notifications & Segment Targeting** | **Firebase Cloud Messaging (FCM) + Firebase Audiences** | **A+** | `9.8/10` | Native APNs/Android/Web Push delivery; Appwrite itself actually uses FCM under the hood for push notifications! |
| **Organizer Live Banner & Feature Flags** | **Firebase Remote Config + Analytics** | **A+** | `9.6/10` | Non-technical organizers can update the in-app banner & audience segments without redeploying code. |
| **Authentication (1-Tap Google, Apple, Magic Link)** | **Appwrite Auth** | **A+** | `9.7/10` | Built-in OAuth2 + Teams/Roles (`Actually Autistic`, `Moderator`, `Organizer`) that map 1:1 to Circle Space permissions. |
| **Spaces, Posts, Comments & 1-Tap Feature Voting** | **Appwrite Databases + Realtime** | **A** | `9.4/10` | Relational-style collections, built-in row-level permissions tied to Appwrite Teams, and automatic WebSocket channels (`databases.*.collections.*.documents`). |
| **Memes, Audio MP3 Release Notes & Avatars** | **Appwrite Storage** | **A** | `9.3/10` | Simple bucket permissions + built-in image preview transformations. |

---

## 3. Grading the 3 Migration Strategies: Piece-by-Piece vs. One-Shot vs. Hybrid Adapter

Because our codebase uses **Riverpod Repository Interfaces** (`AuthRepository`, `FeatureVotingRepository`, `SpacePostRepository`), we evaluated the three ways to execute the transition from Serverpod to Appwrite:

| Strategy | Overall Grade | Speed Score | Safety Score | How It Works | Pros | Cons |
| :--- | :---: | :---: | :---: | :--- | :--- | :--- |
| **Option 1: Piece-by-Piece via Repository Providers (*Recommended: Strangler Fig*)** | **🏆 A+ (`9.6/10`)** | `9.5/10` | `9.8/10` | Keep every feature behind a Riverpod provider (`authRepositoryProvider`, `featureVotingRepositoryProvider`, `postsRepositoryProvider`). Swap **Auth + Feature Voting first** (in 1 PR), then **Posts/Spaces second** (in 1 PR), while keeping Firebase Hosting/FCM/RemoteConfig untouched. | • Zero downtime; app stays 100% shippable after every single PR.<br>• Unlocks **1-Tap Google/Apple Sign-In** immediately without waiting on schema migration.<br>• Instant 1-line rollback per feature via Remote Config or provider override.<br>• Unit, Widget (`patrolWidgetTest`), Integration & Maestro E2E tests run identically against `InMemory`, `Serverpod`, `Appwrite`, and `Firebase` adapters! | • For 24–48 hours between PR 1 and PR 2, both `serverpod_flutter` and `appwrite` packages sit in `pubspec.yaml` (negligible ~300KB impact). |
| **Option 2: One-Shot Swap (*All-at-Once*)** | **B+ (`8.4/10`)** | `8.8/10` | `7.5/10` | Replace Serverpod Auth, Posts, Spaces, and Feature Voting in a single giant branch (`feat/appwrite-cutover`) and remove `serverpod_flutter` in the same PR. | • Because our surface area is still compact (~4 core tables: `users`, `spaces`, `posts`, `feature_votes`), a one-shot swap only takes ~3–4 hours.<br>• Removes `serverpod_flutter` dependencies immediately. | • Larger PR diff (~15 files) increases merge-conflict risk during active UI work.<br>• Harder to isolate whether a regression came from Auth vs. Database permissions. |
| **Option 3: Pure Firebase Everything (*Firestore for Spaces/Posts*)** | **B (`7.9/10`)** | `8.2/10` | `8.0/10` | Move Auth and Databases to Firebase Auth + Cloud Firestore instead of Appwrite. | • Single console (`console.firebase.google.com`). | • NoSQL document nesting and security rules for Circle-style Space Role/Team permissions are harder to maintain than Appwrite Teams + Collections.<br>• Higher per-read cost if members scroll large feeds. |

---

## 4. Concrete Decision: Repository Adapter Pattern (Best of Both Worlds!)

We have designed our domain & data layers so that **you can choose EITHER Piece-by-Piece OR One-Shot at any moment with a 1-line Riverpod override**:

```dart
/// Example: Clean Repository Adapter Pattern in Feature Voting
abstract interface class FeatureVotingRepository {
  Future<List<CommunityFeatureItem>> fetchFeatures();
  Future<List<CommunityFeatureItem>> toggleUpvote(String featureId);
  Future<CommunityFeatureItem> proposeFeature({
    required String title,
    required String description,
  });
  Future<void> submitFeedback(CommunityFeedbackSubmission submission);
}
```

We provide **4 interchangeable implementations** tested by the exact same 4-layer test suite (Unit, Widget BDD, Integration, and Maestro E2E):
1. **`InMemoryFeatureVotingRepository`**: Sub-millisecond deterministic adapter for offline mode, Alpha previews, and widget/BDD tests.
2. **`ServerpodFeatureVotingRepository`**: Connects to the existing Serverpod backend (`v0.6.0`–`v0.8.0-alpha`).
3. **`AppwriteFeatureVotingRepository`**: Ready-to-activate adapter targeting Appwrite Collections (`feature_items` & `feedback_submissions`).
4. **`FirebaseFeatureVotingRepository`**: Ready-to-activate adapter targeting Cloud Firestore (`feature_items` & `feedback_submissions`) + Analytics events.

### Recommended 2-Step Sequence Between Alpha (`v0.8.0-alpha`) and Beta (`v0.9.0-beta`)
1. **Step 1 (2 Hours)**: Flip `authRepositoryProvider` and `featureVotingRepositoryProvider` to **Appwrite** (unlocking 1-Tap Google/Apple Sign-In and persistent cross-device Feature Voting).
2. **Step 2 (2 Hours)**: Flip `postsRepositoryProvider` and `spacesRepositoryProvider` to **Appwrite**, import the Circle.so CSV export via `tool/import_circle_csv.dart`, and keep **Firebase Hosting (`belongonthespectrum.web.app`), FCM, Analytics Audiences, and Remote Config** as our permanent Edge/Growth stack through `v1.0`, `v1.1`, and `v2.0`!
