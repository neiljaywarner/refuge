# Maestro UI tests

Web flows live in [`.maestro/web/`](https://github.com/neiljaywarner/refuge/tree/main/.maestro/web). They drive the Flutter web release build at `http://127.0.0.1:8095`.

Account addresses and the shared password are not stored in this repo. The direct-message and mention flows read `GROKBOT1_EMAIL`, `GROKBOT2_EMAIL`, and `GROKBOT_PASSWORD` from the environment (a gitignored `.maestro/.env.local` on a developer machine).

## Run the web suite

```bash
flutter run -d web-server --release --web-port 8095 --web-hostname 127.0.0.1
maestro -p web test --headless .maestro/web
```

A flow tagged `known-gap` is skipped by [`.maestro/web/config.yaml`](https://github.com/neiljaywarner/refuge/blob/main/.maestro/web/config.yaml). The direct-message and mention flows are included.

## Flows

| Flow | What it checks |
| --- | --- |
| `feature_voting_web.yaml` | Vote & Feedback opens, a feature vote can be cast, and the vote can be removed. |
| `feedback_drawing_web.yaml` | Share Feedback accepts the note “hi from bot”, a scribble on the screenshot, and a praise submit. |
| `space_post_web.yaml` | A reflection published in General Chat appears in that space. |
| `grokbot_dm_web.yaml` | A signed-in member can be picked and a direct message shows up in the recipient’s bell. |
| `grokbot_mention_web.yaml` | An `@handle` on a reflection shows up in the mentioned member’s bell. |
| `calm_tech_walkthrough_web.yaml` | Read-only theme and navigation walkthrough. |

## Recordings

Maestro’s `record` command does not render web flows yet. These videos are the browser window while `maestro -p web test` runs the flow.

* [Feature voting](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/feature_voting_web.mp4)
* [Feedback drawing (“hi from bot”)](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/feedback_drawing_web.mp4)
* [Space post](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/space_post_web.mp4)

The direct-message and mention flows also pass. Their recordings are not published here because the sign-in form would show the account address. The stills below are from after sign-in and show the public handle only.

* [Recipient in the message picker](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/grokbot1_dm_recipient_search.png)
* [Bell after a direct message](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/grokbot2_bell_after_dm.png)
* [Mention post](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/grokbot1_mention_post.png)
* [Bell after an @-mention](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/grokbot2_bell_after_mention.png)

## Product behavior these flows lock in

Vote & Feedback stays on screen at a phone width, and the contrast control no longer sits on top of that chip, so a real pointer click opens the sheet.

The message picker lists signed-in members from `users/{uid}` (public name, plus-tag handle, and tagline). The email address is never written. Sample members remain in the list.

The notification bell prepends cross-account items ahead of the seeded notices. A direct message and an `@handle` mention are stored in `member_notifications` when Firestore rules allow it. Until that collection is deployed, the same notice is stored on the author’s own `users/{uid}` document. Direct-message text is left off that public fallback; the bell still reads “sent you a direct message”. Mention text is kept because the post is public.

Related issues: [#441](https://github.com/neiljaywarner/refuge/issues/441) and [#442](https://github.com/neiljaywarner/refuge/issues/442).
