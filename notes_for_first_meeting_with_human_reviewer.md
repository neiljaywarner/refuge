# Notes for First Meeting with Human Reviewer — Soft Launch & Community Readiness

> **Audience**: Semi-technical human reviewer (retired engineer / technical manager background).  
> **Date**: October 22, 2026  
> **Community**: [Belong on the Spectrum](https://belongonthespectrum.com) (Christian & Neurodivergent-Affirming digital fellowship)  
> **Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge)  
> **Production Web App**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) (also custom domain `belongonthespectrum.com`)  
> **Private Triage Repository**: [`neiljaywarner/belong_feedback`](https://github.com/neiljaywarner/belong_feedback)

---

## 1. Executive Summary

Belong on the Spectrum is transitioning away from a costly commercial software subscription (Circle.so at \$1,000+/year) to our own purpose-built, calm-technology community platform called **Belong** (powered by the open-source Refuge engine). 

The hard external deadline is **Saturday, October 31, 2026**, when the legacy Circle.so subscription ends. To prevent stress for community organizers and members, we are initiating a **7-day calm overlap window beginning Saturday, October 24, 2026**. During this week, both systems will remain available side-by-side. Members can explore the new platform, post reflections, and adjust their preferences without fear of disruption.

Tonight's review focuses on operational readiness: verifying that authentication, discussion spaces, sensory themes, feature voting, private feedback with annotated drawing, and calm push notifications operate reliably and respectfully.

---

## 2. TL;DR (Too Long; Didn't Read)

- **The Software Works Now**: 175+ automated unit, widget, and device BDD tests pass green on every commit. Zero static analysis errors.
- **Save \$1,000+/year**: By hosting on Firebase Edge (Google Cloud free tier), hosting costs are \$0/month for our community scale.
- **No App Store Friction**: Belong runs instantly in any mobile or desktop web browser, and prompts users with 1-tap "Add to Home Screen" (Progressive Web App / WebAPK), bypassing App Store / Play Store gatekeeping.
- **Neurodivergent-First**: Replaces high-anxiety social media patterns (like 1–5 star ratings, endless unread notification counts, and algorithmic outrage feeds) with literal 3-intent feedback, chronological unhurried feeds, and quiet sensory themes (Sage, Clean, Charcoal, High Contrast).
- **Private Feedback**: Private bug reports and ideas automatically route to a confidential private repository (`neiljaywarner/belong_feedback`), ensuring zero member PII is leaked in public trackers. Members can draw, circle, and annotate directly on screenshots before sending.

---

## 3. Frequently Asked Questions (FAQ)

### Q1: Why is there no download in the Apple App Store or Google Play Store yet?
**A**: This is an intentional product decision for soft launch:
1. **Immediate Access**: Members click a web link and are instantly inside the community without waiting for a 50MB app download or app review approvals.
2. **1-Tap PWA Installation**: On Android (Chrome), tapping "Install" creates a genuine native Android app package (WebAPK) with launcher icon, push notifications, and full-screen display. On iOS (Safari), tapping Share -> "Add to Home Screen" pins Belong cleanly with no browser address bar.
3. **No 30% Apple Tax or Approval Delays**: We can push improvements and fixes instantly without waiting 48 hours for App Store review gates.
4. **Play Store & App Store builds are already configured**: We have release APK pipelines ready and will release native store wrappers after community feedback stabilizes.

### Q2: What is Stage 1 ("Any Auth") vs. Firebase Auth?
**A**: Stage 1 was our early preview harness that let testers input their display name and email without password friction. In the active production build, we support full **Firebase Authentication** (Email & Password, Password Reset, and Passwordless Magic Links), plus an optional 1-Tap Google Sign-In toggle in preview mode.

### Q3: Why does the profile require an "ICOC Church Affiliation" question?
**A**: Belong on the Spectrum is sponsored and supported by church fellowships (partnered with DFW Church). Asking this question helps leadership understand whether a member is an existing church member or a welcoming community guest, allowing organizers to shepherd and care for everyone appropriately. Non-members simply select *"I am not a member of an ICOC church"*.

### Q4: How does private feedback protect user privacy?
**A**: Many open-source platforms accidentally publish bug reports with user email addresses, IP addresses, or device IDs on public GitHub issues. Belong solves this with **Split Routing**:
- **💚 Public Praise** ("Works Great") routes to the public encouragement counter.
- **🛠️ Bug Reports & 💡 Ideas** automatically route to our confidential private repository (`neiljaywarner/belong_feedback`). Only authorized community organizers have access.

### Q5: Can users draw on screenshots when submitting feedback?
**A**: Yes! Members can tap **"Draw / Annotate on Screenshot"** to open an interactive drawing canvas with pen colors (Red, Amber, Teal, Blue, White, Black), stroke widths, and undo. They can circle a button, point an arrow, or sketch what happened, and attach it directly to their feedback note.

---

## 4. Common Troubleshooting Guide

| Issue | Likely Cause | Resolution Steps |
| :--- | :--- | :--- |
| **"PWA install banner does not appear"** | Browser already has app installed or iOS Safari requires manual Share action. | On iOS Safari, tap the **Share icon (box with up arrow)** -> scroll down -> tap **"Add to Home Screen"**. On Android Chrome, tap the 3-dot menu -> **"Install App"**. |
| **"Push notifications not received on Android"** | Android 13+ requires explicit runtime permission for app notifications. | Tap **"Notifications"** in bottom navigation, then tap **"Enable Calm Notifications"** to trigger the system permission prompt, or enable in Android Settings -> Apps -> Belong -> Notifications. |
| **"White screen or cached old build on web"** | Browser service worker holding previous staging cache. | Hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+F5` (Windows). Belong automatically checks for service worker updates on startup. |
| **"Forgotten password"** | Member created password account but forgot secret. | Tap "Sign In" -> "Forgot password?" -> enter email. A secure Firebase password reset email will be delivered in <60 seconds. |

---

## 5. Milestone Horizon Roadmap

Here is how our engineering deliverables are structured across project phases:

```
[Now] ───────► [Oct 24] ───────► [Oct 31] ───────► [First Week] ───────► [First Month] ───────► [2026-2027]
Phase:       Soft Launch         Circle Cutover     Initial Feedback     Analytics & APNs     Someday / Maybe
```

### A. Completed Before Alpha (`v0.6.0` – `v0.8.0-alpha`) ✅
- [x] Cross-platform Flutter foundation running on Web, Android, iOS, and Desktop.
- [x] Official Belong branding: Gold infinity loop cross logo, sensory-soothing color palette.
- [x] 8 Community Spaces (Prayer, General Chat, Quiet Musings, Bible Study, Special Interests, Events, Tech Help, Saved Items).
- [x] Sensory Theme Engine: 4 distinct modes (Clean, Sage, Charcoal Dark, High Contrast) and font scaling options.
- [x] Initial seed data and chronological reflection feed.

### B. Completed Before Beta (`v0.8.5` – `v0.9.0-rc`) ✅
- [x] Production Firebase Auth (Email/Password, Magic Link, Password Reset, ICOC affiliation confirmation).
- [x] Threaded discussion comments and nested replies under community reflections.
- [x] Real-time community Feature Voting board with 1-tap voting and 0-vote baseline (#304).
- [x] Member profile screen with post/comment counters (#300).
- [x] Multi-criteria feed sorting (Latest, For You, New Activity, Oldest, Popular, Likes, Alphabetical) (#325).
- [x] Bookmarking / Save for Later space (#155).
- [x] In-app Avatar photo capture, gallery upload, square cropping, and polite permission handling (#333).
- [x] Draw-on feedback canvas with scribble screenshot attachment and private repository dispatch (`neiljaywarner/belong_feedback`) (#335).

### C. Stuff to Finish Before Soft Launch (Saturday, October 24, 2026) 🗓️
- [ ] **Unified General Settings Screen** (`feat(settings)` #336):
  Consolidate sensory themes, font scaling, notification thresholds, and developer preview toggles into one clean settings screen.
- [ ] **Marty / Leadership Circle Review**:
  Conduct 15-minute maintainer walkthrough comparing Circle spaces against Belong.
- [ ] **Circle.so Data Migration Test Run**:
  Run `tool/import_circle_csv.dart --dry-run` against sample Circle export.
- [ ] **Welcome Announcement Banner**:
  Set launch day welcome greeting in Firebase Remote Config.
- [ ] **Production Web Deployment**:
  Deploy release build to `https://belongonthespectrum.web.app` and custom domain `belongonthespectrum.com`.

### D. Stuff to Finish Before Cutover (Saturday, October 31, 2026) 🏁
- [ ] Monitor dual-system adoption during the 7-day overlap window (Oct 24–31).
- [ ] Verify members have introduced themselves and joined their favorite spaces.
- [ ] Post final reminder in legacy Circle announcements.
- [ ] Cancel Circle.so recurring billing cleanly on Oct 31, completing migration.

### E. First Week Post-Launch
- [ ] Triage first batch of feedback notes from `neiljaywarner/belong_feedback`.
- [ ] Address any UI font size or contrast feedback from older community members.
- [ ] Review daily active reflection counts and comment engagement in Firebase Analytics.

### F. First Month Post-Launch
- [ ] **iOS APNs Push Notifications**: Native Apple Push Notification service verification on physical iPhones (#165).
- [ ] **Public 1-Tap Google & Apple Sign-In**: Graduate OAuth buttons from Preview Mode to default sign-in screen once domain verification DNS records propagate.
- [ ] **Automated Daily Community Digest**: Optional quiet email summary for members who prefer not to receive push notifications.

### G. This Year (2026)
- [ ] Native Google Play Store internal tester track release.
- [ ] Audio reflection snippets (short voice memos with auto-captions for non-typing autistic members).
- [ ] Actually Autistic Events calendar live RSVP synchronization.

### H. "Someday / Maybe" Items (Future Exploration)
Items that are valuable ideas but intentionally deferred to protect launch simplicity:
- Direct 1-on-1 encrypted private messaging (evaluated in ADR-0005, deferred to avoid moderation risk).
- Federated ActivityPub / Mastodon community bridging.
- AI quiet moderator assistant to summarize high-volume discussion threads.
- **Browse all Someday / Maybe items on GitHub**:  
  👉 [**GitHub Issues labeled `someday-maybe`**](https://github.com/neiljaywarner/refuge/issues?q=label%3Asomeday-maybe)

---

## 6. Pre-Launch Verification Checklist for Tonight's Human Review

Use this checklist during tonight's walkthrough on real devices:

```
[ ] 1. SENSORY THEME TESTING
       - Tap the theme button in top navigation bar.
       - Switch between Clean ☀️, Sage 🌿, Dark 🌙, and High Contrast 👁️.
       - Verify text remains readable, contrast is calm, and zero flickering occurs.

[ ] 2. MEMBER SIGN-IN & PROFILE
       - Tap "Sign In" in upper right.
       - Test entering name, email, and selecting church congregation affiliation.
       - Tap your avatar circle -> Tap the camera badge -> Verify Avatar Picker opens.
       - Confirm Take Photo / Choose Gallery options appear with polite permission handling.

[ ] 3. DISCUSSION FEEDS & SORTING
       - Switch between Spaces (Prayer, General Chat, Saved for Later).
       - Tap the Feed Sort bar -> Select "Popular", "Alphabetical", "Latest".
       - Tap a reaction emoji (🙏 🕊️ 🤝 💡) -> Verify count increments instantly.

[ ] 4. FEATURE VOTING BOARD
       - In subheader, tap "Vote & Feedback" -> View "Vote on Features (WIP)" tab.
       - Tap the thumb button next to any roadmap item.
       - Verify vote count increments optimistically.

[ ] 5. PRIVATE FEEDBACK WITH DRAWING CANVAS
       - In "Vote & Feedback", switch to "Share Feedback" tab.
       - Select "🛠️ Bug / Confusing" sentiment.
       - Tap "Draw / Annotate on Screenshot".
       - Scribble an arrow or circle with the pen, tap "Attach Scribble".
       - Type "hi, feedback from 20-octoberpm".
       - Tap "Send Private Feedback".
       - Confirm success banner: "Thank you! Your note was securely routed to our private triage queue..."
       - Confirm issue #1 exists in neiljaywarner/belong_feedback.

[ ] 6. PROGRESSIVE WEB APP (PWA) EXPERIENCE
       - Open https://belongonthespectrum.web.app on your phone browser.
       - Add to Home Screen.
       - Launch from home screen icon -> Verify full-screen immersive display with zero URL bar.
```

---

## 7. Appendix: Technical Reference & Architecture

- **Frontend Architecture**: Flutter 3.47 / Dart 3.13, Riverpod 2.6 (`HookConsumerWidget`), feature-first package structure (`lib/src/features/*`).
- **Backend & Cloud**: Google Cloud Firebase Edge (Firestore, Firebase Authentication, Firebase Storage, Cloud Functions, Remote Config).
- **Test Automation Suite**: 175 tests (BDD feature specs via `patrol_finders`, unit tests via `package:test`, real hardware device driving via Maestro MCP & Patrol MCP).
- **Privacy Architecture**: Zero-PII policy in public repositories. Confidential feedback isolation via `neiljaywarner/belong_feedback`.
- **Architectural Decision Records**:
  - `docs/adr/0001-sensory-modes.md`: High contrast and sensory calm mode specifications.
  - `docs/adr/0007-neurodivergent-first-ux-and-feedback-evaluation.md`: 3-intent feedback vs. 5-star ratings.
  - `docs/adr/0009-piece-by-piece-vs-one-shot-appwrite-firebase-hybrid.md`: Pluggable backend adapter seams.
