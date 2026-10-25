# ADR-0011: One Live Database Plus a Backup Feature, After Reviewing the Serverpod Cutover

* **Status**: Accepted
* **Date**: October 24, 2026
* **Deciders**: Neil Jay Warner & Engineering Team
* **Related**:
  * [Issue #212](https://github.com/neiljaywarner/refuge/issues/212)
  * [PR #546](https://github.com/neiljaywarner/refuge/pull/546)
  * [ADR-0009](0009-piece-by-piece-vs-one-shot-appwrite-firebase-hybrid.md)
  * [Wiki: Reflection redundancy and backup](../wiki/Reflection-Redundancy-and-Backup.md)

---

## 1. Context

[PR #546](https://github.com/neiljaywarner/refuge/pull/546) stops the Flutter client from calling Serverpod Cloud. The replacement writes each reflection to Appwrite and to Cloud Firestore, keeps the on-device list, and leaves sign-in on Firebase Auth.

That pull request was reviewed before treating it as the steady state. The question is whether two live writes are a real safety net, or whether Belong should keep one database and use a product feature that exists to restore data.

## 2. What the review found

The Serverpod call is gone from the default build. Unit tests with an in-memory stand-in show the repository asks for an Appwrite upsert, a reaction increment, and a quiet-digest write, and they show `authBackendTargetProvider` still returns Firebase. That is the part that works.

The two-cloud write is not a backup, and it is not yet a working second copy:

| Check | Result |
| :--- | :--- |
| Default build opens Serverpod | No. Serverpod runs only when `BACKEND=serverpod` and `ENABLE_SERVERPOD=true` are both set. |
| Appwrite project users | 0. Firebase Auth does not create an Appwrite session. |
| Live Appwrite write from the app | Not demonstrated. Tests never open a socket. The home screen on `main` already fails to compile against current widgets, so this repository is not what a release binary runs. |
| Firestore second copy | The rules in the pull request are not deployed. `reflections` has no matching rule in the live ruleset, so those writes fail closed. |
| Same post id in both clouds | Fragile. Appwrite row ids are sanitized to 36 characters. Firestore uses the raw id. |
| Failed write on one side | Swallowed. There is no queue that copies the missing row later. |
| Read path | Merges device memory, Firestore, and Appwrite. Equal timestamps keep whichever copy has more reaction counts. A stale richer row can cover a newer correction. |
| Existing Serverpod rows | Not copied. |
| Quiet digest | Each client recomputes it from the rows it currently sees and overwrites the shared row. |

The first version of the Appwrite tables allowed guest create and update, because a Firebase session is not an Appwrite session. The public project id is in the client. Anyone who can call the API could have changed both copies. Those tables are now **disabled**, with no guest permissions. A server API key can still reach them. The client write fails and the screen keeps the device list.

A bad client write that reaches two live databases corrupts both. A backup is an older snapshot the bad write does not touch.

## 3. Decision

1. **Leave Serverpod Cloud.** The $5 monthly cluster is the cost to remove. Cancel it only after a released build no longer calls it.
2. **Keep one live reflection database: Cloud Firestore**, for as long as Firebase Auth is the session. Security rules can require `request.auth`. Appwrite cannot, until a member has an Appwrite session or a server checks the Firebase token and writes with an API key.
3. **Use Firestore's own recovery features as the backup**, after the Firebase project is on the Blaze plan with a budget alert:
   * [Point-in-time recovery](https://firebase.google.com/docs/firestore/pitr): 7 days, one-minute granularity, including a surgical read of the damaged documents.
   * [Scheduled backups](https://firebase.google.com/docs/firestore/backups): one daily schedule and one weekly schedule, retention up to 14 weeks, restore into a new database.
   * Spark cannot enable either feature. Blaze for this community's data size should stay under the old $5 Serverpod bill, and it is metered, so a budget alert belongs next to it.
4. **Do not adopt Appwrite Pro for backups in order to save $5.** Pro is $25 per month per project and includes a daily backup kept for 7 days ([pricing](https://appwrite.io/pricing), [TablesDB backups](https://appwrite.io/docs/products/databases/tablesdb/backups)). The database created for this cutover is serverless TablesDB. Postgres point-in-time recovery applies to dedicated compute, which starts near $10 per month before the recovery add-on. Both cost more than Serverpod.
5. **PR #546 stays a seam, not the steady state.** Shipping it as the live dual-write would publish a client that writes to a disabled Appwrite table and a Firestore collection whose rules are not deployed. The accepted follow-up is a Firestore-only repository, rules that require a Firebase user for creates, and Blaze recovery turned on before Serverpod is cancelled.

Firebase Hosting, Cloud Messaging, Analytics, and Remote Config stay on Firebase. That split is unchanged from ADR-0009.

## 4. Consequences

* Members keep one sign-in. Reflection permissions follow that sign-in.
* A deleted or overwritten post can be read back from the last 7 days once point-in-time recovery is on, and from a daily snapshot for up to 14 weeks once scheduled backups are on.
* Appwrite remains available for a later move, after auth can protect the rows. The empty disabled tables can stay as the schema sketch.
* Two live databases would still be justified for a short, monitored import, with one writer and a copy job. They are not justified as the everyday safety net.
