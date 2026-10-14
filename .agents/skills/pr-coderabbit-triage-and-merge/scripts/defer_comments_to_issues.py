#!/usr/bin/env python3
"""
defer_comments_to_issues.py
Reads comments from a PR and automatically converts unaddressed, non-critical
comments into structured GitHub issues on the repository using the `gh` CLI.
"""

import argparse
import json
import subprocess
import sys
from triage_pr_comments import fetch_pr_comments, get_current_repo_and_pr, parse_comment


def issue_exists(title):
    try:
        out = subprocess.check_output(
            ["gh", "issue", "list", "--state", "all", "--search", title[:30], "--json", "title"],
            text=True,
        )
        data = json.loads(out)
        for issue in data:
            if title[:30].lower() in issue.get("title", "").lower():
                return True
        return False
    except Exception:
        return False


def create_issue_for_comment(comment, dry_run=False):
    cid = comment["id"]
    file_loc = comment["file"]
    summary = comment["summary"]
    category = comment["category"]
    url = comment["url"]
    full_body = comment["full_body"]

    title = f"{category}: {summary}"
    if len(title) > 100:
        title = title[:97] + "..."

    body = f"""### Context & Origin
Deferred review comment on [{file_loc}]({url}) from PR review (Comment ID: `{cid}`).

### Review Finding
{summary}

<details>
<summary>Original Review Comment</summary>

{full_body}

</details>

---
*Created automatically by pr-coderabbit-triage-and-merge skill.*
"""

    if issue_exists(title):
        print(f"⏭️  Issue already exists for: {title}")
        return None

    if dry_run:
        print(f"🔍 [Dry Run] Would create issue: {title}")
        return "dry_run"

    print(f"🚀 Creating issue: {title}")
    res = subprocess.run(
        ["gh", "issue", "create", "--title", title, "--body", body],
        capture_output=True,
        text=True,
    )
    if res.returncode == 0:
        issue_url = res.stdout.strip()
        print(f"   Created: {issue_url}")
        return issue_url
    else:
        print(f"   Error: {res.stderr.strip()}", file=sys.stderr)
        return None


def reply_to_comment(owner, repo, pr_num, cid, body):
    try:
        subprocess.run([
            "gh", "api", f"repos/{owner}/{repo}/pulls/{pr_num}/comments/{cid}/replies",
            "-f", f"body={body}"
        ], capture_output=True, text=True)
    except Exception as e:
        print(f"Failed to reply to comment {cid}: {e}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Convert unaddressed non-critical comments to GitHub issues.")
    parser.add_argument("--pr", type=int, help="PR number (default: auto-detected)")
    parser.add_argument("--repo", type=str, help="owner/repo (default: auto-detected)")
    parser.add_argument("--dry-run", action="store_true", help="Preview without creating issues")
    args = parser.parse_args()

    owner, repo, pr_num = None, None, args.pr
    if args.repo and "/" in args.repo:
        owner, repo = args.repo.split("/", 1)
    else:
        auto_owner, auto_repo, auto_pr = get_current_repo_and_pr()
        owner = owner or auto_owner
        repo = repo or auto_repo
        pr_num = pr_num or auto_pr

    if not owner or not repo or not pr_num:
        print("Error: Could not detect repository and PR number.", file=sys.stderr)
        sys.exit(1)

    comments = fetch_pr_comments(owner, repo, pr_num)
    parsed = [parse_comment(c) for c in comments]

    # Fetch existing replies to avoid duplicate replies
    all_comments_raw = subprocess.check_output(
        ["gh", "api", f"repos/{owner}/{repo}/pulls/{pr_num}/comments"], text=True
    )
    all_comments = json.loads(all_comments_raw)
    replied_ids = {c.get("in_reply_to_id") for c in all_comments if c.get("in_reply_to_id")}

    eligible = [c for c in parsed if not c["addressed"] and not c["is_critical"]]
    print(f"Found {len(eligible)} comments eligible for deferral into GitHub issues.")

    for c in eligible:
        issue_url = create_issue_for_comment(c, dry_run=args.dry_run)
        if not args.dry_run and issue_url and c["id"] not in replied_ids:
            reply_text = f"Deferred to tracked issue: {issue_url}"
            reply_to_comment(owner, repo, pr_num, c["id"], reply_text)
            print(f"   💬 Replied to comment {c['id']}")


if __name__ == "__main__":
    main()

