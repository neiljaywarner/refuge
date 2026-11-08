# Firestore to Appwrite backup (first pass)

> **Issues**: [#798](https://github.com/neiljaywarner/refuge/issues/798) (this pass), [#799](https://github.com/neiljaywarner/refuge/issues/799) (GCS exports, not done here)
> **Decision**: [ADR-0011](https://github.com/neiljaywarner/refuge/blob/main/docs/adr/0011-one-database-plus-backup-not-dual-write.md)
> **Tool**: `tool/firestore_appwrite_backup.dart`
> **Checked against**: `main` (Flutter writers in `lib/`, plus `firestore.rules`)

This is a current-state copy of Firestore into Appwrite TablesDB. It exists so a person can put documents back. It is not point-in-time recovery, and it is not a second live database the phone writes.

Firestore project `belongonthespectrum` stays the database the app reads. Appwrite project `belongonthespectrum` (`6adae5c40013c409e109`), database `belong_community_db`, holds spare tables named `backup_*`. Endpoint: `https://nyc.cloud.appwrite.io/v1`.

## Why this is a CLI

Appwrite free tier allows two functions. The live ones are `dm-mirror` and `dm-push`. `feedback-forward` was removed from the project. Do not redeploy it, and do not add a third function, unless the plan is upgraded.

Cloud Functions and scheduled Firestore exports need the Blaze plan. This project is on Spark, so the first writer is this CLI on a machine that has the two secrets below. Run it by hand, or from a weekly reminder. A later Firebase scheduled function is a Blaze change, not this pass.

`dm-mirror` keeps copying a new direct message into the live table `direct_messages`. That table is a spare of today's message, not an older copy. This CLI writes `backup_direct_messages` and does not change `direct_messages`, `reflection_posts`, or `quiet_digests`.

## If Appwrite Free pauses

A pause of project `belongonthespectrum` stops this spare copy and the live functions `dm-push` and `dm-mirror`. Firestore, Firebase Auth, and Firebase Hosting stay up. The CLI sync fails until someone restores the project in the Appwrite Console. API and end-user traffic do not prevent that pause. The 8 November 2026 choice for a new leave-alone free backend is Supabase Free ([Leave-alone free backends](Leave-Alone-Free-Backends)). This CLI stays an Appwrite copy of Firestore. It is not a move of the live store.

## Inventory

`dart run tool/firestore_appwrite_backup.dart inventory` prints this list as JSON. The table below matches that command.

| Key | Firestore path | Appwrite table | Id strategy | Where the app writes it |
| --- | --- | --- | --- | --- |
| `users` | `users/{uid}` | `backup_users` | doc id, or hash | `member_directory_store.dart`, `profile_storage_service.dart`, `account_deletion_sinks.dart` |
| `reflections` | `reflections/{postId}` | `backup_reflections` | doc id, or hash | `appwrite_post_repository.dart` (production) |
| `reflections_dev` | `reflections_dev/{postId}` | `backup_reflections_dev` | doc id, or hash | same file, dev flavor |
| `direct_messages` | `direct_messages/{messageId}` | `backup_direct_messages` | doc id, or hash | `direct_message_mailbox.dart` |
| `comments` | `comments/{commentId}` | `backup_comments` | doc id, or hash | `local_comment_repository.dart` |
| `comments_dev` | `comments_dev/{commentId}` | `backup_comments_dev` | doc id, or hash | same file, dev flavor |
| `feature_votes` | `feature_votes/{featureId}` | `backup_feature_votes` | doc id, or hash | `feature_voting_repository.dart` |
| `member_feedback` | `member_feedback/{feedbackId}` | `backup_member_feedback` | doc id, or hash | `feature_voting_repository.dart` |
| `member_notifications` | `member_notifications/{notificationId}` | `backup_member_notifications` | doc id, or hash | `member_notification_store.dart` |
| `soft_deleted_users` | `soft_deleted_users/{userId}` | `backup_soft_deleted_users` | doc id, or hash | `admin_banning_repository.dart` |
| `self_deleted_accounts` | `self_deleted_accounts/{flavor}_{uid}` | `backup_self_deleted_accounts` | doc id, or hash | `account_deletion_sinks.dart` |
| `rules_admins` | `rules_admins/{uid}` | `backup_rules_admins` | doc id, or hash | `firestore.rules` only. Clients cannot read it. The document's existence is the organizer allowlist. |
| `saved_posts` | `users/{uid}/saved_posts/{postId}` | `backup_saved_posts` | hash of full path | `saved_posts_store.dart` |
| `notification_settings` | `users/{uid}/notification_settings/{docId}` | `backup_notification_settings` | hash of full path | `push_preference_store.dart` (the doc id in use is `push`) |

`users/{uid}` can also hold `outboundNotices` when the bell collection is not writable. Those fields are inside the user document, so they ride along with `users`.

### Id strategy

Appwrite row ids are at most 36 characters. Legal characters are letters, digits, period, hyphen, and underscore. The id cannot start with a special character.

* **doc id, or hash.** Top-level collections use the Firestore document id when it already fits. Seeded vote ids such as `planned-native-store-apps` fit. A new reflection id looks like `post-<millis>` and fits. A self-delete id is `{flavor}_{uid}` and usually fits.
* **hash of full path.** `saved_posts` and `notification_settings` always hash, because two members can share the same child id (`post-1`, or `push`).
* When the id does not fit, the row id is `b` plus the first 32 hex characters of SHA-256 of the full source path (33 characters).
* Every row stores `sourcePath` (for example `users/uid_example/saved_posts/post-1`) and `sourceId` (the Firestore document id). Restore uses `sourcePath`. It does not need to reverse the hash.

This is not the 36-character truncation in `appwriteRowId` used by the disabled reflection writer. Truncation can collide. The backup hash does not.

### Skipped

| Key | Why it is skipped |
| --- | --- |
| `posts` | `firestore.rules` allows `posts/{postId}`. The app writes `reflections` and `reflections_dev`. |
| `directory_members` | Rules allow it. `MemberDirectoryStore` writes `users/{uid}`. |
| `auth` | Firebase Auth passwords, password hashes, refresh tokens, and the Auth user export. |
| `storage` | Cloud Storage bytes under `avatars/`, `posts/`, `feedback/`, and `diagnostics/` in `storage.rules`. A URL already stored on a Firestore document is copied with that document. The file bytes are not. |

`quiet_digests` is an Appwrite cache, not a Firestore collection. Leave it alone.

## Row shape

Each backup table has the same columns. Permissions are an empty list. Row security is on. Guests cannot read or write. The API key can.

| Column | Type | Required | Meaning |
| --- | --- | --- | --- |
| `sourcePath` | varchar 768 | yes | Full Firestore path under `documents/`. This is the restore key. |
| `sourceId` | varchar 256 | yes | Firestore document id, the last path segment. |
| `sourceUpdatedAt` | varchar 64 | no | Document `updateTime` when Firestore sent one. Otherwise the first of `updatedAt`, `lastVotedAt`, `submittedAt`, `sentAt`, `timestamp`, `createdAt`, `savedAt`, `deletedAt`, `bannedAt`, `restoredAt`. |
| `mirroredAt` | varchar 64 | yes | UTC time the CLI wrote the row. |
| `payload` | longtext | yes | JSON of the Firestore REST `fields` object, so integers stay integers on the way back. |

`payload` longer than 1,000,000 characters is skipped and counted. A base64 screenshot on `member_feedback` can hit that limit. The bytes in Cloud Storage are still not copied.

## Environment

Do not put these values in a flag. Flags land in shell history. Do not commit them. Do not paste them into an issue or pull request.

| Variable | Required when | Default |
| --- | --- | --- |
| `APPWRITE_API_KEY` | `--write` sync, provision, and restore that reads Appwrite | none |
| `FIRESTORE_ACCESS_TOKEN` | a live Firestore read, and `--write` restore | none |
| `APPWRITE_ENDPOINT` | optional | `https://nyc.cloud.appwrite.io/v1` |
| `APPWRITE_PROJECT_ID` | optional | `6adae5c40013c409e109` |
| `APPWRITE_DATABASE_ID` | optional | `belong_community_db` |
| `FIRESTORE_PROJECT_ID` | optional | `belongonthespectrum` |

The Firestore token must be an admin access token (`gcloud auth print-access-token` from an account that can read the database). A member Firebase ID token cannot list other people's messages or push settings, because the security rules hide them. The token is not a file in this repo.

The Appwrite key needs to read and write rows in `belong_community_db`. Create it in the Appwrite console. Scopes are the TablesDB row and table scopes for that database. It is not a `--dart-define`.

## Commands

From the repository root:

```bash
dart run tool/firestore_appwrite_backup.dart inventory
dart run tool/firestore_appwrite_backup.dart schema --collection feature_votes
dart run tool/firestore_appwrite_backup.dart sync --collection feature_votes --dry-run --input test/fixtures/backup/feature_votes.json
```

`--dry-run` and `--write` are mutually required: pass one of them. Neither flag means the command stops before it touches a network write.

`schema` prints the create-table and create-column requests and sends nothing. `provision --write` sends them. A `409` means the table or column already exists and is left in place. Column creation is asynchronous. Wait until each column is `available` in the console before the first `--write` sync.

Try `feature_votes` first. The seeded ids are public roadmap slugs. Then:

```bash
dart run tool/firestore_appwrite_backup.dart sync --collection users --dry-run
dart run tool/firestore_appwrite_backup.dart sync --collection reflections --dry-run
dart run tool/firestore_appwrite_backup.dart sync --collection direct_messages --dry-run
```

Those three read the live project, so `FIRESTORE_ACCESS_TOKEN` must be set. They do not write until you change `--dry-run` to `--write`, and `--write` also needs `APPWRITE_API_KEY` after the table exists.

`--since 2026-11-01T00:00:00Z` skips rows whose `sourceUpdatedAt` is older than that instant. A document with no time is still copied. The Firestore list is still a full read. Spark is billed for that read. There is no change-feed in this pass.

`--output /path/outside/this/repo/feature_votes.json` writes the same JSON the dry-run prints. The CLI refuses a path inside the git working tree. That file can contain member stories. Keep it outside this public repository.

Stdout from a dry-run contains payloads. Do not paste it into GitHub.

## Restore

1. Pick a private JSON snapshot from `--output`, or read the current Appwrite rows.
2. Point `FIRESTORE_PROJECT_ID` at a scratch project for a drill. The default is the live project `belongonthespectrum`.
3. Dry-run. This writes nothing:

```bash
dart run tool/firestore_appwrite_backup.dart restore --collection feature_votes --dry-run --input /path/outside/this/repo/feature_votes.json
```

4. Write back only after the dry-run looks right:

```bash
dart run tool/firestore_appwrite_backup.dart restore --collection feature_votes --write --input /path/outside/this/repo/feature_votes.json
```

Restore sends a Firestore `PATCH` for each row. The update mask is the top-level field names in `payload`. An empty document, such as a `rules_admins` allowlist entry, is recreated with `POST`.

A restore does not delete a Firestore document that is missing from the snapshot. It does not clear a field that was removed after the snapshot. It does not restore Auth users, passwords, or Storage bytes. It does not replay the hour of versions Spark can still show in the console.

## Retention

* The Appwrite row is the latest copy. The next sync overwrites `payload` and refreshes `mirroredAt`. Yesterday's text is gone from that row.
* Keep the private JSON files if you need an older copy. Eight weekly files, then delete the oldest, is enough for this pass. Store them outside this repo. A private git repo is fine. This public repo is not.
* Appwrite Free does not keep a vendor backup of these tables. Losing the Appwrite project loses the spare copy. The JSON files are the older snapshots.
* Spark, with point-in-time recovery left off, can still show about the last hour of document versions in the console. This CLI does not read that hour.

## Known gaps next to GCS and PITR

Pass 2 is [#799](https://github.com/neiljaywarner/refuge/issues/799): scheduled Firestore exports to Cloud Storage, object names with timestamps, about three days of retention, and an import runbook. That needs Blaze. Billing is closed, so it is not implemented here.

Hourly point-in-time recovery is out of scope. Turning it on is also a Blaze change. This mirror cannot answer "what did this note say at 14:03."

Also out of scope:

* Auth password hashes and the Auth user list.
* Storage object bytes. URL fields on Firestore documents are included only because they are fields.
* A perfect merge when both sides changed.
* Deleting an Appwrite row because the Firestore document was deleted.
* Guest access to the backup tables.
* A third Appwrite function.

## What a bad day looks like

The phone still reads and writes Firestore. If Appwrite is down, the CLI sync fails and Firestore is unchanged. If a bad client write lands in Firestore, the next sync copies that bad write over the Appwrite row. The private JSON file from last week is the copy that the bad write does not touch. That is the same rule as ADR-0011: a mirror is not an older backup.
