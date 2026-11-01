# Direct message mirror

This Appwrite function copies a direct message into Appwrite after Cloud Firestore has stored it. Firestore stays the copy the app reads and writes. The phone does not write the Appwrite table and does not hold the API key.

[ADR-0011](../../../docs/adr/0011-one-database-plus-backup-not-dual-write.md) is the decision. A mirror is a spare copy, not a backup of yesterday's text. Reflection tables stay disabled. This function does not turn them on, and it does not add guest create or guest update.

## Layout

| File | Role |
| --- | --- |
| `src/main.js` | Appwrite entry. Checks the Firebase ID token, reads Firestore, writes the row with the API key. |
| `src/handle.js` | `copy` with no network. Tests call this. |
| `test/` | Node tests. They do not call Appwrite or Firestore. |

Runtime is Node 22. The entrypoint is `src/main.js`. The function id is `dm-mirror`.

## What the phone sends

The Dart caller is `lib/src/features/messages/data/direct_message_mirror.dart`. It runs only after Firestore accepts the message. The request body is the Firebase ID token and the document id. It does not send the message text. If the call fails or times out, the sender still gets the Firestore message.

```json
{ "action": "copy", "idToken": "<Firebase ID token>", "messageId": "<direct_messages document id>" }
```

The function reads `direct_messages/{messageId}` with that member's token. If `senderId` is not the token's uid, the function returns 403. A `local-sender` or `thread-local-` document is not copied.

## What is written

Database `belong_community_db`, table `direct_messages`. The row id is the Firestore document id. The row data is `threadId`, `senderId`, `senderName`, `recipientIds`, `recipientNames`, `participantIds`, `subject`, `content`, and `sentAt`. Permissions on the create are an empty list.

Create that table with row security on. Do not grant guest create, guest update, or guest read. Do not change `reflection_posts` or `quiet_digests`.

## Secret

Appwrite injects `APPWRITE_FUNCTION_API_KEY` for each run when the function scopes include `rows.read` and `rows.write`. `src/main.js` sends that key as `X-Appwrite-Key`. If it is empty, the function uses the optional secret `APPWRITE_API_KEY`.

That key is the secret. It is not a `--dart-define`. It is not in the client build. Never commit it. Never paste it into an issue, a pull request, or the wiki.

If the key is missing, the response is `{ "mirrored": false, "reason": "mirror credential is not configured" }`. The Firestore message is unchanged.

## Tests

From this directory:

```bash
npm test
```

That runs `node --test test/handle.test.js`.

## Deploy

Pack this directory without `node_modules`. Upload it as a deployment of function `dm-mirror` with entrypoint `src/main.js`, and activate it.

The function's execute role is `any`. There is no Appwrite user session. The Firebase ID token is the session.
