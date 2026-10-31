# Member feedback forward

This Appwrite function files a private Belong note that is already stored in Cloud Firestore `member_feedback`. It creates the GitHub issue in `neiljaywarner/belong_feedback`. The Flutter app does not contain `FEEDBACK_GITHUB_PAT`.

The same token and secret steps are on the wiki: [Feedback forward function](../../../docs/wiki/Feedback-Forward-Function.md).

Firebase Cloud Functions are not used. The Firebase project is on the Spark plan, which cannot enable Cloud Build. Appwrite hosts this function.

Drawings stay inline in the issue body, with the same 65 KB guard as `PrivateFeedbackRouter`. They are not uploaded to Appwrite Storage.

## Layout

| File | Role |
| --- | --- |
| `src/main.js` | Appwrite entry. Checks the Firebase ID token, reads and patches Firestore, creates the GitHub issue. |
| `src/handle.js` | The forward decision with no network. Tests call this. |
| `src/format.js` | Issue title, body, and labels, including the preview / production stamp. |
| `test/` | Node tests. They do not call Appwrite, Firestore, or GitHub. |

Runtime is Node 22. The entrypoint is `src/main.js`. The function id is `feedback-forward`.

## What the app sends

The Dart caller is `lib/src/features/feedback/data/member_feedback_bridge.dart`. It runs after Firestore accepts a private note (`sad` or `neutral`). Public praise is not forwarded. Failures stay on the device: the note remains in Firestore and the sheet keeps the “not sent to GitHub” toast.

```json
{ "feedbackId": "<member_feedback document id>", "idToken": "<Firebase ID token>" }
```

The function does not accept a title or a message from the phone. It reads `member_feedback/{feedbackId}`. The token’s uid must match `userId` or `authorId`. Otherwise the response is 403.

If `githubIssueNumber` is already a positive integer, the function returns that issue and does not create another.

## Source environment

Preview and production share `neiljaywarner/belong_feedback`. The app writes `sourceEnvironment`, `sourceHost`, `sourceUrl`, and `submittedAt` on the Firestore document. The issue body always includes a **Source environment** line with that value and the host.

| `sourceEnvironment` | Issue title | Extra label |
| --- | --- | --- |
| `production` | no environment prefix | none |
| `preview` | starts with `[preview]` | `preview` (created when missing) |
| `dev` | starts with `[dev]` | `dev` |
| `local` | starts with `[local]` | `local` |
| anything else | starts with `[preview]` | `preview` |

The phone chooses the value. The rules live in `lib/src/features/feedback/domain/feedback_source_stamp.dart`.

Web uses the page host, not the compile-time flavor. A prod build on a Firebase Hosting preview channel is `preview`.

- `localhost`, `127.0.0.1`, `0.0.0.0`, `::1`, or an empty host → `local`
- `belongonthespectrum.web.app` or `belongonthespectrum.firebaseapp.com` → `production`
- `dev-`, `stg-`, or `qa-` plus `belongonthespectrum.web.app` / `.firebaseapp.com` → `dev`
- `belongonthespectrum--<channel>.web.app` or `.firebaseapp.com` → `preview`
- any other website → `preview`

Android, iOS, and desktop use the flavor. `FLAVOR=prod` → `production`. Every other flavor → `dev`. The host recorded for a native build is that flavor’s hosting hostname, not a device name.

## Environment

Set these as secret variables on the function. Do not commit them, print them, or pass them with `--dart-define`.

- `FEEDBACK_GITHUB_PAT` — fine-grained personal access token with Issues read and write on `neiljaywarner/belong_feedback` only. Without it the function returns `github credential is not configured` and does not create an issue.
- `FIREBASE_SERVICE_ACCOUNT_JSON` — Firebase Admin SDK JSON for project `belongonthespectrum`. The account must be allowed to read and update `member_feedback`. `firestore.rules` denies client updates, so this key is what writes `githubIssueCreated`, `githubIssueNumber`, and `githubIssueUrl`. If this variable is empty, `FCM_SERVICE_ACCOUNT_JSON` is used when that account can write Firestore. A missing key can still create the GitHub issue; the response then has `persisted: false`, and a later call can file a duplicate.

Appwrite also injects `APPWRITE_FUNCTION_API_ENDPOINT`, `APPWRITE_FUNCTION_PROJECT_ID`, and `APPWRITE_FUNCTION_API_KEY`. This function does not use them.

## Create `FEEDBACK_GITHUB_PAT`

Repository settings at `/settings/keys` are **deploy keys**. They are not a personal access token.

