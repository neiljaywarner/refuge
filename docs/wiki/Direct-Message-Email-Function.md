# Direct message email function

> **Code**: `functions/`
> **Operator notes**: [README](https://github.com/neiljaywarner/refuge/blob/main/functions/README.md)
> **Decision**: [ADR-0012](ADR-0012-Direct-Message-Alerts)
> **Issue**: [#570](https://github.com/neiljaywarner/refuge/issues/570)

Belong sends a calm email from a Cloud Function when a `direct_messages` document is created. The phone does not compose or send that mail.

Push stays on the Appwrite function `dm-push`. Spark cannot build Cloud Functions, so this email function sends only after a Blaze deploy. Until that deploy, creating a message does not send email.

## Pieces

| Piece | Where |
| --- | --- |
| Trigger | `src/index.js`. `calmDirectMessageEmail` on `direct_messages/{messageId}` create. |
| Decision | `src/handle.js`. One recipient at a time. A refused send is counted and does not throw. |
| Rule | `src/decide.js`. Same on/off rule and subject as `direct_message_email_policy.dart`. |
| Tests | `npm test` in `functions/`. No network. |

## What it will not do

- It will not send when Message alerts are off or the schedule is Completely Muted.
- It will not look up a sign-in address for a member who has not opted in.
- It will not put the message body or an email address in the subject.
- It will not quote the message in the email text.
- It will not email a sample member or a device-only thread. Those sends never create a `direct_messages` document. A `sample-` recipient id on a real document is skipped.
- It will not send when `DM_EMAIL_TRANSPORT_JSON` is missing. The log says the credential is not configured. The log is counts only.

## Secret

`DM_EMAIL_TRANSPORT_JSON` is a Firebase secret. It holds the HTTPS mail endpoint, the provider key, and the From address. Do not commit it. Do not paste it into an issue, a pull request, or this wiki.

The public profile document still must not hold an email address. The function reads Firebase Auth for the address.
