# Reflection redundancy and backup

> **Decision**: [ADR-0011](https://github.com/neiljaywarner/refuge/blob/main/docs/adr/0011-one-database-plus-backup-not-dual-write.md)
> **Reviewed change**: [PR #546](https://github.com/neiljaywarner/refuge/pull/546) for [issue #212](https://github.com/neiljaywarner/refuge/issues/212)
> **Live site**: [belongonthespectrum.web.app](https://belongonthespectrum.web.app)

This page answers a practical question: after dropping the $5 Serverpod database, should reflections live in two clouds at once, or in one cloud with a backup feature made for restore?

## What "redundancy" was trying to do

The cutover writes each new reflection to three places:

1. The phone or browser's memory, so the screen still shows the note if the network fails.
2. Appwrite table `reflection_posts` in project `belongonthespectrum`.
3. A Cloud Firestore collection, `reflections` or `reflections_dev`.

Sign-in stays on Firebase Auth. The hope was that if Appwrite is down, Firestore still has the note, and the other way around.

## Does that actually work?

The part that works is leaving Serverpod. A normal build does not open `refuge4serverpod.api.serverpod.space`.

The two-cloud copy does not work as a safety net yet.

* The automated tests use a fake Appwrite. They never saved a row in the real project.
* The Appwrite project has **0 users**. A Firebase login is not an Appwrite login, so the app cannot prove who is writing.
* To make those writes succeed anyway, the tables were first opened to guests. The project id ships inside the app, so a guest write is a public write. Those tables are now **turned off**. Guest create and update are gone. The client call fails, the error is logged, and the note stays on the device until the app restarts.
* The Firestore rules that would accept `reflections` are in the pull request and are not deployed. The live rules do not mention that collection, so the second copy fails too.
* If one cloud accepts a write and the other does not, nothing comes back later to fill the gap.
* The reader mixes the three copies. When two copies share a time, it keeps the one with more reactions. That can hide a correction.
* Notes that already exist in Serverpod were not moved.
* The home screen on `main` does not currently compile against the widgets it calls, so a release build is not running this repository yet.

So the pull request is a real way to stop calling Serverpod. It is not yet a second durable copy of the community's notes.

## Why two live databases are a weak backup

A backup is an older copy that today's mistake does not overwrite.

Writing the same tap to Appwrite and Firestore stores today's mistake twice. If a bug, a double tap, or a stranger with the project id changes a note, both databases change. You cannot ask either one for the note as it looked yesterday.

Two live databases do help with a different problem: one vendor being down while people are reading. That is availability. It needs a single writer, a copy job, and a planned way to catch up. The current code is two writers and a best-effort merge.

## Pros and cons of the approaches

| Approach | What it is good at | What it costs you |
| :--- | :--- | :--- |
| **Device list only** | The screen works offline and in tests. | Restarting the app, or opening it on another phone, loses the notes. |
| **Serverpod, the current $5 database** | One Postgres database, relational notes, already wired. | $5 every month, and a server we want to stop running. |
| **Appwrite and Firestore, both live** ([PR #546](https://github.com/neiljaywarner/refuge/pull/546)) | Either cloud can answer if the other is unreachable, once writes actually succeed. | Two shapes to keep identical. Firebase users cannot be Appwrite permissions. A bad write hits both. No "yesterday" snapshot. |
| **Firestore only** | The same login that already works can own the security rules. One place to read and one place to fix. | Spark has no managed restore. A regional Firestore incident takes the notes with it until a backup exists. |
| **Appwrite only** | One SDK for tables and realtime, if members later sign in with Appwrite. | Today there is no Appwrite session. Free plan has no backups. Pro is $25 per month for a daily backup kept 7 days. |
| **One database plus its backup feature** | A bad write can be rolled back without a second app database. | Requires a paid plan. Spark and Appwrite Free do not include it. |

## Use one database, and use its backup feature

Yes. That is the better design for Belong right now.

**Keep Cloud Firestore as the only live reflection store.** Firebase Auth is already the session. Rules can say "a signed-in member may create a note, and only that member may change their own note." The feed, the votes, and the files can keep using the Firebase project they already use.

**Turn on Firestore point-in-time recovery and a daily scheduled backup.** Those are the features built for this problem.

* Point-in-time recovery keeps every document version for 7 days, at one-minute steps. You can read the damaged notes as they were and write them back. You can also clone the whole database. Docs: [point-in-time recovery](https://firebase.google.com/docs/firestore/pitr) and [disaster recovery](https://firebase.google.com/docs/firestore/disaster-recovery).
* Scheduled backups add a daily copy and a weekly copy, kept up to 14 weeks, restored into a new database. Docs: [back up and restore](https://firebase.google.com/docs/firestore/backups).
* Both require the **Blaze** plan. They are billed for backup storage and for a restore. For a community of this size the storage is small. Set a budget alert so Blaze cannot surprise you. The Spark plan cannot enable them. Even with recovery off, Firestore can still read the past hour.

### Why this backup, and not Appwrite's

Appwrite's backup screen is the matching feature if Appwrite is the database you actually use.

* On **Pro** ($25 per month per project) a TablesDB database gets one daily backup, kept 7 days, encrypted, stored away from the database, with a restore into a new database. Docs: [TablesDB backups](https://appwrite.io/docs/products/databases/tablesdb/backups). Pricing: [appwrite.io/pricing](https://appwrite.io/pricing).
* The Free plan, which is what this project is on, does not include that.
* Finer restore ("the second before the bad edit") on Appwrite is point-in-time recovery for a **dedicated** database, billed on top of compute that starts around $10 per month. The database created in this cutover is serverless TablesDB, so that switch is not included.

Paying $25 to back up Appwrite, while also paying nothing for a Firestore database the app can already protect with Firebase Auth, spends more than the $5 Serverpod bill and protects the database the members are not signed into.

### When Appwrite would become the one database

Move the live notes to Appwrite when members have an Appwrite session, or when a small server checks the Firebase token and writes with an API key. Then turn on Appwrite's daily backup, or dedicated point-in-time recovery, and stop writing reflections to Firestore. Until that day, Firestore plus Firestore recovery is the pair that matches how people sign in.

## What to do next

1. Leave the Appwrite tables disabled until a signed-in write path exists. They are disabled now.
2. Make the app's default reflection repository Firestore plus the on-device list. Drop the everyday second write.
3. Deploy Firestore rules that require a signed-in member for creates.
4. Move the Firebase project to Blaze, set a budget alert, enable point-in-time recovery, and add a daily backup schedule.
5. Cancel Serverpod after a released build no longer calls it.

The on-device list stays. It is what makes the screen calm when the network drops. It is not the backup of the community's notes.
