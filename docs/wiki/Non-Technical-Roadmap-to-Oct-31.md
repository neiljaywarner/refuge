# 📅 Non-Technical Roadmap & Schedule to October 31st (Circle.so Cutover)

> **Audience**: Community Organizers, Pastors, Moderators, and Non-Technical Leaders at **[Belong on the Spectrum](https://www.belongonthespectrum.com/)** & **[DFW Church](https://dfwchurch.org)**  
> **Key Date**: **Saturday, October 31, 2026** — *Final day of the current Circle.so subscription (\$130/month)*

---

## 1. Executive Summary (In Plain English)

We are moving **Belong on the Spectrum** from Circle.so to our own calm, neurodivergent-affirming community platform (**Belong / Refuge**) **before Saturday, October 31st, 2026**.

Why this move helps the community:
- **Saves ~\$1,000+/year**: Replaces a recurring SaaS bill (see [Circle.so Pricing](https://circle.so/pricing), typically ~\$89–\$99+/month) with an ultra-reliable cloud setup costing under \$5/month.
- **Built Specifically for Neurodivergent & Autistic Comfort**: Features 4 one-tap sensory themes (*High Clarity*, *Warm Calm*, *Low Stimulus Dark*, and *Low Motion*) with zero surprise pop-ups or auto-playing videos.
- **Familiar Layout**: Keeps the exact same rooms (`Start Here & Introduce Yourself`, `Announcements`, `General Chat`, `Memes`, `Online Resources / Videos`, `Actually Autistic Chat`, `Friends Chat`, `Family Chat`, and `Links`) that members already know from Circle.so.
- **Organizer Control Without Coding**: Any authorized community leader can update the **"Message from the Organizer"** welcome banner anytime from a simple web form using [Firebase Remote Config](https://firebase.google.com/products/remote-config) (watch the [2-minute YouTube overview for product & community managers](https://www.youtube.com/watch?v=_CXXVFPO6f0)) without needing a programmer.

---

## 2. Schedule & 7-Day Overlap Window Leading Up to October 31st, 2026

> [!IMPORTANT]
> **Why Overlap Matters for Neurodivergent Members**: Sudden transitions are stressful. Our schedule launches **`v1.0.0` by Friday, October 23 – Saturday, October 24** so there is a **full 7-to-8-day Overlap Window (Oct 24 – Oct 31)** where members can explore the new Belong home at their own pace while Circle.so is still open!

| Dates | Milestone | What Is Ready for the Community | What Organizers & Members Do |
| :--- | :---: | :--- | :--- |
| **Sun, Oct 18 (Tonight)** | **`v0.6.0-alpha` → `v0.8.0-alpha` (Firebase Preview Channel Live)** | • Live **Firebase Hosting Preview Channel** URL to click & test<br>• Official **Belong** cross + gold infinity (`∞`) logo & icons<br>• Top `Feed` and `Spaces` navigation matching Circle.so<br>• 4-tab Bottom Bar (`Home`, `Notifications`, `Msgs`, `Search`)<br>• Live **"Message from the Organizer"** banner via Firebase Remote Config<br>• Simple Alpha Sign-In ("Any Auth") | **Neil & Organizers**: Open the Firebase Preview link on phone/computer and share the organizer's custom feature request |
| **Mon, Oct 19 – Tue, Oct 20** | **`v0.7.0` (Member Profiles & Organizer Priority Feature)** | • Upper-right **Member Profile & Avatar** customization<br>• Community Organizer's priority feature request built<br>• 50% automated quality test coverage | **Organizer**: Try editing the Welcome Message in Firebase Remote Config & preview the custom feature |
| **Wed, Oct 21 – Thu, Oct 22** | **`v0.9.0-rc` (Release Candidate & CSV History Import)** | • Existing Circle.so posts & introductions imported via CSV (**Issue #41**)<br>• Official **Community Guidelines** live under `Links`<br>• **Moderator Early Access**: 5–10 core leaders post welcome notes in `Start Here` and `Memes` | **Moderators**: Seed a few welcoming posts and favorite memes so the rooms feel warm before members arrive |
| **Fri, Oct 23 – Sat, Oct 24** | **`v1.0.0` (Belong Community Launch — Start of 7-Day Overlap!)** | • **`belongonthespectrum.com` Community Launch!**<br>• Both Circle.so and the new Belong app remain open side-by-side for a full week | **Organizers**: Post the *"Come Visit Our New Belong Home (No Rush — You Have All Week!)"* announcement in Circle.so |
| **Sun, Oct 25 – Fri, Oct 30** | **7-Day Calm Overlap & Onboarding Week** | • Members sign in at their own pace, add the Belong icon to their phone Home Screen (PWA), and chat in `General Chat` & `Memes`<br>• Final delta CSV sync of any last-minute Circle posts on Oct 30 | **Members & Leaders**: Welcome newcomers in `Start Here & Introduce Yourself` |
| **Sat, Oct 31, 2026** | **Circle.so Subscription Ends Cleanly** | • Circle.so billing stops (saving ~\$1,000+/year)<br>• Everyone is already settled in the new Belong community | Celebrate! 🎉 |
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
