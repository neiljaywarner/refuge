# Preview group video call (GetStream)

Preview-only group calls for [#872](https://github.com/neiljaywarner/refuge/issues/872), the first slice of [#871](https://github.com/neiljaywarner/refuge/issues/871). This is not a production rollout. `tool/deploy_release.dart` does not turn the call on.

The call is for about ten people for about an hour. Members join from the app, start muted with the camera off, and can unmute, turn the camera on, or leave. The first person in the room can end the call or remove someone. Nothing in this client cuts the room off at forty minutes.

## What stays out of git

Never commit `STREAM_API_SECRET`, `STREAM_API_KEY`, a user token, or a `.env` / `.secret.local` file. The public repository stays secret-free.

| Name | Where it lives | In the Flutter binary? |
| --- | --- | --- |
| `STREAM_API_SECRET` | Firebase secret on `mintStreamCallToken` only | No |
| `STREAM_API_KEY` | Same Firebase secret. The function returns it to a signed-in member. | No |
| `STREAM_APP_ID` | Optional environment variable, only if the Stream dashboard shows an id that is not the API key | No |
| `STREAM_TOKEN_ENDPOINT` | `--dart-define` for the preview build. This is the function URL, not a secret. | Yes, the URL only |
| `STREAM_VIDEO_PREVIEW` | `--dart-define=STREAM_VIDEO_PREVIEW=true` on the preview build | The flag only |

The secret is not a dart-define. The phone and the web app cannot mint tokens. The direct-message functions `dm-push` and `dm-mirror` are unchanged, and this route is not added to them. The email function `calmDirectMessageEmail` does not receive the Stream secrets.

## Configure the function

From a shell, after `firebase login`. The CLI prompts for each value. Nothing is written into the repo.

```bash
firebase functions:secrets:set STREAM_API_KEY --project belongonthespectrum
firebase functions:secrets:set STREAM_API_SECRET --project belongonthespectrum
firebase deploy --only functions:mintStreamCallToken --project belongonthespectrum
```

The function URL looks like:

`https://us-central1-belongonthespectrum.cloudfunctions.net/mintStreamCallToken`

Confirm the URL in the Firebase console after deploy. Put that URL in `STREAM_TOKEN_ENDPOINT` for the preview build.

Local emulator only: create `functions/.secret.local` (gitignored) with `STREAM_API_KEY` and `STREAM_API_SECRET`, then run the functions emulator. Point `STREAM_TOKEN_ENDPOINT` at `http://127.0.0.1:5001/belongonthespectrum/us-central1/mintStreamCallToken`. Loopback HTTP is accepted. Any other `http://` URL is ignored.

## Build a preview channel

The join button is shown only when all three are true:

1. The binary was built with `STREAM_VIDEO_PREVIEW=true`.
2. Preview features are on (Remote Config `organizer_preview_mode_enabled`, or the profile switch).
3. The member is signed in with Firebase. Guest mode cannot join.

This command updates the long-lived dev site and, with `--channel`, a preview channel. Leave the variables unset for an ordinary dev deploy.

```bash
export STREAM_VIDEO_PREVIEW=true
export STREAM_TOKEN_ENDPOINT='https://us-central1-belongonthespectrum.cloudfunctions.net/mintStreamCallToken'
dart run tool/deploy_dev_web.dart --version stream-video-872 --channel stream-video
```

The deploy log says whether the endpoint was set. It does not print the endpoint or any secret.

A channel-only build, which does not run `deploy_release.dart` and does not publish production:

```bash
flutter build web -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=ENABLE_SERVERPOD=false \
  --dart-define=STREAM_VIDEO_PREVIEW=true \
  --dart-define=STREAM_TOKEN_ENDPOINT="$STREAM_TOKEN_ENDPOINT"
firebase hosting:channel:deploy stream-video \
  --config firebase.dev.json \
  --project belongonthespectrum \
  --expires 14d
```

Do not pass `STREAM_API_KEY` or `STREAM_API_SECRET` to Flutter.

Share a link with the call name, for example `https://<preview-host>/?call=monthly`. Signed-in members on that preview open **Join call**, keep the same name, and enter with the microphone and camera off.

## Cost note

Stream measures video in participant-minutes. Ten people for one hour is about 600 participant-minutes. Stream's comparison with Zoom describes a monthly free allowance on the order of 66,000 participant-minutes and about $0.003 per participant-minute after that ([Zoom Video SDK vs. Stream Video](https://getstream.io/blog/zoom-video-sdk-comparison/)). Confirm the current plan in the Stream dashboard before treating that as a bill. This is the cost context for skipping a Zoom plan of about $18 a month. It is not a promise about a future invoice.

## What this slice does not do

Production hosting, a waiting room, screen share, a private invite list, or a 50-person broadcast. Any signed-in member who knows the call name can join the preview room.
