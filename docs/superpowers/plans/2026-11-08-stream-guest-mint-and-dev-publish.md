# Stream Guest Mint and Dev Publish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:writing-plans (this document), then superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Sized for a less expensive model: one checkbox is one verifiable slice. Do not improvise extra scope. Fail closed. Never print secrets. Prefer already-connected MCP tools (`user-Supabase`, `cursor-github`) over CLI logins. Do **not** run `supabase login` and do **not** ask the project owner for CLI verification codes or access tokens unless a later task is explicitly blocked and every other unblocked slice is done.

**Goal:** Make the Belong Stream preview support a Zoom-like invite link (open link → type display name → join without an account), with organizer ability to disallow guest mode, guest mode on by default for Belong preview (`dev` flavor / `FLAVOR=dev` / applicationId `.dev`) and off by default in production — and publish only to the Belong **dev** site when confident.

**Architecture:** Signed-in members mint Stream tokens from a server that holds `STREAM_API_KEY` and `STREAM_API_SECRET`. Guest create/join/revoke/release live today only in open PR #905 on Firebase `mintStreamCallToken` (not deployed; production URL still 404). The live Supabase edge function `mint-stream-call-token` covers signed-in mint only. Guest publish therefore needs either (A) deploy Firebase mint from #905 without enabling Secret Manager unless the owner asks, or (B) port guest actions onto the Supabase function and set Stream secrets via a path that does not embed them in source. Prefer documenting both; do not merge #902 or #905 unless the owner explicitly asks.

**Tech Stack:** Flutter Belong DEV flavor, Firebase Auth (Belong project), GetStream Video, Supabase edge function `mint-stream-call-token`, optional Firebase HTTPS `mintStreamCallToken` from #905, local Node mint under `the local-mint scratch directory (not in this repo) /`, Android emulator / web preview, `tool/deploy_dev_web.dart`.

## Global Constraints

- Never commit or print passwords, API secrets, API keys as values, JWT strings, Firebase ID tokens, invite tokens, emails, vault IDs, raw home-directory paths, billing IDs, or Stream dashboard organization/app IDs. Reporting HTTP status codes and JSON field *names* is fine.
- Stream API **key** may live in the app or Firebase Remote Config (like Giphy). Stream API **secret** must NEVER go in the APK, dart-define, Remote Config, client, or public repo. Tokens are minted server-side only.
- Do not put `STREAM_API_SECRET` or `STREAM_API_KEY` into edge-function source when using `deploy_edge_function`.
- Do not deploy to production (`belongonthespectrum.web.app` or `tool/deploy_release.dart`). Dev only: `https://dev-belongonthespectrum.web.app` via `tool/deploy_dev_web.dart`.
- Do not merge pull requests #902 or #905 unless the project owner explicitly asks.
- Do not enable Firebase Secret Manager unless the owner asks.
- Two devices that use the same Stream `user_id` count as **one** participant.
- Prefer MCP: `user-Supabase` for function inspect; `cursor-github` for issue/PR titles. Call GetDynamicTools before CallDynamicTool.
- Local Stream env files may be checked with `ls`/`stat` only (mode 600). Never `cat`, `Read`, or echo their contents.
- Ask the owner to test only after a reviewed recording of an assistant-run test.

---

## Product goal (must stay visible)

Zoom-like invite link: someone opens the link, types a display name (“join as…”), and joins without an account. Organizer can disallow guest mode. Guest mode **on by default** for Belong preview (`dev` prefix / `FLAVOR=dev` / applicationId `.dev`) and **off by default** in production. Preview/guest work may be deployed to the Belong *dev* site once confident — **never** production.

Related:

- Epic [#871](https://github.com/neiljaywarner/refuge/issues/871)
- Guest issue [#904](https://github.com/neiljaywarner/refuge/issues/904)
- Follow-up [#908](https://github.com/neiljaywarner/refuge/issues/908) — *Follow-ups after Stream preview quick test: Zoom-style guest defaults and public mint*
- Preview PR [#902](https://github.com/neiljaywarner/refuge/pull/902) — *feat(video): preview GetStream group call (#872)* — branch `cursor/stream-video-preview-tests-f2e5` — **OPEN, do not merge**
- Guest PR [#905](https://github.com/neiljaywarner/refuge/pull/905) — *feat(video): Zoom-style guest join for the preview call (#904)* — branch `cursor/stream-guest-join-2e7c` stacked on #902 — **OPEN, do not merge**

What #905 already has (code, not live):

- Firebase `mintStreamCallToken` actions: `createInvite` / `joinGuest` / `revokeInvite` / `releaseGuest`
- Lobby Create/Revoke guest link
- ~24h invite, ~10 guest seats, guests muted/camera off, no end-for-everyone

What #905 does **not** have (tracked in #908):

- Persistent organizer on/off toggle for guest mode (preview default on, production default off)

---

## Verified facts (8 Nov 2026, America/Chicago ~6:58 PM CT)

These were checked via `user-Supabase` MCP and unsigned HTTP. Do not re-deploy the function just to re-check.

### Supabase project

- Project name: `belong-preview-mint`
- Project ref / `project_id`: resolve via `user-Supabase` `list_projects` (name `belong-preview-mint`); do not hard-code the ref in public docs
- Public mint URL: resolve with MCP `get_project_url` for project `belong-preview-mint`, then append `/functions/v1/mint-stream-call-token`

### Edge functions (`list_edge_functions`)

| slug | status | version | verify_jwt |
| --- | --- | --- | --- |
| `local-stream-save` | ACTIVE | 1 | false |
| `mint-stream-call-token` | ACTIVE | 1 | false |

### `mint-stream-call-token` source (`get_edge_function`)

- Signed-in members only: verifies Firebase ID token (Bearer) against Google JWKS for Firebase project `belongonthespectrum` (`aud` / `iss`).
- On success mints a Stream user JWT using `Deno.env.get("STREAM_API_KEY")` and `Deno.env.get("STREAM_API_SECRET")`.
- Missing env → HTTP 503 body error `Video calling is not configured on this preview.`
- Invalid/missing auth → HTTP 401 body error `Sign in is required.`
- **Guest actions are NOT in source:** no `createInvite`, `joinGuest`, `revokeInvite`, or `releaseGuest`.

### Unsigned HTTP checks (no secrets)

| Request | Status | Sanitized body |
| --- | --- | --- |
| POST, no `Authorization` | 401 | `{"error":"Sign in is required."}` |
| POST, `Authorization: Bearer fake.token.value` | 401 | `{"error":"Sign in is required."}` |

### Stream secrets configured on Supabase?

**Unknown.** Proving 503-vs-configured requires a valid Firebase ID token after the auth gate. Unsigned checks never reach the env read. Local gitignored env files exist (mode 600) on the assistant computer under `the local gitignored Stream env directory (not in this repo) /` and on the Mac Belong preview config directory; existence was confirmed with `ls`/`stat` only — contents were not read.

### Other known good

- Local mint server: `the local-mint scratch directory (not in this repo) /mint-server.js` for localhost/emulator tests.
- CLI two-person POC already succeeded (`poc_alice` + `poc_bob` on call `default/poc-quick-test`).
- Firebase HTTPS `mintStreamCallToken` still undeployed (404). Do not enable Secret Manager unless asked.

---

## How a cheaper model should work

1. Read **Current status**, **Next three actions**, then the next unchecked Task.
2. Do only that slice. Verify with the exact command/expected result. Write what you observed (no secrets).
3. If verification fails, stop and report. Do not weaken a security check to make a test pass.
4. Prefer MCP over CLI. If a slice needs the owner (dashboard secrets UI, Firebase deploy approval), finish every other unblocked slice first, then say exactly what is needed — never ask for CLI codes or paste tokens into chat.
5. After each meaningful verified slice, prepare a sanitized docs commit (checkbox updates). A later CloudAgent should commit the plan preferably onto branch `cursor/sanitized-chat-transcript-archive-2378` for #881 — this worker does not open that PR itself.

### Do not print

- Any value from a `stream.env` file, QA env file, or vault login
- JWT / Firebase ID token / invite token strings
- Account emails (redact as `[redacted-email]`)
- Screenshots that show an email address

---

## Current status

- [x] #902 open on `cursor/stream-video-preview-tests-f2e5` (preview GetStream group call).
- [x] #905 open on `cursor/stream-guest-join-2e7c` stacked on #902 (guest join); not merged; not deployed.
- [x] #908 open documenting Zoom-style guest defaults and public mint follow-ups.
- [x] Supabase `mint-stream-call-token` ACTIVE v1, `verify_jwt` false, signed-in mint only; guest actions absent.
- [x] Unsigned public mint returns 401 `Sign in is required.` (no auth and fake Bearer).
- [x] Stream secrets on Supabase function: **unknown** without a real Firebase ID token.
- [x] Local mint + CLI two-person POC succeeded earlier.
- [ ] Public signed-in mint returns token-shaped 200 (blocked until secrets proven set + real Firebase ID token).
- [ ] Guest actions live on a public mint (Firebase deploy from #905 **or** Supabase port).
- [ ] Independent verification of #905 CodeRabbit higher-risk notes.
- [ ] Persistent organizer guest-mode toggle (#908 gap).
- [ ] Dev-site publish of guest path; never production.
- [ ] Owner-ready recording + handoff.

---

## Next three actions

Do these in order. Each has its own verification.

### Action 1 — Prove or unblock public signed-in mint (secrets)

The function is live. It cannot mint until `STREAM_API_KEY` and `STREAM_API_SECRET` exist as Supabase function secrets (not in source).

- [ ] **1a.** Prefer owner or dashboard: if Stream secrets are already set in the Supabase Edge Function secrets UI for project `<resolve via user-Supabase list_projects; name belong-preview-mint>`, skip to 1c. Do not ask for CLI login codes.
- [ ] **1b.** If secrets are not set and no dashboard path is available, document the blocker and continue with Action 2 / Task E. Do not embed secrets in `deploy_edge_function` source. Do not run `supabase login`.
- [ ] **1c.** Re-run unsigned POST checks (expect still 401 `Sign in is required.`).
- [ ] **1d.** Only with a real Belong Firebase ID token obtained from an already-signed-in session (never print it): POST with `Authorization: Bearer <token>` and JSON `{"callId":"monthly"}`. Expect HTTP 200 with field names `apiKey`, `token`, `userId`, `callId`, `expiresAt`; three-part token; no `apiSecret` or `secret` fields. If 503 with `Video calling is not configured on this preview.`, secrets are missing — stop and report.
- [ ] **1e.** Sanitized docs note: statuses only. Mark secrets **yes** / **no** / still **unknown**.

### Action 2 — Choose guest mint path (do not merge PRs)

Guest publish cannot work against the current Supabase function until guest actions exist on a live mint.

- [ ] **2a.** Option A — Deploy Firebase `mintStreamCallToken` from #905 branch without enabling Secret Manager unless the owner asks; confirm the function URL stops 404’ing; keep production hosting untouched.
- [ ] **2b.** Option B — Port `createInvite` / `joinGuest` / `revokeInvite` / `releaseGuest` onto Supabase `mint-stream-call-token` with the same auth boundaries as #905; secrets still via env, never source.
- [ ] **2c.** Record which option the owner prefers. Do not merge #902 or #905.

### Action 3 — Independently verify #905 higher-risk notes before treating guest join as safe

- [ ] **3a.** Guest SDK identity may ignore server-issued credentials if the client uses `User.guest` instead of applying server-issued user credentials — confirm client wiring.
- [ ] **3b.** Failed or abandoned joins can consume guest seats — confirm claim/release/revoke and disconnect paths free seats.
- [ ] **3c.** Authorization-boundary concerns — knowing only the call name must not be enough; invite token required; guests cannot host-moderate.
- [ ] **3d.** Write pass/fail notes per item. Fix only easy low-risk items; leave larger findings documented.

---

## Major milestones

| ID | Milestone | Status | Done looks like |
| --- | --- | --- | --- |
| M1 | Local / CLI mint proven | Done | Local mint + CLI two-person POC on `poc-quick-test` |
| M2 | Public Supabase signed-in mint reachable | Partial | ACTIVE, unsigned 401; secrets unknown; no guest actions |
| M3 | Public signed-in mint issues tokens | Next | Valid Firebase ID token → 200 token-shaped body; unsigned still 401 |
| M4 | Guest actions on a live mint | Not started | createInvite/joinGuest/revokeInvite/releaseGuest on Firebase **or** Supabase public URL |
| M5 | #905 risk notes independently checked | Not started | Written pass/fail for identity, seat leak, auth boundary |
| M6 | Organizer guest-mode toggle | Not started | Preview/`dev` default on; production default off (#908) |
| M7 | Dev-site publish | Not started | `tool/deploy_dev_web.dart` → `https://dev-belongonthespectrum.web.app` only |
| M8 | Owner-ready test | Not started | Recording of assistant test sent before asking owner |

Scheduling of future meetings is [#903](https://github.com/neiljaywarner/refuge/issues/903) and is out of scope.

---

## File map (investigation / later code)

Do not change these unless a verified bug requires it. Prefer a cloud coding agent for application-code edits.

| Path | Role |
| --- | --- |
| `lib/src/features/group_call/data/stream_token_client.dart` | POST with Firebase Bearer; reject secret fields |
| `lib/src/features/group_call/data/stream_video_preview_config.dart` | `STREAM_VIDEO_PREVIEW` and `STREAM_TOKEN_ENDPOINT` dart-defines |
| `lib/src/features/group_call/presentation/group_call_lobby.dart` | Call name; #905 create/revoke guest link UI |
| `functions/` mint sources on #905 | Firebase `mintStreamCallToken` including guest actions |
| Supabase function slug `mint-stream-call-token` | Live signed-in mint only (today) |
| `the local-mint scratch directory (not in this repo) /mint-server.js` | Loopback mint for emulator |
| `the local verify script (not in this repo)` | Verification loop (unit + gray + black box) |
| `tool/deploy_dev_web.dart` | Dev hosting only |
| `tool/deploy_release.dart` | **Do not run** for this work |

---

### Task A: Reconfirm Supabase mint via MCP (no redeploy)

**Tools:** `user-Supabase` `list_edge_functions`, `get_edge_function`

- [ ] **A1.** `list_edge_functions` with the `project_id` from `list_projects` (name `belong-preview-mint`). Expect `mint-stream-call-token` status `ACTIVE`, `verify_jwt` false.
- [ ] **A2.** `get_edge_function` with `function_slug` `mint-stream-call-token`. Confirm source still has Firebase ID token verify and env-based Stream mint.
- [ ] **A3.** Search source for `createInvite`, `joinGuest`, `revokeInvite`, `releaseGuest`. Expect **absent**.
- [ ] **A4.** Do **not** call `deploy_edge_function` unless fixing an obvious safe issue the owner approved. Default: no redeploy.

### Task B: Unsigned HTTP regression

**URL:** resolve mint URL via MCP as in Verified facts, then:

- [ ] **B1.** POST with `Content-Type: application/json` and body `{"callId":"monthly"}` and no Authorization.

Resolve `$MINT_URL` via MCP (`get_project_url` for `belong-preview-mint` + `/functions/v1/mint-stream-call-token`). Do not commit the concrete URL.

```bash
curl -sS -o /tmp/mint-noauth.txt -w '%{http_code}\n' \
  -X POST "$MINT_URL" \
  -H 'Content-Type: application/json' \
  -d '{"callId":"monthly"}'
```

Expected: status `401`, body contains `Sign in is required.`

- [ ] **B2.** Same with `Authorization: Bearer fake.token.value`. Expected: status `401`, same error string.
- [ ] **B3.** Do not claim a signed-in 200 without a real Firebase ID token.

### Task C: Stream secrets evidence (no printing)

- [ ] **C1.** Confirm local env file existence only: `ls`/`stat` on the assistant copy under `the local gitignored Stream env directory (not in this repo) /` and the Mac Belong preview config directory. Expect mode `600`. Never read contents.
- [ ] **C2.** Without a valid Firebase ID token, mark Supabase function secrets as **unknown**.
- [ ] **C3.** If a signed-in mint returns 503 `Video calling is not configured on this preview.`, mark secrets **no**.
- [ ] **C4.** If signed-in mint returns 200 token-shaped with no secret fields, mark secrets **yes** (still do not print values).
- [ ] **C5.** Never put secrets into function source for `deploy_edge_function`. Prefer dashboard secrets UI or an owner-approved non-chat path.

### Task D: Local mint / verify loop (optional if emulator still in use)

**Files:** `the local-mint scratch directory (not in this repo) /mint-server.js`, `the local verify script (not in this repo)`

- [ ] **D1.** Run `the local verify script (not in this repo)` if present.
- [ ] **D2.** Expect unit layers pass; gray-box local mint 200 with no secret fields; black-box Supabase unsigned 401.
- [ ] **D3.** Do not tunnel the localhost mint to the public internet.

### Task E: Guest mint path decision

- [ ] **E1.** Summarize Option A (deploy Firebase mint from #905) vs Option B (port guest actions to Supabase) for the owner in one short note.
- [ ] **E2.** Constraints for both: no Secret Manager enable unless asked; no production deploy; no secrets in client; no merge of #902/#905 without explicit ask.
- [ ] **E3.** After a path is chosen, implement only that path’s smallest next deploy/port slice with its own verify (unsigned 401 still; guest join only after Action 3).

### Task F: #905 CodeRabbit higher-risk independent checks

**PR:** https://github.com/neiljaywarner/refuge/pull/905

- [ ] **F1.** Identity: confirm the Flutter guest join uses server-issued credentials (regular user with minted token) rather than discarding them for a pure `User.guest` path that ignores the mint.
- [ ] **F2.** Seat leak: simulate or unit-test failed join, cancel mid-flight, disconnect; expect seat freed via `releaseGuest` or equivalent.
- [ ] **F3.** Auth boundary: request join with call name only (no invite token) must fail; guests must not get host end/remove controls.
- [ ] **F4.** Also spot-check: revoke blocks new joins; expired invite; rate limit; empty/email/link display names rejected.
- [ ] **F5.** Do not merge #905. Document findings in a sanitized note.

### Task G: Organizer guest-mode toggle (#908)

- [ ] **G1.** Spec: persistent on/off for guest mode; default **on** for Belong preview/`dev`; default **off** for production.
- [ ] **G2.** Today’s Create/Revoke link is not this toggle — do not treat revoke as the durable setting.
- [ ] **G3.** Implement only after M4/M5 are green enough for a preview; keep production binary guest page compiled off (`STREAM_VIDEO_PREVIEW` not set by `deploy_release.dart`).

### Task H: Dev-site publish (never production)

- [ ] **H1.** Gate: M3 green and either a solid two-participant pass or a carefully reviewed guest pass (M4+M5).
- [ ] **H2.** Build with `STREAM_VIDEO_PREVIEW=true` and `STREAM_TOKEN_ENDPOINT` set to the **public** mint URL (not loopback).
- [ ] **H3.** Deploy with `tool/deploy_dev_web.dart` to `https://dev-belongonthespectrum.web.app`.
- [ ] **H4.** Confirm deploy log says the token endpoint was set without printing the endpoint value or any secret.
- [ ] **H5.** Never run `tool/deploy_release.dart` for this work. Never deploy to `belongonthespectrum.web.app`.

### Task I: Two distinct Stream user ids

- [ ] **I1.** When testing two participants, use two different Stream `user_id` values. Same id = one participant tile.
- [ ] **I2.** Prefer signed-in member + guest, or two signed-in members, once public mint works.
- [ ] **I3.** Do not start a second heavy emulator if RAM is constrained; prefer web preview or a second device.

### Task J: Docs hygiene and commit handoff

- [ ] **J1.** Keep this plan’s checkboxes updated after each verified slice.
- [ ] **J2.** Scan staged files for `@` emails, `-----BEGIN`, `apiSecret`, `STREAM_API_SECRET=`, vault IDs, and home-directory paths before any commit.
- [ ] **J3.** Suggested commit message when a CloudAgent commits this plan: `docs(video): add guest mint and dev publish plan`.
- [ ] **J4.** Preferred commit branch for the plan: `cursor/sanitized-chat-transcript-archive-2378` (issue #881). This worker does not open the PR.

### Task K: Remote Config for Stream API key (not secret)

- [ ] **K1.** Optional later (#908 item): publishable Stream API **key** via Firebase Remote Config like Giphy.
- [ ] **K2.** Remote Config must never hold `STREAM_API_SECRET`.

---

## Risks and gotchas

- **Key vs secret vs user token:** Key may be client/Remote Config; secret is server-only; user/invite tokens are short-lived server-minted JWTs — never commit any of them.
- **Same Stream `user_id` on two devices = one participant.** Always use distinct ids for two-person tests.
- **No secrets in repo or function source** when deploying via MCP `deploy_edge_function`.
- **Deploy to dev, not prod.** `tool/deploy_dev_web.dart` only; never `tool/deploy_release.dart` for this slice.
- **#905 CodeRabbit higher-risk (must independently verify):** guest SDK identity may ignore server-issued credentials; failed/abandoned joins can consume guest seats; authorization-boundary concerns.
- **Current Supabase mint cannot serve guest publish** until guest actions are added or Firebase mint from #905 is deployed.
- **Secrets status unknown** until a real Firebase ID token is used; do not invent a 200.
- **Firebase Secret Manager:** do not enable unless the owner asks.
- **PRs #902 and #905 stay open** unless the owner explicitly requests a merge.
- A 401 only proves the sign-in gate, not that Stream credentials loaded. A 503 with `Video calling is not configured on this preview.` means secrets are missing on the function.

---

## Self-review

- Spec coverage: Zoom-like guest join, organizer disallow toggle, preview default on / production default off, public mint, guest path options A/B, #905 risk notes, dev-only publish, secrets hygiene, two-user-id trap, and MCP-first verification are all tasked.
- Placeholder scan: no TBD/TODO; verify steps include exact URLs, expected statuses, and sanitized error strings.
- Consistency: function slug `mint-stream-call-token`, project ref `<resolve via user-Supabase list_projects; name belong-preview-mint>`, PRs #902/#905, issue #908, and deploy tools match the verified context.
- Next three actions are listed before the longer backlog so a cheaper model can start without reading every later task.

---

## Execution handoff

Plan complete and saved to:

``docs/superpowers/plans/2026-11-08-stream-guest-mint-and-dev-publish.md``

A later CloudAgent should commit this sanitized plan (preferably onto `cursor/sanitized-chat-transcript-archive-2378` for #881). Prefer subagent-driven-development or executing-plans for implementation slices after the owner picks guest mint path A or B.
