# Stream Video Preview Verification Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> This plan is sized for a less expensive model: one checkbox is one verifiable slice. Do not improvise extra scope. Fail closed. Never print secrets.

**Goal:** Finish verifying the Belong preview group video call so a recorded first participant, a second participant, and a public shareable path exist on the Belong dev site — not production — before asking the project owner to test.

**Architecture:** The Flutter DEV app never mints Stream tokens itself. A server holds `STREAM_API_KEY` and `STREAM_API_SECRET` and returns `{apiKey, token, userId, callId, expiresAt}` after checking a Firebase ID token. The local mint server on the assistant computer is for the emulator (`adb reverse` of port 5001). The public mint path is the already-deployed Supabase edge function `mint-stream-call-token`. Guest join lives in stacked pull request 905 and is not in the APK that is installed on the emulator today.

**Tech Stack:** Flutter Belong DEV flavor, Firebase Auth (same Belong project), GetStream Video, local Node mint server, Supabase edge function, Android emulator, ADB screenshots and `screenrecord`.

## Global Constraints

- Never commit passwords, API secrets, tokens, vault identifiers, email addresses, home-directory paths, billing-account IDs, or Stream dashboard organization or app IDs.
- Never print `STREAM_API_KEY`, `STREAM_API_SECRET`, JWT strings, Firebase ID tokens, or account emails. Reporting HTTP status codes and JSON field *names* is fine.
- `STREAM_API_SECRET` must not be a dart-define. It stays in a gitignored local file or a server-side function.
- Do not deploy to production (`belongonthespectrum.web.app` or `tool/deploy_release.dart`).
- Do not merge pull requests 786, 873, 881, 902, or 905 unless the project owner asks.
- Do not ask the project owner to test until screenshot or video review shows the flow works. Send them a recording of a real test first.
- Prefer the owner's Mac for machine-local work, but the live emulator join already runs on the assistant computer. Do not start a second 1536 MiB emulator; an earlier second AVD was killed by RAM.
- Move on when stuck instead of looping. Record the blocker and take the next unblocked slice.
- After each meaningful verified slice, push an atomic sanitized docs commit (checkbox updates or a short progress note). No application-code drive-bys in those commits.
- Treat some items as WIP: pull requests 902 and 905 are open on purpose.

---

## How a cheaper model should work

1. Read **Current status** and **Next three actions** before anything else.
2. Do only the next unchecked slice. Verify it. Write what you observed (no secrets).
3. If verification fails, stop and report. Do not weaken a security check to make a test pass.
4. If a slice needs the project owner (for example, pasting a Supabase access token or adding function secrets in the dashboard), do every other unblocked slice first, then say exactly what is needed.
5. Re-run `/workspace/getstream-preview/verify/run.sh` after mint-server or public-function changes. Expect `summary pass=8 fail=0` today; after secrets are set, the Supabase black-box step may change from "reachable 401" to a richer signed-in check — do not treat a new 200 as a failure if the body is token-shaped and has no secret fields.

### Do not print

- Any value from a `stream.env` file, a QA env file, or a vault login
- JWT or Firebase ID token strings
- Account emails that appear on screen (redact them in notes as `[redacted-email]`)
- Screenshots that show an email address (the first-visit welcome screen did; do not commit it)

### Safe artifacts

Assistant-computer paths (not a user home directory):

- Local mint: `/workspace/getstream-preview/local-mint/mint-server.js` on `127.0.0.1:5001` only
- Verification loop: `/workspace/getstream-preview/verify/run.sh`
- Emulator join shots: `/workspace/getstream-preview/emulator-join/`
- Installed package: `com.belongonthespectrum.refuge.dev`
- Emulator: `emulator-5554` (AVD `belong_call_1`)
- ADB: `/home/box/Android/Sdk/platform-tools/adb`

---

## Current status (as of 3:41 PM CT, 8 Nov 2026)

Check these off so later workers do not redo them.

