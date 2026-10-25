# Direct message push function

> **Code**: `appwrite/functions/dm-push`
> **Operator notes**: [README](https://github.com/neiljaywarner/refuge/blob/main/appwrite/functions/dm-push/README.md)
> **Decision**: [ADR-0012](ADR-0012-Direct-Message-Alerts)

Belong sends a direct-message notification from an Appwrite function, not from Firebase Cloud Functions. The Firebase project is on the Spark plan, which cannot build Cloud Functions. This function stays in the app repository because its send rule must match the Dart policy in the same change.

## Pieces

| Piece | Where |
| --- | --- |
| Entry | `src/main.js`. Checks the Firebase ID token with Google's public certificates. |
| Decision | `src/handle.js`. `register` saves the device. `send` notifies the other participants. |
| Rule | `src/decide.js`. Same on/off rule as the Dart file `direct_message_push_policy.dart`. |
| Tests | `npm test` in that directory. Twelve checks. No network. |

The function id is `dm-push`. The runtime is Node 22. The entrypoint is `src/main.js`.

## What it will not do

- It will not send when Message alerts are off or the schedule is Completely Muted.
- It will not send a placeholder token that starts with `fcm_token_calm`.
- It will not send to a sample member. Those sends never create a `direct_messages` document.
- It will not put the message text from the phone into the notification. It reads the stored document.
- It will not send when the FCM credential secret is missing. The response says the credential is not configured.
- It does not send email. That is [#570](https://github.com/neiljaywarner/refuge/issues/570).

## Secret

`FCM_SERVICE_ACCOUNT_JSON` is a secret variable on the function. It is the Firebase Admin SDK JSON for project `belongonthespectrum`. Do not commit it. Do not paste it into an issue, a pull request, or this wiki.

## Still open

Two signed-in test members, on two phones, with Message alerts on, have not yet exchanged a message. Until that happens, a live notification is not confirmed. Do not use a real community member for that check.
