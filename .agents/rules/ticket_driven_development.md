# Rule: Ticket-Driven Development, Pragmatic BDD/TDD & Marionette/Maestro Driving

Under NO circumstances may any changes be pushed directly to the `main` branch. All development must be strictly ticket-driven, follow standard conventional commit naming, and use pragmatic BDD + Marionette/Maestro verification.

## 1. Strict Branch & Commit Governance

1. **Protected `main` Branch**:
   - Never run `git push origin main`.
   - `main` is strictly updated via approved, triaged Pull Requests (`1 GitHub Issue = 1 Worktree Branch = 1 PR`).

2. **Issue-First / Ticket-Driven Workflow**:
   - Every task, bug fix, feature, or refactor MUST be tracked by a GitHub issue ticket (e.g., `#6`, `#14`), grouped under Epics/Milestones (`v0.6.0`, `v0.7.0`, `v0.8.0-alpha`, `v0.9.0-rc`, `v1.0.0`, `v1.0.1`/`v1.1.0`).
   - If a ticket does not exist for the work, create one first using the GitHub MCP server or `gh issue create` before creating a branch or writing code.

3. **Ticket-Named Branches & Git Worktrees**:
   - Create dedicated feature branches (and worktrees in `/Users/neil/belongonthespectrum/.worktrees/issue-<id>-<slug>` when working in parallel):
     - `feat/#<ticket-id>-<slug>` (e.g., `feat/#12-tenant-brand-config`)
     - `fix/#<ticket-id>-<slug>` (e.g., `fix/#15-space-filter-reset`)
     - `docs/#<ticket-id>-<slug>` (e.g., `docs/#18-release-notes`)

4. **Conventional Commits with Ticket Scopes**:
   - Every git commit MUST follow Conventional Commits with the ticket number in scope:
     - `feat(#<ticket>): <imperative summary>`
     - `fix(#<ticket>): <imperative summary>`
     - `docs(#<ticket>): <imperative summary>`
     - `test(#<ticket>): <imperative summary>`
     - `refactor(#<ticket>): <imperative summary>`
     - `chore(#<ticket>): <imperative summary>`

## 2. Testing & Driving Philosophy (BDD + Marionette/Maestro — No Playwright/CDP)

1. **Pragmatic BDD First (Don't Overkill Unit TDD)**:
   - Prioritize human-readable **Behavior-Driven Development (BDD)** specifications (`test/features/*.feature` and `bdd_widget_test` from `pub.dev` where reasonable) that verify real user-observable behaviors (switching spaces, posting reflections/memes, profile updates, DMs, calm notifications, auth flows).
   - Write targeted unit tests for core domain/repository logic (`LocalPostRepository`, `ServerpodPostRepository`, `TenantBrandConfig`), avoiding brittle, over-mocked boilerplate TDD.

2. **Drive Live Apps with Marionette & Maestro (Avoid CDP / Playwright)**:
   - **Do NOT use Playwright or raw Chrome DevTools Protocol (CDP)** scripts to drive the UI.
   - **Marionette (`marionette_mcp` / `marionette_flutter`)**: Connect to the Flutter VM Service WebSocket to inspect interactive semantic elements (`get_interactive_elements`), tap widgets by key/text, trigger hot-reload, and capture screenshots cleanly.
   - **Maestro (`~/.maestro/bin/maestro`)**: Use declarative `.maestro/*.yaml` flows for mobile E2E journeys on the physical **Pixel 9a**.
   - **Patrol (`patrol_mcp` / `patrol_cli`)**: Use when native OS permission dialogs or platform lifecycle interactions are required.

## 3. PR Merge Governance & Automated CodeRabbit Triage

- Merge branches into `main` exclusively through Pull Requests audited and triaged using [.agents/skills/pr-coderabbit-triage-and-merge](../skills/pr-coderabbit-triage-and-merge/SKILL.md):
  - Wait at least 180 seconds after PR creation or push before running triage.
  - Execute `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/triage_pr_comments.py --repo neiljaywarner/refuge4serverpod --pr <pr_num>` to classify comments into addressed, critical blockers, and non-critical items.
  - Execute `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/defer_comments_to_issues.py --repo neiljaywarner/refuge4serverpod --pr <pr_num>` to automatically convert unaddressed non-critical comments into tracked GitHub issues.
- **Mandatory Review Reply Guarantee**:
  - Every single review comment on every PR MUST receive an explicit threaded reply via GitHub API summarizing the resolution/commit or linking the deferred GitHub issue (`Deferred to tracked issue: <issue_url>`).

## 4. Command Execution Permissions & MCP-First Protocol

1. **MCP Server Precedence**:
   - Prefer configured MCP servers (`dart`, `marionette`, `patrol`, `adb`, `github`) where available.
   - When `gh` CLI is authenticated (`gh auth status`), `run_github_mcp.sh` automatically supplies the token to `@modelcontextprotocol/server-github`.
2. **Strictly Prohibited Operations**:
   - `git push origin main` or any direct commit, push, or force operation targeting `main`.
