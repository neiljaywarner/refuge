# Feedback forward function

> **Code**: `appwrite/functions/feedback-forward`
> **Operator notes**: [README](../../appwrite/functions/feedback-forward/README.md)

This Appwrite function files a private Belong note that is already stored in Cloud Firestore `member_feedback`. It creates the GitHub issue in `neiljaywarner/belong_feedback`. The Flutter app does not contain `FEEDBACK_GITHUB_PAT`.

Firebase Cloud Functions are not used. The Firebase project is on the Spark plan, which cannot enable Cloud Build. Appwrite hosts this function.

The function id is `feedback-forward`. The runtime is Node 22. The entrypoint is `src/main.js`. Execute permission is `any`, because the caller has a Firebase session, not an Appwrite user session.

Project: `6adae5c40013c409e109`. Endpoint: `https://nyc.cloud.appwrite.io/v1`.

## Why the token is created in the GitHub web UI

Repository settings at `/settings/keys` are **deploy keys**. They are not a personal access token.

`gh` and the GitHub REST API cannot mint fine-grained personal access tokens for a normal user OAuth session. Create the token in the GitHub web UI while signed in as a user who can administer `neiljaywarner/belong_feedback`.

## Create the fine-grained PAT

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

`list-variables` shows the keys. The values stay hidden. Do not print either secret, and do not commit the files under `.secrets/`.

## Preview stamp check

After the secrets are set, deploy a Hosting preview channel. This command does not publish `https://belongonthespectrum.web.app` unless you also pass `--prod`.

```bash
dart run tool/deploy_release.dart --version feedback-659
```

Open the Hosting preview channel URL, sign in, and submit private Vote & Feedback. In `neiljaywarner/belong_feedback`, expect an issue title `[preview] …`, the label `preview`, and **Source environment** `preview`.

The channel host looks like `https://belongonthespectrum--feedback-659-<hash>.web.app`. A note sent from `https://belongonthespectrum.web.app` stays unprefixed and has no `preview` label.

## What stays off this page

Do not record the token, the service-account JSON, a key id, a Firebase uid, or a member email. The variable names are `FEEDBACK_GITHUB_PAT` and `FIREBASE_SERVICE_ACCOUNT_JSON`. The values are only on the function.
