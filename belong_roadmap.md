# 🌿 Refuge — Product & Engineering Roadmap for Belong on the Spectrum (`belongonthespectrum.com`)

> **Repository**: `neiljaywarner/refuge` (Clean successor to `refuge4serverpod`)  
> **First Anchor Organization**: [Belong on the Spectrum](https://www.belongonthespectrum.com/) (*"Fearfully and Wonderfully Made"* — Psalm 139:14)  
> **Architecture**: Flutter 3 (Web + Android/iOS) + Serverpod 4 Cloud (`scloud`, PostgreSQL 16 + Redis 7 WebSocket Streams) + White-Label Tenant Config  
> **Last Updated**: `2026-10-18`

---

## 1. Executive Summary & Product Vision

**Belong on the Spectrum** (and similar neurodivergent/faith fellowships) needs a clean, welcoming community home like **Circle.so**, without Circle's **$89–$130/month SaaS fee** or sensory-overloading dark patterns (red unread badge spam, typing indicators, algorithmic feeds).

**Refuge** is our white-labelable, calm-tech **Circle competitor** built end-to-end in Dart:
1. **First Tenant (`belongonthespectrum.com`)**: Ships out-of-the-box branded for **Belong on the Spectrum**, while keeping all branding, copy, palette defaults, and space definitions inside a clean `CommunityBrandConfig` so future churches and non-profits can white-label/skin the platform immediately.
2. **Core Circle-Competitor Feature Set for `v1.0.0`**:
   - **Clean Spaces**: A welcoming **General Space (`#main-hall`)**, a **Meme & Special Interests Space (`#special-interests-memes`)**, plus Prayer & Study rooms.
   - **Community Organizer's Priority Feature** (`v0.7.0` — slot ready for organizer specs).
   - **Member Profiles**: Clean profile card/sheet with display name, avatar/initials, bio, God-given special interests, sensory mode preference, and member/steward badge.
   - **Direct Messages / Calm Inbox**: 1-on-1 member messaging without "...is typing" urgency or read-receipt pressure.
   - **Calm Notification Bell**: Top-bar notification bell showing replies, care affirmations, DMs, and announcements without anxiety-inducing red badge counters.
   - **Two-Stage Authentication**:
     - **Stage 1 ("Any Auth" in `v0.8.0-alpha` / `v0.9.0-rc` / `v1.0.0`)**: Frictionless Serverpod session / email+passcode sign-in so every post, reaction, profile, and DM belongs to a real authenticated member.
     - **Stage 2 ("Good Auth" in `v1.0.1` / `v1.1.0`)**: Google Sign-In / OAuth + Push & Email Notifications (fast-follow).

---

## 2. Staged Release Milestones (`v0.5.0` → `v1.1.0`)

| Milestone | Theme | Core Features & Deliverables | Holistic & Automated Test Coverage Gate |
| :--- | :--- | :--- | :--- |
| **`v0.5.0`** *(Done)* | **Working Full-Stack Baseline** | - Live Serverpod Cloud backend + 800ms offline fallback<br>- 5 Spaces, 4 WCAG Sensory Modes (`Clean`, `Sage`, `Dark`, `Contrast`)<br>- Qualitative Care Affirmations + Calm Meme Gallery Modal<br>- Apple Silicon (`arm64`) dev/MCP environment & 26/26 green tests | **Baseline (`26/26` unit/widget/BDD tests passing)** |
| **`v0.6.0`** | **Clean `refuge` Repo + Skinnable Circle Shell** | - Fresh `neiljaywarner/refuge` repo (no `prototype`/`hackathon` naming)<br>- **White-Label `CommunityBrandConfig`** (anchored on `belongonthespectrum.com`)<br>- **Circle-Style Clean UI Polish** for **General (`#main-hall`)** and **Meme (`#special-interests-memes`)** spaces<br>- `bdd_widget_test` + Marionette VM-service driver integration | Foundation for `50%` gate |
| **`v0.7.0`** | **Organizer's Request + Profiles + DMs + 50% Coverage** | - **Community Organizer's Request** *(slot reserved)*<br>- **Member Profile** view & editable special interests/sensory default<br>- **Direct Messages / Calm Inbox** drawer & repository<br>- **Automated Testing Milestone 1 (`50%` Holistic & `flutter test --coverage`)** | **🎯 50% Coverage Gate** (BDD `.feature` flows + Marionette + `--coverage`) |
| **`v0.8.0-alpha`** | **Alpha — "Any Auth" + Calm Notification Bell** | - **Stage 1 Auth ("Any Auth")**: Sign-in / sign-up modal + persisted member identity across posts, reactions, and DMs<br>- **Calm Notification Bell**: Top-bar activity feed drawer (affirmations, DMs, announcements) | Alpha smoke suite on Chrome & Pixel 9a |
| **`v0.9.0-rc`** | **Release Candidate — Clean, Usable & 70% Coverage** | - Author post edit/delete + Steward moderation controls (pin/hide)<br>- End-to-end UX polish across all 4 WCAG sensory modes<br>- **Automated Testing Milestone 2 (`70%` Holistic & `flutter test --coverage`)** | **🎯 70% Coverage Gate** (BDD + Marionette + Maestro/Patrol + `--coverage`) |
| **`v1.0.0`** | **Community Launch (`belongonthespectrum.com`)** | - **Usable by the Belong on the Spectrum Community**<br>- Deployed to production Web + Serverpod Cloud (`scloud`) + Android APK for Pixel/mobile | Full RC + 70%+ regression gate green |
| **`v1.0.1` / `v1.1.0`** | **Fast-Follow — Google Auth, Push/Email Notifications & 90% Coverage** | - **Google Auth ("Good Auth")** (OAuth 2.0 / Serverpod Auth)<br>- **Push & Scheduled Email Notifications** (opt-in alerts & Quiet Digests)<br>- **Multi-Org White-Label Switcher** for additional ministries<br>- **Automated Testing Milestone 3 (`90%` Holistic & `flutter test --coverage`)** | **🎯 90% Coverage Gate** (Full E2E + `integration_test`/Patrol + Maestro + `--coverage`) |

---

## 3. Tiered Automated Testing & Holistic Coverage Strategy (`50%` → `70%` → `90%`)

Per our [ticket_driven_development.md](file:///Users/neil/belongonthespectrum/.agents/rules/ticket_driven_development.md) rule:
- **Pragmatic BDD First**: We prioritize human-readable **BDD feature specs** (`test/features/*.feature` + `bdd_widget_test`) and **holistic user-journey coverage** over brittle, over-mocked unit TDD boilerplate.
- **No CDP / Playwright**: We drive live apps exclusively with **Marionette** (`marionette_mcp` over Flutter VM Service WebSocket), **Maestro** (`.maestro/*.yaml` on physical Pixel 9a), and **Patrol** (`patrol_mcp` / `patrol_cli`).
- **Blended Coverage Definition**: Each milestone gate (`50%`, `70%`, `90%`) combines:
  1. **`flutter test --coverage`** (`lcov.info` line/branch coverage across domain, data, and presentation layers), **AND**
  2. **Holistic User-Flow Coverage** (percentage of core user journeys verified end-to-end via BDD widget tests, Marionette live driving, and Maestro/Patrol device flows).

### Coverage Issue Breakdown (3 Dedicated GitHub Epics/Issues with Subtasks)

1. **Coverage Issue 1 — `v0.7.0`: 50% Automated & Holistic Flow Coverage**
   - [ ] Subtask 1.1: Configure `bdd_widget_test` and baseline `flutter test --coverage` (`lcov.info`) reporting script.
   - [ ] Subtask 1.2: BDD & widget tests for `CommunityBrandConfig` (`belongonthespectrum.com` white-label defaults), General Space (`#main-hall`), and Meme Space (`#special-interests-memes`).
   - [ ] Subtask 1.3: BDD & Marionette smoke verification for the Community Organizer's Request, Member Profile, and DM Inbox (`>= 50%` holistic + LCOV coverage).

2. **Coverage Issue 2 — `v0.9.0-rc`: 70% Automated & Holistic Flow Coverage**
   - [ ] Subtask 2.1: BDD & widget tests for Stage 1 Auth ("Any Auth" sign-in/sign-out/author attribution) and Calm Notification Bell drawer.
   - [ ] Subtask 2.2: BDD & widget tests for Author Post Edit/Delete and Steward Moderation (pin/hide reflection).
   - [ ] Subtask 2.3: Maestro / Marionette E2E flow verification across Chrome + physical Pixel 9a and `flutter test --coverage` reaching `>= 70%`.

3. **Coverage Issue 3 — `v1.1.0`: 90% Automated & Holistic Flow Coverage**
   - [ ] Subtask 3.1: Integration & Patrol/BDD tests for Google Auth ("Good Auth") and token/session refresh resilience.
   - [ ] Subtask 3.2: End-to-end tests for Push / Scheduled Email Notification triggers and preferences.
   - [ ] Subtask 3.3: Multi-tenant White-Label switching verification + full `flutter test --coverage` & E2E matrix reaching `>= 90%`.

---

## 4. Initial GitHub Issue Queue for `neiljaywarner/refuge` (1 Issue = 1 Worktree = 1 PR)

| Issue # | Title | Milestone | Branch / Worktree | Status |
| :--- | :--- | :--- | :--- | :--- |
| **#1** | `chore: bootstrap Apple Silicon ARM64 Mac, MCP servers, official Dart/Flutter skills & clean refuge repo` | `v0.5.0` | `chore/#1-silicon-mac-bootstrap` | **DONE (Close immediately upon creation)** |
| **#2** | `feat(brand): extract white-label CommunityBrandConfig anchored on Belong on the Spectrum` | `v0.6.0` | `feat/#2-white-label-brand-config` | Ready |
| **#3** | `feat(spaces): Circle-style clean UI polish for General (#main-hall) and Meme (#special-interests-memes) spaces` | `v0.6.0` | `feat/#3-circle-clean-spaces` | Ready |
| **#4** | `feat(organizer): implement Belong on the Spectrum community organizer's priority request` | `v0.7.0` | `feat/#4-organizer-request` | Waiting on your details |
| **#5** | `feat(profile): add clean Member Profile sheet with special interests & sensory preference` | `v0.7.0` | `feat/#5-member-profile` | Ready |
| **#6** | `feat(dm): add Direct Messages / Calm Inbox drawer and repository` | `v0.7.0` | `feat/#6-direct-messages-inbox` | Ready |
| **#7** | `test(coverage): achieve 50% holistic BDD, Marionette & LCOV test coverage for v0.7.0` | `v0.7.0` | `test/#7-coverage-50-percent` | Ready |
| **#8** | `feat(auth): add Stage 1 "Any Auth" sign-in and authenticated member attribution` | `v0.8.0-alpha` | `feat/#8-stage1-any-auth` | Ready |
| **#9** | `feat(notifications): add Calm Notification Bell & in-app activity drawer` | `v0.8.0-alpha` | `feat/#9-calm-notification-bell` | Ready |
| **#10** | `feat(moderation): add author post edit/delete and steward moderation controls for RC` | `v0.9.0-rc` | `feat/#10-steward-moderation-rc` | Ready |
| **#11** | `test(coverage): achieve 70% holistic BDD, Maestro/Patrol & LCOV test coverage for v0.9.0-rc` | `v0.9.0-rc` | `test/#11-coverage-70-percent` | Ready |
| **#12** | `feat(auth-google): add Google Sign-In ("Good Auth") for v1.0.1 / v1.1.0 fast-follow` | `v1.1.0` | `feat/#12-google-auth` | Backlog (`1.0.1`/`1.1`) |
| **#13** | `feat(push-email): add push & scheduled Quiet Digest email notifications for v1.0.1 / v1.1.0` | `v1.1.0` | `feat/#13-push-email-notifications` | Backlog (`1.0.1`/`1.1`) |
| **#14** | `test(coverage): achieve 90% holistic BDD, Patrol/Maestro & LCOV test coverage for v1.1.0` | `v1.1.0` | `test/#14-coverage-90-percent` | Backlog (`1.1`) |
