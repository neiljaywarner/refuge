# Belong on the Spectrum (`belongonthespectrum.com`) — Product & Engineering Roadmap (Circle.so Cutover by Oct 31, 2026)

> **Repository**: `https://github.com/neiljaywarner/refuge` (Local: `/Users/neil/belongonthespectrum/refuge`)  
> **First White-Label Community**: [Belong on the Spectrum](https://www.belongonthespectrum.com/) (Christian & Neurodivergent / Autistic Affirming Community partnered with [DFW Church](https://dfwchurch.org))  
> **Hard External Deadline**: **Saturday, October 31, 2026** — **Final day of the existing Circle.so subscription!**  
> **Companion Execution Plan**: [`18-oct-diving-in-since-machine-setup-in25-minutes-successfully.md`](file:///Users/neil/belongonthespectrum/18-oct-diving-in-since-machine-setup-in25-minutes-successfully.md)

---

## 1. Non-Technical Schedule & Timeline to October 31st (Circle.so Cutover)

Because **October 31, 2026** is the final day of Belong on the Spectrum's Circle.so subscription, our release schedule is anchored backward from that date so community organizers, moderators, and members experience a stress-free transition:

| Date Window | Release Milestone | What Non-Technical Organizers & Members Experience | Who Needs to Do What |
| :--- | :---: | :--- | :--- |
| **Sun, Oct 18 (Tonight)** | **`v0.5.0` → `v0.6.0` → `v0.8.0-alpha`** | • Hackathon clutter removed<br>• Official **Belong** cross + gold infinity (`∞`) logo & icons across Web, Android & iOS<br>• Familiar Circle-style `Feed` & `Spaces` layout (`Start Here`, `Announcements`, `General Chat`, `Memes`, `Online Resources / Videos`, `Actually Autistic Chat`, `Friends Chat`, `Family Chat`, `Links`)<br>• **Firebase Remote Config** live so organizers can edit the *"Message from the Organizer"* without code changes<br>• **Non-Technical Wiki** published<br>• **Alpha Sign-In ("Any Auth")** ready to test | **Neil & Organizers**: Glance at Chrome / Pixel 9a UI and share the organizer's custom feature request |
| **Mon, Oct 19 – Wed, Oct 21** | **`v0.7.0`** | • Upper-right **Member Profile & Avatar** view<br>• **Community Organizer's Custom Request** live<br>• **50% Automated Test Coverage** verified | **Community Organizer**: Try editing the Welcome Message in Firebase Remote Config & preview the Alpha link |
| **Thu, Oct 22 – Sat, Oct 24** | **`v0.8.0-alpha` (Moderator & Core Group Alpha)** | • Invite 5–10 friendly Belong moderators/leaders to post in `Start Here`, `General Chat`, and `Memes` | **Moderators**: Post initial welcome threads and seed a few favorite memes/videos |
| **Sun, Oct 25 – Tue, Oct 27** | **`v0.9.0-rc` (Release Candidate)** | • Official **Community Guidelines** published under `Links`<br>• **70% Automated & Holistic Test Coverage** on Web + physical phones | **Organizers**: Final sign-off on Community Guidelines text |
| **Wed, Oct 28 – Fri, Oct 30** | **`v1.0.0` (Belong Community Launch!)** | • `belongonthespectrum.com` points to the new Belong app<br>• Announcement posted in Circle inviting all members into their new home **before** Oct 31 | **All Members**: Join `belongonthespectrum.com`! |
| **Sat, Oct 31, 2026** | **Circle.so Subscription Ends** | • Circle.so billing stops cleanly (saving ~\$1,500/year)<br>• Zero community downtime | Celebrate! 🎉 |
| **Nov 1 – Nov 10, 2026** | **`v1.0.1` & `v1.1.0` (Fast-Follow)** | • Live **Notification Bell** & **Direct Messages (`Msgs`)** replace "Coming Soon" tabs<br>• **1-Tap Google Sign-In ("Good Auth")**<br>• **`Actually Autistic Events`** calendar<br>• **90% Test Coverage** | Automatic upgrade for all members |

---

## 2. Exact Belong UI, Navigation & White-Label Architecture (`v0.6.0`)

### 2.1 Top Header & Sub-Navigation
- **Upper-Left**: Official **Belong** logo (`assets/images/belong_logo.png`) + title.
- **Upper-Right**: Sensory Theme switcher (High Clarity, Warm Calm, Low Stimulus Dark, Low Motion) + **Member Profile Avatar**.
- **Below Logo**: Clean toggle between **`Feed`** and **`Spaces`**.
- **Top of Feed / Start Here**: **"Message from the Organizer"** card powered by **Firebase Remote Config** (`organizer_welcome_title`, `organizer_welcome_message`, `organizer_banner_enabled`) so non-technical organizers can update community announcements anytime from the Firebase web console.

### 2.2 Circle.so-Style Spaces Hierarchy
- 📌 **Pinned**:
  - `General Chat` (`general_chat`)
- 👋 **Welcome**:
  - `Start Here & Introduce Yourself` (`start_here`)
  - `Announcements` (`announcements`)
- 🤝 **Community**:
  - `General Chat` (`general_chat`)
  - `Memes` (`memes`)
  - `Online Resources / Videos` (`resources_videos`)
  - `Actually Autistic Chat` (`actually_autistic_chat`)
  - `Friends Chat` (`friends_chat`)
  - `Family Chat` (`family_chat`)
- 📅 **Actually Autistic**:
  - `Actually Autistic Events` (`actually_autistic_events`) -> Opens calm **"Coming Soon"** view (tracked in **Issue #13**)
- 🔗 **Links**:
  - `Community Guidelines` -> Opens **"Pending — Coming Soon"** view (tracked in **Issue #14**)
  - `DFW Church` -> Opens `https://dfwchurch.org`
  - `Download the Android App` -> Opens **"Pending — Coming Soon"** view (tracked in **Issue #15**)
  - `Download the iOS App` -> Opens **"Pending — Coming Soon"** view (tracked in **Issue #16**)

### 2.3 Bottom Navigation Bar (Vetted via ADR 0005)
- **4 Clean Tabs**:
  1. **`Home`** (`Feed` + `Spaces`)
  2. **`Notifications`** (Clean **"Coming Soon"** view, tracked in **Issue #12**)
  3. **`Msgs`** (Clean **"Coming Soon"** view, tracked in **Issue #12**)
  4. **`Search`** (Instant keyword & space search across posts, memes, and videos)

---

## 3. Complete GitHub Issues & Epics Roster (`neiljaywarner/refuge`)

Every issue has both a **human-readable description** for non-technical stakeholders and a dedicated **`🤖 LLM Execution Brief` comment** so **Gemini 4 Argon Low / Medium** can execute each ticket deterministically in an isolated git worktree:

| Issue | Milestone | Title | Model Tier | Agent Mins | Neil Mins |
| :---: | :---: | :--- | :---: | :---: | :---: |
| **#1** | `v0.5.0` | Bootstrap Apple Silicon ARM64 Mac environment in 24 minutes *(CLOSED/DONE)* | Pro | 24m *(done)* | 2m *(done)* |
| **#2** | `v0.6.0` | Implement White-Label `CommunityBrandConfig` (`belongonthespectrum.com` first tenant) | **Argon Low** | 10m | 0m |
| **#3** | `v0.6.0` | Home Screen Scaffolding & Circle-Style Navigation Update (`Feed`/`Spaces`, Vetted Bottom Nav w/ ADR, Remove Judges API Explorer) | **Argon Low / Med** | 25m | 3m |
| **#4** | `v0.6.0` | Belong Logo, Adaptive Launcher Icons & Multi-Platform App Icons (`Android`, `iOS`, `Web`, `macOS`) | **Argon Low** | 12m | 1m |
| **#5** | `v0.6.0` | Add Firebase Analytics & Firebase Remote Config (`"Message from the Organizer"` live updates) | **Argon Low / Med** | 15m | 1m |
| **#6** | `v0.6.0` | Overhaul Wiki for Non-Technical Organizers, Contributors & Oct 31st Circle.so Cutover Schedule | **Argon Low** | 12m | 1m |
| **#7** | `v0.6.0` | Search tab filtering & visual media/meme post cards for `Memes` and `Online Resources / Videos` | **Argon Low** | 12m | 0m |
| **#8** | `v0.7.0` | Upper-right Member Profile & Avatar view with neurodivergent comfort preferences | **Argon Low** | 15m | 1m |
| **#9** | `v0.7.0` | Implement Belong on the Spectrum community organizer's priority request | **Argon Med / High** | 20m | 5m |
| **#10** | `v0.7.0` | **[EPIC] Achieve 50% automated & holistic test coverage for `v0.7.0`** | **Argon Low** | 15m | 0m |
| **#11** | `v0.8.0-alpha` | Stage 1 Authentication ("Any Auth") for `v0.8.0-alpha` | **Argon Med / High** | 20m | 3m |
| **#12** | `v1.0.1` | **[EPIC] Direct Messages (`Msgs`) Inbox & Calm Notification Bell Engine** | **Argon Med / High** | 35m | 3m |
| **#13** | `v1.1.0` | **[EPIC] `Actually Autistic Events` view & RSVP calendar** | **Argon Low / Med** | 25m | 2m |
| **#14** | `v0.9.0-rc` | Publish Belong `Community Guidelines` view (replaces Pending link) | **Argon Low** | 8m | 2m |
| **#15** | `v1.0.0` | Wire `Download the Android App` link once APK / Play Store build is live | **Argon Low** | 5m | 1m |
| **#16** | `v1.0.0` | Wire `Download the iOS App` link once TestFlight / App Store build is live | **Argon Low** | 5m | 1m |
| **#17** | `v0.9.0-rc` | **[EPIC] Achieve 70% automated & holistic test coverage for `v0.9.0-rc`** | **Argon Low / Med** | 25m | 2m |
| **#18** | `v1.0.1` | Stage 2 Authentication ("Good Auth" — Google Sign-In / OAuth) | **Argon High** | 30m | 5m |
| **#19** | `v1.1.0` | **[EPIC] Achieve 90% automated & holistic test coverage for `v1.1.0`** | **Argon Low / Med** | 30m | 2m |
