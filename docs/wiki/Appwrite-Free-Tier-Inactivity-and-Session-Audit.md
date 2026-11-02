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

If a limit is hit (bandwidth, storage, users, executions), Free freezes the affected capability until the next billing cycle or an upgrade. That is separate from the 7-day pause. Check the organization **Usage** tab. Current ceilings are on the [pricing page](https://appwrite.io/pricing). As of the [2026-01-08 changelog](https://appwrite.io/changelog/entry/2026-01-08), Free allows **2 functions per project**. This repo already has `dm-push`, `dm-mirror`, and `feedback-forward`, so a new scheduled function is not the retention path. A schedule would also sit idle while the project is paused.

## Why the session audit exists

Soft-launch operators need a small record of which clients opened Belong: web, Android, or iOS, which app build, and a coarse place. That is telemetry and a retention habit. It is not product analytics, not PostHog, and not a substitute for Crashlytics. Observability for crashes and journeys stays on the [observability page](Observability-Crashlytics-Analytics-and-Diagnostics).

The client writes one row on each cold start (after Flutter bindings, once per process). Hot restart may write another row. Retention below keeps that cheap. The write is fail-soft: a down or paused Appwrite project must not block startup. Logs go through `AppLogger` / Talker.

Turn the write off with `--dart-define=CLIENT_SESSION_AUDIT=false`. An empty `--dart-define=APPWRITE_ENDPOINT=` skips Appwrite entirely, same as the rest of the client.

## Tables (already created; do not recreate)

Database: `belong_community_db`.

### `client_session_audits`

Permissions already set: `create("any")`, `read("users")`. The guest client can insert. It cannot rely on update, so session end is best-effort and start-only is enough.

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

Code: `lib/src/core/appwrite/client_session_audit.dart`. It uses `AppwriteConfig` and `createAppwriteServices`. There is no second Appwrite client.

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

`city` is a country code or a timezone region label. If neither is safe, the field is omitted. Values that look like an email or an IPv4 address are dropped before the write.

## Retention

Keep raw `client_session_audits` rows until **2000 rows** or **8 weeks (56 days)**, whichever comes first.

Every week, or when the raw count passes **1600**, run the tool below. It:

1. Plans deletes for rows older than 8 weeks, then, if more than 2000 would remain, the oldest rows beyond 2000.
2. Groups those rows by UTC week and upserts `client_session_weekly_summaries`.
3. Deletes the raw rows only after that week's summary write succeeds.

Rows newer than 8 weeks are kept while the table is at or under 2000, even if the count is over 1600. Over 1600 is the signal to run the tool before the cap, not a lower cap. Two thousand short rows are trivial next to Free storage limits.

A crash after the summary write and before the deletes can add the same rows again on the next `--apply`. Check the week row, then rerun. The tool does not delete a week whose summary write failed.

### Runbook

```bash
export APPWRITE_API_KEY='server-key-with-row-read-and-write'
dart run tool/prune_client_session_audits.dart --example
dart run tool/prune_client_session_audits.dart
dart run tool/prune_client_session_audits.dart --apply
```

`--example` uses synthetic rows and does not call Appwrite. The default mode is a dry run. `--apply` writes, then deletes. The key stays in the environment. Do not commit it, paste it into an issue, or pass it as a flag.

Do this on a schedule a person owns (weekly), in addition to the weekly Console visit. The script is not deployed as a Function, for the Free function cap above and because a paused project would not run it.