`gh` and the GitHub REST API cannot mint fine-grained personal access tokens for a normal user OAuth session. Create the token in the GitHub web UI while signed in as a user who can administer `neiljaywarner/belong_feedback`.

1. Open [https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new) while signed in.
2. Token name example used: `feedback pat`. Any clear name is fine.
3. Expiration: No expiration is acceptable for this private feedback bridge (or set 90 days if preferred).
4. Resource owner: the user who owns `belong_feedback`.
5. Repository access: **Only select repositories** → select **`belong_feedback` only**.
6. Repository permissions: **Issues: Read and write**. Metadata stays Read-only.
7. Account permissions: none.
8. Generate the token. Copy the `github_pat_…` value once. Never commit it, paste it into an issue or pull request, or leave it in shell history.
9. After creation, the token settings page looks like `https://github.com/settings/personal-access-tokens/<id>`.

## Set the function secrets

Project: `6adae5c40013c409e109`. Endpoint: `https://nyc.cloud.appwrite.io/v1`. Function id: `feedback-forward`.

Run this from a machine where the Appwrite CLI is already logged in. `.secrets/` is gitignored. Put each value in a mode-600 file under `.secrets/` so the shell history only records `$(cat …)`, then delete the files.

```bash
# Point CLI at the project (once per shell)
appwrite client --endpoint https://nyc.cloud.appwrite.io/v1 --project-id 6adae5c40013c409e109

# PAT — value from a local file so it is not left in shell history
# Put the token in a mode-600 file first, e.g. .secrets/FEEDBACK_GITHUB_PAT (gitignored)
appwrite functions create-variable \
  --function-id feedback-forward \
  --variable-id feedback-github-pat \
  --key FEEDBACK_GITHUB_PAT \
  --value "$(cat .secrets/FEEDBACK_GITHUB_PAT)" \
  --secret true

# Firebase Admin JSON for Firestore read/patch of member_feedback
# Create a key for firebase-adminsdk-…@belongonthespectrum.iam.gserviceaccount.com with gcloud,
# write to .secrets/FIREBASE_SERVICE_ACCOUNT_JSON, then:
appwrite functions create-variable \
  --function-id feedback-forward \
  --variable-id firebase-sa-json \
  --key FIREBASE_SERVICE_ACCOUNT_JSON \
  --value "$(cat .secrets/FIREBASE_SERVICE_ACCOUNT_JSON)" \
  --secret true

# Verify keys exist (values stay hidden)
appwrite functions list-variables --function-id feedback-forward --json

# Remove local secret files
rm -f .secrets/FEEDBACK_GITHUB_PAT .secrets/FIREBASE_SERVICE_ACCOUNT_JSON
```

If `FIREBASE_SERVICE_ACCOUNT_JSON` is empty, the function may use `FCM_SERVICE_ACCOUNT_JSON` when that account can write Firestore.

## Tests

From this directory:

```bash
npm test
```

That runs `node --test test/format.test.js test/handle.test.js`.

## Deploy the function

Create the function once in the Appwrite console for project `6adae5c40013c409e109` (or with the Appwrite CLI):

- Function id: `feedback-forward`
- Runtime: Node 22
- Entrypoint: `src/main.js`
- Execute permission: `any`

There is no Appwrite user session. The Firebase ID token is the session.

Pack this directory without `node_modules` and without AppleDouble files. On macOS, `COPYFILE_DISABLE=1` avoids those extra files. Upload the archive as a deployment and activate it.

```bash
cd appwrite/functions/feedback-forward
COPYFILE_DISABLE=1 tar --exclude node_modules -czf /tmp/feedback-forward.tar.gz .
```

Set the two secrets with the commands above before asking a member to send a note. A deployment with an empty body answers `{ "error": "missing feedback" }` with status 400 and does not create an issue.

## Preview channel for Belong

Preview and production write to the same private repo. Use a Hosting preview channel to prove the stamp before a production release. This command builds the prod flavor and deploys a channel. It does not publish `https://belongonthespectrum.web.app` unless you also pass `--prod`.

```bash
dart run tool/deploy_release.dart --version feedback-659
```

The channel host looks like `https://belongonthespectrum--feedback-659-<hash>.web.app`. Open that host, sign in, and submit private Vote & Feedback. In `neiljaywarner/belong_feedback`, expect an issue title `[preview] …`, the label `preview`, and **Source environment** `preview`. The toast should name `belong_feedback#N`. The body should also include that channel host.

A note sent from `https://belongonthespectrum.web.app` stays unprefixed and has no `preview` label. `https://dev-belongonthespectrum.web.app` is `dev`. `localhost` is `local`.
