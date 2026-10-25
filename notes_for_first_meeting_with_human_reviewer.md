# Notes for First Meeting with Human Reviewer — Soft Launch & Community Readiness

> **Audience**: Semi-technical human reviewer (retired engineer / technical manager background).  
> **Date**: October 24, 2026  
> **Community**: [Belong on the Spectrum](https://belongonthespectrum.com) (Christian & Neurodivergent-Affirming digital fellowship)  
> **Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge)  
> **Production Web App**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) (also custom domain `belongonthespectrum.com`)  
> **Private Triage Repository**: [`https://github.com/neiljaywarner/belong_feedback`](https://github.com/neiljaywarner/belong_feedback)

---

## 1. Executive Summary

Belong on the Spectrum is transitioning away from a costly commercial software subscription (Circle.so at \$1,000+/year) to our own purpose-built, calm-technology community platform called **Belong** (powered by the open-source Refuge engine). 

The hard external deadline is **Saturday, October 31, 2026**, when the legacy Circle.so subscription ends. To prevent stress for community organizers and members, we are initiating a **7-day calm overlap window beginning Saturday, October 24, 2026**. During this week, both systems will remain available side-by-side. Members can explore the new platform, post reflections, and adjust their preferences without fear of disruption.

Tonight's review focuses on operational readiness: verifying that authentication, discussion spaces, sensory themes, feature voting, private feedback with annotated drawing, and calm push notifications operate reliably and respectfully.

---

## 2. TL;DR & Soft Launch Readiness Snapshot

### 📊 Overall Readiness Grade: **B+ (84 / 100)**

- **The Software Works Now**: 230+ automated unit, widget, and device BDD tests pass green on every commit. Zero static analysis errors. Core media stack line coverage is **97.0%**.
- **Automated Device Verification**: Tested across physical Google Pixels (`56091JEBF14039`, `58221JEBF20835`) and Android emulators via Maestro MCP, Patrol MCP, and Marionette CLI with zero-prompt visual regression capture.
- **Save \$1,000+/year**: By hosting on Firebase Edge (Google Cloud Free Spark Tier), hosting costs are **\$0.00/month** for our community scale.
- **Safe Moderation & GDPR Compliance**: In-app account self-deletion ([PR #595](https://github.com/neiljaywarner/refuge/pull/595)), admin soft-ban primitives ([PR #585](https://github.com/neiljaywarner/refuge/pull/585)), and sign-in wall ([PR #575](https://github.com/neiljaywarner/refuge/pull/575)) are fully integrated.
- **No App Store Friction**: Belong runs instantly in any mobile or desktop web browser, and prompts users with 1-tap "Add to Home Screen" (Progressive Web App / WebAPK), bypassing App Store / Play Store gatekeeping.
- **Neurodivergent-First**: Replaces high-anxiety social media patterns with literal 3-intent feedback, chronological unhurried feeds, and quiet sensory themes (Sage Botanical, Classic Sanctuary, Charcoal Night, WCAG AAA High Contrast).
- **Private Feedback Canvas**: Members can open a screenshot drawing canvas, sketch circles/arrows, and submit bug reports or ideas directly to our private GitHub triage queue (`neiljaywarner/belong_feedback`) without exposing emails or IP addresses ([PR #502](https://github.com/neiljaywarner/refuge/pull/502)).

---

## 3. The 3 Next Steps to Full Soft-Launch Readiness (A+ Grade)

To move from our current **84% (B+)** to a complete **100% (A+) public soft launch**, we have sequenced the final work into 3 clear priorities:

1. **Step 1: Production Data Scrub & First-Time Visitor Calm Polish ([#501](https://github.com/neiljaywarner/refuge/issues/501), [#500](https://github.com/neiljaywarner/refuge/issues/500))**:
   - Clean out developer test junk posts (`"blah your face"`, test tokens) and seed 4–5 genuine reflections from community leaders.
   - Remove duplicate "General Chat" space entry and resolve the `"Coming Soon"` label on live Events.
   - Start signed-out guests at notification badge `0` (removing the fake `3` unread badge) and persist feature upvotes in browser `localStorage` to eliminate reload vote resets.

2. **Step 2: Real-Member Direct Messaging & Web History Navigation ([#441](https://github.com/neiljaywarner/refuge/issues/441), [#499](https://github.com/neiljaywarner/refuge/issues/499), [#485](https://github.com/neiljaywarner/refuge/issues/485))**:
   - Update the direct message recipient picker to query real registered members from Firestore instead of hardcoded sample users (`kDevFellowshipMembers`).
   - Push browser history entries for space and tab transitions so clicking the browser **Back** button navigates within Belong instead of exiting the PWA.
   - Verify and harden feed sort/filter chips (`Latest`, `For you`, `New Activity`) against unhandled gesture exceptions on dark themes.

3. **Step 3: CI/CD Auto-Deploy & Branded Support Setup ([#493](https://github.com/neiljaywarner/refuge/issues/493), [#495](https://github.com/neiljaywarner/refuge/issues/495), [PR #507](https://github.com/neiljaywarner/refuge/pull/507))**:
   - Merge PR #507 to stamp git commit SHA, UTC build time, and version tags into About Belong and `version.json`.
   - Add `.github/workflows/deploy.yml` to automatically build and deploy to Firebase Hosting on push to `main`.
   - Configure `support@belongonthespectrum.com` via free Cloudflare Email Routing to personal Gmail for branded, zero-cost support.

---

## 4. Frequently Asked Questions (FAQ)

### Q1: Why is there no download in the Apple App Store or Google Play Store yet?
**A**: This is an intentional product decision for soft launch:
1. **Immediate Access**: Members click a web link and are instantly inside the community without waiting for a 50MB app download or app review approvals.
2. **1-Tap PWA Installation**: On Android (Chrome), tapping "Install" creates a genuine native Android app package (WebAPK) with launcher icon, push notifications, and full-screen display. On iOS (Safari), tapping Share -> "Add to Home Screen" pins Belong cleanly with no browser address bar.
3. **No 30% Apple Tax or Approval Delays**: We can push improvements and fixes instantly without waiting 48 hours for App Store review gates.
4. **Play Store & App Store builds are already configured**: We have release APK pipelines ready and will release native store wrappers after community feedback stabilizes.

### Q2: What is Stage 1 ("Any Auth") vs. Firebase Auth?
**A**: Stage 1 was our early preview harness that let testers input their display name and email without password friction. In the active production build, we support full **Firebase Authentication** (Email & Password, Password Reset, and Passwordless Magic Links), plus an optional 1-Tap Google Sign-In toggle in preview mode, protected by our canonical sign-in wall ([PR #575](https://github.com/neiljaywarner/refuge/pull/575)).

### Q3: Why does the profile require an "ICOC Church Affiliation" question?
**A**: Belong on the Spectrum is sponsored and supported by church fellowships (partnered with DFW Church). Asking this question helps leadership understand whether a member is an existing church member or a welcoming community guest, allowing organizers to shepherd and care for everyone appropriately. Non-members simply select *"I am not a member of an ICOC church"* from the searchable dropdown.

### Q4: How does private feedback protect user privacy?
**A**: Many open-source platforms accidentally publish bug reports with user email addresses, IP addresses, or device IDs on public GitHub issues. Belong solves this with **Split Routing**:
- **💚 Public Praise** ("Works Great") routes to the public encouragement counter.
- **🛠️ Bug Reports & 💡 Ideas** are routed to our private GitHub triage queue (`neiljaywarner/belong_feedback`) with sanitized logs and inline screenshot annotations, keeping sensitive member data completely safe.

### Q5: Can users draw on screenshots when submitting feedback?
**A**: Yes! Members can open an interactive drawing canvas, sketch arrows and circles, pick from multiple colors, and submit the drawing directly with their bug report.

---

## 5. Milestone Horizon Roadmap

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

### B. Completed Before Beta (`v0.8.5` – `v0.9.2`) ✅
- [x] Production Firebase Auth (Email/Password, Magic Link, Password Reset, Sign-in Wall #574).
- [x] Threaded discussion comments and nested replies under community reflections.
- [x] Real-time community Feature Voting board with 1-tap voting.
- [x] Member profile screen with post/comment counters (#300).
- [x] Multi-criteria feed sorting (Latest, For You, New Activity, Oldest, Popular, Likes, Alphabetical) (#325).
- [x] Distinct community space routing and private Saved for Later bookmarks (#445, #446 / PR #465).
- [x] Compact tap-to-expand mobile reflection composer (#447 / PR #474).
- [x] Persistent member profile with searchable ICOC church dropdown (#448 / PR #479).
- [x] In-app avatar and meme photo capture, gallery upload, and square cropping (PR #503).
- [x] In-app drawing feedback canvas with direct GitHub triage queue dispatch (PR #502).
- [x] Remote Config Admin Mode with user soft-deletion / banning (#579 / PR #585).
- [x] In-app account self-deletion with GDPR compliance (#589 / PR #595).
- [x] Native launcher badge MethodChannel for Pixel dots (#331 / PR #444).
- [x] Notification tap deep-linking architecture (#330 / PR #511).
- [x] Precise build identity stamps with commit SHA and UTC timestamp (PR #507).
