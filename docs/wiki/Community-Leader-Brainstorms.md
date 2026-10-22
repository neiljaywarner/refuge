# 🧠 Possible Brainstorms & Design Decisions for Community Leaders & Pastoral Team

> **Audience**: Marty the Organizer, Pastoral Staff, DFW Church Elders, Welcomers, and Ministry Leaders  
> **Platform**: Belong on the Spectrum (`refuge`)  
> **Purpose**: A living catalog of thoughtful design decisions, community feedback, and calm-tech trade-offs to review during leadership check-ins.  
> **Linked GitHub Discussion**: [Issue #265](https://github.com/neiljaywarner/refuge/issues/265)

---

## 1. Executive Summary

As we migrate from Circle.so to Belong on the Spectrum before **October 31, 2026**, our core engineering discipline is **calm technology** — designing an environment that honors autistic and neurodivergent sensory needs while maintaining faithful, accountable church fellowship.

Every visual element, notification, and profile field has a cognitive cost. This guide outlines the key community trade-offs and our evidence-backed recommendations for leadership review.

---

## 2. Key Brainstorm Topics & Recommendations

### 🏷️ Brainstorm 1: Church Affiliation Badge Placement (Main Feed vs. Members Directory)

| Aspect | In the Main Feed (Every Post Card) | Strictly in Members Directory & Profile Sheet |
| :--- | :--- | :--- |
| **Visual Appearance** | Every post header shows `Name ⛪ DFW Church` or `Name 🌱 Welcoming Visitor`. | Post headers show only avatar, author name, and timestamp. Affiliation appears upon tapping the profile or browsing the Directory. |
| **Cognitive Density** | High visual noise; tags repeat on every single screen scroll; pushes discussion text down. | Low stimulus; clean typography; peaceful unhurried reading experience. |
| **Fellowship Dynamic** | Risks creating visual "in-group vs. out-group" cliques right in everyday chatter. | All members share fellowship on equal footing; church accountability is verified and discoverable. |
| **Circle.so Precedent** | ❌ Circle **does not** display custom onboarding questionnaire fields on feed cards. | ✅ Circle keeps detailed custom fields strictly inside the Member Directory and Profile Modal. |

> [!TIP]
> **Leadership Recommendation**: **Keep affiliation badges strictly inside the Members Directory and Member Profile Sheet.**  
> *Rationale*: It completely fulfills Marty's organizer requirement (every member specifies their ICOC congregation or acknowledges visitor status) without cluttering the daily devotional feed. Remember our guiding calm-tech principle: *"When in doubt, leave it out."*

---

### 🔔 Brainstorm 2: Notification Ethics & Delivery Cadence (Instant vs. Calm Batched Digests)

* **The Question**: How should members receive updates from `General Chat`, `Memes`, and `Announcements`?
* **Circle.so Pitfall**: Circle's default notification barrage is the #1 complaint in App Store reviews (causing members to uninstall or mute the app entirely).
* **Leadership Options**:
  1. *Real-Time Push Alerts*: Pushes every reply immediately (high interruption risk).
  2. *Calm Batched Digests (Recommended)*: Summarizes new reflections twice daily (e.g. 9:00 AM Morning Reflection & 6:00 PM Evening Fellowship).
  3. *Organizer High-Priority Override*: Allows pastors/organizers to flag genuine emergencies (e.g. weather cancellations or urgent prayer requests) for immediate delivery.
* **Leadership Recommendation**: Default all new members to **Calm Batched Digest**, with an explicit toggle in their settings ([PR #244](https://github.com/neiljaywarner/refuge/pull/244)).
* **Handling "Don't Allow" on Android 13+ (Spaces Drawer Policy)**:
  - *The Question*: If a member taps "Don't allow" on the system notification dialog, should the app remain completely silent forever, or show a gentle recovery toggle?
  - *Leadership Decision*: **Show a gentle, low-contrast toggle in the Spaces drawer (`"Notifications muted in system settings"` with subtitle `"Tap to adjust calm digest schedules or re-enable later"`).**
  - *Calm-Tech Balance*: The app NEVER interrupts members with repeated full-screen popups or guilt banners. The gentle tile lives quietly at the bottom of Spaces where members can discover and adjust it on their own terms ([PR #268](https://github.com/neiljaywarner/refuge/pull/268)).

---

### 👋 Brainstorm 3: Onboarding Icebreakers for `Start Here & Introduce Yourself`

* **The Question**: Neurodivergent disciples often experience intense blank-page anxiety when asked to *"introduce yourself"*. How can we help newcomers feel safe?
* **Proposed 3-Part Gentle Prompt**:
  1. **Special Interest / Hyperfocus**: *"What is a topic, craft, scripture, or hobby you love talking about?"* (e.g., sensory gardening, acoustics, Biblical Hebrew, train routes).
  2. **Sensory Comfort**: *"What does your ideal peaceful environment look like?"* (e.g., noise-canceling headphones, dim lighting, nature walks).
  3. **Fellowship & Prayer**: *"How can this community best encourage you this month?"*
* **Leadership Recommendation**: Set this prompt as the default placeholder text in `Start Here & Introduce Yourself` via Firebase Remote Config.

---

### 🎨 Brainstorm 4: Default Sensory Theme for New Visitors

* **The Question**: What should the visual mood of Belong on the Spectrum be when an unauthenticated visitor first opens [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)?
* **Available WCAG AAA Palettes**:
  - 🌿 **Sage Botanical (`Warm Calm`)**: Soft muted greens, warm off-white canvas, calming forest accents.
  - 🏛️ **Clean Slate (`High Clarity`)**: Neutral modern grey-blue with crisp high contrast text.
  - 🕯️ **Monastic Dark (`Low Stimulus`)**: Deep charcoal background with warm amber candlelight accents.
  - 🔲 **High Contrast (`Accessibility`)**: Pure stark black-and-white for low-vision members.
* **Leadership Recommendation**: Default to **Sage Botanical** for a warm, living room aesthetic that feels distinct from clinical enterprise tools.

---

### 📅 Brainstorm 5: Actually Autistic Events Format & Norms

* **The Question**: How should community Zoom calls and in-person meetups be structured?
* **Autistic-First Norms to Adopt**:
  1. **Camera Optional**: Zero pressure to be on video; chat-box participation welcomed equally.
  2. **Predictable Sensory Agendas**: Publish schedule, break times, and topic outlines 48 hours in advance.
  3. **Low-Demand Socializing**: Acknowledge that members can listen quietly without feeling obligated to speak.
* **Leadership Recommendation**: Feature these 3 norms prominently in the `Actually Autistic Events` space header.

---

### 📡 Brainstorm 6: Post-Cutover Telemetry & Crash Reporting (Crashlytics vs. PostHog vs. Appwrite Functions)

* **The Question**: Once the Oct 31 cutover is stable, should we consolidate strictly onto Firebase Crashlytics + Analytics, or migrate error logs to self-hosted Appwrite Functions / PostHog?
* **Leadership Guidance & Analysis**:
  1. **Keep Firebase Crashlytics for Crashes (Recommended)**: Unlimited free tier, automated native symbolication for Google Pixel and iOS hardware, and zero server maintenance burden.
  2. **Adopt PostHog for Product Analytics (Recommended)**: Far better than GA4 for seeing which spaces members visit, how sensory themes are adopted, and where onboarding drops off (1M events/month free).
  3. **Use Appwrite Functions for Backend Tasks (Not Crash Logging)**: Appwrite Functions are serverless compute workers (like AWS Lambda). They are ideal for compiling morning/evening calm digest batches, but cannot capture native mobile OS crashes.
* **Full Architecture Guide**: Read the comprehensive breakdown in [`docs/OBSERVABILITY_AND_ANALYTICS.md`](https://github.com/neiljaywarner/refuge/blob/main/docs/OBSERVABILITY_AND_ANALYTICS.md#post-cutover-consolidation-analysis-crashlytics-vs-posthog-vs-appwrite-functions-issue-269) ([Issue #269](https://github.com/neiljaywarner/refuge/issues/269)).

---

## 3. How to Submit Feedback on These Brainstorms

Organizers and leadership team members can share thoughts anytime:
1. **GitHub Discussion**: Post directly on [Issue #265](https://github.com/neiljaywarner/refuge/issues/265).
2. **In-App Feedback**: Tap **Feedback & Vote** in the top bar of [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) and select 💚 *Works Great*, 💡 *Idea / Tweak*, or 🛠️ *Bug / Confusing*.
3. **Weekly Cutover Sync**: Add to the agenda for the Friday Oct 23 leadership sync ahead of the 7-day overlap kickoff!