- [x] Preview GetStream work exists as open [PR #902](https://github.com/neiljaywarner/refuge/pull/902) (`cursor/stream-video-preview-tests-f2e5`). CI analyze-and-test passed. CodeRabbit reviewed it.
- [x] Guest-join work exists as stacked open [PR #905](https://github.com/neiljaywarner/refuge/pull/905) (`cursor/stream-guest-join-2e7c` on top of #902). CI passed. CodeRabbit reviewed it (moderate merge risk). It is not merged and not in the installed APK.
- [x] Local mint server loads Stream credentials from a gitignored env file (including an optional `export ` prefix). It listens only on loopback port 5001.
- [x] Verification loop passed 8 of 8: two Node unit layers (validation and token shape), gray-box HTTP against local mint (real token minted, no secret fields), black-box Firebase function still 404, black-box Supabase function reachable with `401` and message `Sign in is required`.
- [x] Supabase edge function `mint-stream-call-token` is deployed with `verify_jwt` false so clients can send a Firebase ID token. Unsigned calls correctly return 401.
- [x] Stream secrets are **not** yet stored as Supabase function secrets. The connector can deploy code but has no secrets tool. The Supabase CLI on the Mac needs a login or access token before `secrets set --env-file`.
- [x] Firebase HTTPS function `mintStreamCallToken` is still undeployed (HTTP 404). The Mac Firebase CLI is logged in and lists no functions in the Belong project. Secret Manager is not enabled; do not enable it unless asked.
- [x] Emulator-5554 has `adb reverse tcp:5001 tcp:5001`. The installed APK is the #902 localhost debug build, not #905.
- [x] The DEV app requires a real Firebase email/password sign-in (example-account buttons were removed earlier). There is no anonymous bypass.
- [x] The app was signed in with the Mac QA environment variables named `BELONG_AUTH_EMAIL` and `BELONG_AUTH_PASSWORD` (values never written to chat or git). Vault browser fill cannot target native Android fields.
- [x] First-visit profile was skipped. Experimental Preview Features was turned on in Member Profile so the home banner appeared.
- [x] Lobby default call name is `monthly`. After Join call, the in-call UI showed title `Call monthly`, status `Connected`, participant `Fellowship Member`, microphone off, camera off, and host controls (first person in the room). Session was left connected around 3:37 PM CT.
- [x] Safe screenshots saved: home banner, lobby, connected in-call. A welcome screenshot showed an email and must not be committed.

---

## Next three actions

Do these in order. Each has its own verification.

### Action 1 — Make public mint able to issue tokens

The function is already live. It still cannot mint until `STREAM_API_KEY` and `STREAM_API_SECRET` exist as Supabase function secrets.

- [ ] **1a.** If the project owner has added those two names in the Supabase Edge Function secrets UI, skip to 1c.
- [ ] **1b.** If a Supabase access token is provided, set secrets from the existing gitignored Stream env file with `supabase secrets set --project-ref <preview-ref> --env-file <stripped-env>` after removing any `export ` prefix. Do not print the file. Delete any temporary stripped copy afterward.
- [ ] **1c.** Verify unsigned POST still returns 401 `Sign in is required` (no regression).
- [ ] **1d.** Verify a signed-in mint (Firebase ID token from the already-signed-in emulator session, or another test ID token for the Belong project) returns HTTP 200 with field names `apiKey`, `token`, `userId`, `callId`, `expiresAt`, a three-part token, and no `apiSecret` or `secret` fields. Do not print the token or apiKey value.
- [ ] **1e.** Atomic sanitized docs commit: mark Action 1 done and note only HTTP statuses.

If 1b is blocked on owner login, leave Action 1 open and continue with Action 2.

### Action 2 — Re-verify the live emulator session

- [ ] **2a.** Confirm emulator-5554 is still up, `adb reverse --list` still includes `tcp:5001`, and the mint server is still on `127.0.0.1:5001`.
- [ ] **2b.** Screenshot the in-call UI. Expected: still `Call monthly` and `Connected`, or a clear leave/error state if the session dropped.
- [ ] **2c.** If still connected, optionally tap Microphone once and screenshot (then leave it muted again unless testing audio on purpose). Do not tap End call for everyone.
- [ ] **2d.** Save new shots under `/workspace/getstream-preview/emulator-join/` with names that do not include emails. Do not commit images unless they contain no email or other private data.

### Action 3 — Second-participant rehearsal (local or public)

- [ ] **3a.** Decide the smallest second client: same Stream room name `monthly`. Prefer a second signed-in client if a public mint exists; otherwise document why Chrome on the assistant computer cannot reach loopback app ports (earlier `ERR_CONNECTION_REFUSED` from that browser to other localhost ports) and do not pretend a second local browser join worked.
- [ ] **3b.** Do not install a second heavy emulator.
- [ ] **3c.** If public mint works, rebuild or run only what is needed for a second signed-in preview client. Record both sides with screenshots about every half second when practical, plus a `screenrecord`.
- [ ] **3d.** Analyze the screenshots before asking the project owner to join.

---

## Major milestones

| ID | Milestone | Status | Done looks like |
| --- | --- | --- | --- |
| M1 | Local mint proven | Done | Verification loop 8/8; dummy localhost identity receives a token-shaped body with no secret fields |
| M2 | First live emulator join | Done | In-call UI `Connected` for room `monthly`, mic and camera off |
| M3 | Public signed-in mint | Next | Supabase function returns a token-shaped 200 for a real Firebase ID token; unsigned still 401 |
| M4 | Two participants in `monthly` | Not started | Two distinct tiles or names, both showing connected; recording reviewed |
| M5 | Guest-join preview (#905) | Not started | #905 APK or web build installed; CodeRabbit higher-risk notes independently checked; a guest can type a name and join without creating an account |
| M6 | Dev-site publish | Not started | Deployed with `tool/deploy_dev_web.dart` to the Belong dev hosting site only, after M4 or a solid M3+M5; never production |
| M7 | Owner-ready test | Not started | Assistant already in the room from mock or off camera/mic; shareable link ready; owner is sent a video of the assistant's test and only then asked to try, possibly later with a partner |

Scheduling of future meetings is [issue #903](https://github.com/neiljaywarner/refuge/issues/903) and is out of scope.

---

## Mini milestones

### Task A: Keep the mint verification loop honest

**Files:** `/workspace/getstream-preview/verify/run.sh`, `unit_validation.test.js`, `unit_token_shape.test.js`, `lib.js`

- [ ] **A1.** Run `/workspace/getstream-preview/verify/run.sh`.
- [ ] **A2.** Confirm both unit layers pass and gray-box local mint is still 200 with no secret fields.
- [ ] **A3.** If anything fails, inspect without printing tokens, fix the smallest safe cause, and rerun. Do not skip the secret-field assertion.

### Task B: Public Supabase mint secrets

See Action 1. Public function name: `mint-stream-call-token`. It verifies Firebase ID tokens against Google JWKS for the Belong project (`aud` and `iss` must match that project). It must not use the localhost unsigned-JWT shortcut.

Black-box URL shape:

`https://<preview-supabase-ref>.supabase.co/functions/v1/mint-stream-call-token`

The preview project and function are already created. Unsigned POST should remain 401 until a valid Firebase bearer token is sent.

- [ ] **B1.** Confirm the function still exists and `verify_jwt` is false.
- [ ] **B2.** Set Stream secrets without printing them.
- [ ] **B3.** Repeat unsigned 401 check.
- [ ] **B4.** Repeat signed-in 200 token-shape check with no secret fields.
- [ ] **B5.** Sanitized atomic commit noting only statuses.

### Task C: Stay on the connected call

See Action 2. Leave the room up so a second participant can join `monthly` later. Do not press End call for everyone.

### Task D: Second participant

See Action 3.

Constraints:

- One healthy emulator only.
- The assistant-computer browser previously could not open other localhost app ports even when `curl` on the same machine succeeded. Recheck once; if it still fails, use another path instead of fighting the browser jail.
- A public mint plus a web preview, or the #905 guest path, is the intended way for someone on another device to join.

### Task E: Guest-join build (#905)

**PR:** [https://github.com/neiljaywarner/refuge/pull/905](https://github.com/neiljaywarner/refuge/pull/905)

- [ ] **E1.** Independently verify the higher-risk CodeRabbit notes before treating guest join as safe for tonight:
  - Server-issued guest credentials may be ignored if the client uses `User.guest` instead of `User.regular`.
  - Failed or abandoned joins may consume guest seats.
  - Invited users may cross authorization boundaries.
  - Check revoke/claim, expired-before-rate-limit, disconnect-before-freeing-a-seat, zero-width names, and in-flight cancel.
- [ ] **E2.** Do not merge #905.
- [ ] **E3.** Rebuild an APK or web preview from that branch only after E1, still without putting `STREAM_API_SECRET` in dart-defines.
- [ ] **E4.** Guest flow expected: type a name, about 10 guests max, about 24-hour transient link. Creating the invite still needs a signed-in member.
- [ ] **E5.** File or fix only easy, low-risk items. Larger review findings stay documented.

### Task F: Dev-site deploy (not production)

- [ ] **F1.** Deploy only when M3 is green and either M4 or a carefully reviewed M5 local pass is green.
- [ ] **F2.** Use `tool/deploy_dev_web.dart` toward `https://dev-belongonthespectrum.web.app`.
- [ ] **F3.** Build with `STREAM_VIDEO_PREVIEW=true` and `STREAM_TOKEN_ENDPOINT` set to the **public** mint URL, not loopback.
- [ ] **F4.** Confirm the deploy log says the token endpoint was set. The log must not print the endpoint value or any secret.
- [ ] **F5.** Never run `tool/deploy_release.dart` for this work.

### Task G: Recordings, tests, and owner handoff

- [ ] **G1.** Capture ADB screenshots about every 0.5s when practical, plus `screenrecord`, and review them before asking the owner.
- [ ] **G2.** Run Patrol / Maestro / widget tests already in the branch when cheap. File GitHub issues for findings; fix only easy low-risk items.
- [ ] **G3.** Firebase App Distribution comes after a local/`flutter run` pass. Do not put the Stream secret in a dart-define for a distributed binary.
- [ ] **G4.** Send the owner a video of the assistant's real test. Only then ask them to try, first alone, later with a partner if that goes well.

### Task H: Docs hygiene after each slice

- [ ] **H1.** Update checkboxes in this plan.
- [ ] **H2.** Append a short sanitized progress note under `docs/chat-transcripts/` (no emails, secrets, vault IDs, home paths, or token strings).
- [ ] **H3.** Optionally append estimate-only rows to the existing token-analysis files. Do not invent billed usage. Do not add a `raw/` folder or an archive-building script.
- [ ] **H4.** One atomic commit per meaningful verified slice. Suggested messages:
  - `docs(video): mark public mint verified`
  - `docs(video): note second participant recording`
  - `docs: add sanitized preview progress notes`
- [ ] **H5.** Before every commit, scan staged files for `@` email addresses, `-----BEGIN`, `apiSecret`, `STREAM_API_SECRET=`, vault IDs, and home-directory paths.

---

## File map for later code work

Do not change these unless a verified bug requires it. Investigation belongs in a cloud coding agent, not a local clone.

| Path | Role |
| --- | --- |
| `lib/src/features/group_call/data/stream_token_client.dart` | POST with `Authorization: Bearer <Firebase ID token>`; parse body; reject secret fields |
| `lib/src/features/group_call/data/stream_video_preview_config.dart` | `STREAM_VIDEO_PREVIEW` and `STREAM_TOKEN_ENDPOINT` dart-defines |
| `lib/src/features/group_call/presentation/group_call_preview_banner.dart` | Home `Join call` banner |
| `lib/src/features/group_call/presentation/group_call_lobby.dart` | Call name field, default `monthly` |
| `lib/src/features/group_call/presentation/stream_group_call_page.dart` | In-call controls |
| `lib/src/core/config/preview_mode_provider.dart` | Remote Config plus Member Profile override |
| `docs/wiki/Stream-Video-Preview.md` | Join-button gates and error copy |
| `docs/wiki/Preview-Mode-and-Feature-Flags.md` | Experimental Preview Features switch |

Join button is shown only when all three are true: compile-time `STREAM_VIDEO_PREVIEW=true`, preview features enabled, and Firebase signed in.

---

## Known traps

- A 401 from local mint without a bearer token only proves the sign-in check, not that Stream credentials loaded. A 503 `"Video calling is not configured on this preview."` means the secret file was not parsed (watch for an `export ` prefix).
- Vault secure fill works in a browser, not in the native Android app.
- The first-visit welcome screen can display the signed-in email. Do not commit that screenshot.
- Skipping the display-name screen makes the in-call label `Fellowship Member`.
- Closing the profile sheet after toggling Experimental Preview Features is enough; do not Save Profile if required church affiliation would block you.
- Do not tunnel the localhost mint server to the public internet.
- Do not enable unused Secret Manager or answer `y` to a gcloud API-enable prompt unless the owner asks.

---

## Self-review

- Spec coverage: first live join, public mint, second participant, guest join, dev deploy, owner handoff, verification loop, and sanitized atomic commits are all tasked.
- No production deploy, no secret dart-defines, and no merge of the listed pull requests.
- Next three actions are listed before the longer backlog so a cheaper model can start without reading every later task.
