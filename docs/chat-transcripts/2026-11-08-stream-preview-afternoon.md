# Sanitized notes — 8 Nov 2026 afternoon (stream preview)

This is a temporary working note for later cleanup. It is not product documentation. Sensitive values were left out on purpose: no passwords, API secrets, tokens, email addresses, vault identifiers, home-directory paths, billing-account IDs, or Stream dashboard organization or app IDs.

Times are America/Chicago.

## What the owner asked

After the preview work was already in motion, the owner asked:

- What is next for the video test, how far along it is, the next three major milestones, the next seven mini milestones, how good the automated tests and self-healing verification loop are, and the ETA with and without their help.
- Try the Firebase connector and the Firebase CLI on the Mac (which was expected to already be logged in), and ask them if it was not.
- Close the self-healing loop with at least two unit-test layers plus gray-box and black-box checks.
- Use Supabase if needed.
- After the first live `Connected` screenshot, write a specific plan with many milestones and the next three actions so a less expensive model can execute and verify each slice, then push the plan and later progress as atomic commits. Transient notes such as this transcript and the plan are allowed. Private information is not.

## What happened

- Stream API values were stored earlier in a gitignored local env file on the Mac and sourced from the shell config. The same file was copied to the assistant computer without being opened in chat. Values were never written to a public repository.
- The Firebase connector was not signed in. The Mac Firebase CLI was already logged in and listed no Cloud Functions in the Belong project, which matches the production mint URL still returning 404.
- A local mint server on the assistant computer was repaired so it accepts an optional `export ` prefix when reading the env file. A dummy localhost identity then received a real token-shaped response with no secret fields.
- A verification script with two unit layers, a gray-box local HTTP pass, and black-box checks of the public Firebase and Supabase URLs passed 8 of 8 checks.
- A Supabase edge function named `mint-stream-call-token` was deployed. Unsigned calls return 401 and ask for sign-in. Stream secrets are not stored on that function yet, because the connector has no secrets tool and the Supabase CLI needs a login.
- The emulator opened the DEV sign-in screen. There is no anonymous or example-account shortcut. Vault browser fill cannot type into the native Android fields, so sign-in used the Mac QA environment variable *names* `BELONG_AUTH_EMAIL` and `BELONG_AUTH_PASSWORD` without printing the values.
- After skipping the first-visit profile screen and turning on Experimental Preview Features, the home banner showed Join call. The lobby default name was `monthly`. Joining produced an in-call screen titled `Call monthly` with status `Connected`, display name `Fellowship Member`, microphone off, camera off, and host controls. That session was left connected around 3:37 PM CT.
- Screenshots of the home banner, lobby, and connected call were kept. A welcome screenshot that showed an email address must not be committed.

## Open items at 3:41 PM CT

- Add Stream secrets to the deployed Supabase function without printing them, then repeat unsigned and signed-in mint checks.
- Confirm the emulator is still connected to `monthly`, then pursue a second participant.
- Rebuild or install guest-join from pull request 905 only after reviewing its higher-risk notes.
- Deploy to the Belong dev site only after those checks; never to production.
- Ask the owner to test only after a reviewed recording of the assistant's own test.

## Related links

- Plan: `docs/superpowers/plans/2026-11-08-stream-video-preview-verification.md`
- [Pull request 902](https://github.com/neiljaywarner/refuge/pull/902)
- [Pull request 905](https://github.com/neiljaywarner/refuge/pull/905)
- Epic [issue 871](https://github.com/neiljaywarner/refuge/issues/871) and preview slice [issue 872](https://github.com/neiljaywarner/refuge/issues/872)
- Scheduling (out of scope): [issue 903](https://github.com/neiljaywarner/refuge/issues/903)
