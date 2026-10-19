# 📅 Non-Technical Roadmap & Schedule to October 31st (Circle.so Cutover)

> **Audience**: Community Organizers, Pastors, Moderators, and Non-Technical Leaders at **[Belong on the Spectrum](https://www.belongonthespectrum.com/)** & **[DFW Church](https://dfwchurch.org)**  
> **Key Date**: **Saturday, October 31, 2026** — *Final day of the current Circle.so subscription (\$130/month)*

---

## 1. Executive Summary (In Plain English)

We are moving **Belong on the Spectrum** from Circle.so to our own calm, neurodivergent-affirming community platform (**Belong / Refuge**) **before Saturday, October 31st, 2026**.

Why this move helps the community:
- **Saves ~\$1,500/year**: Replaces a \$130/month SaaS bill with an ultra-reliable cloud setup costing under \$5/month.
- **Built Specifically for Neurodivergent & Autistic Comfort**: Features 4 one-tap sensory themes (*High Clarity*, *Warm Calm*, *Low Stimulus Dark*, and *Low Motion*) with zero surprise pop-ups or auto-playing videos.
- **Familiar Layout**: Keeps the exact same rooms (`Start Here & Introduce Yourself`, `Announcements`, `General Chat`, `Memes`, `Online Resources / Videos`, `Actually Autistic Chat`, `Friends Chat`, `Family Chat`, and `Links`) that members already know from Circle.so.
- **Organizer Control Without Coding**: Any authorized community leader can update the **"Message from the Organizer"** welcome banner anytime from a simple web form (Firebase Remote Config) without needing a programmer.

---

## 2. Day-by-Day Schedule to October 31st, 2026

| Dates | Milestone | What Is Ready for the Community | What Organizers Need to Do |
| :--- | :---: | :--- | :--- |
| **Sun, Oct 18 – Mon, Oct 19** | **`v0.6.0` (Clean Belong Look & Feel)** | • Official **Belong** cross + gold infinity (`∞`) logo & icons<br>• Top `Feed` and `Spaces` navigation matching Circle.so<br>• 4-tab Bottom Bar (`Home`, `Notifications`, `Msgs`, `Search`)<br>• Live **"Message from the Organizer"** banner editable via Firebase | Glance at the layout on phone/computer and share any wording tweaks |
| **Tue, Oct 20 – Wed, Oct 21** | **`v0.7.0` (Member Profiles & Organizer Priority Feature)** | • Upper-right **Member Profile & Avatar** customization<br>• Community Organizer's priority feature request built<br>• 50% automated quality test coverage | Test editing the Welcome Message in Firebase & preview the organizer feature |
| **Thu, Oct 22 – Sat, Oct 24** | **`v0.8.0-alpha` (Core Leader & Moderator Alpha)** | • Simple, welcoming **Sign-In ("Any Auth")** so posts and profiles belong to each member<br>• Ready for 5–10 core leaders/moderators to test | Invite a small group of trusted leaders to post a welcome note in `Start Here` and a few favorite `Memes` |
| **Sun, Oct 25 – Tue, Oct 27** | **`v0.9.0-rc` (Release Candidate & CSV History Import)** | • Existing Circle.so posts & introductions imported via CSV (**Issue #41**)<br>• Official **Community Guidelines** live under `Links`<br>• 70% automated quality test coverage across phones & web | Review imported posts and approve final Community Guidelines wording |
| **Wed, Oct 28 – Fri, Oct 30** | **`v1.0.0` (Belong Community Launch!)** | • **Public Launch** on Web & Mobile Home Screen (PWA)<br>• All members invited to join before Circle closes | Post the "Welcome to Our New Belong Home!" announcement in Circle.so |
| **Sat, Oct 31, 2026** | **Circle.so Subscription Ends** | • Circle.so billing stops cleanly<br>• Community is 100% live on Belong | Celebrate! 🎉 |
| **Nov 1 – Nov 10, 2026** | **`v1.0.1` & `v1.1.0` (Fast-Follow Enhancements)** | • Live **Notification Bell** & **Direct Messages (`Msgs`)** replace the "Coming Soon" tabs<br>• 1-Tap **Sign in with Google**<br>• **`Actually Autistic Events`** calendar<br>• Native Apple App Store & Google Play Store listings | Nothing required — updates appear automatically! |

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
| 📅 **Actually Autistic** | **Actually Autistic Events** | 🗓️ *"Coming Soon"* screen (`v1.1.0`) | Shows a friendly Coming Soon page until the community needs an events calendar (**Issue #28**) |
| 🔗 **Links** | **Community Guidelines** | 📜 Live by `v0.9.0-rc` (Oct 27) | Editable via Firebase Remote Config (**Issue #29**) |
| 🔗 **Links** | **DFW Church** | ✅ **Live Now** | Opens `https://dfwchurch.org` |
| 🔗 **Links** | **Download the Android App** | 📱 PWA Guide now → Play Store in `v1.0.1` | Tracked in **Issues #30, #44, #45** |
| 🔗 **Links** | **Download the iOS App** | 🍎 PWA Guide now → App Store in `v1.0.1` | Tracked in **Issues #31, #44, #46** |
