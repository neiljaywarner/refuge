# Direct message mirror

> **Code**: `appwrite/functions/dm-mirror`
> **Operator notes**: [README](https://github.com/neiljaywarner/refuge/blob/main/appwrite/functions/dm-mirror/README.md)
> **Decision**: [ADR-0011](https://github.com/neiljaywarner/refuge/blob/main/docs/adr/0011-one-database-plus-backup-not-dual-write.md)
> **Issue**: [#555](https://github.com/neiljaywarner/refuge/issues/555)

Cloud Firestore is the direct-message database the app reads and writes. After a message is stored, the app asks the Appwrite function `dm-mirror` to copy the same fields. The function checks the Firebase ID token and writes the row with an API key that stays on the function.

The phone does not write the Appwrite table. It does not hold the key. If the function is down, the sender still has the Firestore message.

This is not a backup of an older copy. A bad write can still reach both places. Reflection tables stay disabled. Guest create and guest update stay off.

## What is copied

`threadId`, `senderId`, `senderName`, `recipientIds`, `recipientNames`, `participantIds`, `subject`, `content`, `sentAt`.

A sample thread and a send that never reached Firestore are not copied.

## Checked without a live socket

The mailbox test uses an in-memory stand-in. It shows the mirror is asked after the Firestore write, and a thrown mirror call still returns the Firestore message. `npm test` in `appwrite/functions/dm-mirror` checks the field copy and the empty permission list. Neither test opens Appwrite.
