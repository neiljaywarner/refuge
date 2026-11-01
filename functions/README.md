# Calm direct-message email

This Cloud Function sends one calm email when a real `direct_messages` document is created. The phone does not send the mail and does not choose the subject.

Firebase Cloud Functions need the Blaze plan. The project has been on Spark, which cannot build them. Push stays on the Appwrite function `dm-push` for that reason. This email path is the exception: it has to run where the document is created, with the Admin SDK, so it can read a private preference and a sign-in address without putting either on the phone.

## Layout

| File | Role |
| --- | --- |
| `src/index.js` | Firestore `onDocumentCreated` trigger `calmDirectMessageEmail`. |
| `src/handle.js` | Who receives mail. Tests call this. No network. |
| `src/decide.js` | The same on/off rule and subject as `lib/src/features/notifications/domain/direct_message_email_policy.dart`. |
| `src/transport.js` | Parses the secret. Never logs the key. |
| `test/` | Node tests. They do not call Firestore, Auth, or a mail provider. |

Runtime is Node 22. The codebase root is this directory.

## When an email is sent

All of these have to be true:

- The document is a real stored thread. `senderId` is not `local-sender`, and `threadId` does not start with `thread-local-`.
- The recipient is not the sender and the id does not start with `sample-`.
- `users/{uid}/notification_settings/push` has `enabled: true`.
- The schedule is not `muted`.
- Firebase Auth has a sign-in address for that member.
- `DM_EMAIL_TRANSPORT_JSON` parses as an HTTPS mail endpoint.

Otherwise that recipient is skipped. A sample-member send and a device-only send never create `direct_messages/{id}`, so this trigger does not run for them.

The subject names the sender and says a message is waiting. An empty name, an address-shaped name, or a name that repeats the message becomes "Fellow Member". The plain text says the same thing and does not quote the message. The sign-in address is the `To` header only.

## Secret

Set this with the Firebase CLI. Do not commit it. Do not paste it into an issue, a pull request, or the wiki.

```bash
firebase functions:secrets:set DM_EMAIL_TRANSPORT_JSON --project belongonthespectrum
```

The value is JSON:

```json
{
  "endpoint": "https://api.resend.com/emails",
  "apiKey": "<provider key>",
  "from": "Belong <notifications@belongonthespectrum.com>"
}
```

The function POSTs `{ from, to, subject, text }` with `Authorization: Bearer <apiKey>`. That matches the Resend email API. Another HTTPS provider can sit behind the same shape. If the secret is missing, the function logs `email credential is not configured` and does not pretend a message was sent. The log line is counts only. It does not include an address, a token, or the message.

## Deploy

From the repository root, after `npm install` in this directory:

```bash
firebase deploy --only functions:calmDirectMessageEmail --project belongonthespectrum
```

Hosting deploys pass `--only hosting` and do not publish this function.

## Tests

From this directory:

```bash
npm test
```

That runs `node --test test/decide.test.js test/handle.test.js test/transport.test.js`.
