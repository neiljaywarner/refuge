# Direct message push

This is the Appwrite function that sends a phone notification after a direct message is stored. It lives in this repository so the send rule stays next to the Dart copy in `lib/src/features/notifications/domain/direct_message_push_policy.dart`. A second repository would let those two copies drift.

Firebase Cloud Functions are not used. The Firebase project is on the Spark plan, which cannot enable Cloud Build. Appwrite hosts this function on the free tier.

## Layout

| File | Role |
| --- | --- |
| `src/main.js` | Appwrite entry. Checks the Firebase ID token, reads Firestore, stores the device row, and calls FCM. |
| `src/handle.js` | `register` and `send` with no network. Tests call this. |
| `src/decide.js` | The same on/off rule and Android channel choice as the Dart policy. |
| `test/` | Node tests. They do not call Appwrite, Firestore, or FCM. |

Runtime is Node 22. The entrypoint is `src/main.js`. The function id is `dm-push`.

## What the phone sends

The Dart caller is `lib/src/features/notifications/data/direct_message_push_caller.dart`. It runs only when Firebase is configured and a member is signed in. Failures are swallowed so the message stays stored.

`register` body:

```json
{ "action": "register", "idToken": "<Firebase ID token>", "enabled": true, "schedule": "twiceDaily", "fcmToken": "<device token>" }
```

`send` body:

```json
{ "action": "send", "idToken": "<Firebase ID token>", "messageId": "<direct_messages document id>" }
```

`send` does not accept a message body from the phone. It reads `direct_messages/{messageId}` with that member's token. Firestore rules already allow a participant to read the document. If `senderId` is not the token's uid, the function returns 403.

## When a notification is sent

All of these have to be true:

- Message alerts are on.
- The schedule is not `muted`.
- The device token is non-empty and does not start with `fcm_token_calm`.
- The recipient is not the sender.
- `FCM_SERVICE_ACCOUNT_JSON` is set and parses as a service account with `client_email` and `private_key`.

Otherwise the function skips that recipient. If the credential is missing, the response says `push credential is not configured` and `sent` is 0.

On means a normal notification, with sound, on the Android channel `direct_messages`. `immediateGentle` (Immediate Gentle Cards) is the quiet extra: channel `calm_digest_channel_v2`, no sound. The shade text names the sender and at most 80 characters of the message. An empty name becomes "Fellow Member".

## Where the token is stored

The row id is the Firebase uid. The table is `push_devices` in database `belong_community_db`. Columns are `enabled`, `schedule`, and `fcmToken`. Row security is on and the row permissions are empty, so a client cannot read another member's token. The function's API key can.

The phone also writes `users/{uid}/notification_settings/push` in Firestore. That path is owner-only. The public `users/{uid}` profile must not hold a token or an email address. The function reads the Appwrite row, not the public profile.

## Environment

Appwrite injects these:

- `APPWRITE_FUNCTION_API_ENDPOINT`
- `APPWRITE_FUNCTION_PROJECT_ID`
- `APPWRITE_API_KEY`

Set this one yourself, as a secret variable. Do not commit it and do not print it.

- `FCM_SERVICE_ACCOUNT_JSON` — the Firebase Admin SDK JSON for project `belongonthespectrum`. The function uses it only to obtain a Firebase Cloud Messaging access token.

## Tests

From this directory:

```bash
npm test
```

That runs `node --test test/decide.test.js test/handle.test.js`.

## Troubleshooting

**Phone log shows `dm-push register 500 {"error":"push failed"}` and Appwrite execution errors say `could not store push device (401)`.**  
The function's `APPWRITE_API_KEY` must be allowed to create and update rows in `belong_community_db` / `push_devices`. Regenerate or extend the key scopes in the Appwrite console, then update the function variable. Until that succeeds, `push_devices` stays empty and closed-app notifications are skipped.

**Phone log showed `general_unknown_origin` for `com.belongonthespectrum.refuge.dev`.**  
The Dart caller uses a direct HTTP POST to `/functions/dm-push/executions` with `X-Appwrite-Project` only. It does not use the Appwrite SDK for execute, so the dev application id does not need its own Android platform entry for push register/send.

## Deploy

Pack this directory without `node_modules` and without AppleDouble files. On macOS, `COPYFILE_DISABLE=1` avoids those extra files. Upload the archive as a deployment of function `dm-push` with entrypoint `src/main.js`, and activate it.

The function's execute role is `any`. There is no Appwrite user session. The Firebase ID token is the session.

A deployment answers `{ "error": "unknown action" }` with status 400 when the body has no `register` or `send` action. That check does not send a notification.
