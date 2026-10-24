# 🤝 Notes for 1:00 PM Meeting with Potential Business Partner / Technical Co-Founder

> **Date**: October 24, 2026 — 1:00 PM (CDT)  
> **Topic**: Belong on the Spectrum — Ministry Launch, Technical Architecture & Commercial SaaS Expansion  
> **Context**: Partner has successfully run his own software development consultancy / agency for years. Discussion explores mutual interest in advising, partnering, or co-founding to scale Belong from a local church ministry into a sustainable, revenue-generating calm-tech community platform.

---

## 1. Executive Summary: The Mission & The Opportunity

### The Origin (Ministry Need)
- **Belong on the Spectrum** ([belongonthespectrum.com](https://belongonthespectrum.com)) was created to serve Christian neurodivergent (autistic, ADHD, sensory-sensitive) individuals and their families.
- We currently host this community on **Circle.so**, which costs **\$1,000+ per year**. Circle is noisy, algorithm-heavy, lacks neurodivergent accessibility (WCAG AAA contrast, sensory themes), and forces communities into an expensive, one-size-fits-all subscription.
- **The Hard Cutoff**: Legacy Circle.so subscription ends on **Saturday, October 31, 2026**.
- **The Soft Launch Window**: 7-day calm overlap window begins **today (October 24)** through **October 31**, running both systems side-by-side so members experience zero disruption.

### The Business Horizon (Commercial SaaS Opportunity)
- What begins as a local ministry platform has massive commercial potential: **"Circle meets Subsplash, built for Calm & Accessibility."**
- **The Problem in the Market**:
  - Existing community software (Circle.so, Mighty Networks, Discord, Discourse) is built for hyper-engagement, gamification, dopamine loops, and ad revenue.
  - Churches, mental health non-profits, recovery ministries, and neurodivergent organizations desperately want quiet, safe, unhurried digital spaces without high subscription overhead.
  - Churches already spend **\$2,000–\$15,000/year** on church management and app suites (Pushpay, Subsplash, Planning Center) that offer poor community fellowship features.
- **The Revenue Model**:
  1. **B2B White-Label / Hosted Communities**: \$49–\$99/month per organization (50% cheaper than Circle's \$99–\$219/mo tiers, with 85%+ gross margins on Google Cloud serverless).
  2. **Agency Consulting & Integration**: Setup fees (\$1,500–\$5,000) for custom church domain routing, branding themes, CSV data migration, and Single Sign-On.
  3. **Patron / Creator Fellowship Tiers**: Optional member-supported micro-contributions (\$5–\$10/mo).
  4. **Accessibility Grants**: Significant grant funding available from faith and disability foundations (Lilley Endowment, Templeton, neurodiversity innovation funds).

---

## 2. Technical Architecture: What We Have Built

As an experienced dev consultant, you will appreciate how cleanly this system has been engineered. We avoided typical MVP spaghetti and built enterprise-grade foundations:

```
[Flutter Multi-Platform Client: Web PWA, Android APK, iOS, macOS]
                         │
                         ▼
           [Riverpod 2.6 State Management]
                         │
       ┌─────────────────┼─────────────────┐
       ▼                 ▼                 ▼
[Firebase Auth & Edge]  [Firestore & Cloud]   [Modular Backend Seams]
 (Email, Magic Links,   (Collections, Storage (Serverpod WebSocket &
  Remote Config Admin)   Session Replays)      Appwrite Realtime Ready)
```

### Key Technical Assets Already Working in Production:
1. **Single Dart Codebase Across 4 Surfaces**:
   - Production Web / PWA: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) (`v0.9.1+2`).
   - Android Native: Release APK + installed WebAPK with launcher icon and offline service worker.
   - iOS / Safari: 1-tap "Add to Home Screen" with standalone full-screen view.
2. **226+ Automated Tests Passing Green**:
   - BDD widget tests (`patrolWidgetTest` / `bdd_widget_test`), unit tests (`package:test`), and end-to-end integration tests.
3. **Hardware-Driven CI/CD & Automation**:
   - Automated device driving via **Maestro MCP** and **Marionette CLI** across 2 connected physical Google Pixels (`56091JEBF14039`, `58221JEBF20835`) and Android emulators.
   - Instant zero-prompt visual regression screenshot capture.
4. **Neurodivergent-First Features (Unique IP)**:
   - **4 Sensory Colorways**: Classic Sanctuary, Sage Botanical, Twilight Calm, Charcoal Night.
   - **WCAG AAA High Contrast Mode**: Instant black/yellow high-contrast toggle for low-vision and sensory regulation.
   - **In-App Drawing Feedback Canvas**: Members scribble arrows and circles directly onto screenshots before submitting private bug reports or ideas.
   - **Zero-PII Privacy Architecture**: Public reflections are sanitized; private feedback routes securely to a confidential triage queue (`neiljaywarner/belong_feedback`).
   - **7 Multi-Criteria Feed Sort Modes**: Latest, For You, New Activity, Oldest, Popular, Likes, Alphabetical.
5. **Cost Optimization**:
   - Shifting from Serverpod Cloud (\$5/mo cluster) to pure Firebase Edge + Appwrite brings ongoing baseline hosting to **\$0.00/month** on Google Cloud Free Spark Tier.

---

## 3. Where We Are Right Now (Launch Readiness & WIP)

### Done & Shipped (`v0.9.1+2` on `main`)
- [x] Firebase Authentication (Email/Password, Password Reset, Magic Links).
- [x] 8 Community Spaces (Prayer, General Chat, Quiet Musings, Bible Study, Special Interests, Events, Tech Help, Saved Items).
- [x] Threaded discussion comments and nested replies.
- [x] In-app avatar photo capture, gallery upload, and square crop.
- [x] Feature voting roadmap board with optimistic 1-tap upvoting.
- [x] Remote Config Admin Mode with user soft-deletion / banning.
- [x] Review sentiment benchmark auditor (`tool/analyze_app_reviews.dart`) comparing Belong against 60 Circle.so reviews.
- [x] Serverpod deprecation roadmap and turn-off checklist.

### In-Flight Polish (Being Finalized by Subagents Today)
- **Space isolation**: Ensuring unique post streams per space slug (Issue #445).
- **Private Bookmarking**: Restricting "Saved for Later" to personal bookmarks without public posting (Issue #446).
- **Mobile Composer Compactness**: Collapsing the reflection composer on Android mobile to maximize message reading area (Issue #447).
- **Profile Persistence**: Storing preferred display name and ICOC church affiliation in a clean dropdown (Issue #448).
- **FCM Real-Time Alerts**: Dual-device notification shade and in-app Material banner for direct messages (Issue #382).

---

## 4. Potential Roles & Partnership Structures

We can structure collaboration to fit your availability, consulting bandwidth, and long-term interest:

| Model | Time Commitment | Structure | Focus Areas |
| :--- | :---: | :--- | :--- |
| **1. Technical Co-Founder / Equity Partner** | 5–15 hrs/wk | Meaningful equity / revenue share | Co-lead architecture, SaaS platform commercialization, enterprise backend scale, B2B sales. |
| **2. Strategic Technical Advisor** | 2–4 hrs/mo | Advisory equity / retainer | Architecture reviews, security audits, vendor evaluations (Appwrite vs Supabase vs Firebase), hiring guidance. |
| **3. Agency / Delivery Partner** | Project-based | Revenue share / client billings | Your consultancy sells white-label community instances to churches and non-profit clients; we provide core platform and updates. |
| **4. Paid Consultant / Contractor** | Flexible sprints | Hourly / sprint fee | Targeted execution on high-complexity modules (e.g. Stripe billing, APNs production push, LiveKit video rooms). |

---

## 5. Agenda for Our 1:00 PM Call

1. **Welcome & The Story (10 mins)**:
   - Why Belong was born: Personal story, autistic fellowship need, Circle.so pain points.
   - Live demo on mobile/web: Walk through sensory themes, high contrast, drawing canvas, and unhurried feeds.
2. **Codebase & Architecture Tour (15 mins)**:
   - Walk through the repo: Flutter/Dart structure, Riverpod providers, BDD test suites (226+ tests), Maestro automation.
   - How we maintain zero-prompt unattended dev sessions and clean worktree isolation.
3. **The Business & Scale Potential (15 mins)**:
   - Why church tech is ripe for disruption: Subsplash / Pushpay / Circle fatigue.
   - Unit economics: Near-zero hosting costs vs \$49–\$99/mo per community.
   - Non-profit grants and philanthropic backing.
4. **Discussion & Alignment (20 mins)**:
   - What resonated? What potential red flags or technical hurdles do you see?
   - What level of involvement (if any) excites you?
   - Agree on next steps (e.g. sandbox repo access, follow-up coffee next week).
