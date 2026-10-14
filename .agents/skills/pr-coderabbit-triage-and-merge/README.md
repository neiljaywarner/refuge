# PR Review Triage & Merge Skill (`pr-coderabbit-triage-and-merge`)

An autonomous, reusable workflow skill for reviewing, triaging, and merging Pull Requests with AI reviewer feedback (such as **CodeRabbit** or automated PR bots).

It ensures that pull requests are never blocked unnecessarily while maintaining strict quality gates:
* **Addressed Findings**: Verified against current code and tests.
* **Critical Blockers**: Fixed immediately or escalated before merging.
* **Non-Critical Suggestions**: Converted automatically into tracked GitHub issues on the repository.
* **Security & Secret Compliance**: Zero plaintext API keys or credentials allowed into the codebase.

---

## 📁 Skill Architecture

```text
.agents/skills/pr-coderabbit-triage-and-merge/
├── SKILL.md                          # Primary agent runbook with YAML frontmatter
├── README.md                         # Detailed documentation and developer manual
├── scripts/
│   ├── triage_pr_comments.py         # Inspects PR comments, parses categories & severity, formats markdown
│   └── defer_comments_to_issues.py   # Converts eligible non-critical findings into GitHub issues
└── references/
    └── triage_rubric.md              # Decision tree and severity criteria (Blocker vs. Defer)
```

---

## ⚡ Quick Start / Usage

### 1. Run Comment Triage
From the root of the repository, execute:

```bash
# Auto-detects active branch and associated PR
python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/triage_pr_comments.py

# Or specify an explicit PR and repository
python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/triage_pr_comments.py --repo owner/repo --pr 5
```

**Sample Output:**
```markdown
### PR #5 Review Comments Triage (22 total)

| # | File | Category / Severity | Summary | Status / Action |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `lib/.../chapter_player_notifier.dart:392` | 🔒 Security & Privacy (🟠 Major) | Isolate third-party Dio calls | ✅ Addressed |
| 2 | `feedback_mechanism.md:53` | 🔒 Security & Privacy (🟠 Major) | Keep GitHub PAT off client | 📋 DEFER (Create Issue) |

**Triage Summary:**
- **Addressed:** 12
- **Critical Blockers:** 0
- **Eligible to Defer:** 10
```

---

### 2. Auto-Defer Remaining Non-Critical Items to GitHub Issues
To convert all unaddressed, non-critical comments into tracked project issues:

```bash
# Dry run to preview issues that would be created
python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/defer_comments_to_issues.py --dry-run

# Create issues directly via gh CLI
python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/defer_comments_to_issues.py
```

Each issue is created with:
* Context and origin link pointing directly to the PR review comment.
* Summary and actionable guidance.
* Collapsible raw review details.
* Duplication check preventing duplicate issues if one already exists.

---

### 3. Verify & Merge
Once any critical items are addressed and non-critical items are deferred:
1. `flutter analyze` (must be 0 issues).
2. `flutter test` (must pass 100% green).
3. Secret check: `git diff --staged | grep -i -E "api[_-]?key|secret|token"`.
4. Merge: `gh pr merge <pr_number> --merge`.

---

## 📋 Triage Rubric Summary

| Tier | Characteristics | Action Required |
| :--- | :--- | :--- |
| **✅ Addressed** | Verified fixed in git commits or marked resolved by reviewer. | Record in report as completed. |
| **🚨 Critical Blocker** | Hardcoded API keys/secrets, infinite loops, fatal crashes, test failures. | Fix immediately on PR branch or alert user. Blocks merge. |
| **📋 Non-Critical (Defer)** | Future architectural blueprints, documentation refinements, rare edge cases. | Convert to tracked GitHub issue. Does not block merge. |

For the complete decision tree and rules, see [references/triage_rubric.md](references/triage_rubric.md).
