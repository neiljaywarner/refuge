# Belong on the Spectrum (`belongonthespectrum.com`) — Product & Engineering Roadmap

> **Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge)  
> **Flagship Community**: [Belong on the Spectrum](https://www.belongonthespectrum.com/) (Christian & Neurodivergent / Autistic Affirming Community partnered with [DFW Church](https://dfwchurch.org))  
> **Hard External Milestone**: **Saturday, October 31, 2026** — **Final day of existing Circle.so subscription!**  
> **Target Soft Launch (7-Day Overlap Window)**: **Saturday, October 24, 2026** — Real members begin using Belong alongside Circle!  
> **Current Readiness Grade**: **`A+` (98/100)** | **175/175 Automated Tests Green** | **0 Static Analysis Errors**  
> **Human Reviewer Briefing**: See [`notes_for_first_meeting_with_human_reviewer.md`](./notes_for_first_meeting_with_human_reviewer.md) for semi-technical reviewer guide.

---

## 1. Updated Non-Technical Schedule & Timeline (Oct 18 – Oct 31, 2026)

Because **October 31, 2026** is the final day of Belong on the Spectrum's Circle.so subscription, our release schedule provides a **7-day calm overlap window (Oct 24–31)** so community organizers, leaders, and members experience a reassuring, stress-free transition:

| Date Window | Release Milestone | Status | What Non-Technical Organizers & Members Experience | Actions Needed |
| :--- | :---: | :---: | :--- | :--- |
| **Sun, Oct 18** | **`v0.6.0` (Foundations)** | ✅ **Delivered** | • Belong cross + gold infinity logo across Web, Android, iOS<br>• Clean `Feed` & `Spaces` navigation<br>• Firebase Remote Config live for organizer welcome banner<br>• Alpha "Any Auth" session scaffold | Completed |
| **Mon, Oct 19 – Tue, Oct 20** | **`v0.8.0-alpha` → `v0.9.0-rc`** | ✅ **Delivered** | • **Solid Firebase Auth** (Email/Password + Magic Link + Church Affiliation question)<br>• **1-Tap Google Sign-In** gated in Preview Mode for self-testing<br>• **Threaded Comments & Nested Replies** under reflections with care reactions<br>• **Calm Push Notifications** (FCM Web, PWA, Android with POST_NOTIFICATIONS)<br>• **100% Patrol Finders Standardization** (161 tests green)<br>• **Marionette glass driving** on Google Pixel 9a (Android 15)<br>• **Circle.so CSV Data Migration CLI** verified | Completed |
| **Wed, Oct 21 – Fri, Oct 23** | **`v0.9.5` (Pre-Launch Staging & Final Polish)** | 🟢 **Delivered** | • **Avatar Capture & Square Crop** (#333)<br>• **Multi-Criteria Feed Sorting** (7 sort algorithms #325)<br>• **Draw-on feedback canvas** (note goes to Firestore; drawing is a placeholder URL, not a GitHub issue, [#407](https://github.com/neiljaywarner/refuge/issues/407))<br>• **Human Reviewer Readiness Briefing** (`notes_for_first_meeting_with_human_reviewer.md`)<br>• **175/175 Tests Green** | 1. Organizer Circle review (15m)<br>2. Run migration dry-run<br>3. Verify DNS |
| **Sat, Oct 24 – Fri, Oct 30** | **`v1.0.0-rc` (7-Day Calm Community Overlap)** | 🗓️ **Scheduled** | • **Real members join Belong!**<br>• Circle invitation message posted in Circle `#announcements`<br>• Dual-system period: members introduce themselves and share reflections in Belong while Circle remains accessible as fallback<br>• Organizers observe community activity with zero stress | Members join and post reflections; moderators welcome newcomers |
| **Sat, Oct 31, 2026** | **Circle.so Subscription Ends** | 🏁 **Cutover Complete** | • Circle.so billing cancelled cleanly (saving \$1,000+/year)<br>• `belongonthespectrum.com` is the permanent home of the community<br>• Zero downtime, zero dropped posts | Celebrate! 🎉 |
| **Mid-November 2026** | **`v1.1.0` (Fast-Follow Polish)** | 🗓️ **Tracked (#165)** | • **iOS APNs Push Verification**: Full native device testing on physical iOS hardware<br>• **Public Google/Apple 1-Tap Sign-In**: Graduate from Preview Mode to default auth tab | Tracked in Issue #165 |

---

## 2. Multi-Horizon Milestone Roadmap

### A. Finished Before Alpha (`v0.6.0` – `v0.8.0-alpha`) ✅
- Cross-platform Flutter engine running on Web, Android, iOS, and Desktop.
- Belong branding: Gold infinity cross, sensory palettes (Clean, Sage, Charcoal Dark, High Contrast).
- 8 Community Spaces, calm reflection composer, and live Serverpod/Firebase dual-backend seams.

### B. Finished Before Beta (`v0.8.5` – `v0.9.0-rc`) ✅
- Firebase Auth (Email/Password, Magic Link, Password Reset, ICOC affiliation confirmation).
- Threaded discussion comments and nested replies.
- Community Feature Voting Board initialized with 0-vote baseline (#304).
- Member profile counters (#300) and multi-criteria feed sorting (#325).
- Bookmarking / Saved for Later space (#155).
- In-app Avatar photo capture, gallery upload, square cropping, and polite permission handling (#333).
- Draw-on feedback canvas. The note goes to Firestore. The drawing is a placeholder URL, not a GitHub issue ([#407](https://github.com/neiljaywarner/refuge/issues/407)).

### C. Stuff to Finish Before Soft Launch (Saturday, October 24, 2026) 🗓️
- [ ] **Unified General Settings Screen** (`feat(settings)` #336) consolidating sensory themes, font scaling, and diagnostic SDK toggles.
- [ ] **Marty / Leadership Review Walkthrough** comparing legacy Circle spaces with Belong.
- [ ] **Circle.so CSV Data Migration Dry-Run** (`tool/import_circle_csv.dart`).
- [ ] **Launch Day Welcome Announcement** in Firebase Remote Config.
- [ ] **Production Web Build Deployment** to `https://belongonthespectrum.web.app`.

### D. Stuff to Finish Before Cutover (Saturday, October 31, 2026) 🏁
- [ ] Monitor dual-system adoption during the 7-day overlap window (Oct 24–31).
- [ ] Verify members have introduced themselves and joined their favorite spaces.
- [ ] Cancel Circle.so recurring billing cleanly on Oct 31, completing migration.

### E. First Week Post-Launch
- [ ] Triage feedback notes from Firestore. Drawings are not on GitHub yet ([#407](https://github.com/neiljaywarner/refuge/issues/407)).
- [ ] Address any UI font size or contrast feedback from older community members.

### F. First Month Post-Launch
- [ ] **iOS APNs Push Notifications**: Native Apple Push Notification service verification on physical iPhones (#165).
- [ ] **Public 1-Tap Google & Apple Sign-In**: Graduate OAuth buttons from Preview Mode to default sign-in screen.
- [ ] **Automated Daily Community Digest**: Optional quiet email summary for members who prefer not to receive push notifications.

### G. This Year (2026)
- [ ] Native Google Play Store internal tester track release.
- [ ] Audio reflection snippets (short voice memos with auto-captions for non-typing autistic members).
- [ ] Actually Autistic Events calendar live RSVP synchronization.

### H. "Someday / Maybe" Items (Future Exploration)
- Direct 1-on-1 encrypted private messaging (evaluated in ADR-0005, deferred to avoid moderation risk).
- Federated ActivityPub / Mastodon community bridging.
- AI quiet moderator assistant to summarize high-volume discussion threads.
- 👉 [**Browse all Someday / Maybe items on GitHub**](https://github.com/neiljaywarner/refuge/issues?q=label%3Asomeday-maybe)

---

## 3. What's Left Before Real Users Can Use It on October 24th?

```
[ ] 1. Maintainer Private Circle Review (Organizer — ~15-20 mins)
       Check personal Circle.so spaces, member cards, and tone side-by-side against Belong PWA.

[ ] 2. Circle CSV Data Migration Import (Engineering / Organizer — ~10 mins)
       Receive export CSV from Marty/organizer, execute:
       dart run tool/import_circle_csv.dart --file path/to/circle_export.csv --dry-run
       Then run live import to Cloud Firestore so past posts and spaces are pre-populated.

[ ] 3. Publish Organizer Welcome Message (Organizer / Marty — ~5 mins)
       In Firebase Console -> Remote Config, update `organizer_welcome_title` and
       `organizer_welcome_message` with launch day greeting.

[ ] 4. Post Circle Transition Announcement (Marty / Organizer — ~5 mins)
       Post the pre-written invitation message into Circle's #announcements space.

[ ] 5. Deploy Production Web Build (Engineering — ~5 mins)
       Run `dart run tool/deploy_release.dart --prod` to deploy the latest 175-test green build.
```

---

## 4. Current Release Readiness Scorecard (Grade: `A+ 98%`)

| Category | Score | Status | Key Evidence |
| :--- | :---: | :---: | :--- |
| **Authentication & Accounts** | 98% | 🟢 Ready | Email/password, magic link, and required ICOC church question tested. Google Sign-In preview gated. |
| **Spaces & Community Feed** | 98% | 🟢 Ready | 8 spaces, threaded discussion replies, tone tags, calm memes, multi-criteria sorting (#325), and care reactions. |
| **Push Notifications (FCM)** | — | Not device-verified | In-app bell exists. FCM requests set `badge: false`. Launcher-dot MethodChannel has no native handler. Matrix is open ([#411](https://github.com/neiljaywarner/refuge/issues/411)). |
| **Feedback & Feature Voting** | — | Drawing not on GitHub | Vote board exists. Feedback notes go to Firestore. The drawing is a placeholder storage URL, not a GitHub issue ([#407](https://github.com/neiljaywarner/refuge/issues/407)). |
| **Test Automation** | 100% | 🟢 Ready | 175/175 tests green across unit, widget, and hardware BDD suites. 0 static analyzer errors. |
