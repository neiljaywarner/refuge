# Feedback bridge status

Updated Saturday, Oct 31, 2026, 1:30 PM America/Chicago.

Issue [#659](https://github.com/neiljaywarner/refuge/issues/659). Pull request [#716](https://github.com/neiljaywarner/refuge/pull/716) is merged to `main` (`e91434d`).

## Done

- Appwrite function `feedback-forward` is deployed and live. Runtime Node 22. Entrypoint `src/main.js`. Deployment `6ae61ffc9bbd12cf1006`.
- A live call with an empty body returned `400` and `{"error":"missing feedback"}`.
- A live call with a bad token returned `401` and `{"error":"unauthorized"}`. No GitHub issue was created.
- The function’s variable list is empty. `FEEDBACK_GITHUB_PAT` and `FIREBASE_SERVICE_ACCOUNT_JSON` are not set.
- A prod-flavor web build of the branch (`lib/main_prod.dart`, `FLAVOR=prod`) loads in Chrome and stops on the members-only sign-in wall. The subtitle is “Sign in to Belong on the Spectrum”. There is no `[DEV]` or `PREVIEW` tag. Vote & Feedback is not on that screen.
- A fake `*.web.app` host over plain HTTP is rejected by Chrome with `ERR_SSL_PROTOCOL_ERROR`. That is not a Hosting preview channel.

## Not done

- No Firebase Hosting preview URL. This Linux agent’s Firebase CLI has no logged-in user, so `dart run tool/deploy_release.dart --version feedback-659` has not run. Production `https://belongonthespectrum.web.app` was not published from this work.
- No end-to-end note. The app requires a signed-in member, and the function cannot file `belong_feedback#N` until the two secrets above exist.

## Next

1. Finish the Firebase CLI login started in chat. The session id is in the chat, not in this file. Paste the authorization code back. Then this agent deploys a preview channel only: `dart run tool/deploy_release.dart --version feedback-659`, with no `--prod`.
2. A Mac worker for this repo is connected and idle. This session cannot place a command on it. A trial subagent stayed on Linux, so the preview was not deployed from the Mac.
3. Set `FEEDBACK_GITHUB_PAT` and `FIREBASE_SERVICE_ACCOUNT_JSON` on Appwrite function `feedback-forward` before expecting a toast that names `belong_feedback#N`.
