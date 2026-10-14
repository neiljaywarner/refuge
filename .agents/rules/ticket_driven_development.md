# Rule: Zero Direct Pushes to Main, Ticket-Driven Branches & Conventional Commits

Under NO circumstances may any changes be pushed directly to the `main` branch. All development must be strictly ticket-driven and follow standard conventional commit naming.

## Strict Requirements

1. **Protected `main` Branch**:
   - Never run `git push origin main`.
   - `main` is strictly updated via approved, triaged Pull Requests.

2. **Issue-First / Ticket-Driven Workflow**:
   - Every task, bug fix, feature, or refactor MUST be tracked by a GitHub issue ticket (e.g., `#6`, `#14`).
   - If a ticket does not exist for the work, create one first using `gh issue create` before creating a branch or writing code.

3. **Ticket-Named Branches**:
   - Create and work on dedicated feature branches that reference the ticket ID:
     - `feat/#<ticket-id>-<slug>` (e.g., `feat/#6-walking-mode`)
     - `fix/#<ticket-id>-<slug>` (e.g., `fix/#14-shuffle-repetition`)
     - `docs/#<ticket-id>-<slug>` (e.g., `docs/#10-licensing-notes`)

4. **Conventional Commits with Ticket Scopes**:
   - Every single git commit MUST follow the Conventional Commits specification and include the ticket number in the scope:
     - `feat(#<ticket>): <imperative summary>`
     - `fix(#<ticket>): <imperative summary>`
     - `docs(#<ticket>): <imperative summary>`
     - `test(#<ticket>): <imperative summary>`
     - `refactor(#<ticket>): <imperative summary>`
     - `chore(#<ticket>): <imperative summary>`
   - Examples:
     - `feat(#6): add background audio service and lockscreen controls`
     - `fix(#14): preserve iteration count across shuffle translation cycles`

5. **PR Merge Governance & Automated CodeRabbit Triage**:
   - Merge branches into `main` exclusively through Pull Requests audited and triaged using the [.agents/skills/pr-coderabbit-triage-and-merge](../../skills/pr-coderabbit-triage-and-merge/README.md) skill:
     - Wait at least 180 seconds after PR creation or push before running triage.
     - Execute `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/triage_pr_comments.py --repo <owner/repo> --pr <pr_num>` to classify comments into addressed, critical blockers, and non-critical items.
     - Execute `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/defer_comments_to_issues.py --repo <owner/repo> --pr <pr_num>` to automatically convert unaddressed non-critical comments into tracked GitHub issues.
   - **Mandatory Review Reply Guarantee**:
     - Every single review comment on every PR MUST receive an explicit threaded reply via GitHub API:
       - Either summarizing the resolution/commit if addressed, OR
       - Providing the direct GitHub issue link (`Deferred to tracked issue: <issue_url>`) so no reviewer finding is ever left unacknowledged or abandoned.

## Command Execution Permissions & MCP-First Protocol

### 0. MCP Server Precedence (MANDATORY)
- **Always Prefer MCP Servers**: Whenever an MCP server is configured and functional (`github` MCP via `call_mcp_tool`, `marionette` MCP, `patrol` MCP), you MUST execute GitHub operations (issue creation, PR creation, PR merging, comments, issue inspection) using the **`github` MCP server via `call_mcp_tool`**, NOT local CLI commands (`gh`).
- Do NOT prompt or invoke `gh` CLI commands when GitHub MCP tools (`create_issue`, `create_pull_request`, `merge_pull_request`, `add_issue_comment`) are available.

### 1. Permitted Autonomous Commands
- `git commit` (on dedicated ticket/feature branches with conventional commit syntax).
- `git push origin <ticket-branch>` (pushing to feature/ticket branches is fully authorized).
- `git push origin master` (**ONLY permitted within the isolated GitHub Wiki git repository** `*.wiki.git`, NEVER in code repositories).
- `git status`, `git diff`, `git branch`, `git checkout`, `git add`.
- Python review triage and auto-defer scripts:
  - `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/triage_pr_comments.py`
  - `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/defer_comments_to_issues.py`
- Test & verification commands: `flutter test`, `flutter analyze`.

### 2. Strictly Prohibited Operations
- `git push origin main` or any direct commit, push, or destructive force operation targeting `main`.
- `git push origin master` targeting the primary code repository (`master` is reserved exclusively for the standalone GitHub Wiki `*.wiki.git` repository).
- Accidental nesting of the cloned wiki repo inside the primary project working directory (always clone into `.worktrees/selah_wiki` or `.git/info/exclude` directories).

