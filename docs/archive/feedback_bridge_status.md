# Feedback bridge status

Updated Sunday, Nov 1, 2026, 9:50 PM America/Chicago.

Issue [#659](https://github.com/neiljaywarner/refuge/issues/659). Pull request [#716](https://github.com/neiljaywarner/refuge/pull/716) is merged to `main`. Finish checklist: [feedback-bridge-finish.md](../plans/feedback-bridge-finish.md) (PR [#785](https://github.com/neiljaywarner/refuge/pull/785)).

## Done (code and backend)

- Appwrite function `feedback-forward` is deployed. Runtime Node 22. Entrypoint `src/main.js`. Deployment `6ae61ffc9bbd12cf1006` status `ready`.
- Live smoke: empty body → `400` `{"error":"missing feedback"}`; bad Firebase ID token → `401` `{"error":"unauthorized"}`.
- Function secret **names** are configured on Appwrite: `FEEDBACK_GITHUB_PAT` and `FIREBASE_SERVICE_ACCOUNT_JSON`. Values are not stored in git and must not be printed.
- Flutter writes Firestore first, stamps `sourceEnvironment` / `sourceHost`, then calls the function with the member’s Firebase ID token. Member confirmation copy is plain (`feedbackSavedForOrganizers`); it does not show `belong_feedback#N` (issue #490).
- `appwrite/functions/feedback-forward/README.md` documents the plain toast and organizer-side preview stamp (cloud doc fix, PR #785).
- Tests (Sunday Nov 1, cloud agent): `npm test` in `appwrite/functions/feedback-forward` (15/15 pass); `flutter test` on `feedback_drawing_test.dart`, `member_feedback_bridge_test.dart`, `feedback_source_stamp_test.dart` (all pass).

## Not done (requires Mac + signed-in member)

| Check | Status |
| --- | --- |
| Firebase Hosting preview URL for `--version feedback-659` | **Not deployed** — Linux cloud agent Firebase CLI has no logged-in user |
| End-to-end private note on real preview host | **Not run** — needs preview URL and Belong sign-in |
| Confirmed `[preview]` issue in `neiljaywarner/belong_feedback` from a real submit | **Not confirmed** |

When the Mac finish pass completes, fill in:

- Preview URL: _(pending)_
- Issue filed from E2E: yes / no
- Issue number (if yes): _(pending)_

## Next (Mac only)

Follow [feedback-bridge-finish.md](../plans/feedback-bridge-finish.md) steps 1–9 on a Darwin checkout: preview deploy without `--prod`, sign in, send one synthetic private note, verify plain toast and one preview-stamped GitHub issue. Then update the table above with URL and issue number (no member note text, no emails).

If the toast succeeds but no issue appears, inspect Appwrite executions for `feedback-forward` and record only HTTP status and the `error` / `reason` string (for example `github credential is not configured` if the PAT is empty).
