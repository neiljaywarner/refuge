# Ops / Deploy readiness (1 November 2026, US Central)

Updated ~7:05 PM CT on 1 November 2026 from Mac `main` at `a6c3a34` (includes rules merge `19dbe16` / [#754](https://github.com/neiljaywarner/refuge/pull/754)). This page has no API keys, no mail JSON, and no service-account files. Keep secrets in Firebase or Appwrite, not here.

| Item | Status | Next step |
| --- | --- | --- |
| Rules ([#754](https://github.com/neiljaywarner/refuge/pull/754)) | **Firestore rules deployed** to `belongonthespectrum` via `firebase deploy --only firestore:rules` (maintainer Firebase CLI session). Storage rules **not** deployed: Storage is not set up, and creating the default bucket failed with billing absent (`billingEnabled: false`). | Open [Storage Get Started](https://console.firebase.google.com/project/belongonthespectrum/storage) only after the Blaze section below is accepted and billing is linked. Then create the default bucket and run `firebase deploy --only storage --project belongonthespectrum`. Confirm new publish times in the console. Soft-check: signed-in member can send a DM / attach media without a rules denial. |
| DM email ([#769](https://github.com/neiljaywarner/refuge/pull/769) / [#570](https://github.com/neiljaywarner/refuge/issues/570)) | Code is on `main`. `calmDirectMessageEmail` is **not** deployed. Live billing is still off. No `DM_EMAIL_TRANSPORT_JSON` secret. `firebase functions:list` shows no functions. | Follow the Blaze section below. A budget alert does not stop charges. Create a Resend key outside this repo. `firebase functions:secrets:set DM_EMAIL_TRANSPORT_JSON --project belongonthespectrum`, then `firebase deploy --only functions:calmDirectMessageEmail --project belongonthespectrum`. JSON shape is in `functions/README.md`. |
| dm-mirror ([#774](https://github.com/neiljaywarner/refuge/pull/774) / [#797](https://github.com/neiljaywarner/refuge/pull/797) / [#808](https://github.com/neiljaywarner/refuge/issues/808)) | **Live on Appwrite `tier-0` (2/2 function slots)**: `dm-push` + `dm-mirror` are active. `feedback-forward` was retired on `tier-0` (`#797`) and client builds skip calling it by default (`APPWRITE_FEEDBACK_FORWARD_ENABLED=false` in `#808`); private feedback notes persist durably in Firestore `member_feedback`. | Keep `dm-push` and `dm-mirror` warm via `.github/workflows/appwrite-keepalive.yml`. |
| Crashlytics ([#481](https://github.com/neiljaywarner/refuge/issues/481)) | Native collection is wired. `ErrorReporterService.recordError` also writes Crashlytics, so a framework error can show twice. No prod device proof yet. | Prod Android test crash with `flavor=prod`, then confirm in console. |
| Giphy prod | Prod smoke **PASS** (attach sheet + GIPHY logo). Remote Config keys confirmed in use. | Re-check only if RC keys change. |
| neiljaywarner/test | Accidental empty private repo still exists. Mac `gh` can see it (admin) but token lacks `delete_repo` scope (`gist`, `read:org`, `repo`, `workflow` only). Cloud-agent token is refuge-only (404). | Delete from GitHub Settings → Danger Zone, or `gh auth refresh -h github.com -s delete_repo` then `gh api -X DELETE repos/neiljaywarner/test` (HTTP 204 = gone). |
| CodeRabbit [#778](https://github.com/neiljaywarner/refuge/issues/778) | Analysis-chain comment posted ~00:55 UTC 2 Nov. | Wait for a finished review, then triage findings into issues. |

## Blaze near $0–$5, with a card on file

Draft decision for [#800](https://github.com/neiljaywarner/refuge/issues/800), written 2 November 2026. Sources checked that day: [Firebase pricing](https://firebase.google.com/pricing), [pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans), [budget alerts](https://firebase.google.com/docs/projects/billing/budget-alerts), [spend caps](https://firebase.google.com/docs/projects/billing/spend-caps), [Cloud Billing budgets](https://cloud.google.com/billing/docs/how-to/budgets), [Functions quotas](https://firebase.google.com/docs/functions/quotas), and [Firestore export](https://firebase.google.com/docs/firestore/manage-data/export-import). Linking a card, and any deploy, stay out of this page.

**Friendlies recommendation: conditional yes.** Reopen billing, put `belongonthespectrum` on Blaze, and watch **$1** and **$5**. That is a watch band a person acts on. There is no project-wide hard stop at $5.

Stay on Spark if any charge at all is unacceptable. The live web app, Auth, Firestore quotas, Hosting, Crashlytics, and FCM keep working. Storage rules, the calm email function, and Google-hosted Firestore backups stay blocked. That is the choice where $0 is structural.

### Prerequisite: billing is closed

The Cloud Billing account for this project is **closed**. Firebase reports **`billingEnabled: false`**. Budgets, a Storage bucket, Cloud Functions, and Firestore export all wait on an open billing account linked to the project. Linking one upgrades Spark to Blaze. Unlinking it, or closing the account, is what returned the project to this state. Reopening (or creating a new billing account and linking it) comes before the steps below.

### Spark vs Blaze right now

Spark needs no payment method. When a product hits its no-cost quota, Spark turns that product off until the next cycle. Nothing is charged, because no payment method is on the project.

Blaze is pay as you go. It includes no-cost allowances, then bills past them, and it is the only way to turn on the paid Google Cloud pieces below. The [pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans) page says usage that stays inside those allowances is not charged, and it calls out Cloud Functions as the exception to read before you rely on that sentence.

| | Spark today | Blaze, if billing is reopened |
| --- | --- | --- |
| Auth, Firestore inside quota, Hosting, Crashlytics, FCM, Remote Config | In use | Same products, card on file |
| Cloud Storage default bucket and `storage.rules` | Bucket create failed (`billingEnabled: false`). The pricing page lists Storage as not available on Spark. | No-cost allowance, then paid. About 5 GB stored. Download and operation quotas depend on the bucket (`*.appspot.com` vs `*.firebasestorage.app`). |
| `calmDirectMessageEmail` ([#570](https://github.com/neiljaywarner/refuge/issues/570)) | Cannot deploy. Functions are not on Spark. | Can deploy. See allowances below. |
| Firestore export / backup to Cloud Storage ([#799](https://github.com/neiljaywarner/refuge/issues/799)) | Blocked. Export requires billing. | Available, and billed. See below. |

### What Blaze unlocks for Belong

**Storage.** Creating the default bucket and deploying `storage.rules` is the friendlies task that is actually stuck. Member media stays on hold until that bucket exists.

**Functions email.** `calmDirectMessageEmail` runs where the message document is created. On Blaze the no-cost allowance is 2 million invocations, 400,000 GB-seconds, 200,000 CPU-seconds, and 5 GB of outbound networking per month, plus 120 Cloud Build minutes per day and 500 MB of Artifact Registry storage ([pricing](https://firebase.google.com/pricing)). A quiet friendlies inbox fits inside those numbers. Firebase's [quotas page](https://firebase.google.com/docs/functions/quotas) also says a deploy stores a container and that this storage can be a small charge. Treat the first deploy as "likely cents," and check the billing report after it. Do not write it down as $0.

**Firestore export backups.** Managed export to a Cloud Storage bucket needs Blaze. Google charges one document read per exported document, plus the cost of storing the files. Those reads do not show in the Firebase usage panel, and the export docs say the operation will not trigger a budget alert until it finishes. A scheduled export is a real backup. It is also a real way to leave $0 behind, including on a quiet week, because the reads happen even when nobody is in the app.

Point-in-time recovery and the console's scheduled backups are the same class of feature: Blaze, billed for the copies they keep ([backups](https://firebase.google.com/docs/firestore/backups)). Rates change; use the pricing page when you turn them on. The backup that stays at $0 today is the private weekly JSON file in [One database plus a backup](Reflection-Redundancy-and-Backup). The Appwrite mirror ([#798](https://github.com/neiljaywarner/refuge/issues/798)) runs without Blaze. It is a second copy. Putting an older version back still needs a file from an earlier day.

Firebase Test Lab's small daily allowance (virtual and physical) exists on Spark. A custom results bucket is Cloud Storage, so it waits on the same billing link.

Quotas friendlies already rely on, from the pricing page, for Firestore standard edition on either plan: **1 GiB** stored, **50,000 reads/day**, **20,000 writes/day**, **20,000 deletes/day**, **10 GiB/month** egress. Hosting's no-cost allowance is **10 GB** stored and **360 MB/day** transferred. These reset on Google's clock (daily quotas at midnight US Pacific). They are project-wide, shared by dev and prod in this one Firebase project.

### Card on file, and a month that happens to be $0

Blaze requires a Cloud Billing account, and that account requires a payment method. The card can be charged as soon as usage leaves an allowance, or as soon as you use something that has no allowance (export reads, backup storage, function container storage).

A careful month can still total $0 if you only touch products inside their allowances and you skip exports. That is a habit. Spark is the plan where the platform itself refuses to bill. "Blaze aimed at $0" still has a chargeable card.

Phone-number sign-in is billed per SMS on Blaze and is unavailable on Spark. Belong's email sign-in is in the no-cost Auth set. Leave phone auth off.

### Monitoring: $1 and $5, and what those alarms actually do

Create these after the billing account is open and linked, and before the bucket or the function:

1. **Alerts-only budget, this project, $5 per month**, with email at **$1** and **$5** (20% and 100%). Mail goes to the billing admins and project owners already on the account. Keep phone numbers and personal addresses out of git.
2. **Cloud Functions spend cap**, as low as the console allows (aim at **$1**). At 100% of that service budget, Cloud Billing pauses **new** Cloud Functions usage for the rest of the month. The same kind of cap exists for Firebase Extensions, App Hosting, and Firebase AI Logic. Storage and Firestore are outside it, so a backup export is outside it.

What Google documents, and what we should believe:

- An alerts-only budget sends email. It leaves the service running and leaves the card chargeable. Cloud Billing's own caution: a budget does not automatically set a hard cap on spending. ([Budget alerts](https://firebase.google.com/docs/projects/billing/budget-alerts), [budgets](https://cloud.google.com/billing/docs/how-to/budgets).)
- Cost numbers arrive late. The first notification can take several hours. Usage can land in the report after the threshold has already been passed. Google says to set the budget below the amount you can afford to lose. A monthly budget keeps counting for the first two days of the next month.
- Spend caps are in **Preview** (no SLA, and the service list can change). Google says they are not hard caps: enforcement can lag by several minutes, and the overage during that lag is billed. Lifting an enforced cap leaves that service unlimited for the rest of the month unless you set a higher number. The original cap comes back at the start of the next month.
- A function that unlinks billing when a budget Pub/Sub message arrives is something you would build yourself. Creating the $1 email does not install it. It runs late, it can fail, and unlinking billing drops the project back toward Spark: new function deploys stop, and non-default Storage buckets stay on disk while the app loses access to them.

The kill switch a person can use the same day: downgrade to Spark in the Firebase console, or unlink the Cloud Billing account in Google Cloud. Do that if the $5 mail arrives and the cause is still unclear. The mail is the signal. Stopping the card means unlinking billing.

### What to do for friendlies

If a few dollars in a bad month is acceptable, and someone will unlink billing the same day a $5 mail shows up:

1. Reopen the closed billing account, or create one, and link it to `belongonthespectrum`.
2. Create the $1 / $5 alerts and the Functions spend cap first.
3. Create the default Storage bucket and deploy storage rules.
4. Deploy `calmDirectMessageEmail` only after the mail secret exists outside this repo.
5. Leave recurring Firestore exports off until the $1 alert has stayed quiet and someone has counted the documents. One manual export can be the first Google backup. Until then, keep the private weekly JSON file.
6. On a $5 mail, unlink billing the same day unless the cause is already understood and small.

If a surprise charge is unacceptable, stay on Spark and keep the JSON backup. Revisit Blaze when a card is an explicit yes.

## What was left undone on purpose

- No Firebase Hosting deploy.
- No Cloud Function deploy, and no invented mail secret.
- No Appwrite function created or deleted.
- Storage bucket not created while billing is absent.
- The same page lives in `docs/wiki/Ops-Deploy-Readiness.md` so `dart run tool/refuge_cli.dart sync-wiki` keeps it (see [#782](https://github.com/neiljaywarner/refuge/pull/782)).
