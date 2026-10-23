# 🖼️ Belong on the Spectrum — Visual UI & Accessibility Catalog

*Catalog File: `visual_catalog.md`*  
*Target Environment: Flutter 3.38+ / Dart 3.8+ (Web, Android Pixel 9a, iOS)*

This catalog provides an exhaustive visual audit of every screen, sensory mode, interactive modal, and real-time state in **Belong on the Spectrum** (powered by Refuge). Beneath each visual asset reference, this guide documents the design rationale, calm-tech affordances, what to look for during QA audits, and links to the tracked GitHub Issue and Wiki architectural guide.

---

## 📑 Table of Contents
1. [Calm Home Feed & Sage Theme](#1-calm-home-feed--sage-theme)
2. [Fellowship Spaces & Circle Parity Directory](#2-fellowship-spaces--circle-parity-directory)
3. [Sensory Themes & High-Contrast Mode](#3-sensory-themes--high-contrast-mode)
4. [Community Feature Voting & Literal Feedback](#4-community-feature-voting--literal-feedback)
5. [Member Profile & Activity Counters Drill-Down](#5-member-profile--activity-counters-drill-down)
6. [Calm Notification Ethics & Filterable Inbox](#6-calm-notification-ethics--filterable-inbox)
7. [Save for Later (Private Bookmarking) & Quick (+) Post Composer](#7-save-for-later-private-bookmarking--quick--post-composer)
8. [Cross-Device Real-Time Synchronization (Dual Google Pixels)](#8-cross-device-real-time-synchronization-dual-google-pixels)
9. [Prettier Sensory Authentication & Guest State](#9-prettier-sensory-authentication--guest-state)
10. [Progressive Web App (PWA) Direct Installation Flow (Google Pixel 9a)](#10-progressive-web-app-pwa-direct-installation-flow-google-pixel-9a)

---

### 1. Calm Home Feed & Sage Theme

![Calm Home Feed & Sage Theme](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/home_feed.png)

- **Purpose**: Welcoming neurodivergent believers into a restful, predictable environment without algorithmic manipulation, endless notification badges, or sensory overload.
- **What to Look For**:
  - **Calm Sage Palette**: Soft herbal greens (`#68A67D`) with muted cards that minimize eye fatigue and visual glare.
  - **Space Navigation Carousel**: Unhurried filter chips (`#prayer-sanctuary`, `#weekly-study`, `#announcements`, `#special-interests-memes`, `#main-hall`, `#saved-for-later`).
  - **Quiet Digest Banner**: Summarizes unhurried community activity without aggressive notification counts.
  - **Unhurried Reflection Cards**: Post author avatar, intent tag (`[Prayer Request]`, `[Comfort Only]`, `[Bible Deep Dive]`), clean content body, and qualitative care affirmation reactions (`🙏 Praying`, `🤍 Support`, `🌱 Encouraged`, `😄 Relatable`).
- **Associated GitHub Issue**: [#284: Auth Callback, Demo Mode Seeding & Live Feed Switching](https://github.com/neiljaywarner/refuge/issues/284)
- **Associated Wiki Page**: [Belong Community Guide](https://github.com/neiljaywarner/refuge/wiki/Belong-Community-Guide)

---

### 2. Fellowship Spaces & Circle Parity Directory

![Fellowship Spaces & Circle Parity Directory](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/spaces_directory.png)

- **Purpose**: A Circle.so-parity navigation hierarchy organizing the church community into structured spaces so members can participate at their own comfort level without chaotic channel flooding.
- **What to Look For**:
  - **Section Headings**: `PINNED`, `WELCOME`, `COMMUNITY`, `ACTUALLY AUTISTIC`, and `LINKS`.
  - **Safe Introductions**: "Start Here & Introduce Yourself" (`👋`) provides a low-pressure entry point for newly joined members.
  - **Special Interest & Humor**: Dedicated spaces for special interests and memes (`😂`) where neurodivergent Christians celebrate deep research topics and wholesome faith humor.
  - **Saved for Later Space**: Private bookmarks accessible right inside the community directory (`🔖`).
- **Associated GitHub Issue**: [#22: Circle Parity Spaces Hierarchy & Collapsible Sections](https://github.com/neiljaywarner/refuge/issues/22)
- **Associated Wiki Page**: [User Journeys and Fellowship Rooms](https://github.com/neiljaywarner/refuge/wiki/User-Journeys-and-Fellowship-Rooms)

---

### 3. Sensory Themes & High-Contrast Mode

![Sensory Themes & High-Contrast Mode](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/sensory_theme_menu.png)

- **Purpose**: Accommodating wide spectrums of neurodivergent sensory profiles (photophobia, visual crowding, high-contrast visual needs, nighttime sensory recovery).
- **What to Look For**:
  - **Herbal Sage (Default)**: Restful nature tones avoiding intense blue light.
  - **Warm Desert**: Earthy sand tones comforting for migraine and light sensitivities.
  - **Charcoal Dark**: Deep neutral dark mode without harsh neon borders.
  - **Clean Paper**: High readability neutral background.
  - **High Contrast**: WCAG AAA certified black/white ratio for visual accessibility.
  - **Sensory Font Scaling**: Instant adjustment between 1.0x, 1.15x, 1.30x, and 1.50x font scales.
- **Associated GitHub Issue**: [#277: High-Contrast Mode Toggle & Sensory Font Scaling Presets](https://github.com/neiljaywarner/refuge/issues/277)
- **Associated Wiki Page**: [Calm Tech and Accessibility](https://github.com/neiljaywarner/refuge/wiki/Calm-Tech-and-Accessibility)

---

### 4. Community Feature Voting & Literal Feedback

![Community Feature Voting & Literal Feedback](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/feature_voting.png)

- **Purpose**: Transparent, neurodivergent-friendly roadmap prioritization where disciples guide features directly without corporate obfuscation.
- **What to Look For**:
  - **Literal Status Badges**: `WIP · Shipping Before Oct 31`, `Planned · Community Prioritized`, `Community Idea · Vote to Prioritize`.
  - **Reactive Live Stream Sync**: Multi-user concurrency updates vote counters across clients in real-time.
  - **Sensory Soundscapes Item**: Upcoming ambient sound generator with nature noise loops.
  - **Private Feedback Seam**: The note is written to Firestore. The drawing stays with the note and is not presented as an https://storage.belongonthespectrum.com upload. Notes are saved in Firestore member_feedback with a clipboard handoff for organizers. The sheet does not say a note was filed on belong_feedback. The app does not embed an API token and does not create a GitHub issue by itself ([#407](https://github.com/neiljaywarner/refuge/issues/407)).
- **Associated GitHub Issues**: [#302: Epic: Community Feature Roadmap & Real-Time Voting](https://github.com/neiljaywarner/refuge/issues/302), [#303: Multi-User Concurrency E2E Test & Reactive Broadcast Sync](https://github.com/neiljaywarner/refuge/issues/303), [#304: Reset Feature Vote Counts to Zero](https://github.com/neiljaywarner/refuge/issues/304)
- **Associated Wiki Page**: [Questions for Product Users and Alpha Testers](https://github.com/neiljaywarner/refuge/wiki/Questions-for-Product-Users-and-Alpha-Testers)

---

### 5. Member Profile & Activity Counters Drill-Down

![Member Profile & Activity Counters](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/member_profile.png)

- **Purpose**: Rich community connection allowing members to share their story, church congregation affiliation, communication preferences, and browse fellow disciples' authored posts and comments.
- **What to Look For**:
  - **Profile Header**: Avatar, Display Name, Church Affiliation Badge (`⛪ DFW Church` / `🌱 Welcoming Visitor`), and Profile Tagline.
  - **Activity Counters**: Interactive chips displaying total Posts and Comments count.
  - **Activity Drill-Down Modal**: Tapping Posts opens their authored reflections with real-time care affirmations and direct comment navigation.
  - **Sensory Communication Comfort**: Explicit badges: `Prefer Direct Questions`, `Low Energy / Slow Responses OK`, `No Phone Calls`.
- **Associated GitHub Issue**: [#300: Member Profile Activity Counters & Drill-Down](https://github.com/neiljaywarner/refuge/issues/300)
- **Associated Wiki Page**: [Community Leader Brainstorms](https://github.com/neiljaywarner/refuge/wiki/Community-Leader-Brainstorms)

---

### 6. Calm Notification Ethics & Filterable Inbox

![Calm Notifications View](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/notifications_inbox.png)

- **Purpose**: Mindful notification management preventing auditory startle, dopamine reward loops, or anxiety-inducing badge pileups.
- **What to Look For**:
  - **Bottom Navigation Bell Badge**: Subtle unread counter badge synchronized with the mobile OS launcher icon.
  - **Filter Chips**: `Inbox`, `Mentions` (`＠`), `Threads` (`↩️`), and `Following` (`❤️`).
  - **Avatar Context Badges**: Visual indicator in the lower-right corner of author avatars representing the exact notification event.
  - **Mark All as Read Action**: Upper-right action button that cleans in-app and launcher unread states; greyed out when unread count is 0.
- **Associated GitHub Issue**: [#286: Bottom Nav Bell Badge, Filtered Inbox & Launcher Badging](https://github.com/neiljaywarner/refuge/issues/286)
- **Associated Wiki Page**: [Calm Notifications Architecture (ADR-0010)](https://github.com/neiljaywarner/refuge/wiki/ADR-0010-Notifications-Local-Awesome-vs-FCM)

---

### 7. Save for Later (Private Bookmarking) & Quick (+) Post Composer

![Save for Later & Quick Post Composer](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/saved_for_later_and_composer.png)

- **Purpose**: Private thought preservation and effortless reflection sharing directly from the main AppBar.
- **What to Look For**:
  - **Quick (+) Post Composer**: Circular primary action button situated beside the member avatar in the top AppBar for instant reflection drafting.
  - **1-Tap Bookmark Action**: Bookmark ribbon icon (`🔖`) on every reflection card. Tapping toggles private saved status with a gentle, non-blocking toast.
  - **Saved for Later Space**: Dedicated space filter chip in the home feed displaying only your privately bookmarked reflections.
  - **Offline Persistence**: Bookmarks persist across sessions and offline restarts via reactive Riverpod state and local storage.
- **Associated GitHub Issue**: [#155: Save for Later (Private Bookmarking of Posts & Reflections)](https://github.com/neiljaywarner/refuge/issues/155)
- **Associated Wiki Page**: [Threaded Comments and Discussion Architecture](https://github.com/neiljaywarner/refuge/wiki/Threaded-Comments-and-Discussion-Architecture)

---

### 8. Cross-Device Real-Time Synchronization (Dual Google Pixels)

![Dual Pixel Hardware Sync](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/dual_pixel_sync.png)

- **Purpose**: Physical proof of cross-client sync across two phones (Pixel Left and Pixel Right). Device serials are not recorded here.
- **What to Look For**:
  - **Instant Reaction Propagation**: Affirmation reaction tapped on Device 1 increments the counter on Device 2 within sub-100ms latency.
  - **Multi-Device Stream Integrity**: Real-time broadcasts without full screen refreshes, flickering, or dropped WebSocket frames.
- **Associated GitHub Issue**: [#282: Physical Glass & Marionette Live Walkthrough](https://github.com/neiljaywarner/refuge/issues/282)
- **Associated Wiki Page**: [Dual Pixel Cloud Demo](https://github.com/neiljaywarner/refuge/wiki/Dual-Pixel-Cloud-Demo)

---

### 9. Prettier Sensory Authentication & Guest State

![Sensory Authentication Screen](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/sensory_auth_screen.png)

- **Purpose**: A reassuring, beautifully themed authentication experience with gentle rounded inputs, pastel branding icons, and reliable offline test fallback.
- **What to Look For**:
  - **Calm Typography**: Clear, legible headings with subtitle: *"Unhurried Christian fellowship • Safe, sensory-friendly & private"*.
  - **Clean State Switching**: Smooth transition between signed-out guest mode (demo sample reflections) and authenticated membership (live database feed).
  - **Offline Resilience**: Clean card presentation with one-tap entry button during offline testing or local development.
- **Associated GitHub Issue**: [#155 & #284: Prettier Authentication & Home Callback](https://github.com/neiljaywarner/refuge/issues/155)
- **Associated Wiki Page**: [PWA Guide for Members and Organizers](https://github.com/neiljaywarner/refuge/wiki/PWA-Guide-for-Members-and-Organizers)

---

### 10. Progressive Web App (PWA) Direct Installation Flow (Google Pixel 9a)

![PWA Installation & Standalone](https://raw.githubusercontent.com/neiljaywarner/refuge/main/doc/screenshots/pwa_standalone_fullscreen_pixel9a.png)

- **Purpose**: Direct device installation without corporate App Store friction, store passwords, credit card prompts, or 150MB+ download bloat.
- **What to Look For**:
  - **Native WebAPK Provisioning**: Android creates an official OS-level app launcher icon alongside native apps.
  - **Zero Browser Clutter**: Removes URL address bar, search tabs, and bottom navigation pills for a true fullscreen sanctuary.
  - **Instant Under-5MB Footprint**: Installs in under 3 seconds with zero disk overhead.
- **Associated GitHub Issues**:
  - [#312: Human-readable guide — Why There's No App Store App & Why You Don't Need One](https://github.com/neiljaywarner/refuge/issues/312)
  - [#313: Deep Technical Breakdown: Android APK vs. Web PWA](https://github.com/neiljaywarner/refuge/issues/313)
- **Associated Wiki Pages**:
  - [Why Isn't Belong in the App Store?](https://github.com/neiljaywarner/refuge/wiki/Why-No-App-Store-App)
  - [Android APK vs. Web PWA Technical Breakdown](https://github.com/neiljaywarner/refuge/wiki/Android-APK-vs-Web-PWA-Details)
