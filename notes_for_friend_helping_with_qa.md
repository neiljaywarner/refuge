# 🧪 Notes for 2:00 PM Friend QA Session — Final Pre-Launch Walkthrough

> **Date**: October 24, 2026 — 2:00 PM (CDT)  
> **Session Goal**: Conduct an unhurried, focused walkthrough of Belong on the Spectrum to uncover any genuine launch blockers, identify polish opportunities, and finalize our soft-launch punch list before opening the doors to community members.  
> **Production Web App**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) (`v0.9.1+2`)  
> **Android / PWA**: Installable via Chrome on Android ("Install App" or Add to Home Screen)

---

## ⚠️ Appendix / Known In-Flight Fixes (DO NOT COUNT / ALREADY IN PROGRESS)

To make our 2:00 PM meeting as fast and efficient as possible, **another autonomous agent is already actively fixing the following 5 issues right now**. You do **not** need to test, log, or count these items:

| # | Known Issue Description | Current Status / Ticket |
| :---: | :--- | :--- |
| **1** | **Duplicate messages across Community Spaces**:<br>Viewing General Chat, Start Here, Announcements, or Memes shows the same default reflections feed ("Welcome to Belong..."). | 🛠️ In-Flight fix: Backend space routing is being expanded to isolate each space's unique post stream ([Issue #445](https://github.com/neiljaywarner/refuge/issues/445)). |
| **2** | **"Saved for Later" space posts to General Chat**:<br>The Saved for Later space currently allows public posting and redirects reflections to General Chat instead of acting strictly as a private bookmark list. | 🛠️ In-Flight fix: Reflection composer is being removed from Saved for Later, making it 100% private bookmarks ([Issue #446](https://github.com/neiljaywarner/refuge/issues/446)). |
| **3** | **Android page layout: Composer crowds out messages**:<br>On mobile screens, the reflection composer and stacked headers take up over 65% of the viewport, crowding out the message feed. | 🛠️ In-Flight fix: Moving composer into a compact, collapsible single-line bar with modal sheet ([Issue #447](https://github.com/neiljaywarner/refuge/issues/447)). |
| **4** | **Sign-in / Profile: Display name & ICOC church selection don't persist; prefer dropdown**:<br>Profile selections are lost on page refresh, and church selection currently uses buttons instead of a clean dropdown selector. | 🛠️ In-Flight fix: Migrating to standard `DropdownButtonFormField` and adding persistent storage ([Issue #448](https://github.com/neiljaywarner/refuge/issues/448)). |
| **5** | **Wiki / PWA instructions missing explicit starting URL**:<br>PWA guide needs Step 0: "Open `belongonthespectrum.web.app` in your phone's browser". | 🛠️ In-Flight fix: Wiki documentation updated ([Issue #449](https://github.com/neiljaywarner/refuge/issues/449)). |

---

## 🎯 High-Priority QA Test Plan (What We WANT to Test Today)

Please walk through the following 7 core flows during our call:

### Flow 1: First Impression & PWA Installation
- [ ] Open [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) in your desktop browser (Chrome/Edge/Safari).
- [ ] Open the same link in your mobile browser (iPhone Safari or Android Chrome).
- [ ] Test "Add to Home Screen" or "Install App".
- [ ] Verify: Does the app launch cleanly without a browser address bar? Are the gold infinity loop cross and "Belong" title visible?

### Flow 2: Sensory Themes & Accessibility (Core Differentiator!)
- [ ] Tap the **Sensory Themes** button in the top navigation bar.
- [ ] Switch between the 4 palettes:
  - ☀️ **Classic Clean** (Neutral, calm parchment)
  - 🌿 **Sage Botanical** (Gentle greens, low sensory stimulation)
  - 🌙 **Charcoal Night** (Soothing dark mode)
  - 👁️ **High Contrast** (WCAG AAA compliant deep black & yellow)
- [ ] Verify: Does text remain sharp and readable? Is there any screen flickering, jarring animation, or unreadable contrast?

### Flow 3: Authentication & Password Recovery
- [ ] In the upper right, tap **"Sign In"**.
- [ ] Test signing up with a test email and password.
- [ ] Sign out, then tap **"Forgot password?"**.
- [ ] Enter your email and tap submit.
- [ ] Verify: Do you receive the Firebase password reset email within 60 seconds? Does the reset link work?

### Flow 4: Discussion Feeds, Sorting & Reactions
- [ ] View the **Prayer Sanctuary** or **Weekly Bible Study** space.
- [ ] Tap each reaction button beneath a reflection:
  - 🙏 **Praying**
  - 🕊️ **Peace**
  - 🤝 **Standing With You**
  - 💡 **Encouraged**
- [ ] Verify: Does the count increment immediately (optimistic UI)?
- [ ] Tap the **Sort Bar** above the feed:
  - Try **"Latest"**, **"For You"**, **"Popular"**, and **"Alphabetical"**.
  - Verify: Does the list reorder smoothly without crashing?

### Flow 5: Threaded Comments & Nested Replies
- [ ] Tap on any reflection card to open the **Threaded Discussion View**.
- [ ] Type a kind test comment (e.g. *"Thinking of you today, thank you for sharing."*) and post it.
- [ ] Tap **"Reply"** on an existing comment to create a nested reply.
- [ ] Verify: Does the reply appear properly indented underneath the parent comment?

### Flow 6: Feature Roadmap & Community Voting
- [ ] In the subheader, tap **"Vote & Feedback"** -> **"Vote on Features (WIP)"**.
- [ ] Review the community roadmap items (e.g. Quiet Room Soundscapes, Calendar Events).
- [ ] Tap the **Thumbs Up / Upvote** icon on an item.
- [ ] Verify: Does the vote count increment immediately? Refresh the page—does your vote persist?

### Flow 7: Private Feedback & Draw-On Screenshot Canvas
- [ ] Switch to the **"Share Feedback"** tab.
- [ ] Select sentiment: **"🛠️ Bug / Confusing"**.
- [ ] Tap **"Draw / Annotate on Screenshot"**.
- [ ] Scribble an arrow or circle with the pen tool (try changing colors: Red, Amber, Teal).
- [ ] Tap **"Attach Scribble"** and enter a short message.
- [ ] Tap **"Send Private Feedback"**.
- [ ] Verify: Does the success banner confirm: *"Thank you! Your note was securely routed to our private triage queue"*?

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

---

## ⏱️ Meeting Schedule (45–60 mins)
- **0:00 – 0:10**: Welcome, review the 5 in-flight items in the Appendix, set scope.
- **0:10 – 0:35**: Live testing across Flows 1–7 on your phone and computer.
- **0:35 – 0:45**: Triage findings in the Punch-List table above and identify P0 blockers vs P1 polish.
- **0:45 – 0:50**: Final go/no-go recommendation for opening the 7-day soft-launch window.
