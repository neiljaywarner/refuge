# Appwrite Free tier: inactivity pause and session audit

> **Project**: `belongonthespectrum` (`6adae5c40013c409e109`), endpoint `https://nyc.cloud.appwrite.io/v1`, database `belong_community_db` (TablesDB).
> **Issue**: [#781](https://github.com/neiljaywarner/refuge/issues/781)
> **Related**: [Backend migration strategy](Backend-Migration-Strategy-Serverpod-Appwrite-Firebase) · [Observability](Observability-Crashlytics-Analytics-and-Diagnostics)

## Client heartbeats do not keep Free alive

Appwrite Free (changelog [2026-02-20](https://appwrite.io/changelog/entry/2026-02-20-1)) pauses a project that has **no Console development activity for 7 consecutive days**.

Staff clarified the rule in [this thread](https://appwrite.io/threads/1481574986136158322): **runtime API, SDK, and end-user traffic does not count.** The exact Console signals are unpublished and can change. Opening the Console and doing normal development work usually counts. A client session row does not.

The session audit exists so operators can see coarse client mix (platform, OS, app version, rough place) and so raw rows stay small. **It is not a pause-prevention mechanism.**

A year of soft-launch friendlies on Free needs one of these:

1. **Weekly Console keepalive.** At least once every 7 days, open this project in the Appwrite Console (or an equivalent Console / MCP session) and do real development activity. Do not rely on friendlies using the app.
2. **Pro** if Belong must stay up without someone visiting the Console. Paid plans are the path for continuous availability. The changelog says projects that need that should not stay on Free.

## What a pause does, and how to Restore

When Free pauses the project:

- Data is kept. Rows, files, and users are not deleted by the pause.
- Users cannot use the project (auth, database, storage, functions) until it is restored.
- Background work stops: backups, cron, and scheduled functions.

Restore:

1. Sign in to the [Appwrite Console](https://cloud.appwrite.io).
2. Open organization project `belongonthespectrum`.
3. Choose **Restore**. The project becomes active immediately. Data is still there.
4. Background jobs start again only after the restore.

If a limit is hit (bandwidth, storage, users, executions, or database writes), Free freezes the affected capability until the next billing cycle or an upgrade. That is separate from the 7-day pause. Check the organization **Usage** tab. Current ceilings are on the [pricing page](https://appwrite.io/pricing). Database writes on Free are **250,000 per month** ([reads and writes](https://appwrite.io/docs/advanced/billing/database-reads-and-writes)). As of the [2026-01-08 changelog](https://appwrite.io/changelog/entry/2026-01-08), Free allows **2 functions per project**. The live functions are `dm-push` and `dm-mirror`. `feedback-forward` was removed, and that slot is already taken. Do not add a third function. A schedule would also sit idle while the project is paused.

## Why the session audit exists

Soft-launch operators need a small record of which clients opened Belong: web, Android, or iOS, which app build, and a coarse place. That is telemetry and a retention habit. It is not product analytics, not PostHog, and not a substitute for Crashlytics. Observability for crashes and journeys stays on the [observability page](Observability-Crashlytics-Analytics-and-Diagnostics).

On each cold start (after Flutter bindings, once per process) the app posts one snapshot to the admission server when `CLIENT_SESSION_AUDIT_URL` is set. Hot restart may post another snapshot. The phone does not call TablesDB. The post is fail-soft: a down server or a paused Appwrite project must not block startup. Logs go through `AppLogger` / Talker.

Turn the post off with `--dart-define=CLIENT_SESSION_AUDIT=false`. Leave `--dart-define=CLIENT_SESSION_AUDIT_URL=` empty (the default) and the app writes nothing. An empty `--dart-define=APPWRITE_ENDPOINT=` still skips the rest of Appwrite. The admission URL is not an Appwrite client endpoint and it does not carry an API key.

## Tables (already created; do not recreate)

Database: `belong_community_db`.

### `client_session_audits`

Client create and client update must be **off**. `create("any")` lets anyone insert rows, skip the sanitizer, and spend the Free write quota. The weekly prune is not an admission control: it does not run on the write path, and rows can pile up between runs. The admission server below is the writer. API-key writes bypass ordinary client rate limits, so the server applies its own budget before it writes.

| Column | Required | Notes |
| --- | --- | --- |
| `city` | no | varchar 128. Country code, or an IANA timezone city when that is all we have. Never GPS. |
| `timezone` | yes | `DateTime.timeZoneName`, or a UTC offset when the name is blank. |
| `locale` | no | BCP 47 tag from `PlatformDispatcher`, such as `en-US`. |
| `osName` | yes | `web`, or `Platform.operatingSystem` on mobile and desktop. |
| `osVersion` | no | Short OS version. Not a device id. |
| `appVersion` | yes | `package_info_plus` version name, or `unknown`. |
| `appBuild` | no | Build number when the platform provides one. |
| `platform` | yes | `android`, `ios`, or `web`. Desktop Flutter sends `linux`, `macos`, or `windows`. |
| `sessionStartedAt` | yes | UTC datetime. |
| `sessionEndedAt` | no | UTC datetime when a later update is allowed. Often empty. |

Code: `lib/src/core/appwrite/client_session_audit.dart` posts the snapshot. `lib/src/core/appwrite/client_session_audit_admission.dart` checks fields and the write budget. `tool/client_session_audit_server.dart` writes with the API key. The phone has no second Appwrite client for this table and no API key.

### `client_session_weekly_summaries`

Permissions: `read("users")` only. Writes use a server API key, not the guest client.

| Column | Notes |
| --- | --- |
| `weekStart` | Monday 00:00 UTC. |
| `weekEnd` | The next Monday 00:00 UTC. |
| `sessionCount` | Sessions folded into this week by this summary. |
| `platformCountsJson` | JSON object of platform to count. |
| `osCountsJson` | JSON object of OS name to count. |
| `appVersionCountsJson` | JSON object of app version to count. |
| `cityCountsJson` | JSON object of coarse city label to count. Missing city is `unknown`. |
| `rawRowsSummarized` | How many raw rows those counts came from. |

Row id: `week-YYYY-MM-DD` (the Monday). Re-running merges into that row.

## Non-PII rules

Never store, log, or summarize:

- email address
- user id or Appwrite / Firebase uid
- display name
- IP address
- precise GPS or a location permission prompt
- device id, advertising id, or installation id

`city` is a country code or a timezone region label. If neither is safe, the field is omitted. The client drops values that look like an email or an IPv4 address. The admission server rejects the whole request when any field is an email, an IPv4 address, a compressed IPv6 address, or an expanded IPv6 address embedded in other text (such as `peer 2001:db8:0:0:0:0:0:1`). It also rejects unknown keys and values longer than the column max. These patterns are not a complete privacy filter. A free-text field can still contain a person's name. There is no name classifier.

A caller address is used only to build an in-memory rate-limit key. It is hashed with a process-local salt, it is not logged by this process, and it is not sent to Appwrite. A TLS proxy in front of the process can still write the address to its own access log. Turn that log off, or redact the client address, if the promise is that IP addresses are not kept.

## Admission server

This is not an Appwrite function. Both Free function slots are in use (`dm-push`, `dm-mirror`). Reusing either function is not safe: both execute as `any`, check a Firebase ID token, and hold a rows API key. `dm-push` also holds the FCM service account. A public session route in that process would share a credential that writes direct messages.

Run `tool/client_session_audit_server.dart` as its own process. It listens on `127.0.0.1:8787` unless you pass `--public` with another `--host`. One process is the budget. Extra copies each get their own memory counters.

Before each API-key write the server allows:

- **8 writes per caller per hour** (start, end, and a couple of retries)
- **120 writes per 10 minutes** for the whole process
- **800 writes per rolling 24 hours** for the whole process

800 a day is about 24,800 writes in a 31-day month, under 10% of the Free 250,000 write quota, and it leaves room for messages and the weekly prune. A restart clears the counters. Hostile rows are rejected before they spend a write.

At most **8** requests may be reading a body or waiting on Appwrite at once. Another arrival gets `503` immediately. It is not lined up behind a slow body. Opening the Appwrite connection is limited to **5 seconds**.

The rate-limit identity is the direct TCP address this process sees. `X-Forwarded-For` is ignored unless `SESSION_AUDIT_TRUSTED_PROXIES` lists that direct address (comma-separated). Leave the variable empty for a loopback or a client that connects straight to this process. Behind one TLS reverse proxy, every phone shares the proxy's 8 writes an hour until you set the variable to the proxy address this process actually sees. List only addresses this process accepts connections from. Do not trust forwarding headers from the public internet.

The proxy must append the client address of the TCP connection it accepted, or replace `X-Forwarded-For` with that address. Send a bare IP and no port. This process walks from the right and skips trusted hops, so the rightmost remaining address is the caller. A proxy that copies the incoming header unchanged lets the caller choose a new identity on every request. `::ffff:10.0.0.2` is the same address as `10.0.0.2`. The default bind stays `127.0.0.1`. `--public` is still required for any other host.

Browser calls must come from a Belong web origin (`belongonthespectrum.web.app`, `dev-belongonthespectrum.web.app`, `belongonthespectrum.com`, and the matching firebaseapp host) or from loopback. Native apps send no `Origin` and are limited by the caller key and the project caps. Add more origins with `SESSION_AUDIT_ALLOWED_ORIGINS` (comma-separated). Do not put the API key in that list or in the app.

```bash
# .env.session-audit is gitignored by `.env.*`. One line: APPWRITE_API_KEY=...
# Mode 600. Then:
set -a
. ./.env.session-audit
set +a
dart run tool/client_session_audit_server.dart
```

This server only creates a row (`POST`) and patches `sessionEndedAt` (`PATCH`). Those calls need the project scope `rows.write`. They do not read rows, so `rows.read` is not required here. Appwrite API-key scopes are project-wide. The console does not limit `rows.write` to `belong_community_db`. A key with that scope can write every table in the project. Create a separate key, add no extra scopes, and do not reuse the `dm-push` or `dm-mirror` key. The weekly prune lists and deletes rows, so that tool's key still needs `rows.read` and `rows.write`. Do not commit the file, paste the key into an issue, or pass it as a flag.

Point a build at the server only after it is reachable over HTTPS from the phones that should report:

```bash
flutter build web --dart-define=CLIENT_SESSION_AUDIT_URL=https://audit.example/session
```

`http://` is accepted only for `localhost` and `127.0.0.1`.

### Lock the table (required ops step)

This repository cannot change the live table. Shipping the server does not remove `create("any")`. Until the grants below are gone, a direct REST client can still create and update rows.

1. Sign in to the [Appwrite Console](https://cloud.appwrite.io).
2. Open organization project `belongonthespectrum` (`6adae5c40013c409e109`).
3. Open **Databases** → `belong_community_db` → table `client_session_audits` → **Settings** → **Permissions**.
4. Remove every client create and update permission. That includes `create("any")`, `create("guests")`, `create("users")`, `update("any")`, `update("guests")`, and `update("users")`.
5. Open several existing rows and clear any per-row update permission. Rows created while `create("any")` was on can carry their own update grant. An empty permission list on new writes does not rewrite those older rows.
6. `read("users")` lets every signed-in Appwrite user read the table. That is wider than operator-only access. Console admins can read without it, and the phone uses Firebase, not an Appwrite user. Remove `read("users")` unless a specific Appwrite user must read rows from the client SDK. The admission server does not need it. The API key bypasses table permissions.
7. Confirm the Flutter app and this repo contain no API key.

Prove create and update separately. One request each. Do not loop them. A denied POST does not prove update is closed.

```bash
curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST 'https://nyc.cloud.appwrite.io/v1/tablesdb/belong_community_db/tables/client_session_audits/rows' \
  -H 'Content-Type: application/json' \
  -H 'X-Appwrite-Project: 6adae5c40013c409e109' \
  -d '{"rowId":"unique()","data":{"timezone":"UTC","osName":"web","appVersion":"x","platform":"web","sessionStartedAt":"2026-11-08T00:00:00.000Z"}}'

curl -s -o /dev/null -w '%{http_code}\n' \
  -X PATCH 'https://nyc.cloud.appwrite.io/v1/tablesdb/belong_community_db/tables/client_session_audits/rows/probe' \
  -H 'Content-Type: application/json' \
  -H 'X-Appwrite-Project: 6adae5c40013c409e109' \
  -d '{"data":{"sessionEndedAt":"2026-11-08T00:00:00.000Z"}}'
```

Expect `401` or `403` for both. A `201` or `200` means that call is still public. A `404` on the PATCH does not prove update is closed: a permitted caller can be told that `probe` is missing. If you see `404`, go back to the table permissions and the existing rows.

The server stores new rows with an empty permission list and `rowId` `unique()`. Session end is a later PATCH of `sessionEndedAt` only, and only when the client repeats the end token the server returned. That token is an HMAC of the row id under the API key. The compare is constant-time. After a key rotation, older sessions cannot set an end time. Start-only is still enough.

## Retention

Keep raw `client_session_audits` rows until **2000 rows** or **8 weeks (56 days)**, whichever comes first. The weekly prune is not admission control and it is not a cap on new writes.

Every week, or when the raw count passes **1600**, run the tool below. It:

1. Plans deletes for rows older than 8 weeks, then, if more than 2000 would remain, the oldest rows beyond 2000.
2. Groups those rows by UTC week and upserts `client_session_weekly_summaries`.
3. Deletes the raw rows only after that week's summary write succeeds.

Rows newer than 8 weeks are kept while the table is at or under 2000, even if the count is over 1600. Over 1600 is the signal to run the tool before the cap, not a lower cap. Two thousand short rows are trivial next to Free storage limits.

A crash after the summary write and before the deletes can add the same rows again on the next `--apply`. Check the week row, then rerun. The tool does not delete a week whose summary write failed.

### Runbook

```bash
# Same .env.session-audit file as the admission server. Mode 600.
set -a
. ./.env.session-audit
set +a
dart run tool/prune_client_session_audits.dart --example
dart run tool/prune_client_session_audits.dart
dart run tool/prune_client_session_audits.dart --apply
```

`--example` uses synthetic rows and does not call Appwrite. The default mode is a dry run. `--apply` writes, then deletes. Load the key from the file above so it is not typed into the shell. Do not commit it, paste it into an issue, or pass it as a flag.

Do this on a schedule a person owns (weekly), in addition to the weekly Console visit. The script is not deployed as a Function, for the Free function cap above and because a paused project would not run it.
