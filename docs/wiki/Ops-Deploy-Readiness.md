# Ops / Deploy readiness (1 November 2026, US Central)

Updated ~7:05 PM CT on 1 November 2026 from Mac `main` at `a6c3a34` (includes rules merge `19dbe16` / [#754](https://github.com/neiljaywarner/refuge/pull/754)). This page has no API keys, no mail JSON, and no service-account files. Keep secrets in Firebase or Appwrite, not here.

| Item | Status | Next step |
| --- | --- | --- |
| Rules ([#754](https://github.com/neiljaywarner/refuge/pull/754)) | **Firestore rules deployed** to `belongonthespectrum` via `firebase deploy --only firestore:rules` (Mac CLI signed in as `neilwarner@gmail.com`). Storage rules **not** deployed: Storage is not set up, and creating the default bucket failed with billing absent (`billingEnabled: false`). | Open [Storage Get Started](https://console.firebase.google.com/project/belongonthespectrum/storage) after Blaze/billing is linked, create the default bucket, then `firebase deploy --only storage --project belongonthespectrum`. Confirm new publish times in the console. Soft-check: signed-in member can send a DM / attach media without a rules denial. |
| DM email ([#769](https://github.com/neiljaywarner/refuge/pull/769) / [#570](https://github.com/neiljaywarner/refuge/issues/570)) | Code is on `main`. `calmDirectMessageEmail` is **not** deployed. Live billing is still off. No `DM_EMAIL_TRANSPORT_JSON` secret. `firebase functions:list` shows no functions. | Switch `belongonthespectrum` to Blaze + budget alert. Create a Resend key outside this repo. `firebase functions:secrets:set DM_EMAIL_TRANSPORT_JSON --project belongonthespectrum`, then `firebase deploy --only functions:calmDirectMessageEmail --project belongonthespectrum`. JSON shape is in `functions/README.md`. |
| dm-mirror ([#774](https://github.com/neiljaywarner/refuge/pull/774) / [#555](https://github.com/neiljaywarner/refuge/issues/555)) | Table `belong_community_db.direct_messages` is live (row security on; permissions empty). Function **not** created. Appwrite tier-0 still at the 2-function cap: `dm-push` (live) + `feedback-forward` (present). Neither was removed. | Upgrade the Appwrite plan, or free a slot only after Neil names which function to remove. Then create `dm-mirror` (Node 22, `src/main.js`, execute `any`, scopes `rows.read` + `rows.write`) and deploy `appwrite/functions/dm-mirror`. |
| Crashlytics ([#481](https://github.com/neiljaywarner/refuge/issues/481)) | Native collection is wired. `ErrorReporterService.recordError` also writes Crashlytics, so a framework error can show twice. No prod device proof yet. | Prod Android test crash with `flavor=prod`, then confirm in console. |
| Giphy prod | Prod smoke **PASS** (attach sheet + GIPHY logo). Remote Config keys confirmed in use. | Re-check only if RC keys change. |
| neiljaywarner/test | Accidental empty private repo still exists. Mac `gh` can see it (admin) but token lacks `delete_repo` scope (`gist`, `read:org`, `repo`, `workflow` only). Cloud-agent token is refuge-only (404). | Delete from GitHub Settings → Danger Zone, or `gh auth refresh -h github.com -s delete_repo` then `gh api -X DELETE repos/neiljaywarner/test` (HTTP 204 = gone). |
| CodeRabbit [#778](https://github.com/neiljaywarner/refuge/issues/778) | Analysis-chain comment posted ~00:55 UTC 2 Nov. | Wait for a finished review, then triage findings into issues. |

## What was left undone on purpose

- No Firebase Hosting deploy.
- No Cloud Function deploy, and no invented mail secret.
- No Appwrite function created or deleted.
- Storage bucket not created while billing is absent.
- The same page lives in `docs/wiki/Ops-Deploy-Readiness.md` so `dart run tool/refuge_cli.dart sync-wiki` keeps it (see [#782](https://github.com/neiljaywarner/refuge/pull/782)).
