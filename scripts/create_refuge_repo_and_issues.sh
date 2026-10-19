#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Bootstrap Clean `neiljaywarner/refuge` Repository, Milestones & GitHub Issues
# Every issue includes:
#   1. A rich human-readable description (Non-technical context + Acceptance Criteria)
#   2. Milestone & Labels assignment
#   3. A dedicated follow-up comment (`🤖 LLM Execution Brief`) for Argon Low/Medium
# ==============================================================================

REPO="neiljaywarner/refuge"
REPO_DIR="/Users/neil/belongonthespectrum/refuge"
GH="/opt/homebrew/bin/gh"

echo "==> Verifying GitHub CLI authentication (account: $("$GH" api user --jq .login))..."

cd "$REPO_DIR"

# Stage .gitignore and scripts update for initial clean baseline before creating repo
git add .gitignore belong_roadmap.md scripts/create_refuge_repo_and_issues.sh
if ! git diff --cached --quiet; then
  git commit -m "chore(repo): harden .gitignore against PII/keys and add Belong roadmap"
fi

echo "==> Creating or linking GitHub repository $REPO..."
if ! "$GH" repo view "$REPO" >/dev/null 2>&1; then
  "$GH" repo create "$REPO" --public \
    --description "Refuge — Calm, neurodivergent-affirming community platform powering Belong on the Spectrum (Circle.so replacement)" \
    --source="$REPO_DIR" --remote=origin --push
else
  git remote set-url origin "https://github.com/$REPO.git" || git remote add origin "https://github.com/$REPO.git"
  git push -u origin main
fi

echo "==> Creating clean labels..."
for entry in \
  "epic:FF7043:Multi-issue milestone epic" \
  "bdd-testing:1E88E5:BDD Gherkin widget, Marionette, Patrol, or Maestro tests" \
  "whitelabel:8E24AA:Multi-tenant white-label architecture (Belong first tenant)" \
  "circle-parity:43A047:Circle.so replacement feature for Belong on the Spectrum" \
  "auth:FB8C00:Authentication and member identity" \
  "notifications:00ACC1:In-app notification bell, digests, and direct messages" \
  "infra:546E7A:Developer tooling, CI/CD, and cloud infrastructure" \
  "branding-icons:D81B60:Belong logo, launcher icons, and multi-platform app icons" \
  "coming-soon:7E57C2:Tracked placeholder view scheduled for fast-follow release" \
  "firebase:FFCA28:Firebase Analytics and Firebase Remote Config" \
  "wiki-docs:00897B:Contributor & Non-Technical Organizer Wiki and ADRs" \
  "setup:009688:Environment, MCP server, and CLI bootstrap" \
  "education:3F51B5:Educational reference for developers and mentees" \
  "mentoring:E91E63:Best-practice walkthroughs for engineers Neil is mentoring"; do
  IFS=":" read -r name color desc <<< "$entry"
  "$GH" label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force >/dev/null 2>&1 || true
done

echo "==> Creating Release Milestones anchored to Oct 31, 2026 Circle.so sunset..."
create_milestone() {
  local title="$1"
  local due="$2"
  local desc="$3"
  "$GH" api "repos/$REPO/milestones" -f title="$title" -f due_on="$due" -f description="$desc" >/dev/null 2>&1 || true
}

create_milestone "v0.5.0 - Baseline & Apple Silicon Setup" "2026-10-19T04:59:59Z" "Working baseline migrated to Apple Silicon Mac in 24 minutes with 26/26 tests passing."
create_milestone "v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki" "2026-10-20T04:59:59Z" "Remove hackathon clutter, Circle-style Home/Feed/Spaces navigation, ADR-vetted 4-tab Bottom Nav, Belong multi-platform icons, Firebase Analytics + Remote Config, and Non-Technical Wiki."
create_milestone "v0.7.0 - Profile, Organizer Request & 50% Coverage" "2026-10-22T04:59:59Z" "Upper-right Member Profile view, Community Organizer priority request, and 50% BDD/holistic test coverage."
create_milestone "v0.8.0-alpha - Usable Community Alpha (Any Auth)" "2026-10-24T04:59:59Z" "Stage 1 frictionless authentication so Belong community leaders and alpha testers can sign in and post."
create_milestone "v0.9.0-rc - Release Candidate & 70% Coverage" "2026-10-28T04:59:59Z" "Release Candidate with Community Guidelines, moderation polish, and 70% automated & holistic test coverage."
create_milestone "v1.0.0 - Belong Community Launch (Circle.so Cutover)" "2026-10-31T04:59:59Z" "Production launch for belongonthespectrum.com before the October 31st Circle.so subscription ends."
create_milestone "v1.0.1 - Fast-Follow Notifications & Good Auth" "2026-11-04T05:59:59Z" "Live Notification Bell, Direct Messages (Msgs) inbox, and Google Sign-In / OAuth."
create_milestone "v1.1.0 - Nice-to-Haves, Events & 90% Coverage" "2026-11-11T05:59:59Z" "Actually Autistic Events calendar, rich digest preferences, and 90% automated & holistic test coverage."

