#!/usr/bin/env python3
"""
triage_pr_comments.py
Fetches and inventories all PR review comments (especially CodeRabbit comments),
classifies them into Addressed, Critical Blockers, or Non-Critical (Defer to Issues),
and outputs a markdown summary table or JSON.
"""

import argparse
import json
import re
import subprocess
import sys


def get_current_repo_and_pr():
    try:
        pr_json = subprocess.check_output(
            ["gh", "pr", "view", "--json", "number,headRepositoryOwner,headRepository"],
            text=True,
        )
        data = json.loads(pr_json)
        pr_num = data.get("number")
        owner = data.get("headRepositoryOwner", {}).get("login", "")
        repo = data.get("headRepository", {}).get("name", "")
        return owner, repo, pr_num
    except Exception:
        return None, None, None


def fetch_pr_comments(owner, repo, pr_num):
    endpoint = f"repos/{owner}/{repo}/pulls/{pr_num}/comments"
    output = subprocess.check_output(
        ["gh", "api", endpoint, "--paginate"],
        text=True,
    )
    return json.loads(output)


def parse_comment(comment):
    body = comment.get("body", "")
    path = comment.get("path", "")
    line = comment.get("line") or comment.get("original_line") or "?"
    html_url = comment.get("html_url", "")
    user = comment.get("user", {}).get("login", "unknown")
    cid = comment.get("id")

    # Check if already addressed
    addressed = "✅ Addressed" in body or "✅ resolved" in body.lower()

    # Extract category
    category = "General"
    cat_match = re.search(r"\*\*(🔒[^*]+|🎯[^*]+|📐[^*]+|🩺[^*]+|🗄️[^*]+)\*\*", body)
    if cat_match:
        category = cat_match.group(1).strip()

    # Extract severity
    severity = "Minor"
    sev_match = re.search(r"\*\*(🔴 Critical|🟠 Major|🟡 Minor|🔵 Low)\*\*", body)
    if sev_match:
        severity = sev_match.group(1).strip()

    # Extract clean headline summary (ignoring badges, details tags, and scripts)
    summary = ""
    lines = body.split("\n")
    for l in lines:
        stripped = l.strip()
        if not stripped:
            continue
        if stripped.startswith("<") or stripped.startswith("```") or stripped.startswith("🏁") or stripped.startswith("set -") or stripped.startswith("---") or stripped.startswith("rg ") or stripped.startswith("sed "):
            continue
        # Check if line has a bold title that isn't the badge
        m_bold = re.search(r"\*\*([^*]+)\*\*", stripped)
        if m_bold:
            candidate = m_bold.group(1).strip()
            if not any(badge in candidate for badge in ["🔒", "🎯", "📐", "🩺", "🗄️", "Critical", "Major", "Minor", "Low", "Quick win", "Heavy lift"]):
                summary = candidate
                break
        # Or take the first informative sentence
        if not summary and len(stripped) > 15 and not stripped.startswith("*"):
            summary = stripped
            break

    if not summary:
        summary = f"Review comment on {path}:{line}"

    # Check critical status
    is_security = "🔒" in category or "security" in summary.lower() or "secret" in summary.lower() or "key" in summary.lower()
    is_critical = "Critical" in severity or (is_security and ("plaintext" in summary.lower() or "hardcoded" in summary.lower()))

    recommendation = "Addressed" if addressed else ("Critical / Fix Now" if is_critical else "Defer to Issue")

    return {
        "id": cid,
        "author": user,
        "file": f"{path}:{line}",
        "category": category,
        "severity": severity,
        "summary": summary[:140],
        "addressed": addressed,
        "is_critical": is_critical,
        "recommendation": recommendation,
        "url": html_url,
        "full_body": body,
    }


def main():
    parser = argparse.ArgumentParser(description="Triage PR review comments.")
    parser.add_argument("--pr", type=int, help="PR number (default: auto-detected from git)")
    parser.add_argument("--repo", type=str, help="owner/repo (default: auto-detected)")
    parser.add_argument("--json", action="store_true", help="Output raw JSON")
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
        print("Error: Could not detect repository and PR number. Specify --repo and --pr.", file=sys.stderr)
        sys.exit(1)

    comments = fetch_pr_comments(owner, repo, pr_num)
    parsed = [parse_comment(c) for c in comments]

    if args.json:
        print(json.dumps(parsed, indent=2))
        return

    print(f"### PR #{pr_num} Review Comments Triage ({len(parsed)} total)\n")
    print("| # | File | Category / Severity | Summary | Status / Action |")
    print("| :--- | :--- | :--- | :--- | :--- |")
    for idx, c in enumerate(parsed, 1):
        status_badge = "✅ Addressed" if c["addressed"] else (
            "🚨 CRITICAL (Fix Now)" if c["is_critical"] else "📋 DEFER (Create Issue)"
        )
        print(f"| {idx} | `{c['file']}` | {c['category']} ({c['severity']}) | [{c['summary']}]({c['url']}) | {status_badge} |")

    # Counts
    addressed_count = sum(1 for c in parsed if c["addressed"])
    critical_count = sum(1 for c in parsed if not c["addressed"] and c["is_critical"])
    defer_count = sum(1 for c in parsed if not c["addressed"] and not c["is_critical"])

    print(f"\n**Triage Summary:**")
    print(f"- **Addressed:** {addressed_count}")
    print(f"- **Critical Blockers:** {critical_count}")
    print(f"- **Eligible to Defer:** {defer_count}\n")


if __name__ == "__main__":
    main()
