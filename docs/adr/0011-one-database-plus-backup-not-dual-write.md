# ADR-0011: One Live Database Plus a Backup Feature, After Reviewing the Firebase Cutover

* **Status**: Accepted
* **Date**: October 24, 2026
* **Deciders**: Engineering Team
* **Related**:
  * [Issue #212](https://github.com/neiljaywarner/refuge/issues/212)
  * [PR #546](https://github.com/neiljaywarner/refuge/pull/546)
  * [ADR-0009](0009-piece-by-piece-vs-one-shot-appwrite-firebase-hybrid.md)
  * [Wiki: Reflection redundancy and backup](../wiki/Reflection-Redundancy-and-Backup.md)

---

## 1. Context

[PR #546](https://github.com/neiljaywarner/refuge/pull/546) stops the Flutter client from calling the retired cloud backend. The replacement writes each reflection to Appwrite and to Cloud Firestore, keeps the on-device list, and leaves sign-in on Firebase Auth.

That pull request was reviewed before treating it as the steady state. The question is whether two live writes are a real safety net, or whether Belong should keep one database and use a product feature that exists to restore data.

## 2. What the review found

The Firebase call is gone from the default build. Unit tests with an in-memory stand-in show the repository asks for an Appwrite upsert, a reaction increment, and a quiet-digest write, and they show `authBackendTargetProvider` still returns Firebase. That is the part that works.

The two-cloud write is not a backup, and it is not yet a working second copy:

| Check | Result |
| :--- | :--- |
| Default build opens a second cloud socket | No. The default reflection path is Appwrite plus Cloud Firestore. Firebase Auth is unchanged. |
| Appwrite project users | 0. Firebase Auth does not create an Appwrite session. |
| Live Appwrite write from the app | Not demonstrated. Tests never open a socket. The home screen on `main` already fails to compile against current widgets, so this repository is not what a release binary runs. |
| Firestore second copy | The rules in the pull request are not deployed. `reflections` has no matching rule in the live ruleset, so those writes fail closed. |
| Same post id in both clouds | Fragile. Appwrite row ids are sanitized to 36 characters. Firestore uses the raw id. |
| Failed write on one side | Swallowed. There is no queue that copies the missing row later. |
| Read path | Merges device memory, Firestore, and Appwrite. Equal timestamps keep whichever copy has more reaction counts. A stale richer row can cover a newer correction. |
| Existing Firebase rows | Not copied. |
| Quiet digest | Each client recomputes it from the rows it currently sees and overwrites the shared row. |

The first version of the Appwrite tables allowed guest create and update, because a Firebase session is not an Appwrite session. The public project id is in the client. Anyone who can call the API could have changed both copies. Those tables are now **disabled**, with no guest permissions. A server API key can still reach them. The client write fails and the screen keeps the device list.

A bad client write that reaches two live databases corrupts both. A backup is an older snapshot the bad write does not touch.

## 3. Decision

Same-evening revision: the project is not taking payments, so the plan must stay on free tiers and must not ask for a credit card. Blaze, Appwrite Pro, and Neon paid history are documented below as later upgrades, not the current plan.

1. **Leave Firebase.** The $5 monthly cluster is the cost to remove. Cancel it only after a released build no longer calls it.
2. **Firestore on the Spark plan is the live reflection database.** Firebase Auth is the session, and rules can require `request.auth`. Spark already keeps about one hour of document versions with point-in-time recovery left off ([PITR](https://firebase.google.com/docs/firestore/pitr)).
3. **A one-way mirror to Appwrite is a good free redundancy, and the pull request's two-way merge is not the way to build it.** Firestore stays the copy the app reads. An Appwrite Function on the free plan checks the Firebase ID token and writes the row with an API key stored as a function secret. The phone never holds that key. If Appwrite is down, the note is still in Firestore. If Firestore is over the free quota, the mirror can be read until the quota resets. A bad write can still reach both, which is why the mirror is not the backup.
4. **The backup is a JSON snapshot in a private GitHub repository.** A weekly Dart script, or a GitHub Action using the free minutes on a private repo, exports reflections to `reflections-YYYY-MM-DD.json` and keeps several weeks of files. Restoring means reading an older file back into Firestore. Those files stay out of the public `refuge` repo because the notes can contain personal stories.
5. **Do not buy a backup plan yet.** When a card is acceptable later, Firestore point-in-time recovery (7 days) and scheduled backups (up to 14 weeks) on Blaze are the upgrade. Appwrite Pro is $25 per month for a daily backup kept 7 days. Cloudflare D1 on Workers Free is the $0 product that already includes 7-day time travel, if the live database ever moves.

Firebase Hosting, Cloud Messaging, Analytics, and Remote Config stay on Firebase. That split is unchanged from ADR-0009.

## 4. Consequences

* Members keep one sign-in. The screen reads Firestore. Appwrite is the spare copy.
* The undo window without a credit card is the weekly private JSON file, plus about one hour of Firestore history.
* The Appwrite tables stay disabled until the function, not the phone, is the writer.
* [PR #546](https://github.com/neiljaywarner/refuge/pull/546) remains a seam. Its client-side dual-write and three-way merge are not the accepted mirror.

## 5. Follow-through for direct messages (1 November 2026)

Direct messages use the same rule. Firestore collection `direct_messages` is the copy the app reads and writes. The Appwrite function `dm-mirror` checks the Firebase ID token and writes the same fields with an API key that stays on the function. The phone does not write the table. If the function fails, the sender still has the Firestore message. Reflection tables stay disabled. Guest create and guest update stay off. This mirror is not a backup of an older copy.

## 6. Leave-alone free backend (8 November 2026)

This note does not change sections 1–5. Firestore on Spark remains the live member store. Firebase Auth and Firebase Hosting stay. Appwrite remains the function host for `dm-push` and `dm-mirror`, and the spare/mirror path.

When a new free backend has to keep running for days without a person opening a vendor console, prefer Supabase Free. Appwrite Free pauses after 7 days with no Console development activity, and member traffic does not count. Supabase Free can also pause, after too little activity over 7 days, but Dashboard visits and app, API, and database requests count. It is not "the free tier that does not pause."

The projects checked that day, and the vendor links, are in [Leave-alone free backends](../wiki/Leave-Alone-Free-Backends.md). Issue [#906](https://github.com/neiljaywarner/refuge/issues/906). No client, function, or schema moves to Supabase in this decision.

Related, not closed by that note: [#781](https://github.com/neiljaywarner/refuge/issues/781), [#786](https://github.com/neiljaywarner/refuge/pull/786), [#789](https://github.com/neiljaywarner/refuge/issues/789), [#792](https://github.com/neiljaywarner/refuge/issues/792), [#873](https://github.com/neiljaywarner/refuge/pull/873).
