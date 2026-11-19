# Maestro UI tests

Maestro drives a running app. For this repo that is either a local Flutter web server or a hosted site, depending on the `url:` line at the top of the flow.

Web flows live in [`.maestro/web/`](https://github.com/neiljaywarner/refuge/tree/main/.maestro/web). Android flows live in [`.maestro/`](https://github.com/neiljaywarner/refuge/tree/main/.maestro) and are a different suite (`maestro test .maestro` does not pick up `web/`).

Patrol cannot open an arbitrary URL. See [Patrol UI tests](Patrol-UI-Tests) for the local-build runner.

## Install

Maestro 2.11.0 is the CLI these flows were last run with. It started on OpenJDK 21 with Google Chrome. An older note in this repo mentioned Java 17; 2.11.0 did not need a separate 17 install.

```bash
# Pin the CLI. The install script honors MAESTRO_VERSION.
export MAESTRO_VERSION=2.11.0
curl -fsSL "https://get.maestro.mobile.dev" | bash
maestro --version
```

If the script reports a corrupt zip, download `maestro.zip` from the [cli-2.11.0 release](https://github.com/mobile-dev-inc/maestro/releases/tag/cli-2.11.0) and check it against `checksums_sha256.txt` in that release.

Chrome has to be on `PATH` (`google-chrome`). Web support is still marked beta by the CLI.

## Local web server versus a hosted site

| Target | How | Writes data? |
| --- | --- | --- |
| Local web server | `url: http://127.0.0.1:8095` in the committed web flows | Only if the flow submits, and only to whatever backend that `flutter run` was started with |
| Dev hosting | `url: https://dev-belongonthespectrum.web.app` in `dev_hosting_smoke.yaml` | That flow does not sign in, post, or vote |
| Public site | Not the default of any committed flow. Copy a flow and change `url:` to `https://belongonthespectrum.web.app` | Do not point a flow that posts, votes, or registers at the public site |

Start the local server the committed flows expect:

```bash
flutter run -d web-server --release --web-port 8095 --web-hostname 127.0.0.1
```

A plain `flutter run` uses `FLAVOR=dev` (see `lib/main.dart`). The default post repository still talks to Firestore. For a run that must not write reflections, pass `--dart-define=BACKEND=local`. That flag selects only the post repository. Account creation and sign-in still use `authRepositoryProvider`, which is Firebase Auth, so a flow that registers still writes an account.

### What is deployed

Maestro reads whatever is already hosted. It does not deploy.

Check `https://belongonthespectrum.web.app/version.json` and `https://dev-belongonthespectrum.web.app/version.json`. Each file has `git_sha`, `version`, `build_number`, `flavor`, and `build_time_utc`.

On 2026-11-14:

- Public `version.json` was flavor `prod`, version `0.9.9`, build `9990`, git `dc99aaa56e3c9bcec4368e161f1149490bed7376`, built `2026-11-04T05:53:43.552Z`. That commit is behind `main`.
- Dev `version.json` was flavor `dev`, release tag `ci-1620412`, git `1620412668c4594df42525d7204c9ca0774a10be`, built `2026-11-14T16:21:08.576Z`. That matched `main` at the start of that check. Later commits on `main` (group-call analytics and profile reload) were not in that dev build yet.

The public site and the dev site both stop a signed-out visit on the sign-in wall (#601). There is no guest feed. `Join call` is not on that screen. The group-call preview is a compile flag (`STREAM_VIDEO_PREVIEW`) plus a signed-in member, and production deploys leave it off. See [Stream video preview](Stream-Video-Preview).

## Run the web suite

```bash
maestro -p web test --headless .maestro/web
```

Phone-sized headless Chrome:

```bash
maestro -p web test --headless --screen-size 390x844 .maestro/web
```

`--screen-size` applies to the headless browser. Omit `--headless` when you need to watch the window. `--debug-output` keeps the hierarchy and screenshots from a failed step.

A flow tagged `known-gap` or `live-dev` is skipped by [`.maestro/web/config.yaml`](https://github.com/neiljaywarner/refuge/blob/main/.maestro/web/config.yaml). Passing a flow path still runs that file. The direct-message and mention flows are included in the directory run and need credentials (below).

Unsigned launch now stops at the sign-in wall, so the home flows in this folder fail before they can vote, post, or open Spaces. That is #601, tracked for Maestro in [#771](https://github.com/neiljaywarner/refuge/issues/771). Re-run them against a local server only after a signed-in session, or use Patrol's read-only harness for the home shell.

Some painted sentences on the wall are missing from the web accessibility tree, so Maestro cannot see them even though they are on screen ([#971](https://github.com/neiljaywarner/refuge/issues/971)). `dev_hosting_smoke.yaml` waits for the exact text `Belong`, which is not a node in that tree, and fails on current dev hosting.

## Credentials

Account addresses and the shared password are not stored in this repo. The direct-message, mention, and account flows reference `${GROKBOT1_EMAIL}`, `${GROKBOT2_EMAIL}`, and `${GROKBOT_PASSWORD}`. `maestro test` does not read a gitignored `.maestro/.env.local`, and `.maestro/web/config.yaml` does not supply those values. Maestro 2.11.0 accepts them on the command (`maestro test --help` shows `-e` / `--env`).

```bash
maestro -p web test --headless \
  -e GROKBOT1_EMAIL=member@belongonthespectrum.com \
  -e GROKBOT2_EMAIL=tester@example.com \
  -e GROKBOT_PASSWORD='the shared password' \
  .maestro/web/grokbot_dm_web.yaml
```

Do not invent accounts on the public site to satisfy those flows. The password stays out of the repo.

## Flows

| Flow | What it checks | Safe on the public site? |
| --- | --- | --- |
| `calm_tech_walkthrough_web.yaml` | Read-only theme and navigation walkthrough. Needs the home shell. | No home shell while signed out. Do not treat a wall failure as a missing theme. |
| `directory_web.yaml` | Read-only spaces list, member directory, events, guidelines. | Same. `spaces_tab` is not on the wall. |
| `feature_voting_web.yaml` | Vote & Feedback opens. The vote control is tapped only while it says "Vote for Native iOS App Store and Google Play Apps", then the flow expects "Remove vote". It does not tap again to clear the vote. | No. A first run casts a real vote if it gets past the wall. |
| `feedback_drawing_web.yaml` | Share Feedback accepts the note "hi from bot", a scribble, and a praise submit. | No. |
| `space_post_web.yaml` | A reflection published in General Chat appears in that space. | No. |
| `attach_media_animated_text_web.yaml` | Attach-media sheet can request animated text. | No publish, but it needs the composer, which is behind the wall. |
| `feed_sort_every_option_web.yaml` | Every feed sort. Tagged `known-gap` after the members-only wall. | Excluded from the suite. |
| `grokbot_accounts_web.yaml` | Create or sign in two accounts from the environment. | No. Needs the env vars. Do not run this against production. |
| `grokbot_dm_web.yaml` | A signed-in member can be picked and a direct message shows up in the recipient's bell. | No. Needs the env vars. |
| `grokbot_mention_web.yaml` | An `@handle` on a reflection shows up in the mentioned member's bell. | No. Needs the env vars. |
| `dev_hosting_smoke.yaml` | Opens dev hosting and checks it is not "Site Not Found". Tagged `live-dev`. | Dev URL only. Does not sign in, post, or vote. Currently fails on the exact text `Belong` (#971). |
| `account_delete_and_return.yaml` | Opt-in dev flow in the Android folder, tagged `known-gap`. A synthetic member deletes and types `RESTORE`. | No. |

## Recordings

Maestro's `record` command does not render web flows yet. These videos are the browser window while `maestro -p web test` runs the flow.

* [Feature voting](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/feature_voting_web.mp4)
* [Feedback drawing ("hi from bot")](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/feedback_drawing_web.mp4)
* [Space post](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/space_post_web.mp4)

The direct-message and mention flows also pass when credentials are present. Their recordings are not published here because the sign-in form would show the account address. The stills below are from after sign-in and show the public handle only.

* [Recipient in the message picker](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/grokbot1_dm_recipient_search.png)
* [Bell after a direct message](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/grokbot2_bell_after_dm.png)
* [Mention post](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/grokbot1_mention_post.png)
* [Bell after an @-mention](https://github.com/neiljaywarner/refuge/blob/main/docs/maestro/web/grokbot2_bell_after_mention.png)

## Product behavior these flows lock in

Vote & Feedback stays on screen at a phone width, and the contrast control no longer sits on top of that chip, so a real pointer click opens the sheet.

The message picker lists signed-in members from `users/{uid}` (public name, plus-tag handle, and tagline). The email address is never written. Sample members remain in the list.

The notification bell prepends cross-account items ahead of the seeded notices. A direct message and an `@handle` mention are stored in `member_notifications` when Firestore rules allow it. Until that collection is deployed, the same notice is stored on the author's own `users/{uid}` document. Direct-message text is left off that public fallback; the bell still reads "sent you a direct message". Mention text is kept because the post is public.

Related issues: [#441](https://github.com/neiljaywarner/refuge/issues/441), [#442](https://github.com/neiljaywarner/refuge/issues/442), and [#771](https://github.com/neiljaywarner/refuge/issues/771).
