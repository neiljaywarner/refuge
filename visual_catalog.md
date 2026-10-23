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

![Sensory Themes & High Contrast](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/sensory_themes.png)

- **Purpose**: Neurodivergent-first accessibility accommodating photophobia, astigmatism, visual glare, and low-vision processing needs.
- **What to Look For**:
  - **Four Sensory Modes**:
    1. **Clean (☀️)**: Soft warm paper theme with gentle off-white surfaces (`#FBFBFB`).
    2. **Sage (🌿)**: Calming herbal tone with muted green accents to soothe nervous system overstimulation.
    3. **Charcoal / Dark (🌙)**: Low-light theme eliminating blue light for quiet evening reading.
    4. **High Contrast (👁️)**: True `#000000` deep black background with vivid `#FFEB3B` yellow outlines, pure white text, and zero fuzzy gradients.
  - **Sensory Font Scaling**: Preset slider options (`Calm (100%)`, `Comfortable (115%)`, `Spacious (130%)`, `Maximum (145%)`) allowing instant text enlargement without screen overflows.
- **Associated GitHub Issue**: [#268: Sensory Theme Controller & 1-Tap High Contrast Toggle](https://github.com/neiljaywarner/refuge/issues/268)
- **Associated Wiki Page**: [Calm Tech and Accessibility Guide](https://github.com/neiljaywarner/refuge/wiki/Calm-Tech-and-Accessibility)

---

### 4. Community Feature Voting & Literal Feedback

![Feature Voting Board](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/feature_voting_sheet.png)

- **Purpose**: Transparent, collaborative roadmap shaping where neurodivergent members vote on community features and provide literal, ambiguity-free feedback.
- **What to Look For**:
  - **1-Tap Voting**: Incrementing vote counts with subtle haptic affirmation and zero modal popups.
  - **Roadmap Status Chips**: Distinct, non-overlapping status badges (`In Progress`, `Under Consideration`, `Planned`).
  - **Literal 3-Intent Feedback**: Form allowing members to categorize feedback strictly by intent: `Praise / What Works Well`, `Frustration / Sensory Glitch`, or `Feature Request`.
  - **Zero Algorithmic Bias**: Items are sorted by community votes, not engagement metrics or commercial tracking.
- **Associated GitHub Issue**: [Epic #302: Community Feature Roadmap & Real-Time Voting](https://github.com/neiljaywarner/refuge/issues/302)
- **Associated Wiki Page**: [QA and Beta Testing Guide](https://github.com/neiljaywarner/refuge/wiki/QA-and-Beta-Testing-Guide)

---

### 5. Member Profile & Activity Counters Drill-Down

![Member Profile Activity Counters](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/member_profile_counters.png)

- **Purpose**: Respectful member transparency and connection allowing community members to view authored posts and comments without performative vanity metrics or clout culture.
- **What to Look For**:
  - **Author Header**: Member name, church affiliation (ICOC / Visiting Ally), member since date, and bio/tagline.
  - **Activity Badges**: `Posts (X)` and `Comments (Y)` interactive tabs.
  - **Inline Drill-Down**: Tapping the count tabs reveals the exact list of reflections or discussion replies authored by the member.
  - **Direct Interaction**: Members can like a post or open the threaded discussion directly from the member's profile dialog.
- **Associated GitHub Issue**: [#300: Member Profile Activity Counters & Drill-Down Navigation](https://github.com/neiljaywarner/refuge/issues/300)
- **Associated Wiki Page**: [Belong Community Guide](https://github.com/neiljaywarner/refuge/wiki/Belong-Community-Guide)

---

### 6. Calm Notification Ethics & Filterable Inbox

![Calm Notification Ethics](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/notifications_inbox.png)

- **Purpose**: Respecting cognitive bandwidth by rejecting manipulative red alert dots, clickbait notifications, and late-night interruptions.
- **What to Look For**:
  - **Filter Chips**: Filter by `All`, `Mentions`, `Threads`, and `Following`.
  - **Action Avatar Badges**: Small sub-badges on the bottom-right of the member avatar (`❤️` for care reaction, `↩️` for reply, `@` for mention).
  - **Relative Timestamps**: Calm, plain-language times (`1 hr ago`, `2 days ago`).
  - **Quiet Mark as Read**: Clean checkmark button in the upper right, disabled when all notifications are read.
- **Associated GitHub Issue**: [#286: Notification Bell, Launcher Badge & Filterable Inbox](https://github.com/neiljaywarner/refuge/issues/286)
- **Associated Wiki Page**: [ADR-0010: Notifications Architecture & Calm Ethics](https://github.com/neiljaywarner/refuge/wiki/ADR-0010-Notifications-Local-Awesome-vs-FCM)

---

### 7. Save for Later (Private Bookmarking) & Quick (+) Post Composer

![Save for Later & Quick Post](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/bookmarks_and_composer.png)

- **Purpose**: Enabling members to save deep biblical studies, reflections, or resources during moments of sensory overload for quiet evening reading, plus an instant `(+)` composer button.
- **What to Look For**:
  - **Bookmark Ribbon**: Located on each `ReflectionCard` header; toggles between outline (`Icons.bookmark_border_rounded`) and filled (`Icons.bookmark_rounded`).
  - **100% Private**: Bookmarks are strictly private to the user; no public save counts or performative ribbons.
  - **Top-Right Quick Button**: Easy `(+)` button beside the profile avatar opens a bottom sheet with the full `ReflectionComposer` from any view.
  - **Peaceful Empty State**: When no items are saved, displays a calm message explaining how to save reflections for unhurried retrieval.
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
