# 🌙 Unattended Session Execution Plan (`unattended_session_908pm.md`)

> **Window**: Sunday, October 18, 2026 · **9:08 PM – 11:30+ PM CDT**
> **Target Outcome**: Ship **`v0.6.0`**, **`v0.7.0`**, and **`v0.8.0-alpha`** (*Usable Community Alpha with Stage 1 Auth, Feature Voting 4-Layer Test Suite, Direct Messages, Events Calendar, Circle CSV Importer, and Live Deployment to `https://belongonthespectrum.web.app` + Firebase Preview Channels*).
> **Companion Review Doc**: [`neil_to_review_sunday_night.md`](file:///Users/neil/belongonthespectrum/refuge/neil_to_review_sunday_night.md)
> **Deployment Runbook**: [`DEPLOYMENT.md`](file:///Users/neil/belongonthespectrum/refuge/DEPLOYMENT.md)
> **Backend Migration ADR**: [`docs/adr/0009-piece-by-piece-vs-one-shot-appwrite-firebase-hybrid.md`](file:///Users/neil/belongonthespectrum/refuge/docs/adr/0009-piece-by-piece-vs-one-shot-appwrite-firebase-hybrid.md)
> **Live Wiki**: [GitHub Wiki (`refuge.wiki.git`)](https://github.com/neiljaywarner/refuge/wiki)

---

## 1. Zero-Interruption Autonomous Execution Architecture

1. **System Wake Lock Active**: `caffeinate -dimsu -t 28800` (`task-718`) running for 8 hours.
2. **Firebase Authenticated & Provisioned**: Project `belongonthespectrum` (`https://belongonthespectrum.web.app`) live and configured in `.firebaserc` & `firebase.json`, plus Firebase MCP server registered in `~/.gemini/config/mcp_config.json`.
3. **All CLI & MCP Tools Pre-Authorized**: `gh` (`issue`, `pr`, `api`, `label`, `release`), `firebase` (`deploy`, `hosting:channel:deploy`), `flutter`, `dart`, `adb`, `patrol`, `marionette_mcp`, and `git push` are all verified with exit code 0.

---

## 2. Execution Phases (Phases 0 – 5)

See [`/Users/neil/belongonthespectrum/unattended_session_908pm.md`](file:///Users/neil/belongonthespectrum/unattended_session_908pm.md) and [`neil_to_review_sunday_night.md`](file:///Users/neil/belongonthespectrum/refuge/neil_to_review_sunday_night.md) for the live ticket-by-ticket tracker.
