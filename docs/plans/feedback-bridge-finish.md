# Finish the feedback bridge

Hand this file to a cheaper model. Run it on the Mac checkout of `neiljaywarner/refuge`. If `uname -s` is not `Darwin`, stop. Do not do this on the Linux cloud agent. Firebase login and Flutter are already on the Mac. This session cannot place work there.

**Cloud agent (Sunday Nov 1, 2026):** README toast sentence fixed, `docs/archive/feedback_bridge_status.md` refreshed, Node + Flutter feedback tests green on PR #785. Steps 1–9 below still require Mac.

Do not deploy production. Do not pass `--prod`. Do not print tokens, service-account JSON, passwords, or member emails. Do not put `FEEDBACK_GITHUB_PAT` in `--dart-define`.

## Already done (do not redo)

Checked Sunday, Nov 1, 2026, 7:10 PM America/Chicago.

- Code is on `main`. Pull request #716 is merged. Status note #745 is merged.
- Appwrite function `feedback-forward` exists, deployment `6ae61ffc9bbd12cf1006` is `ready`, and an empty execution still returns `400` `{"error":"missing feedback"}`.
- Secret **names** exist on that function: `FEEDBACK_GITHUB_PAT` and `FIREBASE_SERVICE_ACCOUNT_JSON`. Values are hidden. Do not read or print them.
- The phone writes `sourceEnvironment`, `sourceHost`, `sourceUrl`, `submittedAt`, `userId`, and `authorId`, then calls the function with the Firebase ID token and the Firestore document id. The function reads the document. It does not trust a title or message from the phone.
- `ResilientFeatureVotingRepository.submitFeedback` delegates to `FirebaseFeatureVotingRepository`, which calls the bridge. Do not “fix” that wrapper.
- Member toast is plain on purpose. `feedbackSavedForOrganizers` in `lib/src/features/feedback/domain/feedback_success_copy.dart` must stay free of the words GitHub, clipboard, and `belong_feedback`. Tests in `test/features/feedback/feedback_drawing_test.dart` lock that. Issue #490 won over the older “toast names belong_feedback#N” sentence.

## Not done

- No Hosting preview URL has been opened for this build.
- No private issue in `neiljaywarner/belong_feedback` has been confirmed from a real submit.
- `appwrite/functions/feedback-forward/README.md` still says the toast should name `belong_feedback#N`. That sentence is wrong. The toast must stay the plain #490 sentence. The GitHub issue is for organizers, not the member.

`live: false` on the function list is not a task. The empty execution still completes on that deployment. Do not recreate the function.

## Grade the work before you call it done

Every row must be A- or better. If one cell is lower, you are not done.

| Area | A- means |
| --- | --- |
| Member UX | After Send Private Feedback, the only confirmation is the plain sentence from `feedbackSavedForOrganizers`. No GitHub, no issue number, no “copied to clipboard”, no raw exception. Praise still thanks them for encouragement. A missing reply email still says a reply needs a valid email. |
| Organizer UX | One new issue in `neiljaywarner/belong_feedback`. Title starts with `[preview]`. Label `preview` is present. Body has **Source environment** `preview` and the preview host. Production would be unprefixed and would not have that label. Do not file a second issue for the same Firestore id. |
| Technical | Preview channel only. Function returned a real issue number and patched `githubIssueCreated`, `githubIssueNumber`, and `githubIssueUrl`. No secret in git, logs, or the issue body. Client build has no `FEEDBACK_GITHUB_PAT` dart-define. |
| Code health | No drive-by refactor. The only code or doc edit allowed in this pass is the README sentence below, plus a status line. Tests you run stay green. |
| Usability of the check | A person can repeat it from this file without guessing a host, a command, or which toast is correct. |

## Steps

1. On the Mac, `git fetch origin main` and use a **new** worktree of `origin/main`. Do not touch a dirty checkout. Do not print the worktree path if it contains a home directory; say “fresh worktree of main”.
2. `firebase login:list`. If nobody is logged in, stop and ask for a Firebase CLI login. Do not start a login that waits forever. Do not deploy.
3. From that worktree, run only:

   ```bash
   dart run tool/deploy_release.dart --version feedback-659
   ```

   Confirm the log does not say it published `https://belongonthespectrum.web.app`. Save the preview URL. It looks like `https://belongonthespectrum--feedback-659-<hash>.web.app`.
4. Open that HTTPS URL in Chrome. A fake `*.web.app` host on port 8080 is not a preview. Chrome will show `ERR_SSL_PROTOCOL_ERROR` for that. Ignore it.
5. Sign in with an account that already works on Belong. Do not create a user. Do not hunt through CI logs for a password. If you cannot sign in, stop. The preview URL is still useful; say that sign-in blocked the note.
6. Open Vote & Feedback. Pick Idea / Tweak or Bug / Confusing. Type a short synthetic note such as “Preview stamp check. Please close.” Leave the email empty unless you are using a synthetic address like `member@belongonthespectrum.com`. Do not use a real person’s address. Send.
7. Pass: the toast is exactly `Thanks! Your note was saved for organizers. We can only reply if you add a valid email.` Fail: the toast mentions GitHub, an issue number, or a clipboard.
8. In `neiljaywarner/belong_feedback`, find the new issue. Pass only if the title starts with `[preview]`, the label `preview` exists, and the body contains `Source environment` with `preview` and the preview host. Then close that issue with a one-line comment that it was a stamp check. Do not paste the member note or any email into the pull request or this plan.
9. If the toast was the plain success sentence but no issue appeared, read the function execution in Appwrite. Report only the status code and the `error` or `reason` string. If the reason is `github credential is not configured`, the PAT secret is empty. Stop. Do not invent a token.
10. Fix the README. In `appwrite/functions/feedback-forward/README.md`, replace the sentence that says the toast should name `belong_feedback#N` with: the member toast stays the plain saved-for-organizers sentence and does not name GitHub; organizers see `[preview]`, the `preview` label, and the source line on the private issue. Do not change Dart copy.
11. Update `docs/archive/feedback_bridge_status.md`. That note is stale: it says the secret names are missing, and they are not. Replace the “Not done” section with the preview URL, whether an issue was filed, and the issue number if there is one. No note text. No emails. Do not create a second status file at the repo root.
12. Run `npm test` in `appwrite/functions/feedback-forward` and `flutter test test/features/feedback/feedback_drawing_test.dart test/features/feedback/member_feedback_bridge_test.dart test/features/feedback/feedback_source_stamp_test.dart`. All of those must pass. Do not run the whole suite unless one of these fails for a reason you caused.

## Stop without “fixing” these

- Do not show `belong_feedback#N` in the toast. That would fail the #490 tests and the member UX grade.
- Do not remove the silent clipboard write in this pass. It is a known smell (the toast no longer says the note was copied). Leave it unless the human asks.
- Do not open Firestore updates to the client. The function’s service account is what patches the GitHub fields.
- Do not log the ID token, the PAT, or the service-account key.
- Do not deploy hosting to the live site to “see it in production”.

## Done when

The preview URL loads this `main`, a private note shows the plain toast, and one `[preview]` issue exists in the private repo. The README no longer tells the next person to expect an issue number in the toast. The grade table above is all A- or better.
