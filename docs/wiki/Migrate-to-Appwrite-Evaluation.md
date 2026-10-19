# ⚖️ Backend & Auth Evaluation: Why 1-Tap Google Sign-In + Appwrite (`appwrite.io`) Fits Between Alpha & Beta

*Last Updated: October 18, 2026 (`2026-10-18T20:01:00-05:00`)*
*Canonical Repo Document: [`docs/migrate_to_appwrite.md`](https://github.com/neiljaywarner/refuge/blob/main/docs/migrate_to_appwrite.md)*

---

## 🎯 Executive Summary: 37signals "Getting Real" + Zero "Forgot Password" Friction

1. **Tonight (`v0.6.0`–`v0.8.0-alpha`)**: We follow **37signals "Getting Real"** — ship the impressive Circle-style UI, 6 Belong spaces, Search, Profile, and 1-Tap Feature Voting tonight with Stage 1 Auth so we don't delay our live preview channel!
2. **Between Alpha (`v0.8.0-alpha`) and Beta (`v0.9.0-beta`) — 90% Likelihood Sweet Spot**:
   - Why prioritize **1-Tap Google Sign-In** (and Appwrite) right between Alpha and Beta instead of waiting until after `1.0`?
   - Because **for autistic and neurodivergent community members, inventing a new password or dealing with a "Forgot Password" link is a huge executive-function barrier!**
   - Giving Belong members **1-Tap Google Sign-In** before the October 24–31 Circle transition week is a massive real-world UX win — and **Appwrite Cloud (`appwrite.io`)** provides turnkey OAuth2 (Google + Apple), Realtime channels, FCM Push integration, and a **$0/month free tier** (up to 75,000 MAU vs. $5/month).

---

## 📊 Graded Likelihood by Release Window

| Timing Window | Estimated Likelihood | Grade | Product & UX Assessment |
| :--- | :---: | :---: | :--- |
| **1. Before `v0.8.0-alpha` (Tonight)** | **10%** | 🔴 **Too Early** | Don't slow down tonight's preview deploy. Stage 1 Auth + Profile + Feature Voting is ready now. |
| **2. Between Alpha (`v0.8.0-alpha`) & Beta (`v0.9.0-beta`)** | **90% (Recommended)** | 🟢 **Sweet Spot (`A+`)** | **Delivers 1-Tap Google Sign-In before community onboarding (eliminating "Forgot Password" links!)** while moving to Appwrite's **$0/month** tier + Realtime + FCM. |
| **3. Right Before or After `v1.0.0`** | **85%** | 🟢 **Strong Fallback** | Even if we use Firebase Google Auth first for Beta and switch the DB to Appwrite at `v1.0`, our CodeWithAndrea repository pattern keeps the swap under 4 hours. |

---

## 🔍 Head-to-Head Comparison for Belong on the Spectrum

| Capability | Stage 1 Alpha Stack | Appwrite (`appwrite.io`) + Firebase Analytics/Remote Config | Winner for Beta & `1.0` |
| :--- | :--- | :--- | :--- |
| **Sign-In UX for Members** | Email/Password (requires password memory / reset links) | **1-Tap Google & Apple Sign-In (`createOAuth2Session`)** | 🏆 **1-Tap Google/Apple Sign-In** |
| **Monthly Hosting Cost** | ~$5/month (Serverpod Cloud mini) | **$0/month** on Appwrite Cloud Free Tier (75,000 MAU) | 🏆 **Appwrite ($0/mo)** |
| **Realtime Feed & Direct Messages** | Custom streaming endpoints | **Zero-boilerplate Realtime subscriptions** | 🏆 **Appwrite** |
| **FCM Push, Analytics & Remote Config** | Native Firebase | Appwrite Messaging **natively bridges FCM/APNs** while **Firebase Analytics & Remote Config** stay active | 🤝 **Best of Both Worlds** |
