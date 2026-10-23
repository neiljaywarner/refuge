# 📅 Non-Technical Roadmap & Schedule to October 31st (Circle.so Cutover)

> **Audience**: Community Organizers, Pastors, Moderators, and Non-Technical Leaders at **[Belong on the Spectrum](https://www.belongonthespectrum.com/)** & **[DFW Church](https://dfwchurch.org)**  
> **Key Date**: **Saturday, October 31, 2026** — *Final day of the current Circle.so subscription (\$130/month)*  
> **Current Status**: 🟢 **Ahead of Schedule** (Core features & migration tools already completed on Monday, Oct 19!)

---

## 1. Executive Summary (In Plain English)

We are moving **Belong on the Spectrum** from Circle.so to our own calm, neurodivergent-affirming community platform (**Belong / Refuge**) **before Saturday, October 31st, 2026**.

Why this move helps the community:
- **Saves ~\$1,000+/year**: Replaces a recurring SaaS bill (see [Circle.so Pricing](https://circle.so/pricing), typically ~\$89–\$99+/month) with an ultra-reliable cloud setup costing under \$5/month.
- **Built Specifically for Neurodivergent & Autistic Comfort**: Features 4 one-tap sensory themes (*High Clarity*, *Warm Calm*, *Low Stimulus Dark*, and *Low Motion*) with zero surprise pop-ups or auto-playing videos.
- **Familiar Layout**: Keeps the exact same rooms (`Start Here & Introduce Yourself`, `Announcements`, `General Chat`, `Memes`, `Online Resources / Videos`, `Actually Autistic Chat`, `Friends Chat`, `Family Chat`, and `Links`) that members already know from Circle.so.
- **Organizer Control Without Coding**: Any authorized community leader can update the **"Message from the Organizer"** welcome banner anytime from a simple web form using [Firebase Remote Config](https://firebase.google.com/products/remote-config) (watch the [2-minute YouTube overview for product & community managers](https://www.youtube.com/watch?v=_CXXVFPO6f0)) without needing a programmer.
- **Preserves Community History**: Our pure-Dart spreadsheet migration tool ([`Circle-CSV-Migration-Guide.md`](Circle-CSV-Migration-Guide)) safely brings over past introductions and discussions so no memories are lost.

---

## 2. Schedule & 7-Day Overlap Window Leading Up to October 31st, 2026

> [!IMPORTANT]
> **Why Overlap Matters for Neurodivergent Members**: Sudden transitions are stressful. Our schedule launches **`v1.0.0` by Friday, October 23 – Saturday, October 24** so there is a **full 7-to-8-day Overlap Window (Oct 24 – Oct 31)** where members can explore the new Belong home at their own pace while Circle.so is still open!

| Dates | Milestone | Current Progress & Status | What Organizers & Members Do |
| :--- | :---: | :--- | :--- |
| **Sun, Oct 18** | **`v0.6.0-alpha` → `v0.8.0-alpha` (Preview Live)** | ✅ **Delivered**: Live Web PWA at [`belongonthespectrum.web.app`](https://belongonthespectrum.web.app), Belong logo & infinity branding, 4-tab bottom nav, Remote Config welcome banner, and Android test build 2. | **Organizers**: Verified live web preview link on phone and computer. |
| **Mon, Oct 19** | **`v0.7.0` (Organizer Feature & Migration Tools)** | ✅ **Delivered Ahead of Schedule**: <br>• Marty the Organizer's required ICOC church affiliation question & non-member option.<br>• Interactive Members Section & Directory.<br>• Circle CSV Data Importer CLI (`tool/import_circle_csv.dart`) with 11 tests.<br>• Dual Observability (Crashlytics + Offline Diagnostics).<br>• 82 automated tests passing green. | **Organizers**: Previewed the Member Profile Sheet on emulator and verified church affiliation dropdown. |
| **Tue, Oct 20** | **`v0.8.5` (Test Hardening & Dual-Pixel Driving)** | ✅ **Delivered**: Telemetry adapters exist for Firebase, Aptabase, and PostHog. Product PostHog events are not sent unless `POSTHOG_KEY` or `POSTHOG_BELONG_PROJECT_TOKEN` is passed at build time ([#410](https://github.com/neiljaywarner/refuge/issues/410)). 175 automated tests passing green. | **Organizers**: Product conversion analytics are not live. |
| **Wed, Oct 21 – Thu, Oct 22** | **`v0.9.5-rc` (Release Readiness & Cutover Launch Gate)** | ✅ **Delivered**: <br>• Circle App Store review sentiment audit CLI (`tool/analyze_app_reviews.dart`).<br>• Careful read-only Pixel 9a Maestro discovery flow (`.maestro/circle_app_discovery_careful.yaml`).<br>• Circle migration welcome announcement ([`docs/circle_migration_invitation_post.md`](https://github.com/neiljaywarner/refuge/blob/main/docs/circle_migration_invitation_post.md)) for Oct 24 kickoff.<br>• Full profile & auth hardening (32/32 tests passing green).<br>• Release Readiness Progress Dashboard ([Issue #261](https://github.com/neiljaywarner/refuge/issues/261)). | **Organizers**: Check the Circle welcome post template and review progress dashboard. |
| **Fri, Oct 23 – Sat, Oct 24** | **`v1.0.0` Community Launch (Start of 7-Day Overlap!)** | 🚀 **Milestone Target**: Production app launched at [`belongonthespectrum.com`](https://belongonthespectrum.com) / [`belongonthespectrum.web.app`](https://belongonthespectrum.web.app)! Both Circle and Belong remain open side-by-side. | **Organizers**: Post the *"Welcome to Our New Belong Home (Take Your Time — 7 Days of Overlap)"* announcement in Circle.so ([Issue #249](https://github.com/neiljaywarner/refuge/issues/249)). |
| **Sun, Oct 25 – Fri, Oct 30** | **7-Day Calm Overlap & Onboarding Week** | 🌿 Members explore at their own unhurried pace, sign in with email/password or magic link, and chat in `General Chat` & `Memes`. Final delta sync on Oct 30. | **Members & Welcomers**: Say hello to newcomers in `Start Here & Introduce Yourself`! |
| **Sat, Oct 31, 2026** | **Circle.so Subscription Ends Cleanly** | 🎉 Circle billing stops permanently. Everyone is happily settled in Belong on the Spectrum. | Celebrate! 🥳 |
| **Nov 1 – Nov 10, 2026** | **`v1.0.1` & `v1.1.0` (Fast-Follow Polish)** | 🌟 Live Notification Bell, Direct Messages (`Msgs`), Actually Autistic Events calendar, and native App Store/Play Store packages. | Updates appear automatically in the app. |

---

## 3. How Every Circle.so Space Maps to the New Belong App

Members will find their favorite rooms organized in the exact same structure under **`Spaces`**:

| Section | Space / Link Name | Status at Oct 31 Launch (`v1.0.0`) | Notes for Organizers |
| :--- | :--- | :---: | :--- |
| 📌 **Pinned** | **General Chat** | ✅ **Live Now** | Quick access right at the top |
| 👋 **Welcome** | **Start Here & Introduce Yourself** | ✅ **Live Now** | Includes the editable *"Message from the Organizer"* banner |
| 👋 **Welcome** | **Announcements** | ✅ **Live Now** | For important community updates |
| 🤝 **Community** | **General Chat** | ✅ **Live Now** | Everyday fellowship and conversation |
| 🤝 **Community** | **Memes** | ✅ **Live Now** | Supports clean image/meme cards |
| 🤝 **Community** | **Online Resources / Videos** | ✅ **Live Now** | Share helpful videos & articles (never auto-plays audio!) |
| 🤝 **Community** | **Actually Autistic Chat** | ✅ **Live Now** | Peer conversation space |
| 🤝 **Community** | **Friends Chat** | ✅ **Live Now** | Welcoming space for friends & allies |
| 🤝 **Community** | **Family Chat** | ✅ **Live Now** | Space for parents, spouses, and family members |
| 👥 **Directory** | **Members Section & Directory** | ✅ **Live Now** | Member profiles, avatars, and ICOC church affiliation |
| 📅 **Actually Autistic** | **Actually Autistic Events** | 🗓️ Friendly *"Coming Soon"* screen (`v1.1.0`) | Ready when the community schedules live events (**Issue #28**) |
| 🔗 **Links** | **Community Guidelines** | 📜 Live by `v0.9.0-rc` | Editable via Firebase Remote Config (**Issue #29**) |
| 🔗 **Links** | **DFW Church** | ✅ **Live Now** | Opens `https://dfwchurch.org` |
| 🔗 **Links** | **Download the Android App** | 📱 PWA Guide now → Play Store in `v1.0.1` | Tracked in **Issues #30, #44, #45** |
| 🔗 **Links** | **Download the iOS App** | 🍏 PWA Guide now → App Store in `v1.0.1` | Tracked in **Issues #31, #44, #46** |
