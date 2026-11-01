# 🧪 Notes for 2:00 PM Friend QA Session — Final Pre-Launch Walkthrough

> **Date**: October 24, 2026 — 2:00 PM (CDT)  
> **Session Goal**: Conduct an unhurried, focused walkthrough of Belong on the Spectrum to uncover any genuine launch blockers, identify polish opportunities, and finalize our soft-launch punch list before opening the doors to community members.  
> **Production Web App**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)  
> **Android / PWA**: Installable via Chrome on Android ("Install App" or Add to Home Screen)

---

## 🎯 Soft Launch Readiness Snapshot: **B+ (84 / 100)**

Belong on the Spectrum is 84% ready for public soft launch. The underlying architecture, sensory accessibility, security moderation, and automated tests (230+ green tests) are solid. Today's walkthrough is designed to test real-world usability and ensure our punch list covers everything needed for an A+ launch.

---

## ✅ Part 1: Already Verified & Resolved on `main` (No Need to Re-Test)

The following items from earlier testing rounds have been **fully fixed, verified with automated tests, and merged to `main`**:

| Feature / Fix | Verification / PR | Result |
| :--- | :--- | :--- |
| **Distinct Feed Routing Across Spaces** | PR #465 ([#445](https://github.com/neiljaywarner/refuge/issues/445), [#446](https://github.com/neiljaywarner/refuge/issues/446)) | General Chat, Start Here, and Announcements now stream their own distinct reflections. |
| **Private Saved for Later Sanctuary** | PR #465 ([#446](https://github.com/neiljaywarner/refuge/issues/446)) | Public composer removed; Saved for Later acts strictly as private bookmarks. |
| **Compact Reflection Composer on Mobile** | PR #474 ([#447](https://github.com/neiljaywarner/refuge/issues/447)) | Collapsed single-line bar with modal expander; feeds are no longer crowded out. |
| **Persistent Profile & Church Dropdown** | PR #479 ([#448](https://github.com/neiljaywarner/refuge/issues/448)) | Name and ICOC church selection persist across reloads via clean searchable dropdown. |
| **Sign-In Wall for Safe Fellowship** | PR #575 ([#574](https://github.com/neiljaywarner/refuge/issues/574)) | Guarantees authenticated community access; prevents anonymous trolling. |
| **Admin Moderation & Account Deletion** | PR #585, #595 ([#579](https://github.com/neiljaywarner/refuge/issues/579), [#589](https://github.com/neiljaywarner/refuge/issues/589)) | In-app account self-deletion and admin soft-ban primitives operational. |
| **Direct GitHub Feedback Canvas** | PR #502 ([#460](https://github.com/neiljaywarner/refuge/issues/460)) | In-app scribble tool directly dispatches screenshot annotations to private triage queue. |

---

## ⚠️ Part 2: Appendix of Known In-Flight Fixes (DO NOT COUNT AS DEFECTS)

To make our 2:00 PM meeting as fast and productive as possible, **autonomous agents are already actively working on the following items**. Please do **not** count or spend time logging them:

| # | Known In-Flight Issue | Current Status / Ticket |
| :---: | :--- | :--- |
| **1** | **Guest Demo Mode shows badge `3` + test feed junk**:<br>Signed-out guests see an unread badge `3`, and the live feed has leftover dev test posts ("blah your face", test tokens). | 🛠️ In-Flight fix: Data scrub script & default guest unread count to 0 ([Issue #501](https://github.com/neiljaywarner/refuge/issues/501)). |
| **2** | **Guest feature votes reset after page reload**:<br>Reloading the web page resets the "Vote for..." button state even though the vote count was incremented, allowing double-voting. | 🛠️ In-Flight fix: Storing anonymous voter ID in browser `localStorage` ([Issue #500](https://github.com/neiljaywarner/refuge/issues/500), [#487](https://github.com/neiljaywarner/refuge/issues/487)). |
| **3** | **Browser Back button exits Belong on web**:<br>Pressing the browser Back button exits the app rather than navigating back to previous in-app spaces/tabs. | 🛠️ In-Flight fix: Synchronizing Flutter Web routing with browser history stack ([Issue #499](https://github.com/neiljaywarner/refuge/issues/499)). |
| **4** | **DM composer only lists sample members**:<br>The direct message recipient search currently only suggests mock profiles (`kDevFellowshipMembers`) rather than real registered accounts. | 🛠️ In-Flight fix: Live Firestore query for real fellowship member accounts ([Issue #441](https://github.com/neiljaywarner/refuge/issues/441)). |
| **5** | **Dark feed sort button tap crash hardening**:<br>Tapping sort options on dark theme was reported to cause an unhandled state crash on certain screen densities. | 🛠️ In-Flight fix: Full test pyramid hardening for all sort and filter chips ([Issue #485](https://github.com/neiljaywarner/refuge/issues/485)). |
| **6** | **Password visibility eye toggle**:<br>Adding password show/hide eye icon to sign-in and registration fields. | 🛠️ In-Flight fix: PR #594 in review ([Issue #593](https://github.com/neiljaywarner/refuge/issues/593)). |
| **7** | **Meme photo upload crop & zoom**:<br>Square cropping and pan/zoom for meme uploads. | 🛠️ In-Flight fix: PR #600 in review ([Issue #587](https://github.com/neiljaywarner/refuge/issues/587)). |

---

## 🎯 Core QA Walkthrough Plan (What We WANT to Test Today)

Please walk through the following 6 core flows during our call:

### Flow 1: First Impression & Mobile PWA Installation
- [ ] Open [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) in your mobile browser (iPhone Safari or Android Chrome).
- [ ] Test "Add to Home Screen" or "Install App".
- [ ] Launch Belong from your phone's home screen.
- [ ] Verify: Does the app open in full screen without browser bars? Are the gold infinity loop cross and Belong title crisp?

### Flow 2: Sensory Themes & Low-Stimulation Contrast (Core Differentiator!)
- [ ] Tap the **Sensory Themes** icon in the app bar.
- [ ] Switch between the 4 palettes:
  - ☀️ **Classic Sanctuary** (Calm parchment, soothing neutral)
  - 🌿 **Sage Botanical** (Soft green tones, low stimulation)
  - 🌙 **Charcoal Night** (Muted dark mode)
  - 👁️ **WCAG AAA High Contrast** (Bold black and yellow for visual accessibility)
- [ ] Verify: Does the text stay sharp? Is the transition smooth with zero screen flickering or blinding flashes?

### Flow 3: Account Sign-Up & Password Reset
- [ ] Tap **"Sign In"** in the upper right.
- [ ] Test signing up with a personal or test email.
- [ ] Sign out, then tap **"Forgot password?"**.
- [ ] Enter your email and submit.
- [ ] Verify: Do you receive the Firebase reset email within 60 seconds? Does the reset link function properly?

### Flow 4: Discussion Feeds, Sorting & Encouraging Reactions
- [ ] Navigate to the **Prayer Sanctuary** or **Weekly Bible Study** space.
- [ ] Try the calm reaction buttons under a reflection:
  - 🙏 **Praying**
  - 🕊️ **Peace**
  - 🤝 **Standing With You**
  - 💡 **Encouraged**
- [ ] Verify: Does the counter update immediately with no lag?
- [ ] Tap the **Sort Bar** above the feed (`Latest`, `For You`, `Popular`).
- [ ] Verify: Does the feed reorder cleanly?

### Flow 5: Threaded Discussions & Compact Mobile Composer
- [ ] Tap on any reflection card to open the **Threaded Discussion View**.
- [ ] Type an encouraging reply (e.g. *"Standing with you in prayer today!"*) and post.
- [ ] Test replying directly to a previous comment.
- [ ] On mobile, test the compact composer at the bottom of the feed:
  - Tap to expand.
  - Add text and an intent tag (`[Prayer Request]`, `[Comfort Only]`, `[Bible Deep-Dive]`).
  - Submit the reflection.
- [ ] Verify: Does the composer expand smoothly and collapse after posting without covering older messages?

### Flow 6: Private Feedback with Draw-On Screenshot Canvas
- [ ] In the subheader, tap **"Vote & Feedback"** -> **"Share Feedback"**.
- [ ] Select sentiment: **"🛠️ Bug / Confusing"**.
- [ ] Tap **"Draw / Annotate on Screenshot"**.
- [ ] Scribble an arrow or circle with the pen tool (try changing colors: Teal, Amber, Red).
- [ ] Tap **"Attach Scribble"**, enter a short comment, and submit.
- [ ] Verify: Does the confirmation message clearly confirm that your note and screenshot were safely routed to the organizers?

---

## 📝 Findings & Punch-List Log (Fill In During Call)

Use this table to record any new observations during our 2:00 PM session:

| Item # | Screen / Area | What Happened (Expected vs Actual) | Severity (P0 / P1 / P2) | Action Item / Owner |
| :---: | :--- | :--- | :---: | :--- |
| **1** | | | | |
| **2** | | | | |
| **3** | | | | |
| **4** | | | | |
| **5** | | | | |

### Severity Scale:
- 🔴 **P0 (Blocker)**: Crash, blank white screen, cannot log in, or data loss. *Must fix before members log in.*
- 🟡 **P1 (Soft-Launch Polish)**: Visual overlap, awkward button padding, or confusing phrasing. *Fix during 7-day overlap window.*
- 🟢 **P2 (Nice-to-Have)**: Future feature request or cosmetic preference. *Track in GitHub for v1.0 in December.*
