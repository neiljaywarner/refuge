# 🏋️ Weeknights Execution Plan: Week of Oct 19, 2026 (`weeknights_week_of_oct19th.md`)

> **Goal**: Rapid, high-quality, continuous delivery leading to our **October 24–31 7-Day Overlap Window** with **minimal human interaction (5–10 minutes/evening)** so Neil can go to the gym, relax, and attend to daily life.
>
> **Live Web (Production)**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)  
> **Executive Review**: [`human_to_review_after_session.md`](human_to_review_after_session.md)  
> **Master Dashboard**: [`status.md`](status.md)  
> **Maintainer Questions**: [`questions_19_oct_evening.md`](questions_19_oct_evening.md) ([Issue #101](https://github.com/neiljaywarner/refuge/issues/101))

---

## 🧘 Low-Touch Human Interaction Protocol (5–10 Mins / Evening)

To keep development velocity high while protecting your gym and rest time, the autonomous agent runs independently using the following daily cycle:

```
┌────────────────────────────────────────────────────────────────────────┐
│                  DAILY LOW-TOUCH MAINTENANCE CYCLE                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Before Gym (2 mins):                                                │
│    - Quick scan of status.md or human_to_review_after_session.md       │
│    - Kick off agent unattended session with caffeinate                │
│                                                                        │
│ 2. During Gym / Evening (0 mins):                                      │
│    - Agent works autonomously in isolated git worktrees                │
│    - 1 Issue = 1 Worktree = 1 PR with zero-approval GitHub MCP pushes  │
│    - Automated BDD, widget tests, and Dart MCP static analysis verify  │
│                                                                        │
│ 3. After Gym / Wind-Down (5 mins):                                     │
│    - Inspect 1-page summary in human_to_review_after_session.md        │
│    - Answer any high-signal questions in questions_*.md                │
│    - All PRs are already tested, linted, and squashed                  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📅 Day-by-Day Weeknight Roadmap (Oct 19 – Oct 23)

### 🟢 Monday Night, Oct 19: Core Organizer Features & Migration Tools (COMPLETE ✅)
- **Accomplishments Delivered**:
  - Marty the Organizer's SMS request shipped: Member Profile Sheet with required ICOC church affiliation question and explicit non-member option ([#93](https://github.com/neiljaywarner/refuge/issues/93), PRs [#94](https://github.com/neiljaywarner/refuge/pull/94), [#95](https://github.com/neiljaywarner/refuge/pull/95), [#97](https://github.com/neiljaywarner/refuge/pull/97)).
  - Interactive Members Section & Directory (`BelongMembersDirectoryView`) live.
  - Pure-Dart Circle.so CSV Data Migration Importer CLI (`tool/import_circle_csv.dart`) built and verified with `--dry-run` and 11 unit tests ([#41](https://github.com/neiljaywarner/refuge/issues/41), PR [#98](https://github.com/neiljaywarner/refuge/pull/98)).
  - Dual Observability documented across Firebase Crashlytics & offline Talker ring buffers ([#99](https://github.com/neiljaywarner/refuge/issues/99), PR [#100](https://github.com/neiljaywarner/refuge/pull/100)).
  - Marionette MCP & CLI guide published (`readme_marionette.md`, PR [#104](https://github.com/neiljaywarner/refuge/pull/104)).
  - ADR-0010 Calm Notifications & Test Coverage Plan merged (PR [#106](https://github.com/neiljaywarner/refuge/pull/106)).
  - Repo-level Zero-PII and agent rules merged (PR [#108](https://github.com/neiljaywarner/refuge/pull/108)).
  - Idea PR [#110](https://github.com/neiljaywarner/refuge/pull/110) opened: Calm Sensory Ambient Soundscapes & Brown Noise Generator.
  - Automated tests passing: **82/82 on main** (93/93 on soundscapes branch).
- **Human Touch Needed Tonight**: **3–5 minutes**. Glance at [Issue #101](https://github.com/neiljaywarner/refuge/issues/101) when back from the gym.

---

### 🟡 Tuesday Night, Oct 20: Test Suite Hardening & Clean Seams (v0.8.5)
- **Autonomous Focus**:
  - Elevate test suite from 82 to **95+ automated tests** via Dart MCP `run_tests`.
  - Add BDD widget tests for the new Members Directory (`test/features/profile/members_directory_widget_test.dart`).
  - Add unit tests verifying church affiliation validation logic and non-member badge styling.
  - Run `tool/refuge_cli.dart privacy-scan` across all branches to guarantee zero PII.
- **Human Touch Needed**: **5 minutes**. Check that test counts increased on `status.md`. Off to the gym! 🏋️

---

### 🟠 Wednesday Night, Oct 21: Synthetic Data Dry-Run & Staging Verification
- **Autonomous Focus**:
  - Run the pure-Dart CSV importer against sample community data fixtures to verify space sorting.
  - Verify that past posts map cleanly to canonical slugs (`start_here`, `general_chat`, `memes`, etc.).
  - Ensure image cards in `memes` display with rounded corners and alt text.
  - Verify offline resilience: app functions gracefully when disconnected from network.
- **Human Touch Needed**: **5–10 minutes**. Open the web preview channel on your phone to tap through sample cards between gym sets.

---

### 🔵 Thursday Night, Oct 22: Release Candidate (v0.9.0-rc) & PWA Audit
- **Autonomous Focus**:
  - Build and audit Release Candidate `v0.9.0-rc`.
  - Verify PWA *"Add to Home Screen"* manifest, service worker caching, and theme color meta tags on Chrome and Android emulator.
  - Test Firebase Remote Config welcome banner update to verify that non-technical organizers can edit community announcements without code deployments.
  - Prune any obsolete worktrees and verify 0 static analysis errors.
- **Human Touch Needed**: **5 minutes**. Confirm the RC preview link opens smoothly.

---

### 🟣 Friday, Oct 23: v1.0.0 Production Cutover & 7-Day Overlap Launch! 🚀
- **Autonomous Focus**:
  - Deploy `v1.0.0` to production hosting: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app).
  - Publish GitHub Release `v1.0.0` with human-readable release notes.
  - Distribute Android Pre-Alpha Build 3 to the tester group via Firebase App Distribution.
- **Human Touch Needed**: **10 minutes**.
  - Copy and paste the friendly invitation message from [`How-You-Can-Help-Volunteer-Guide.md`](docs/wiki/How-You-Can-Help-Volunteer-Guide.md) into Circle.so announcing that the 7-day calm exploration week has begun!

---

### 🏖️ Saturday, Oct 24 – Friday, Oct 30: 7-Day Calm Community Overlap
- **What Happens**:
  - Both Circle.so and Belong on the Spectrum remain open simultaneously.
  - Members explore the new app at their own unhurried pace.
  - Organizers welcome members in `Start Here & Introduce Yourself`.
  - Zero pressure, zero rushed migration.

---

### 🎃 Saturday, October 31, 2026: Official Cutover Celebration!
- Circle.so subscription ends cleanly.
- Belong on the Spectrum is 100% independent, sensory-safe, and saving ~$1,000+/year! 🎉