# Helper to create an issue and immediately attach an LLM execution comment
create_issue_with_llm_comment() {
  local title="$1"
  local labels="$2"
  local milestone="$3"
  local human_body="$4"
  local llm_comment="$5"

  local url
  url=$("$GH" issue create --repo "$REPO" \
    --title "$title" \
    --label "$labels" \
    --milestone "$milestone" \
    --body "$human_body")
  local num="${url##*/}"
  echo "   -> Created Issue #$num: $title"
  "$GH" issue comment "$num" --repo "$REPO" --body "$llm_comment" >/dev/null
  LAST_ISSUE_NUM="$num"
}

# ------------------------------------------------------------------------------
# ISSUE #1: Apple Silicon Mac Setup (DONE)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "chore(infra): Bootstrap Apple Silicon ARM64 Mac environment in 24 minutes" \
  "infra,setup,mentoring" \
  "v0.5.0 - Baseline & Apple Silicon Setup" \
  "## Why This Matters (Human & Mentoring Summary)
We unboxed a brand-new 48GB RAM Apple Silicon (\`arm64\`) Mac and restored the complete development, cloud deployment, and automated testing environment in **24 minutes** so development on **Belong on the Spectrum** can proceed at full speed.

## Completed Checklist
- [x] Restored shell dotfiles and patched \`.zprofile\`, \`.zshenv\`, \`.zshrc\` for native \`/opt/homebrew\`
- [x] Installed Rosetta 2, Xcode Command Line Tools, and Homebrew 7.0.9
- [x] Installed native ARM64 formulae (\`git\`, \`gh\`, \`jq\`, \`ffmpeg\`, \`cocoapods\`, \`ruby\`, \`node\`, \`openjdk@17\`) and casks (\`flutter 3.47.7\`, \`android-studio\`, \`android-platform-tools\`)
- [x] Verified \`flutter test\` (\`26/26\` passing in 1s) and live Chrome debug session." \
  "### 🤖 LLM Execution Brief (Status: COMPLETED)
- **Status**: Completed in 24 minutes (`M1`–`M10` in `18Oct2026_session_plan_and_status.md`).
- **Verification**: `/opt/homebrew/bin/flutter test` -> `26/26` passed."

"$GH" issue close "$LAST_ISSUE_NUM" --repo "$REPO" --comment "✅ Completed in 24 minutes on 48GB Apple Silicon Mac. Closing as DONE."

# ------------------------------------------------------------------------------
# ISSUE #2: Mentoring & Education — Marionette MCP, Patrol MCP, Dart/Flutter MCP & 25 Official Skills (DONE)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "chore(mentoring): Configure Marionette MCP/CLI, Patrol MCP/CLI, Dart/Flutter MCP Servers & 25 Official Skills for BDD" \
  "setup,education,mentoring,bdd-testing" \
  "v0.5.0 - Baseline & Apple Silicon Setup" \
  "## Why This Matters (For Engineers & Mentees)
This issue documents how we equip our AI coding agents with **deterministic Flutter & Dart tooling** instead of brittle browser scraping (avoiding CDP/Playwright):

1. **Dart & Flutter Official MCP Server** (\`dart mcp-server --enable all\`): Gives agents direct access to analyzer diagnostics, symbol lookup, hot reload, pub search, and widget tree inspection.
2. **Marionette MCP Server & CLI** (\`marionette_mcp 0.7.0\` by LeanCode): Connects directly to the running Flutter VM Service (\`ws://127.0.0.1:<port>/<token>/ws\`) to inspect interactive elements, tap buttons, enter text, and trigger hot reloads in milliseconds.
3. **Patrol MCP Server & CLI** (\`patrol_cli 4.8.0\` & \`patrol_mcp 0.2.1\` by LeanCode): Enables native mobile automation and permission handling on physical devices (like our Google Pixel 9a).
4. **Maestro CLI** (\`~/.maestro/bin/maestro\`): Runs declarative YAML end-to-end user flows.
5. **25 Official Dart & Flutter Skills** (\`.agents/skills/dart-*\` and \`.agents/skills/flutter-*\`): Official \`dart-lang/skills\` and \`flutter/skills\` playbooks plus pragmatic **BDD Gherkin (\`bdd_widget_test\`)** workflows.

## Exact Commands Used to Install This Stack
\`\`\`bash
# 1. Activate Marionette MCP & Patrol CLI/MCP globally via Dart pub
dart pub global activate marionette_mcp
dart pub global activate patrol_cli
dart pub global activate patrol_mcp

# 2. Install Maestro CLI
curl -Ls \"https://get.maestro.mobile.dev\" | bash

# 3. Clone & vendor the 25 official Dart & Flutter skills into .agents/skills/
git clone --depth 1 https://github.com/dart-lang/skills.git /tmp/dart_skills
git clone --depth 1 https://github.com/flutter/skills.git /tmp/flutter_skills
cp -R /tmp/dart_skills/skills/* .agents/skills/
cp -R /tmp/flutter_skills/skills/* .agents/skills/
\`\`\`

## How 48GB RAM + Parallel Worktrees + BDD Speeds Up Development
- With **48GB unified memory**, we can keep Chrome and physical Pixel 9a VM services hot while running **2 to 3 isolated \`git worktree\` subagents in parallel** (\`.worktrees/issue-N-...\`), cutting sequential wall-clock time by **~60%**." \
  "### 🤖 LLM Execution Brief (Status: COMPLETED — Reference for All Future Agents)
- **MCP Config Location**: \`.agents/mcp_config.json\`
- **Installed Binaries**:
  - \`/Users/neil/.pub-cache/bin/marionette_mcp\` (\`0.7.0\`)
  - \`/Users/neil/.pub-cache/bin/patrol\` (\`4.8.0\`)
  - \`/Users/neil/.pub-cache/bin/patrol_mcp\` (\`0.2.1\`)
  - \`/opt/homebrew/bin/dart mcp-server --enable all\`
  - \`/Users/neil/.maestro/bin/maestro\`
- **Verification**: All 27 skills are committed under \`.agents/skills/\` and active in this workspace."

"$GH" issue close "$LAST_ISSUE_NUM" --repo "$REPO" --comment "✅ Marionette MCP (0.7.0), Patrol CLI (4.8.0) + Patrol MCP (0.2.1), Dart/Flutter MCP Server, Maestro, and all 25 official Dart & Flutter skills are installed, verified, and committed to \`.agents/\` for mentees to reference!"

# ------------------------------------------------------------------------------
# ISSUE #2: White-Label CommunityBrandConfig (v0.6.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(whitelabel): Implement CommunityBrandConfig with Belong on the Spectrum as first tenant" \
  "whitelabel,circle-parity" \
  "v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki" \
  "## Why This Matters (Human Summary)
Refuge is designed to power calm, neurodivergent-affirming communities starting with **Belong on the Spectrum** (\`https://www.belongonthespectrum.com/\`), while remaining easy to white-label for future partner organizations and churches.

Instead of hardcoding community names, logos, or space lists inside UI widgets, this issue introduces a single \`CommunityBrandConfig\` configuration layer.

## Acceptance Criteria
- [ ] Create \`CommunityBrandConfig\` domain model containing:
  - \`tenantId\` (\`'belong'\`), \`displayName\` (\`'Belong'\`), \`fullTitle\` (\`'Belong on the Spectrum'\`), \`domain\` (\`'belongonthespectrum.com'\`)
  - \`logoAssetPath\` (\`'assets/images/belong_logo.png'\`)
  - Brand palette seeds matching the Belong logo (\`#F3EFE6\` warm cream, \`#112334\` deep navy, \`#C99F49\` warm gold)
  - Default \`organizerWelcomeMessage\` fallback (overridable via Firebase Remote Config)
  - Default Circle-style Space sections & External Links (\`dfwchurch.org\`, etc.)
- [ ] Provide \`belongBrandConfigProvider\` via Riverpod so any screen reads branding dynamically.
- [ ] Add BDD widget/unit tests verifying \`Belong\` default configuration and custom white-label override." \
  "### 🤖 LLM Execution Brief (Argon Low / Medium Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Low / Flash (~10 Agent Clock Minutes)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-2-whitelabel-brand-config -b feat/#2-whitelabel-brand-config
  \`\`\`
- **Files to Create / Edit**:
  - Create \`lib/src/core/branding/community_brand_config.dart\`
  - Create \`lib/src/core/branding/brand_config_provider.dart\`
  - Update \`pubspec.yaml\` to register \`assets/images/belong_logo.png\` under \`flutter: assets:\`
  - Create BDD test \`test/features/whitelabel_brand_config.feature\`
- **Verification**:
  \`\`\`bash
  /opt/homebrew/bin/dart run build_runner build --delete-conflicting-outputs
  /opt/homebrew/bin/dart analyze
  /opt/homebrew/bin/flutter test
  \`\`\`
- **Safety Rules**: Never push to \`main\`; open a PR with \`Closes #2\`; zero PII or API keys."

# ------------------------------------------------------------------------------
# ISSUE #3: Home Screen Scaffolding & Circle-Style Navigation Update (v0.6.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(ui): Home Screen Scaffolding & Circle-style Navigation Update (Feed/Spaces, Vetted Bottom Nav w/ ADR, Remove Judges API Explorer)" \
  "circle-parity,whitelabel" \
  "v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki" \
  "## Why This Matters (Human Summary)
As we prepare to transition **Belong on the Spectrum** off their \$130/month Circle.so subscription before **October 31st**, members need an immediately familiar, clean, clutter-free layout that mirrors their existing Circle community structure — without any leftover hackathon prototype banners.

## What Changes for Community Members
1. **Clean Belong Experience**: The old \"Judges API Explorer\" banner and hackathon rubric references are completely removed.
2. **Top Header**:
   - **Upper-Left**: Crisp **Belong** logo + community title.
   - **Upper-Right**: Sensory Theme switcher + **Member Profile Avatar**.
   - **Below Logo**: Clean toggle between **\`Feed\`** (all recent community posts) and **\`Spaces\`** (structured room directory / navigation drawer).
3. **Familiar Circle.so Spaces Structure**:
   - 📌 **Pinned**: \`General Chat\`
   - 👋 **Welcome**: \`Start Here & Introduce Yourself\`, \`Announcements\`
   - 🤝 **Community**: \`General Chat\`, \`Memes\`, \`Online Resources / Videos\`, \`Actually Autistic Chat\`, \`Friends Chat\`, \`Family Chat\` (each with friendly icons)
   - 📅 **Actually Autistic**: \`Actually Autistic Events\` (tapping shows a calm **\"Coming Soon\"** screen linked to Issue #13)
   - 🔗 **Links**:
     - \`Community Guidelines\` (shows **\"Pending — Coming Soon\"** screen)
     - \`DFW Church\` (opens \`https://dfwchurch.org\`)
     - \`Download the Android App\` (shows **\"Pending — Coming Soon\"** screen)
     - \`Download the iOS App\` (shows **\"Pending — Coming Soon\"** screen)
4. **Bottom Navigation Bar (Vetted via ADR)**:
   - 4 clean tabs: **\`Home\`**, **\`Notifications\`** (*Coming Soon* view), **\`Msgs\`** (*Coming Soon* view), and **\`Search\`**.

## Acceptance Criteria
- [ ] Write \`docs/adr/0005-bottom-navigation-bar-package-selection.md\` vetting \`pub.dev\` bottom nav packages (\`salomon_bottom_bar\`, \`google_nav_bar\`, Material 3 \`NavigationBar\`) for WCAG AAA low-motion accessibility and Flutter 3.47 compatibility.
- [ ] Remove Judges API Explorer from \`community_anchor_banner.dart\` and hackathon text from \`about_refuge_dialog.dart\`.
- [ ] Implement Top Bar (Belong logo upper-left, Profile avatar upper-right), \`Feed\`/\`Spaces\` sub-navigation, full Circle space hierarchy, and 4-tab Bottom Navigation Bar.
- [ ] Create reusable \`ComingSoonView\` for \`Notifications\`, \`Msgs\`, \`Actually Autistic Events\`, and pending links." \
  "### 🤖 LLM Execution Brief (Argon Low / Medium Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Low / Medium (~25 Agent Clock Minutes)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-3-circle-home-navigation -b feat/#3-circle-home-navigation
  \`\`\`
- **Files to Create / Edit**:
  - Create \`docs/adr/0005-bottom-navigation-bar-package-selection.md\`
  - Edit \`lib/src/features/fellowship_spaces/domain/fellowship_space.dart\` (add sections: \`Pinned\`, \`Welcome\`, \`Community\`, \`Actually Autistic\`, \`Links\` and exact slugs: \`general_chat\`, \`start_here\`, \`announcements\`, \`memes\`, \`resources_videos\`, \`actually_autistic_chat\`, \`friends_chat\`, \`family_chat\`, \`actually_autistic_events\`)
  - Create \`lib/src/core/presentation/coming_soon_view.dart\`
  - Edit \`lib/src/features/reflections/presentation/community_anchor_banner.dart\` (remove Judges API Explorer; display Remote Config / organizer welcome banner instead)
  - Edit \`lib/src/features/about/presentation/about_refuge_dialog.dart\` (remove hackathon text)
  - Edit \`lib/src/home_screen.dart\` (Top bar with \`assets/images/belong_logo.png\` left + Profile avatar right, \`Feed\` | \`Spaces\` selector below logo, Circle-style Spaces drawer/view, and 4-tab bottom nav: \`Home\`, \`Notifications\`, \`Msgs\`, \`Search\`)
  - Update existing widget tests in \`test/\` so all tests pass with the new navigation structure.
- **Verification**:
  \`\`\`bash
  /opt/homebrew/bin/dart analyze
  /opt/homebrew/bin/flutter test
  \`\`\`"

# ------------------------------------------------------------------------------
# ISSUE #4: Belong Logo & Multi-Platform App/Launcher Icons (v0.6.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(branding): Belong Logo, Adaptive Launcher Icons & Multi-Platform App Icons (Android, iOS, Web, macOS)" \
  "branding-icons,whitelabel" \
  "v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki" \
  "## Why This Matters (Human Summary)
When Belong members install the app on their iPhone, Android phone, Mac, or browser home screen, they should see the authentic **Belong on the Spectrum** cross + gold neurodiversity infinity (\`∞\`) icon designed according to Apple and Android platform best practices.

## Reference Assets
- Uploaded Logo: \`assets/images/belong_logo.png\` (\`#F3EFE6\` warm cream background, \`#112334\` deep navy \`BELONG\` cross beam, \`#C99F49\` gold neurodiversity infinity loop)
- Website: \`https://www.belongonthespectrum.com/\`
- Circle Asset Reference: \`https://assets-v2.circle.so/ha2nubb2l7bw3do5nae9y2t7vkau\`

## Acceptance Criteria
- [ ] **Android Adaptive Icons (API 26+)**: Solid \`#F3EFE6\` background color + safe-zone padded foreground icon so circular/squircle masks on Pixel devices never clip the \`B\` or \`G\` in \`BELONG\` or the gold infinity loop.
- [ ] **iOS & macOS Icons**: Full-bleed opaque \`1024x1024\` master icon with zero alpha transparency (Apple App Store requirement).
- [ ] **Web PWA Icons & Manifest**: Update \`web/icons/\`, \`web/favicon.png\`, \`web/index.html\` title, and \`web/manifest.json\` (\`Belong on the Spectrum\`).
- [ ] Configure \`flutter_launcher_icons\` in \`pubspec.yaml\` so icons can be regenerated for any future white-label tenant." \
  "### 🤖 LLM Execution Brief (Argon Low / Flash Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Low / Flash (~12 Agent Clock Minutes)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-4-belong-logo-and-icons -b feat/#4-belong-logo-and-icons
  \`\`\`
- **Steps**:
  1. Prepare \`assets/images/belong_logo.png\` and safe-zone padded \`assets/images/belong_icon_foreground.png\` (1024x1024).
  2. Add \`flutter_launcher_icons\` to \`dev_dependencies\` in \`pubspec.yaml\` and configure \`android\`, \`ios\`, \`web\`, and \`macos\` targets with \`background_color: \"#F3EFE6\"\`, \`theme_color: \"#112334\"\`.
  3. Run \`/opt/homebrew/bin/dart run flutter_launcher_icons\` to generate all platform assets.
  4. Update \`web/manifest.json\` and \`web/index.html\` title to \`Belong on the Spectrum\`.
  5. Run \`/opt/homebrew/bin/dart analyze && /opt/homebrew/bin/flutter test\`."

# ------------------------------------------------------------------------------
# ISSUE #5: Firebase Analytics & Firebase Remote Config ("Message from the Organizer") (v0.6.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(firebase): Add Firebase Analytics & Firebase Remote Config ('Message from the Organizer' live updates)" \
  "firebase,whitelabel" \
  "v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki" \
  "## Why This Matters (Human Summary)
Non-technical community organizers at **Belong on the Spectrum** need to be able to update the **\"Message from the Organizer\"** banner, welcome text, or community announcement links at any time **without needing a developer to change code or publish a new app update**.

By integrating **Firebase Remote Config** alongside **Firebase Analytics**:
1. Organizers can log into the friendly Firebase Console web page, change \`organizer_welcome_title\`, \`organizer_welcome_message\`, or \`organizer_banner_visible\`, click **Publish**, and every member's app updates automatically.
2. Organizers can see privacy-safe, aggregate community engagement metrics (which spaces are most active, sensory theme usage) via **Firebase Analytics**.
3. **Zero API Keys or PII in Git**: The service uses safe environment injection / fallback defaults when running in local unit tests or unconfigured environments so no secrets are ever committed to GitHub.

## Acceptance Criteria
- [ ] Create \`OrganizerRemoteConfigService\` supporting keys:
  - \`organizer_welcome_title\` (default: \`\"Welcome to Belong on the Spectrum\"\`)
  - \`organizer_welcome_message\` (default: \`\"You belong here. Take your time, choose a sensory theme that feels comfortable, and introduce yourself in Start Here when you are ready.\"\`)
  - \`organizer_banner_enabled\` (default: \`true\`)
  - \`dfw_church_url\` (default: \`\"https://dfwchurch.org\"\`)
- [ ] Create \`CommunityAnalyticsService\` logging privacy-safe, non-PII events (\`space_viewed\`, \`sensory_theme_changed\`, \`feed_tab_switched\`, \`reflection_posted\`).
- [ ] Render the \"Message from the Organizer\" card at the top of \`Feed\` / \`Start Here\` driven by \`OrganizerRemoteConfigService\`.
- [ ] Document how non-technical organizers edit Remote Config values in the Wiki (\`docs/wiki/Organizer-Remote-Config-Guide.md\`).
- [ ] Add BDD widget tests verifying custom organizer messages render when Remote Config updates." \
  "### 🤖 LLM Execution Brief (Argon Low / Medium Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Low / Medium (~15 Agent Clock Minutes)
- **SECURITY MANDATE**: **NEVER commit \`firebase_options.dart\`, \`google-services.json\`, \`GoogleService-Info.plist\`, or raw API keys to Git.** Use an abstract \`RemoteConfigDataSource\` / \`AnalyticsDataSource\` with Riverpod providers and \`String.fromEnvironment\` so production reads Firebase when initialized and gracefully falls back to \`BelongBrandConfig\` defaults in tests/CI.
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-5-firebase-analytics-remote-config -b feat/#5-firebase-analytics-remote-config
  \`\`\`
- **Files to Create / Edit**:
  - \`lib/src/core/firebase/organizer_remote_config_service.dart\`
  - \`lib/src/core/firebase/community_analytics_service.dart\`
  - Wire into \`lib/src/features/reflections/presentation/community_anchor_banner.dart\` (now the **Message from the Organizer** banner)
  - Add BDD test \`test/features/organizer_remote_config.feature\`"

# ------------------------------------------------------------------------------
# ISSUE #6: High-Quality Contributor & Non-Technical Wiki + Oct 31 Circle Cutover Timeline (v0.6.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "docs(wiki): Overhaul Wiki for Non-Technical Organizers, Contributors & Oct 31st Circle.so Cutover Schedule" \
  "wiki-docs,circle-parity" \
  "v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki" \
  "## Why This Matters (Human Summary)
Our documentation and GitHub Wiki should welcome **non-technical community organizers, pastors, moderators, and open-source contributors** — with **zero mention of the past hackathon**.

Most importantly, **Belong on the Spectrum's Circle.so subscription ends on October 31st, 2026**. Non-technical leaders need a clear, reassuring, plain-English **Schedule & Cutover Timeline to October 31st** so everyone knows what is ready today, when alpha/beta testing happens, how to update the \"Message from the Organizer\" via Firebase Remote Config, and how the final cutover happens before October 31st.

## Acceptance Criteria
- [ ] Remove `docs/wiki/Hackathon-Judges-Portal.md` and strip all hackathon/judges references from `docs/wiki/Home.md`, `_Sidebar.md`, `_Footer.md`, and all wiki pages.
- [ ] Create **`docs/wiki/Non-Technical-Roadmap-to-Oct-31.md`**:
  - Plain-English calendar from **Oct 18 to Oct 31, 2026** (the last day of the Circle.so subscription).
  - Clear explanation of Alpha (`v0.8.0-alpha`), Release Candidate (`v0.9.0-rc`), and Launch (`v1.0.0` before Oct 31).
  - Side-by-side comparison showing how every Circle.so space maps to the new Belong app.
- [ ] Create **`docs/wiki/Organizer-Remote-Config-Guide.md`**:
  - Step-by-step non-technical guide for updating the **\"Message from the Organizer\"** and announcements via Firebase Remote Config without touching code.
- [ ] Create **`docs/wiki/Contributor-Guide.md`**:
  - Welcoming guide for developers, designers, and QA testers (Ticket-Driven Development, worktrees, BDD `.feature` files, WCAG AAA sensory accessibility rules)." \
  "### 🤖 LLM Execution Brief (Argon Low / Flash Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Low / Flash (~12 Agent Clock Minutes)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-6-non-technical-wiki-oct31 -b docs/#6-non-technical-wiki-oct31
  \`\`\`
- **Files to Create / Edit / Delete**:
  - \`git rm docs/wiki/Hackathon-Judges-Portal.md\`
  - Create \`docs/wiki/Non-Technical-Roadmap-to-Oct-31.md\`
  - Create \`docs/wiki/Organizer-Remote-Config-Guide.md\`
  - Create \`docs/wiki/Contributor-Guide.md\`
  - Update \`docs/wiki/Home.md\`, \`docs/wiki/_Sidebar.md\`, \`docs/wiki/_Footer.md\`, \`docs/wiki/Belong-Community-Guide.md\`, and \`README.md\` to remove all hackathon mentions and highlight Belong + Contributor & Non-Technical guides."

# ------------------------------------------------------------------------------
# ISSUE #7: Search Tab & Media/Meme Post Cards (v0.6.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(spaces): Search tab filtering & visual media/meme post cards for Memes and Online Resources / Videos" \
  "circle-parity" \
  "v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki" \
  "## Why This Matters (Human Summary)
Two of the most loved spaces in Belong on the Spectrum are **\`Memes\`** and **\`Online Resources / Videos\`**, alongside a fast **\`Search\`** tab in the bottom navigation bar so members can find uplifting resources, videos, or past conversations without sensory overload.

## Acceptance Criteria
- [ ] Implement instant keyword + space filter in the \`Search\` bottom nav tab.
- [ ] Support clean image/meme preview cards and video/resource link cards in \`Memes\` and \`Online Resources / Videos\` (never auto-playing audio/video, respecting Low Motion mode)." \
  "### 🤖 LLM Execution Brief (Argon Low / Flash Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Low / Flash (~12 Agent Clock Minutes)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-7-search-and-media-spaces -b feat/#7-search-and-media-spaces
  \`\`\`
- **Files to Create / Edit**:
  - Create \`lib/src/features/search/presentation/community_search_view.dart\`
  - Update \`lib/src/features/reflections/presentation/reflection_card.dart\` to render optional media/resource preview cards safely (zero autoplay)."

# ------------------------------------------------------------------------------
# ISSUE #8: Upper-Right Member Profile & Avatar View (v0.7.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(profile): Upper-right Member Profile & Avatar view with neurodivergent comfort preferences" \
  "circle-parity" \
  "v0.7.0 - Profile, Organizer Request & 50% Coverage" \
  "## Why This Matters (Human Summary)
In the upper-right corner of the Belong app sits the member's **Profile Avatar**. Tapping it lets members customize how they appear to the community, share optional neurodivergent communication preferences (e.g., *\"Literal communication appreciated\"*, *\"Happy to pray together\"*), and pick their default Sensory Theme.

## Acceptance Criteria
- [ ] Tapping the upper-right avatar opens the **Member Profile** sheet/screen.
- [ ] Members can edit their Display Name, short Bio, Avatar color/initials, and Neurodivergent Comfort Badges.
- [ ] Includes quick Sensory Theme switcher and persists locally via \`shared_preferences\`." \
  "### 🤖 LLM Execution Brief (Argon Low / Flash Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Low / Flash (~15 Agent Clock Minutes)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-8-member-profile-avatar -b feat/#8-member-profile-avatar
  \`\`\`
- **Files to Create / Edit**:
  - \`lib/src/features/profile/domain/member_profile.dart\`
  - \`lib/src/features/profile/presentation/member_profile_sheet.dart\`
  - Wire upper-right avatar tap in \`lib/src/home_screen.dart\`."

# ------------------------------------------------------------------------------
# ISSUE #9: Community Organizer's Priority Request (v0.7.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(belong): Implement Belong on the Spectrum community organizer's priority request" \
  "whitelabel,circle-parity" \
  "v0.7.0 - Profile, Organizer Request & 50% Coverage" \
  "## Why This Matters (Human Summary)
Reserved ticket in \`v0.7.0\` for the specific workflow/feature requested by the **Belong on the Spectrum** community organizer so their top priority is built and verified before the October 31st Circle.so cutover.

## Acceptance Criteria
- [ ] Capture exact organizer specification from Neil.
- [ ] Add BDD \`.feature\` test and implement end-to-end." \
  "### 🤖 LLM Execution Brief (Argon Medium / High)
- **Model Tier Recommendation**: Gemini 4 Argon Medium / High (~20 Agent Clock Minutes once specification is provided by Neil)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-9-organizer-request -b feat/#9-organizer-request
  \`\`\`"

# ------------------------------------------------------------------------------
# ISSUE #10: [EPIC] 50% Automated & Holistic Test Coverage (v0.7.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "test(coverage): [EPIC] Achieve 50% automated & holistic test coverage for v0.7.0" \
  "epic,bdd-testing" \
  "v0.7.0 - Profile, Organizer Request & 50% Coverage" \
  "## Why This Matters (Human Summary)
To make sure Belong on the Spectrum is rock-solid for community members, we track three progressive automated testing milestones (**50%** at \`v0.7.0\`, **70%** at \`v0.9.0-rc\`, and **90%** at \`v1.1.0\`). Coverage combines human-readable **BDD Gherkin scenarios** (\`.feature\` files), widget/unit tests, and live **Marionette** verification.

## Subtasks
- [ ] Add \`bdd_widget_test\` Gherkin \`.feature\` specs for Circle Home Navigation (\`Feed\` / \`Spaces\`), Pinned/Welcome/Community sections, and Coming Soon views
- [ ] Add BDD widget tests for \`CommunityBrandConfig\`, Firebase Remote Config organizer banner, and Member Profile view
- [ ] Verify \`flutter test --coverage\` generates \`coverage/lcov.info\` >= 50%" \
  "### 🤖 LLM Execution Brief (Argon Low / Flash Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Low / Flash (~15 Agent Clock Minutes)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-10-coverage-50-percent -b test/#10-coverage-50-percent
  \`\`\`
- **Verification**:
  \`\`\`bash
  /opt/homebrew/bin/dart run build_runner build --delete-conflicting-outputs
  /opt/homebrew/bin/flutter test --coverage
  \`\`\`"

# ------------------------------------------------------------------------------
# ISSUE #11: Stage 1 'Any Auth' for Alpha (v0.8.0-alpha)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(auth): Stage 1 Authentication ('Any Auth') for v0.8.0-alpha" \
  "auth,circle-parity" \
  "v0.8.0-alpha - Usable Community Alpha (Any Auth)" \
  "## Why This Matters (Human Summary)
Before launching \`1.0\`, community members need a simple, welcoming way to sign in so their posts, comments, and profile avatar belong to them across sessions — without getting blocked by complex OAuth setup during early alpha testing.

## Acceptance Criteria
- [ ] Clean **Welcome / Sign In to Belong** screen featuring the Belong logo and calm typography.
- [ ] Frictionless email + display name sign-in persisted across sessions and passed to Serverpod post creation.
- [ ] Sign-out button inside the upper-right Member Profile sheet." \
  "### 🤖 LLM Execution Brief (Argon Medium / High Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Medium / High (~20 Agent Clock Minutes)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-11-stage1-any-auth -b feat/#11-stage1-any-auth
  \`\`\`
- **Files to Create / Edit**:
  - \`lib/src/features/auth/domain/auth_session.dart\`
  - \`lib/src/features/auth/presentation/belong_sign_in_dialog.dart\`
  - Wire authenticated author name into post creation and upper-right avatar."

# ------------------------------------------------------------------------------
# ISSUE #12: [EPIC] Direct Messages (Msgs) & Notification Bell Engine (v1.0.1 / v1.1.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(comms): [EPIC] Direct Messages (Msgs) Inbox & Calm Notification Bell Engine (replaces Coming Soon views)" \
  "epic,notifications,coming-soon,circle-parity" \
  "v1.0.1 - Fast-Follow Notifications & Good Auth" \
  "## Why This Matters (Human Summary)
In \`v0.6.0\`, the **\`Notifications\`** and **\`Msgs\`** tabs in the bottom navigation bar show a clean **\"Coming Soon\"** view so we can prioritize core spaces and authentication first. This fast-follow epic replaces both placeholders with real-time, calm notifications and 1-on-1 member direct messaging.

## Subtasks
- [ ] Direct Messages (\`Msgs\`) inbox and 1-on-1 conversation view
- [ ] In-app \`Notifications\` feed with unread badge and \"Mark all read\"
- [ ] Calm digest preferences (never overwhelming or spamming neurodivergent members)" \
  "### 🤖 LLM Execution Brief
- **Target Release**: \`v1.0.1\` / \`v1.1.0\` fast-follow.
- **Note for \`v0.6.0\`**: Reference **Issue #12** inside the \`Notifications\` and \`Msgs\` \`ComingSoonView\` widgets."

# ------------------------------------------------------------------------------
# ISSUE #13: [EPIC] Actually Autistic Events View & Calendar (v1.1.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(events): [EPIC] Actually Autistic Events view & RSVP calendar (replaces Coming Soon view)" \
  "epic,coming-soon,circle-parity" \
  "v1.1.0 - Nice-to-Haves, Events & 90% Coverage" \
  "## Why This Matters (Human Summary)
Under the **\`Actually Autistic\`** section in the Circle navigation drawer sits **\`Actually Autistic Events\`**. Because the community hasn't actively used the events module yet, tapping it in \`v0.6.0\` displays a clean **\"Coming Soon\"** view while this epic tracks building a lightweight, sensory-friendly meetup & Zoom link calendar for \`v1.1.0\`." \
  "### 🤖 LLM Execution Brief
- **Target Release**: \`v1.1.0\`
- **Note for \`v0.6.0\`**: When a user taps \`Actually Autistic Events\` in the Spaces drawer, render \`ComingSoonView(title: 'Actually Autistic Events', issueNumber: 13)\`."

# ------------------------------------------------------------------------------
# ISSUE #14: Community Guidelines View (Pending Link under Links)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(links): Publish Belong Community Guidelines view (replaces Pending link under Links)" \
  "coming-soon,whitelabel" \
  "v0.9.0-rc - Release Candidate & 70% Coverage" \
  "## Why This Matters (Human Summary)
Under the **\`Links\`** section of Spaces, **\`Community Guidelines\`** initially displays a **\"Pending\"** placeholder in \`v0.6.0\`. For the \`v0.9.0-rc\` Release Candidate (before the Oct 31st Circle cutover), this issue populates the official Belong on the Spectrum community kindness & safety guidelines (editable via Firebase Remote Config!)." \
  "### 🤖 LLM Execution Brief
- **Target Release**: \`v0.9.0-rc\`
- **Note for \`v0.6.0\`**: Render \`ComingSoonView(title: 'Community Guidelines (Pending)', issueNumber: 14)\` when tapped under \`Links\`."

# ------------------------------------------------------------------------------
# ISSUE #15: Download the Android App Link (Pending Link under Links)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(links): Wire 'Download the Android App' link once Play Store / APK build is published" \
  "coming-soon,infra" \
  "v1.0.0 - Belong Community Launch (Circle.so Cutover)" \
  "## Why This Matters (Human Summary)
Under the **\`Links\`** section of Spaces, **\`Download the Android App\`** displays a **\"Pending\"** placeholder until the signed Belong Android APK / Play Store listing is live for the October 31st launch." \
  "### 🤖 LLM Execution Brief
- **Target Release**: \`v1.0.0\`
- **Note for \`v0.6.0\`**: Render \`ComingSoonView(title: 'Download the Android App (Pending)', issueNumber: 15)\` or URL from Firebase Remote Config key \`android_app_download_url\`."

# ------------------------------------------------------------------------------
# ISSUE #16: Download the iOS App Link (Pending Link under Links)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(links): Wire 'Download the iOS App' link once TestFlight / App Store build is published" \
  "coming-soon,infra" \
  "v1.0.0 - Belong Community Launch (Circle.so Cutover)" \
  "## Why This Matters (Human Summary)
Under the **\`Links\`** section of Spaces, **\`Download the iOS App\`** displays a **\"Pending\"** placeholder until the TestFlight / iOS App Store link is live for the October 31st launch." \
  "### 🤖 LLM Execution Brief
- **Target Release**: \`v1.0.0\`
- **Note for \`v0.6.0\`**: Render \`ComingSoonView(title: 'Download the iOS App (Pending)', issueNumber: 16)\` or URL from Firebase Remote Config key \`ios_app_download_url\`."

# ------------------------------------------------------------------------------
# ISSUE #17: [EPIC] 70% Automated & Holistic Test Coverage (v0.9.0-rc)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "test(coverage): [EPIC] Achieve 70% automated & holistic test coverage for v0.9.0-rc" \
  "epic,bdd-testing" \
  "v0.9.0-rc - Release Candidate & 70% Coverage" \
  "## Why This Matters (Human Summary)
Before switching the whole Belong community over from Circle.so on October 31st, our Release Candidate (\`v0.9.0-rc\`) must pass **70% automated & holistic test coverage** across Chrome and physical mobile hardware (\`Pixel 9a\`).

## Subtasks
- [ ] BDD widget tests for Stage 1 Auth, Search tab, and Member Profile
- [ ] Declarative Maestro flows in \`.maestro/\` for core Belong user journeys
- [ ] Patrol integration test harness for physical Pixel 9a verification
- [ ] Verify \`flutter test --coverage\` + holistic flow coverage >= 70%" \
  "### 🤖 LLM Execution Brief (Argon Low / Medium Ready)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-17-coverage-70-percent -b test/#17-coverage-70-percent
  \`\`\`"

# ------------------------------------------------------------------------------
# ISSUE #18: Stage 2 'Good Auth' — Google Sign-In / OAuth (v1.0.1 / v1.1.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "feat(auth): Stage 2 Authentication ('Good Auth' — Google Sign-In / OAuth)" \
  "auth" \
  "v1.0.1 - Fast-Follow Notifications & Good Auth" \
  "## Why This Matters (Human Summary)
Upgrades Stage 1 Alpha Authentication to support 1-tap **Sign in with Google** (and/or Appwrite/Serverpod OAuth) so members never have to remember a password." \
  "### 🤖 LLM Execution Brief (Argon High)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-18-stage2-google-auth -b feat/#18-stage2-google-auth
  \`\`\`"

# ------------------------------------------------------------------------------
# ISSUE #19: [EPIC] 90% Automated & Holistic Test Coverage (v1.1.0)
# ------------------------------------------------------------------------------
create_issue_with_llm_comment \
  "test(coverage): [EPIC] Achieve 90% automated & holistic test coverage for v1.1.0" \
  "epic,bdd-testing" \
  "v1.1.0 - Nice-to-Haves, Events & 90% Coverage" \
  "## Why This Matters (Human Summary)
Comprehensive **90% blended test coverage** across unit tests, \`bdd_widget_test\` Gherkin scenarios, Marionette live flows, Patrol integration tests, and Maestro end-to-end journeys for \`v1.1.0\`." \
  "### 🤖 LLM Execution Brief (Argon Low / Medium Ready)
- **Worktree Setup**:
  \`\`\`bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-19-coverage-90-percent -b test/#19-coverage-90-percent
  \`\`\`"

echo "==> SUCCESS! Clean repository https://github.com/$REPO and all 19 Issues/Epics with LLM Execution Brief comments are live!"
