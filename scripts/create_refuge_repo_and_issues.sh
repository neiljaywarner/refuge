#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/Users/neil/belongonthespectrum/refuge"
OWNER="neiljaywarner"
REPO_NAME="refuge"
FULL_REPO="${OWNER}/${REPO_NAME}"

echo "======================================================================"
echo " Bootstrapping Clean GitHub Repo (${FULL_REPO}) & Ticket Queue"
echo "======================================================================"

if ! /opt/homebrew/bin/gh auth status >/dev/null 2>&1; then
  echo "--> gh CLI is not authenticated yet. Launching browser login..."
  /opt/homebrew/bin/gh auth login -h github.com -p https -w
fi

cd "$REPO_DIR"

# 1. Create neiljaywarner/refuge if it doesn't exist yet
if ! /opt/homebrew/bin/gh repo view "$FULL_REPO" >/dev/null 2>&1; then
  echo "--> Creating public repository ${FULL_REPO}..."
  /opt/homebrew/bin/gh repo create "$FULL_REPO" \
    --public \
    --description "Refuge — Calm-tech digital community platform for Belong on the Spectrum (belongonthespectrum.com) built with Flutter & Serverpod 4."
fi

# 2. Point origin to neiljaywarner/refuge and push initial v0.5.0 baseline
/opt/homebrew/bin/git remote set-url origin "https://github.com/${FULL_REPO}.git"
/opt/homebrew/bin/git add -A
if [ -n "$(/opt/homebrew/bin/git status --porcelain)" ]; then
  /opt/homebrew/bin/git commit -m "chore(#1): initialize clean refuge repository at v0.5.0 baseline with belong_roadmap.md and 25 official Dart/Flutter skills"
fi
/opt/homebrew/bin/git push -u origin main

# 3. Create Milestones via GitHub API
for m in "v0.5.0" "v0.6.0" "v0.7.0" "v0.8.0-alpha" "v0.9.0-rc" "v1.0.0" "v1.1.0"; do
  /opt/homebrew/bin/gh api "repos/${FULL_REPO}/milestones" -f title="$m" >/dev/null 2>&1 || true
done

