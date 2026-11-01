# 🤖 Less-Expensive LLM Execution Plan: Marionette `*_feature.txt` Driving, Patrol BDD & CodeRabbit PR Loop

*Last Updated: October 18, 2026 (`2026-10-18T20:07:00-05:00`)*
*Linked Status Files:*
- [`18Oct2026_session_plan_and_status.md`](18Oct2026_session_plan_and_status.md)
- [`18-oct-diving-in-since-machine-setup-in25-minutes-successfully.md`](18-oct-diving-in-since-machine-setup-in25-minutes-successfully.md)
- [`tokens-usage.md`](tokens-usage.md)
- [`belong_roadmap.md`](belong_roadmap.md)

---

## 🚦 1. Which Less-Expensive Model Should Neil Switch To Right Now?

Based on your live quota snapshot:
- 🥇 **Top Pick Right Now**: **`Gemini 3.8 Flash Medium`** (`94%` 5-hour burst remaining, `79%` weekly remaining — completely separate pool from `Gemini 4 Argon`!)
- 🥈 **Second Pick**: **`Gemini 4 Argon Low`** or **`Gemini 4 Argon Medium`** (`54%` weekly pool remaining)
- 🥉 **Third Pick**: **`Claude Sonnet 5.5 Medium`** (`93%` weekly pool remaining, `86%` 5-hr remaining)

---

## 🎯 2. Immediate Task #1 for the Less-Expensive LLM (Do This First!)

### Step A: Create & Drive `test/features/*_feature.txt` Files with Marionette MCP / CLI -> Convert to `patrol_finders` / Patrol Tests
Following the proven pattern from `selah_prototype_audio_13sep2026/test/features/*_feature.txt`:
1. **Create human-readable Gherkin specification files (`test/features/*_feature.txt`)** designed specifically to be **driven interactively via Marionette MCP / CLI (`~/.pub-cache/bin/marionette_mcp`)** in Chrome before locking them in as `patrol_finders` (`patrolWidgetTest`) and Patrol integration tests (`patrolTest`):
   - `test/features/circle_spaces_navigation_feature.txt`: Switching between `Feed` and `Spaces`, verifying `PINNED`, `WELCOME`, `COMMUNITY`, `ACTUALLY AUTISTIC`, and `LINKS`, and filtering *Geek Out!* and *Say Hello*.
   - `test/features/feedback_and_feature_voting_feature.txt`: Opening `Belong Roadmap & Feedback`, upvoting a `WIP · Shipping Before Oct 31` item in 1 tap, and testing the Literal 3-Intent feedback cards (`💚 Works Great`, `💡 Idea / Tweak`, `🛠️ Bug / Confusing`).
   - `test/features/member_profile_and_search_feature.txt`:Searching community posts/tags in `CommunitySearchView` and editing neurodivergent identity badges in `MemberProfileDialog`.
2. **Drive each `*_feature.txt` flow in Chrome using Marionette MCP / CLI** (following `.agents/skills/marionette-token-saver/SKILL.md`: use text/accessibility tree inspection first, and capture 1 clean screenshot per milestone for the GitHub PR!).
3. **Lock in the corresponding `patrol_finders` widget test (`test/features/*_test.dart`)** and run `run_tests` via the `dart` MCP server (`ServerName: "dart"`).

---

## 🔄 3. Immediate Task #2: Open Wave 2 PRs (`#20` & `#18`), Poll CodeRabbit, Merge & Deploy `v0.5.5` / `v0.6.0-alpha` Preview Channel

1. **Commit & Push Worktree 5 (`issue-18-circle-home-navigation`) and Worktree 4 (`issue-20-firebase-and-flavors`)** using `/opt/homebrew/bin/dart run tool/refuge_cli.dart` so PRs appear on [`https://github.com/neiljaywarner/refuge/pulls`](https://github.com/neiljaywarner/refuge/pulls).
2. **Poll & Triage CodeRabbit Comments on Open PRs (`#47`, `#48`, `#49`, plus `#20` & `#18`)**:
   - Check `gh pr view <PR> --repo neiljaywarner/refuge --comments` and `gh api repos/neiljaywarner/refuge/pulls/<PR>/comments`.
   - Fix any actionable CodeRabbit feedback in the worktree, re-verify via Dart MCP `run_tests`, then **squash-merge and delete the branch** (`gh pr merge <PR> --repo neiljaywarner/refuge --squash --delete-branch`).
3. **Sync Any Updated Wiki Pages** via `/opt/homebrew/bin/dart run tool/refuge_cli.dart sync-wiki-now` so [`https://github.com/neiljaywarner/refuge/wiki`](https://github.com/neiljaywarner/refuge/wiki) stays 100% up to date.
4. **Deploy Live Firebase Hosting Preview Channel (`v0.5.5-alpha` / `v0.6.0-alpha`)** and attach Chrome/Simulator screenshots to the GitHub Issues & PRs!
