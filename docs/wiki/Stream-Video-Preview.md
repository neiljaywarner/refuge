# Preview group video call (GetStream)

Preview-only group calls for [#872](https://github.com/neiljaywarner/refuge/issues/872) and guest links for [#904](https://github.com/neiljaywarner/refuge/issues/904). Both sit under [#871](https://github.com/neiljaywarner/refuge/issues/871). This is not a production rollout. `tool/deploy_release.dart` does not turn the call on, and this page does not deploy anything.

The call is for about ten people for about an hour. People start muted with the camera off. They can unmute, turn the camera on, or leave. Nothing in this client cuts the room off at forty minutes.

## Status 2026-11-09 ~1 AM CT

Progress note for [#908](https://github.com/neiljaywarner/refuge/issues/908#issuecomment-6734212132). This is a preview check, not a production rollout.

The dev preview site (dev-belongonthespectrum.web.app) is built from `69ff740` with `STREAM_VIDEO_PREVIEW=true`. It points at the public preview mint, a Supabase Edge Function that handles the guest actions. Invites are stored hashed in a private schema. The Stream secret stays on the server. Production is not affected.

Verified so far:

- A guest in Mac Chromium joined a call hosted by an emulator APK.
- Then two real Pixel 9a phones: a signed-in APK as host, and a signed-out guest in Chrome on the dev site.
- The guest skips Sign in.
- The guest gets only Microphone, Camera, and Leave. The host gets Remove and End call.
- Two-way live video works in both directions.
- Chrome on a real Pixel renders the call. An earlier blank WebGL page was emulator-only.

Audio is not proven. In a real two-phone call the second person could not hear the host. The mics looked unmuted, and nobody has confirmed that sound arrives. Next check: Mac Chrome with a fake-audio WAV file, and a Pixel running the APK. Play a tone each way, measure WebRTC inbound `audioLevel` and `totalAudioEnergy`, record the Pixel's output (for example with scrcpy), and toggle mute at least three times. Suspects: Android sending call audio to the earpiece instead of the speaker; unmute not publishing an audio track after a muted join; Chrome autoplay blocking remote audio; `RECORD_AUDIO` permission or call volume.

Not yet run: the website on both Pixels, and the APK on both Pixels.

TODO: Stream Video 1.7.2 pulls in `system_info2` 4.2.0, which breaks `dart2js` on web. The dev site was built with a temporary local `dependency_overrides` pin of `system_info2` 4.1.0. That pin is not in this repo.

## Invite someone who is not signed in

This is the Zoom-style door. A signed-in member makes a link. Someone else opens that link, types a name, and joins. They do not create a Belong account.

How a member makes the link:

1. Sign in on a preview build that has the group call turned on.
2. Open **Join call** and keep the call name you want, such as `monthly`.
3. Tap **Create guest link**.
4. Select the link and send it to the people you want in the room.

On the phone, that link is `https://dev-belongonthespectrum.web.app/?call=…&invite=…` (or the matching non-production site). It is not a `file://` link. Opening it on a preview build shows **Join as a guest** without an account. A production build still shows sign-in. A call name with no invite token still shows sign-in.

What the link does:

| Question | Answer |
| --- | --- |
| How long does it last? | About 24 hours. The member who made it can tap **Revoke link** sooner. |
| How many guests? | At most 10 guests in that call at the same time. This is not a lifetime total. When someone leaves, or their short pass runs out, the seat opens. |
| What can a guest do? | Join, turn their own microphone and camera on or off, and leave. They start muted, with the camera off. |
| What can a guest not do? | End the call for everyone, or remove another person. Those buttons are only for a signed-in host. |
| Is the call name enough? | No. A person who only knows the name, and is not signed in, stays on the sign-in screen. The link's invite token is required. |
| What if the host has not opened the room yet? | The guest can still join. The room is created for the member who made the link, so the guest does not become the host. |

Treat the link like a Zoom link. Anyone who has it can try to join until it expires or is revoked. Do not post it in a public place.

A guest who is already inside keeps their seat for about 30 minutes at a time. The app refreshes that pass while they stay. If they close the tab without leaving, the seat stays taken until that pass runs out. Revoking the link stops new people and stops a refresh. It does not instantly hang up someone who is already connected. Their pass simply is not renewed.

The app asks again if someone tries to join too many times on one link (about 20 tries in 10 minutes). A name has to be short. It cannot be an email address, a web link, or a name with odd hidden characters.

Scheduled meetings are [#903](https://github.com/neiljaywarner/refuge/issues/903). When that work starts, it should reuse these invite rules: the same kind of token, the same expiry and revoke, the same 10-guest cap, and the same rule that guests cannot host. Do not invent a second way in.

A waiting room, where the host admits each guest one by one, is later hardening. It is not part of this preview.

## What stays out of git

Never commit `STREAM_API_SECRET`, `STREAM_API_KEY`, a user token, an invite token, or a `.env` / `.secret.local` file. The public repository stays secret-free. Tests use fakes such as `unit-test-stream-secret`.

| Name | Where it lives | In the Flutter binary? |
| --- | --- | --- |
| `STREAM_API_SECRET` | Firebase secret on `mintStreamCallToken` only | No |
| `STREAM_API_KEY` | Same Firebase secret. The function returns it to whoever may join. | No |
| `STREAM_APP_ID` | Optional environment variable, only if the Stream dashboard shows an id that is not the API key | No |
| `STREAM_TOKEN_ENDPOINT` | `--dart-define` for the preview build. This is the function URL, not a secret. | Yes, the URL only |
| `STREAM_VIDEO_PREVIEW` | `--dart-define=STREAM_VIDEO_PREVIEW=true` on the preview build | The flag only |
| Invite token | Returned once to the member who creates the link. Stored in Firestore only as a hash. | No |

The secret is not a dart-define. The phone and the web app cannot mint tokens. Guest join uses the same function. There is no third function and no Appwrite route for this. The direct-message functions `dm-push` and `dm-mirror` are unchanged. The email function `calmDirectMessageEmail` does not receive the Stream secrets.

## Configure the function

From a shell, after `firebase login`. The CLI prompts for each value. Nothing is written into the repo. Do this only when an operator is ready. This document does not run the deploy.

```bash
firebase functions:secrets:set STREAM_API_KEY --project belongonthespectrum
firebase functions:secrets:set STREAM_API_SECRET --project belongonthespectrum
firebase deploy --only functions:mintStreamCallToken --project belongonthespectrum
```

The function URL looks like:

`https://us-central1-belongonthespectrum.cloudfunctions.net/mintStreamCallToken`

Confirm the URL in the Firebase console after deploy. Put that URL in `STREAM_TOKEN_ENDPOINT` for the preview build.

Guest create, revoke, join, and release are actions on this same function. Invite rows live in Firestore where clients cannot list or read them (`stream_call_invites` and `stream_call_guests` in `firestore.rules`). Ship those rules with a later rules deploy. Until then, an unmatched path is already denied.

Local emulator only: create `functions/.secret.local` (gitignored) with `STREAM_API_KEY` and `STREAM_API_SECRET`, then run the functions emulator. Point `STREAM_TOKEN_ENDPOINT` at `http://127.0.0.1:5001/belongonthespectrum/us-central1/mintStreamCallToken`. Loopback HTTP is accepted. Any other `http://` URL is ignored.

## Build a preview channel

The signed-in join button is shown only when all three are true:

1. The binary was built with `STREAM_VIDEO_PREVIEW=true`.
2. Preview features are on (Remote Config `organizer_preview_mode_enabled`, or the profile switch).
3. The member is signed in with Firebase.

A guest link is a separate door. It still needs the preview compile flag. It does not need a Belong account, and it does not use the in-app preview switch, because that person is not signed in. A production binary without the flag does not show the name page, even if someone pastes a link.

This command updates the long-lived dev site and, with `--channel`, a preview channel. Leave the variables unset for an ordinary dev deploy. Run it only after the preview looks safe. Do not point it at production.

```bash
export STREAM_VIDEO_PREVIEW=true
export STREAM_TOKEN_ENDPOINT='https://us-central1-belongonthespectrum.cloudfunctions.net/mintStreamCallToken'
dart run tool/deploy_dev_web.dart --version stream-video-904 --channel stream-video
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

Signed-in members can still open `https://<preview-host>/?call=monthly`, tap **Join call**, and enter with the microphone and camera off. That path requires Firebase sign-in. It is not the guest path.

An ad hoc test without signup:

1. A signed-in member creates a guest link for the call name.
2. Open that full link in a private window, or another browser, where you are not signed in.
3. Type a short name and tap **Join call**.
4. You should enter muted, with the camera off, and you should not see **End call for everyone** or **Remove someone**.

## In the call

The room opens with the microphone and camera off, and they stay off until that person taps the button. Stream's default call type would turn the camera on by itself; this preview turns it back off. The camera button shows the live camera, not the state from the moment of joining. The controls are:

| Control | Who sees it | What it does |
| --- | --- | --- |
| Microphone | Everyone in the room | Turns that person's microphone on or off. |
| Camera | Everyone in the room | Turns that person's camera on or off. |
| Leave call | Everyone in the room | Steps this person out. The room stays open for everyone else. |
| Remove someone | A signed-in member who created the room, or a Stream host or admin | Asks for a name, then asks again before removing them. A member can rejoin with the call name. A guest needs a link that still works. |
| End call for everyone | The same host | Asks before disconnecting the room. |

The first person in the room is not automatically the host. A guest is never the host, even if they arrive first. The function creates the room for the member who made the link and adds the guest as a call member, not as a host, admin, or moderator.

There is no 40-minute cutoff in this client. A member's user token lasts three hours (`STREAM_TOKEN_TTL_SECONDS` in `functions/src/stream_token.js`), so a one-hour call can start late. A guest's token lasts about 30 minutes and is refreshed while they stay, still scoped to that one call. If Stream asks for a fresh token, a member's app calls `mintStreamCallToken` again with the Firebase ID token. A guest's app calls it again with the invite token. The API secret still stays on the function.

Stream describes guests as temporary named users. Tokens are minted on the server, with an expiry. The function adds the guest to the call as `call_member`. Stream rejects the hyphenated name `call-member`. That membership is not host or admin, so a guest cannot end the call or remove people. `guest` is not a built-in call role. Call tokens add access to the named call. They do not, by themselves, ban every other call. The invite token is what decides who receives a Stream token at all.

Before a real test, confirm in the Stream dashboard that the `user` and `call_member` roles on the `default` call type cannot end the call or remove people, and that `host` and `admin` can. This function does not change those grants.

A name that is empty or contains `@` is shown as "Fellow Member" for a signed-in member. A guest must type an acceptable name or the join stops. A call error that looks like a token, a secret, or a long SDK dump is replaced with "The call could not connect." The response body from a failed mint is not shown.

## When the button or the call does not come up

The signed-in join button needs all three gates. One closed gate is enough to hide it. A guest link is judged separately.

| What you see | What to check |
| --- | --- |
| No join button on the home screen | The binary was built without `STREAM_VIDEO_PREVIEW=true`, preview features are off, or the person is not signed in. Browsing without an account does not show this button. |
| The sign-in screen, and you only know the call name | That is expected. The call name alone does not let a guest in. Ask a signed-in member for a guest link. |
| The "Join as a guest" name page | The preview flag is on and the address has a real invite token. Type a short name. You do not need an account. |
| The lobby says this preview has no token address | `STREAM_TOKEN_ENDPOINT` was unset, or it was not an `https://` URL. Loopback `http://127.0.0.1` and `http://localhost` are the emulator exception. A URL with a username or password is ignored. |
| "A Firebase sign-in is required to join by call name." | The member path had no ID token, or the function returned 401. Use a guest link if you are not signed in. |
| "This invite link is not valid." | The token is missing, too short, or not one this function created. |
| "This invite link has expired or was revoked." | It is older than about 24 hours, or the member tapped **Revoke link**. Make a new link. |
| "This call already has 10 guests." | Ten guests still hold seats. Wait until someone leaves, or until a seat's 30-minute pass runs out. |
| "Too many join attempts." | That one link was tried too often. Wait a few minutes. |
| "Use a short name. Leave out email addresses and web links." | The name was empty, too long, an email, a web link, or it contained control characters. |
| "Video calling is not configured on this preview yet." | `mintStreamCallToken` has no `STREAM_API_KEY` or `STREAM_API_SECRET` (HTTP 503). |
| "The call could not be prepared." | The function could not create the room or set the guest as a call member. The seat is released. Try again in a moment. |
| "The call could not start. Try again in a moment." | Any other failure. The app does not show the response body. |

The function answers browsers on `*.web.app`, `*.firebaseapp.com`, and loopback only. Another origin is refused before the ID token is checked and before the secret is read. The deploy log says whether the token endpoint was set. It does not print the endpoint, the invite token, or any secret.

## Automated checks

These use fake fixtures. They do not call Stream and they do not need a real key.

```bash
node --test functions/test/stream_call.test.js functions/test/stream_guest.test.js
flutter test test/features/group_call/ test/core/firebase/firestore_members_only_rules_test.dart
```

That covers the preview gate, dart-define filtering, member token minting, guest expiry, revoke, the 10-guest cap, name checks, host refusal, the name-entry page, the invite link on the lobby, and the in-call microphone, camera, leave, and host controls. A device pass with Patrol or Maestro is still the follow-up in [#878](https://github.com/neiljaywarner/refuge/issues/878).

## Cost note

Stream measures video in participant-minutes. Ten people for one hour is about 600 participant-minutes. Stream's comparison with Zoom describes a monthly free allowance on the order of 66,000 participant-minutes and about $0.003 per participant-minute after that ([Zoom Video SDK vs. Stream Video](https://getstream.io/blog/zoom-video-sdk-comparison/)). Confirm the current plan in the Stream dashboard before treating that as a bill. This is the cost context for skipping a Zoom plan of about $18 a month. It is not a promise about a future invoice.

## What this slice does not do

Production hosting, a waiting room, screen share, or a 50-person broadcast. A signed-in member who knows the call name can still join the preview room. A person who is not signed in cannot, unless they have a guest link that has not expired or been revoked. Scheduling a future meeting is [#903](https://github.com/neiljaywarner/refuge/issues/903) and should reuse these invite rules.
