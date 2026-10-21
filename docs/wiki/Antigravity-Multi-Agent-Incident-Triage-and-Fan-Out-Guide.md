# 🐝 Antigravity Multi-Agent Incident Triage & "Fan-Out" Guide

> [!TIP]
> **Antigravity Use-Case Reference**: Implementation guide for Google Antigravity's [Incident Triage, Debugging & Root Cause Analysis](https://antigravity.google/use-cases/incident-triage) use case. Explains how to leverage multi-agent parallel fan-out to drastically cut Mean Time to Resolution (MTTR) for Belong on the Spectrum.

---

## 🧭 Why Multi-Agent Fan-Out?

In complex full-stack Flutter applications powered by Riverpod, Serverpod WebSockets, and Firebase services, diagnosing an incident sequentially can take 30–60 minutes:
1. First, reading through 500 lines of logs...
2. Then, checking git commit history...
3. Then, searching closed issues...
4. Finally, writing a repro test.

**Multi-Agent Fan-Out** collapses this entire sequence from serial into parallel:
When an incident is reported, the orchestrator immediately invokes **4 specialized subagents concurrently**, each running in its own lightweight context with specific tools.

```
                              ┌─────────────────────────┐
                              │   Master Orchestrator   │
                              │ (Synthesizes & Reports) │
                              └────────────┬────────────┘
                ┌──────────────────┬───────┴────────┬──────────────────┐
                ▼                  ▼                ▼                  ▼
       ┌─────────────────┐ ┌───────────────┐ ┌──────────────┐ ┌─────────────────┐
       │ Subagent 1      │ │ Subagent 2    │ │ Subagent 3   │ │ Subagent 4      │
       │ Logs & Traces   │ │ Git & Blame   │ │ GitHub MCP   │ │ Repro & Patch   │
       │                 │ │               │ │ Historical   │ │                 │
       │ • Crashlytics   │ │ • Recent PRs  │ │ • Search PRs │ │ • Failing test  │
       │ • Talker Buffer │ │ • Diff check  │ │ • CodeRabbit │ │ • Verify green  │
       └────────┬────────┘ └───────┬───────┘ └──────┬───────┘ └────────┬────────┘
                └──────────────────┼────────────────┴──────────────────┘
                                   ▼
                      ┌─────────────────────────┐
                      │ Single Root Cause (RCA) │
                      │ & Verified Patch PR     │
                      └─────────────────────────┘
```

---

## 🛠️ How to Trigger Multi-Agent Fan-Out in Antigravity

### Method 1: The `/teamwork-preview` Slash Command
Type `/teamwork-preview` directly in chat when you want multiple autonomous agents to collaborate on a bug, feature, or outage.

### Method 2: Natural Language Instruction
You can prompt the agent directly:
> *"Antigravity, please fan out 3 subagents to investigate this Crashlytics incident: Subagent 1 for log analysis, Subagent 2 to check recent git commits, and Subagent 3 to write a reproducing widget test."*

The orchestrator executes this by calling `invoke_subagent` for each specialized role:
```dart
invoke_subagent(
  TypeName: 'research',
  Role: 'Log & Stack Trace Investigator',
  Prompt: 'Inspect Talker logs and Crashlytics reports for exception "invalid-action-code". Isolate exact timestamp and stack frame.'
);

invoke_subagent(
  TypeName: 'research',
  Role: 'Git Regression Auditor',
  Prompt: 'Audit git commits merged to main in the last 48 hours for changes touching AuthRepository or BelongAuthSheet.'
);

invoke_subagent(
  TypeName: 'self',
  Role: 'Repro Test Builder',
  Prompt: 'Write a failing patrolWidgetTest capturing the auth flow failure, then verify the candidate fix.'
);
```

---

## 🔍 The 4 Specialized Subagent Roles

### 1. Log & Telemetry Investigator
- **Scope**: Queries Firebase Crashlytics, device logcat, and local `ServerpodTelemetryBackup` ring buffer.
- **Rule**: Scrubs PII (emails, auth tokens, device serials) before posting findings.

### 2. Git History & Blame Auditor
- **Scope**: Runs `git log -p -n 10` and `git diff` against recent PRs.
- **Goal**: Identifies the exact commit that introduced the regression.

### 3. Historical Knowledge & CodeRabbit Auditor
- **Scope**: Uses GitHub MCP (`search_issues`, `pull_request_read`) to find if CodeRabbit or a prior PR already discussed this failure signature.

### 4. Reproducer & Patch Verifier
- **Scope**: Works in an isolated worktree (`/Users/neil/belongonthespectrum/.worktrees/issue-<NUM>-<slug>`).
- **Goal**: Creates a deterministic test, applies the fix, and runs `run_tests` via the Dart MCP server.

---

## 📊 Summary of Benefits for Belong on the Spectrum
- **Zero Token Bloat**: Each subagent operates with a clean, focused context window rather than cluttering the parent conversation.
- **Time Savings**: RCA delivered in under 2 minutes instead of 20 minutes.
- **Higher Accuracy**: Multiple perspectives prevent premature conclusions.
