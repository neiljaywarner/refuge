# Backend & Database Architecture

> **Engineering Architecture & Under-the-Hood Data Dictionary for Organizers, Mentors & Apprentices**  
> *Tracked in Issue #93 · Living Architecture Reference*

> **Live on `main` (22 October 2026).** Serverpod is still the default post backend. Cloud Firestore is still the second copy. Appwrite has not replaced either. Appwrite is on `main` ([PR #412](https://github.com/neiljaywarner/refuge/pull/412), `fc71fd4`) and stays off unless both `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` are set. [#384](https://github.com/neiljaywarner/refuge/issues/384) is not closed. The Flutter package name is still `refuge4serverpod` ([#233](https://github.com/neiljaywarner/refuge/issues/233)).

---

## 1. Under-the-Hood Architecture Overview

**Belong on the Spectrum** is powered by an accessible, calm-tech frontend with a **pluggable multi-backend architecture** (ADR-0009). The client consumes abstractions through Riverpod providers, allowing the application to connect to:

1. **Serverpod RPC & PostgreSQL** (default post backend on `main`).
2. **Cloud Firestore / Firebase** (second copy of posts, plus profiles, votes, and feedback notes).
3. **Appwrite** (on `main` via [PR #412](https://github.com/neiljaywarner/refuge/pull/412), `fc71fd4`; off unless both `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` are set; [#384](https://github.com/neiljaywarner/refuge/issues/384) is not closed).
4. **Deterministic In-Memory Repositories** (Local offline development, BDD widget tests, and CI/CD with zero cloud dependencies).

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Flutter Client (hooks_riverpod)                     │
│        lib/src/features/{profile, reflections, feedback, spaces}       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Pluggable Repository & Service Abstractions              │
│       PostRepository  ·  AuthRepository  ·  FeatureVotingRepository    │
└───────────┬───────────────────────┼─────────────────────────┬──────────┘
            │                       │                         │
            ▼                       ▼                         ▼
┌──────────────────────┐  ┌───────────────────┐  ┌───────────────────────┐
│   Serverpod RPC      │  │ Cloud Firestore   │  │ In-Memory (tests)     │
│   (Default posts)    │  │ (Second copy)     │  │ Appwrite opt-in only  │
└──────────────────────┘  └───────────────────┘  └───────────────────────┘
```

---

## 2. Where to Find Stuff "Under the Hood"

| Subsystem | Under-the-Hood Location | Purpose / Contents |
| :--- | :--- | :--- |
| **Firestore Database** | Firebase Console -> Project `belong-on-the-spectrum` -> *Firestore Database* | Live user profiles, reflections, feature votes, and feedback |
| **Firebase Remote Config** | Firebase Console -> *Remote Config* -> Parameters | Live organizer welcome banner, community guidelines markdown, dynamic announcements |
| **Crashlytics & Errors** | Firebase Console -> *Crashlytics* & `Talker` diagnostics | Unhandled exceptions and handled errors scrubbed of PII (`ErrorReporterService`) |
| **Serverpod Endpoints** | `refuge4serverpod_server/lib/src/endpoints/` | Dart Serverpod endpoints (`post_endpoint.dart`, `feature_endpoint.dart`) |
| **Serverpod Models** | `refuge4serverpod_server/lib/src/models/` | YAML schema definitions (`*.spy.yaml`) compiled to typed Dart entities |
| **Frontend Repositories** | `lib/src/features/*/data/` | Pluggable client adapters implementing repository interfaces |
| **Domain Models** | `lib/src/features/*/domain/` | Immutable business logic (`MemberProfile`, `Post`, `CommunityBrandConfig`) |

---

## 3. Firestore Database Collections & Schema

### 3.1. Collection: `users`
Stores community member profiles, special interests, and fellowship verification status.

*Document ID*: Firebase Auth User UID (`{uid}`) or generated member ID.

```json
{
  "uid": "usr_948194a28f",
  "displayName": "Marty",
  "email": "marty@belongonthespectrum.com",
  "bio": "Belong Organizer, passionate about neurodiversity in faith communities.",
  "icocChurchAffiliation": "DFW Church (Partner)",
  "isIcocMember": true,
  "comfortBadges": [
    "Community Organizer",
    "Literal communication appreciated"
  ],
  "sensoryTheme": "cream",
  "authMethod": "firebase_auth",
  "createdAt": "2026-10-18T20:00:00.000Z",
  "updatedAt": "2026-10-19T08:30:00.000Z"
}
```

#### Field Specifications:
- `uid` (`string`, required): Unique identifier from auth provider.
- `displayName` (`string`, required): Chosen member name displayed in reflections.
- `email` (`string`, required): Member email (private, zero-PII rules apply).
- `bio` (`string`, optional): Member bio and special interest description.
- `icocChurchAffiliation` (`string`, required for Belong): Indicates which ICOC congregation the member attends, or explicitly `"I am not a member of an ICOC church"`.
- `isIcocMember` (`boolean`, computed/stored): `true` if affiliated with an ICOC church; `false` if visitor/non-member.
- `comfortBadges` (`list<string>`): Communication preferences (e.g. "Literal communication appreciated", "Low-stimulus preferred").
- `sensoryTheme` (`string`): Preferred visual theme (`cream`, `darkNavy`, `contrast`, `softSage`).

---

### 3.2. Collection: `posts` (Reflections)
Stores calm-tech fellowship reflections, prayers, and study insights.

*Document ID*: Auto-generated document ID (`{postId}`).

```json
{
  "id": "post_78129034",
  "authorName": "Hannah M.",
  "authorUid": "usr_102849",
  "spaceKey": "prayer",
  "toneTag": "Contemplative",
  "specialInterestTag": "Scripture & Botany",
  "content": "Reflecting on Psalm 139:14 today. Finding quiet comfort in God's intentional design of neurodiversity.",
  "timestamp": "2026-10-19T08:15:00.000Z",
  "reactions": {
    "pray": 14,
    "peace": 8,
    "encouraged": 12,
    "relatable": 9
  }
}
```

#### Field Specifications:
- `spaceKey` (`string`, indexed): Space partition (`prayer`, `general_chat`, `memes`, `study`, `actually_autistic_chat`).
- `toneTag` (`string`, indexed): Emotional context tag (`Gentle`, `Contemplative`, `Joyful`, `Direct`, `Venting`).
- `reactions` (`map<string, int>`): Sensory-safe reactions (no vanity metrics; calm affirmation counts only).

---

### 3.3. Collection: `features` (Roadmap & Feature Voting)
Public roadmap features that community members can vote on.

*Document ID*: Feature slug/id (e.g., `wip-direct-messages`).

```json
{
  "id": "wip-direct-messages",
  "title": "Direct Messages (Msgs Tab)",
  "description": "Private, low-pressure 1-on-1 messaging with unhurried response expectations.",
  "stage": "inProgress",
  "votesCount": 25,
  "votedUserIds": ["usr_948194a28f", "usr_102849"]
}
```

---

### 3.4. Collection: `feedback` (Private Organizer Feedback)
Private feedback submitted by members directly to community organizers.

*Document ID*: Auto-generated document ID (`{feedbackId}`).

```json
{
  "id": "fb_6619028",
  "sentiment": "happy",
  "message": "The contrast theme and unhurried layout make reading reflections much less overwhelming.",
  "contact": "optional_member@belong.org",
  "isPrivateTriage": false,
  "createdAt": "2026-10-19T08:20:00.000Z"
}
```

---

## 4. Zero-PII Protections & Security

1. **Member Privacy**: Emails and contact information are never rendered in public reflections or client queries.
2. **Crash & Observability Zero-PII**: `ErrorReporterService` automatically redacts emails and secret tokens before sending to Crashlytics or `Talker`.
3. **Church Affiliation Integrity**: Church affiliations verify fellowship connections while explicitly providing a welcoming option for non-member seekers.
