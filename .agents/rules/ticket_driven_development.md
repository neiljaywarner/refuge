---
trigger: always_on
description: Enforces strict Ticket-Driven Development (1 Issue = 1 Worktree = 1 PR), Marionette *_feature.txt driving + patrol_finders BDD + pragmatic TDD, visual screenshots/videos on PRs/Issues/Wiki, and continuous CodeRabbit PR triage, squash-merge, and branch deletion.
---

# Ticket-Driven Development, Marionette/Patrol BDD, Visual Evidence & CodeRabbit PR Merge Rule

Every agent (across all model tiers) working in `/Users/neil/belongonthespectrum` and `/Users/neil/belongonthespectrum/refuge` MUST follow this integrated workflow:

## 1. Strict Ticket-Driven Development (`1 Issue = 1 Worktree = 1 PR`)
- **No Direct Commits to `main`**: Never commit or push directly to `main`.
- **Issue First**: Every feature, bugfix, doc update, or refactor must map to a GitHub Issue on `https://github.com/neiljaywarner/refuge/issues` with a human-readable summary and a `🤖 LLM Execution Brief` comment.
- **Isolated Worktree per Ticket**:
  Create worktrees under `/Users/neil/belongonthespectrum/.worktrees/issue-<NUM>-<slug>` with branch naming `feat/#<NUM>-<slug>`, `fix/#<NUM>-<slug>`, `docs/#<NUM>-<slug>`, or `chore/#<NUM>-<slug>`.
- **Atomic Pull Requests**: Push the branch and open a Pull Request on `https://github.com/neiljaywarner/refuge/pulls` referencing `Closes #<NUM>`.

## 2. Continuous CodeRabbit Triage, Squash-Merge & Branch Deletion (`tool/refuge_cli.dart`)
- Inspired by `.agents/skills/pr-coderabbit-triage-and-merge/` (`triage_pr_comments.py` / `defer_comments_to_issues.py`), adapted into our pure-Dart CLI (`tool/refuge_cli.dart`):
  1. When a PR is opened, trigger `@coderabbitai review`.
  2. Inspect PR review comments (`gh api repos/neiljaywarner/refuge/pulls/<PR>/comments` & `reviews`):
     - Fix critical/blocking bugs or security issues immediately in the worktree.
     - Defer non-blocking polish items to Issue `#36` (CodeRabbit Release Audit Gate) with a clear reference comment.
  3. **Do Not Leave Verified PRs Hanging Open**: Once `analyze_files` and `run_tests` pass via the Dart MCP server, **squash-merge the PR and delete the branch** (`gh pr merge <PR> --squash --delete-branch`), pull `origin/main`, and prune the completed worktree so PRs continuously open, get verified/triaged, and close cleanly!

## 3. Marionette `*_feature.txt` Driving + `patrol_finders` BDD + Pragmatic TDD + Visual Evidence
- **Marionette `test/features/*_feature.txt` Specs**: Write human-readable Gherkin `*_feature.txt` files designed to be driven interactively via Marionette MCP/CLI (`marionette_mcp`) and converted into fast `patrol_finders` widget tests (`patrolWidgetTest` / `$`) or Patrol native integration tests (`patrolTest`) per `.agents/skills/bdd-patrol-testing/SKILL.md`.
- **Pragmatic Unit TDD**: Use Red-Green-Refactor unit tests strictly for genuine domain/business logic (`CommunityBrandConfig`, `OrganizerRemoteConfigService`, `FeatureVotingNotifier`, Circle CSV parsing).
- **Visual Screenshots & Videos on Wiki, PRs & Issues**: Follow `plan_to_make_videos_and_screenshots_for_wiki_and_prs_andgithub_issues.md` to capture and embed screenshots/videos across the Wiki (`refuge.wiki.git`), Pull Requests, and GitHub Issues.
