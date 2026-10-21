# Belong on the Spectrum (`belongonthespectrum.com`) — Product & Engineering Roadmap

> **Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge) (Local: `/Users/neil/belongonthespectrum/refuge`)  
> **Flagship Community**: [Belong on the Spectrum](https://www.belongonthespectrum.com/) (Christian & Neurodivergent / Autistic Affirming Community partnered with [DFW Church](https://dfwchurch.org))  
> **Hard External Milestone**: **Saturday, October 31, 2026** — **Final day of existing Circle.so subscription!**  
> **Target Soft Launch (7-Day Overlap Window)**: **Saturday, October 24, 2026** — Real members begin using Belong alongside Circle!  
> **Current Readiness Grade**: **`A-` (91/100)** | **147/147 Automated Tests Green** | **0 Static Analysis Errors**

---

## 1. Updated Non-Technical Schedule & Timeline (Oct 18 – Oct 31, 2026)

Because **October 31, 2026** is the final day of Belong on the Spectrum's Circle.so subscription, our release schedule provides a **7-day calm overlap window (Oct 24–31)** so community organizers, leaders, and members experience a reassuring, stress-free transition:

| Date Window | Release Milestone | Status | What Non-Technical Organizers & Members Experience | Actions Needed |
| :--- | :---: | :---: | :--- | :--- |
| **Sun, Oct 18** | **`v0.6.0` (Foundations)** | ✅ **Delivered** | • Belong cross + gold infinity logo across Web, Android, iOS<br>• Clean `Feed` & `Spaces` navigation<br>• Firebase Remote Config live for organizer welcome banner<br>• Alpha "Any Auth" session scaffold | Workspace setup in 24m |
| **Mon, Oct 19 – Tue, Oct 20** | **`v0.8.0-alpha` → `v0.9.0-rc`** | ✅ **Delivered** | • **Solid Firebase Auth** (Email/Password + Magic Link + Church Affiliation question)<br>• **1-Tap Google Sign-In** gated in Preview Mode for self-testing<br>• **Threaded Comments & Nested Replies** under reflections with care reactions<br>• **Calm Push Notifications** (FCM Web, PWA, Android with POST_NOTIFICATIONS)<br>• **100% Patrol Finders Standardization** (147 tests green)<br>• **Marionette glass driving** on Google Pixel 9a (Android 15)<br>• **Circle.so CSV Data Migration CLI** verified | Neil & Organizers review status report card & test brief |
| **Wed, Oct 21 – Fri, Oct 23** | **`v0.9.5` (Pre-Launch Staging & Final Polish)** | 🟡 **Active** | • **Maintainer Review**: Compare Belong side-by-side against personal Circle space<br>• **Staging CSV Import**: Test run Marty's Circle export ZIP with `tool/import_circle_csv.dart`<br>• **Organizer Welcome Banner**: Set launch day announcement in Remote Config<br>• **Production Web Deploy**: Push build to `belongonthespectrum.com` / `belongonthespectrum.web.app` | 1. Neil personal Circle review (15m)<br>2. Run migration dry-run<br>3. Verify DNS |
| **Sat, Oct 24 – Fri, Oct 30** | **`v1.0.0-rc` (7-Day Calm Community Overlap)** | 🗓️ **Scheduled** | • **Real members join Belong!**<br>• Circle invitation message posted in Circle `#announcements`<br>• Dual-system period: members introduce themselves and share reflections in Belong while Circle remains accessible as fallback<br>• Organizers observe community activity with zero stress | Members join and post reflections; moderators welcome newcomers |
| **Sat, Oct 31, 2026** | **Circle.so Subscription Ends** | 🏁 **Cutover Complete** | • Circle.so billing cancelled cleanly (saving \$1,000+/year)<br>• `belongonthespectrum.com` is the permanent home of the community<br>• Zero downtime, zero dropped posts | Celebrate! 🎉 |
| **Mid-November 2026** | **`v1.1.0` (Fast-Follow Polish)** | 🗓️ **Tracked (#165)** | • **iOS APNs Push Verification**: Full native device testing on physical iOS hardware<br>• **Public Google/Apple 1-Tap Sign-In**: Graduate from Preview Mode to default auth tab | Tracked in Issue #165 |

---

## 2. What's Left Before Real Users Can Use It on October 24th?

The code, infrastructure, authentication, push notifications, and automated test suite are already **100% production-ready**. Only **5 operational/maintainer checklist items** remain before the October 24th launch:

```
[ ] 1. Maintainer Private Circle Review (Neil — ~15-20 mins)
       Check personal Circle.so spaces, member cards, and tone side-by-side against Belong PWA.
       (Preserved in status.md — NOT in a public GitHub issue).

[ ] 2. Circle CSV Data Migration Import (Engineering / Neil — ~10 mins)
       Receive export CSV from Marty/organizer, execute:
       dart run tool/import_circle_csv.dart --file path/to/circle_export.csv --dry-run
       Then run live import to Cloud Firestore so past posts and spaces are pre-populated.

[ ] 3. Publish Organizer Welcome Message (Organizer / Marty — ~5 mins)
       In Firebase Console -> Remote Config, update `organizer_welcome_title` and
       `organizer_welcome_message` with launch day greeting.

[ ] 4. Post Circle Transition Announcement (Marty / Neil — ~5 mins)
       Post the pre-written invitation message from docs/wiki/Circle-Cutover-and-Community-Invitation.md
       into Circle's #announcements space welcoming members into Belong.

[ ] 5. Deploy Production Web Build (Engineering — ~5 mins)
       Run `dart run tool/deploy_release.dart --prod` to deploy the latest 147-test green build.
```

---

## 3. Current Release Readiness Scorecard (Grade: `A- 91%`)

| Category | Score | Status | Key Evidence |
| :--- | :---: | :---: | :--- |
| **Authentication & Accounts** | 95% | 🟢 Ready | Email/password, magic link, and required ICOC church question tested. Google Sign-In preview gated. |
| **Spaces & Community Feed** | 96% | 🟢 Ready | 8 spaces, threaded discussion replies (`#156`), tone tags, and calm care reactions. |
| **Push Notifications (FCM)** | 90% | 🟢 Ready | Web Push, PWA WebAPK, and Android 13+ POST_NOTIFICATIONS live (`#168`). iOS deferred to mid-Nov. |
| **Sensory & Calm-Tech UX** | 94% | 🟢 Ready | Brown noise soundscapes (`#110`), muted earth palettes, reassuring error text, accessible close buttons. |
| **Automated Test Suite** | 95% | 🟢 Ready | **147/147 tests green**; 100% standardized on `patrol_finders` (`$`) syntax. 0 analyzer errors. |
| **Hardware Verification** | 94% | 🟢 Ready | Real Google Pixel 9a (Android 15) glass driving via Marionette RPC. Full video recorded. |
| **DevOps & Process** | 98% | 🟢 Ready | 35 atomic PRs merged via GitHub MCP with zero terminal prompts. Zero PII leaks. |