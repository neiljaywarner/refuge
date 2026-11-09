# Leave-alone free backends

> **Decision**: 8 November 2026, [#906](https://github.com/neiljaywarner/refuge/issues/906)
> **Live store**: [ADR-0011](https://github.com/neiljaywarner/refuge/blob/main/docs/adr/0011-one-database-plus-backup-not-dual-write.md)
> **Restore comparison**: [Reflection redundancy and backup](Reflection-Redundancy-and-Backup.md)

When Belong needs a free backend that can sit for days without someone opening a vendor console, prefer **Supabase Free** if that project will see enough activity to avoid a pause. Its pause rule counts Dashboard visits and ordinary app, API, and database requests. A quiet project can still pause. Appwrite Free counts Console development activity only.

This page does not move the live app. Firestore stays the member store. Firebase Auth and Firebase Hosting stay the session and the site. No Flutter code, function, or schema moves to Supabase here.

## What stays where

| Job | Where it lives |
| :--- | :--- |
| Member feed, profiles, votes, feedback, in-app direct messages | Cloud Firestore, project `belongonthespectrum` |
| Sign-in and the public site | Firebase Auth and Firebase Hosting |
| Live functions `dm-push` and `dm-mirror`, plus the spare/mirror path | Appwrite project `belongonthespectrum` (`6adae5c40013c409e109`, region nyc) |
| A new spare or preview that should not depend on an Appwrite Console visit | Supabase Free, when Dashboard or database activity is enough to avoid the 7-day pause. The existing fallback / preview project is `belong-preview-mint` |

Appwrite is still in use. An Appwrite Free pause stops those extras. It does not, by itself, take Firebase Hosting, Firebase Auth, or the Firestore feed offline. Members can still sign in, read rooms, post, reply, and send direct messages inside Belong. Closed-app phone alerts (`dm-push`), the direct-message mirror (`dm-mirror`), the spare/mirror copy, and any session-audit writes on that Appwrite project stop until someone restores it.

Restoring Appwrite does not replay failed `dm-mirror` requests. A message sent during the pause can remain missing from the Appwrite table `direct_messages`. The backup CLI writes that spare copy to `backup_direct_messages` instead ([Firestore to Appwrite backup](Firestore-to-Appwrite-Backup.md)).

A pause of the Supabase preview project does not take the Firebase site offline. Belong does not read the live feed from Supabase.

Session-audit writes are open work in [#781](https://github.com/neiljaywarner/refuge/issues/781), [#786](https://github.com/neiljaywarner/refuge/pull/786), and [#873](https://github.com/neiljaywarner/refuge/pull/873). This page does not choose a write path and does not add a client write.

## Appwrite Free

Official rule, [20 February 2026 changelog](https://appwrite.io/changelog/entry/2026-02-20-1): a Free project with no development activity for 7 consecutive days is paused. The same entry says Free projects stay active when they show development activity in the Console. Data is not deleted. While paused, users cannot reach the project, and background processes do not run. Restore is from the Appwrite Console, and the project becomes active again immediately.

A later rule, [29 June 2026 changelog](https://appwrite.io/changelog/entry/2026-06-29): a free project that stays paused for 90 days is deleted, including its resources. Affected projects get email alerts first. To keep a paused project, resume it from the Appwrite Console, or upgrade the organization to a paid plan, before that window ends. Pro and Enterprise projects are not paused or deleted for inactivity.

Runtime traffic does not count. On the [staff thread cited from #789](https://appwrite.io/threads/1481574986136158322), Appwrite said API calls, SDK usage, and end-user visits do not count, and that they do not publish the exact detection logic. Do not document MCP or CLI as a Console keepalive.

Checked 8 November 2026:

| Fact | Value |
| :--- | :--- |
| Organization | Personal Projects |
| Billing plan | `tier-0` (Free) |
| Project | `belongonthespectrum` (`6adae5c40013c409e109`), region nyc |
| Project status | active. No restore was needed that day. |
| `consoleAccessedAt` | 2026-11-08T15:00:53.867+00:00, which is 9:00 AM America/Chicago |
| `mcpAccessedAt` | 2026-11-02T00:51:12.578+00:00 on the check recorded in #906. A project read the same evening returned 2026-11-08T21:24:39.693+00:00. `consoleAccessedAt` stayed at the time above. |

## Supabase Free

Official rule: [Free project pausing](https://supabase.com/docs/guides/platform/free-project-pausing). Supabase pauses a Free project that has too little activity over 7 days. Projects with too few database queries in that window are the clearest candidates. Typically a few user requests to the database each day over the previous week is enough to keep it from pausing. After the warning email, either a Dashboard visit or enough API calls from the connected app can prevent the pause.

That is friendlier for leave-alone than Appwrite, because requests from the connected app, including database requests, can keep the project awake. It is not a promise that Supabase never pauses. [#792](https://github.com/neiljaywarner/refuge/issues/792) asked for that distinction. The pausing guide does not say a Free project stays up with no activity. The [pricing page](https://supabase.com/pricing) short line, "paused after 1 week of inactivity," is the headline. The pausing guide is the page that says what counts.

Supabase sends a warning email roughly one week before the pause, and a confirmation email once the project is paused. Restore is from the Dashboard: open the organization, open the paused project, choose **Resume project**. A paused project can be restored for up to a year. Paid-plan projects are not paused for inactivity.

A Free plan grants two active projects. The limit applies across organizations where the same person is an Owner or an Administrator. Paused projects do not count. Docs: [billing on Supabase](https://supabase.com/docs/guides/platform/billing-on-supabase).

Checked 8 November 2026, Supabase organization (Free plan):

| Project | Ref | Region | Status | Created |
| :--- | :--- | :--- | :--- | :--- |
| `belong-preview-mint` | `kcgsbtaamipkfmiluczb` | us-east-1 | `ACTIVE_HEALTHY` | 2026-11-08T19:39:09.758787Z, which is 1:39 PM America/Chicago |
| `eb_demo` | `xvqerlmcfhglhehzioqs` | us-east-1 | `INACTIVE` (paused) | 2022-10-11T22:05:50.259351Z |

`belong-preview-mint` is the existing fallback / preview project. `eb_demo` is paused and left alone. Do not resume it.

Free is also not the restore product. Daily backups start on Pro. Free projects are told to dump the database themselves. That comparison stays on [Reflection redundancy and backup](Reflection-Redundancy-and-Backup.md). Docs: [database backups](https://supabase.com/docs/guides/platform/backups).

## Why the pause rules pick different hosts

Appwrite Free requires a person in the Console. Supabase Free does not. Dashboard visits or app, API, and database requests count, as the pausing guide above says. A low-traffic spare can still pause, because Supabase pauses Free projects with too little activity over 7 days. Typically a few database requests a day is what keeps one from pausing. If the spare must stay up without that activity, use a plan that is not paused for inactivity. Supabase sends a warning email roughly one week before a pause. Resume the project from the Dashboard. A paused project can be restored for up to a year.

Prefer Supabase Free for a spare or preview that can live on that activity rule. Keep the live member path on Firebase. Keep the functions and the current spare copy on the Appwrite project that already runs them, and restore that project from the Console when it pauses. Do not treat a missing keepalive workflow, an MCP call, or a CLI call as a substitute for that Console visit.

## Related issues, not closed here

[#781](https://github.com/neiljaywarner/refuge/issues/781), [#786](https://github.com/neiljaywarner/refuge/pull/786), [#789](https://github.com/neiljaywarner/refuge/issues/789), [#792](https://github.com/neiljaywarner/refuge/issues/792), [#873](https://github.com/neiljaywarner/refuge/pull/873).

## See also

- [Ops / Deploy readiness](Ops-Deploy-Readiness.md)
- [Firestore to Appwrite backup](Firestore-to-Appwrite-Backup.md)
- [Bus protocol](Bus-Protocol.md)
- [Backend and database architecture](Backend-and-Database-Architecture.md)
