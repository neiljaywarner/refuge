# Backend Evaluation & Migration Plan: Serverpod + Firebase vs. Appwrite (`appwrite.io`)

- **Document ID**: `ADR-0008` / `docs/migrate_to_appwrite.md`
- **Last Updated**: `2026-10-18T20:01:00-05:00`
- **Status**: Evaluated — **Ship `v0.8.0-alpha` First ("Getting Real"), Then Wire 1-Tap Google Auth / Appwrite Between Alpha & Beta (`v0.8.5` / `v0.9.0-beta`, ~90% Likelihood)**
- **Wiki Mirror**: [`Migrate-to-Appwrite-Evaluation`](https://github.com/neiljaywarner/refuge/wiki/Migrate-to-Appwrite-Evaluation)

---

## 1. Executive Summary: 37signals "Getting Real" + Why Google Sign-In Matters So Much

Our top priority is launching a calm, reliable **Belong on the Spectrum** community app by **October 24, 2026** so our members have a **7-day calm overlap window** before the **October 31, 2026** Circle.so subscription renewal (saving ~$1,000+/year).

Following 37signals' **"Getting Real"** philosophy:
1. **For `v0.6.0`–`v0.8.0-alpha` (Tonight)**: Ship the working alpha + Firebase Hosting Preview Channel immediately with Stage 1 Auth (simple account/profile) so people can explore all 6 Belong spaces, search, and vote on features tonight without waiting on OAuth console setup.
2. **Between Alpha (`v0.8.0-alpha`) and Beta (`v0.9.0-beta`) — The Sweet Spot for 1-Tap Google Sign-In & Appwrite**:
   - Why not wait until after `1.0` for Google Sign-In? Because **for autistic and neurodivergent community members, remembering another password or clicking a "Forgot Password" reset link is a massive executive-function friction point!**
   - **1-Tap Google Sign-In (and Apple Sign-In)** is one of the single biggest UX value-adds we can give members before they migrate from Circle.so during the Oct 24–31 overlap week.
   - Because **Appwrite (`appwrite.io`)** makes 1-Tap Google & Apple OAuth2 a turnkey toggle *and* gives us a **$0/month free tier** (vs. $5/month) plus built-in Realtime & FCM Push integration, **between Alpha (`v0.8.0-alpha`) and Beta (`v0.9.0-beta`) is the optimal window (90% likelihood)** to wire Google Sign-In + Appwrite!

---

## 2. Graded Likelihood by Release Window

| Migration / Google Auth Window | Likelihood Estimate | Grade | Product & UX Rationale |
| :--- | :---: | :---: | :--- |
| **Window A: Before `v0.8.0-alpha` (Tonight)** | **10%** | 🔴 **Too Early** | Don't delay tonight's live preview channel deployment. Stage 1 Auth + Profile + Feature Voting is 100% ready tonight. |
| **Window B: Between Alpha (`v0.8.0-alpha`) & Beta (`v0.9.0-beta`)** | **90% (Recommended)** | 🟢 **Sweet Spot (`A+`)** | **Huge user value-add before broad community onboarding.** Eliminates "Forgot Password" frustration with **1-Tap Google Sign-In** while locking in Appwrite's **$0/month** tier, Realtime feed/DMs, and FCM push before the Oct 24–31 Circle cutover week! |
| **Window C: Right Before or Right After `v1.0.0`** | **85%** | 🟢 **Strong Fallback** | If we wire Firebase Google Sign-In first for Beta and move the database to Appwrite at `v1.0`, our repository pattern still keeps the swap under 4 hours. |

---

## 3. Why Appwrite + Firebase Analytics/FCM Is the Ideal Pairing

| Capability | Current Alpha Stack | Appwrite Cloud (`appwrite.io`) + Firebase Analytics/FCM | Why Members & Organizers Win |
| :--- | :--- | :--- | :--- |
| **1-Tap Google & Apple Sign-In** | Stage 1 Email/Password (requires password reset flow) | **1-Tap `createOAuth2Session(provider: OAuthProvider.google)`** | **Zero "Forgot Password" friction** for neurodivergent members! |
| **Monthly Hosting Cost** | ~$5/month (Serverpod Cloud mini) | **$0/month** (Appwrite Cloud Free Tier: 75,000 MAU, Realtime, Storage) | Saves 100% of recurring backend hosting fees. |
| **Realtime Posts & Direct Messages** | Polling / custom streams | **Built-in Realtime WebSocket channels** | Instant updates in *Say Hello*, *Geek Out!*, and *Msgs*. |
| **FCM Push & Analytics** | `firebase_messaging` + `firebase_analytics` | Appwrite Messaging **natively integrates with FCM/APNs** while `firebase_analytics` + `firebase_remote_config` stay active | Organizers keep Firebase Remote Config & Analytics with zero conflict. |