echo "--> Creating Issue #1 (Apple Silicon Mac Setup) and marking it DONE..."
ISSUE_1_URL=$(/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "chore: bootstrap Apple Silicon ARM64 Mac, MCP servers, official Dart/Flutter skills & clean refuge repo" \
  --milestone "v0.5.0" \
  --body "## Summary
Set up brand-new Apple Silicon (\`arm64\`) Mac environment from migration bundle in 24 minutes and initialize clean \`${FULL_REPO}\` repository.

## Completed Checklist
- [x] Extracted \`silicon_mac_home_and_configs.zip\` and patched \`.zprofile\`, \`.zshenv\`, \`.zshrc\` to \`/opt/homebrew\` + \`JAVA_HOME\` (OpenJDK 17)
- [x] Installed Rosetta 2, Xcode Command Line Tools, Homebrew 7.0.9, and native ARM64 formulae & casks (\`flutter 3.47.7\`, \`android-studio\`, \`android-platform-tools\`)
- [x] Activated \`serverpod_cli 4.0.4\`, \`serverpod_cloud_cli 1.1.0\`, \`firebase-tools\`, \`maestro\`, \`marionette_mcp 0.7.0\`, \`patrol_cli 4.8.0\`, \`patrol_mcp 0.2.1\`, and \`dart mcp-server\`
- [x] Installed all 25 official Dart & Flutter skills into \`.agents/skills/\` and updated \`ticket_driven_development.md\`
- [x] Verified \`flutter test\` (\`26/26\` passing in 1s), \`scloud me\`, and live Chrome WebSocket connection")
/opt/homebrew/bin/gh issue close "$ISSUE_1_URL" --repo "$FULL_REPO" --comment "Completed and verified on Apple Silicon Mac (26/26 tests passing in 1s, live in Chrome, MCP servers & 25 official skills configured)."

echo "--> Creating 3 Automated Testing & Holistic Flow Coverage Epics (50% @ v0.7.0, 70% @ v0.9.0-rc, 90% @ v1.1.0)..."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "test(coverage): achieve 50% holistic BDD, Marionette & LCOV test coverage for v0.7.0" \
  --milestone "v0.7.0" \
  --body "## Goal (Milestone \`v0.7.0\`)
Achieve **50% blended automated & holistic user-flow coverage** across BDD feature specs (\`bdd_widget_test\` + \`test/features/*.feature\`), Marionette VM-service live driving, Maestro flows, and \`flutter test --coverage\` (\`lcov.info\`).

## Subtasks (1 Issue/Subtask = 1 Worktree = 1 PR)
- [ ] **Subtask A**: Add \`bdd_widget_test\` & \`marionette_flutter\` harness + baseline \`flutter test --coverage\` script
- [ ] **Subtask B**: BDD feature & widget tests for white-label \`CommunityBrandConfig\` (\`belongonthespectrum.com\`), General Space (\`#main-hall\`), and Meme Space (\`#special-interests-memes\`)
- [ ] **Subtask C**: BDD & Marionette verification for Community Organizer's Request, Member Profile, and Direct Messages / Inbox (\`>= 50%\` coverage gate)"

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "test(coverage): achieve 70% holistic BDD, Maestro/Patrol & LCOV test coverage for v0.9.0-rc" \
  --milestone "v0.9.0-rc" \
  --body "## Goal (Milestone \`v0.9.0-rc\`)
Achieve **70% blended automated & holistic user-flow coverage** for the Release Candidate gate prior to \`v1.0.0\` launch for **Belong on the Spectrum**.

## Subtasks (1 Issue/Subtask = 1 Worktree = 1 PR)
- [ ] **Subtask A**: BDD & widget tests for Stage 1 Auth ('Any Auth' sign-in, session persistence, author attribution) and Calm Notification Bell drawer
- [ ] **Subtask B**: BDD & widget tests for Author Post Edit/Delete and Steward Moderation controls (pin/hide)
- [ ] **Subtask C**: Marionette (Chrome) + Maestro/Patrol (Pixel 9a) E2E flow verification & \`flutter test --coverage\` reaching \`>= 70%\`"

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "test(coverage): achieve 90% holistic BDD, Patrol/Maestro & LCOV test coverage for v1.1.0" \
  --milestone "v1.1.0" \
  --body "## Goal (Milestone \`v1.1.0\`)
Achieve **90% blended automated & holistic user-flow coverage** across unit, widget, BDD, \`integration_test\` / Patrol (\`--coverage\`), Marionette, and Maestro.

## Subtasks (1 Issue/Subtask = 1 Worktree = 1 PR)
- [ ] **Subtask A**: BDD & Patrol integration tests for Google Sign-In ('Good Auth') and session refresh resilience
- [ ] **Subtask B**: Automated tests for Push & Scheduled Quiet Digest Email Notification delivery & opt-in preferences
- [ ] **Subtask C**: Multi-tenant White-Label organization switching tests + full LCOV/E2E suite reaching \`>= 90%\`"

echo "--> Creating Circle-Competitor Feature Issues for v0.6.0 - v1.1.0..."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(brand): extract white-label CommunityBrandConfig anchored on Belong on the Spectrum" \
  --milestone "v0.6.0" \
  --body "Extract all community branding (name, domain \`belongonthespectrum.com\`, anchor scripture Psalm 139:14, default sensory palette, and default spaces) into a skinnable \`CommunityBrandConfig\` model so Belong on the Spectrum is the default first tenant and future orgs can white-label effortlessly."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(spaces): Circle-style clean UI polish for General (#main-hall) and Meme (#special-interests-memes) spaces" \
  --milestone "v0.6.0" \
  --body "Streamline space switching, composer ergonomics, and card layout for General (\`#main-hall\`) and Meme (\`#special-interests-memes\`) spaces so the experience is as clean and intuitive as Circle.so on Chrome and Pixel 9a."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(organizer): implement Belong on the Spectrum community organizer's priority request" \
  --milestone "v0.7.0" \
  --body "Implement the community organizer's specific feature request for Belong on the Spectrum (details anchored in \`belong_roadmap.md\`)."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(profile): add clean Member Profile sheet with special interests & sensory preference" \
  --milestone "v0.7.0" \
  --body "Add a Circle-style Member Profile view/sheet displaying member name, avatar/initials, bio, God-given special interests, sensory mode preference, and role badge."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(dm): add Direct Messages / Calm Inbox drawer and repository" \
  --milestone "v0.7.0" \
  --body "Add a 1-on-1 Direct Messages / Calm Inbox drawer (no typing-indicator pressure) backed by Serverpod protocol and 800ms resilient local fallback."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(auth): add Stage 1 'Any Auth' sign-in and authenticated member attribution" \
  --milestone "v0.8.0-alpha" \
  --body "Add frictionless Stage 1 sign-in so posts, reactions, DMs, and profiles are tied to an authenticated member session instead of hardcoded 'Fellowship Member'."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(notifications): add Calm Notification Bell & in-app activity drawer" \
  --milestone "v0.8.0-alpha" \
  --body "Add a top-bar Notification Bell opening a calm activity drawer (care affirmations, replies, DMs, announcements) without anxiety-inducing red unread counters."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(moderation): add author post edit/delete and steward moderation controls for RC" \
  --milestone "v0.9.0-rc" \
  --body "Allow authors to edit/delete their own reflections and allow community stewards to pin announcements or gently archive/hide posts for RC readiness."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(auth-google): add Google Sign-In ('Good Auth') for v1.0.1 / v1.1.0 fast-follow" \
  --milestone "v1.1.0" \
  --body "Upgrade authentication with Google OAuth / Serverpod Auth ('Good Auth') as a fast-follow in v1.0.1 / v1.1.0."

/opt/homebrew/bin/gh issue create --repo "$FULL_REPO" \
  --title "feat(push-email): add push & scheduled Quiet Digest email notifications for v1.0.1 / v1.1.0" \
  --milestone "v1.1.0" \
  --body "Add opt-in push notifications and scheduled daily/weekly Quiet Digest email delivery for v1.0.1 / v1.1.0."

echo "======================================================================"
echo " Done! All Milestones & Issues created on https://github.com/${FULL_REPO}/issues"
echo "======================================================================"
