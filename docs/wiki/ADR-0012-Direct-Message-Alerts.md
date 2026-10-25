# Direct message alerts

> **Decision**: [ADR-0012](https://github.com/neiljaywarner/refuge/blob/main/docs/adr/0012-direct-message-alerts-are-opt-in.md)
> **Function**: [Direct message push](Direct-Message-Push-Function)
> **Issue**: [#571](https://github.com/neiljaywarner/refuge/issues/571)
> **Product page**: [Gentle notifications](Notifications-Product-Guide)
> **Checked**: October 24, 2026, on Pixel Left and Pixel Right

A direct message can arrive as a normal notification, with sound. Nothing is sent until you turn **Message alerts** on. Immediate Gentle Cards is the quiet choice.

## What you do

1. Open **Notifications**.
2. Open **Calm Notification Preferences**.
3. Turn **Message alerts** on.
4. Sign in on that phone.

The switch starts off. Turning it on asks the phone for permission once. After that, the phone remembers the choice, including the next time you open Belong.

When alerts are on, the notification uses the Android channel named Direct messages. That channel has sound. Completely Muted sends nothing. Immediate Gentle Cards still appears, without sound.

The sheet says where the system controls live:

- Android: Settings, then Apps, then Belong, then Notifications, then Direct messages.
- iPhone: Settings, then Notifications, then Belong.
- Mac: System Settings, then Notifications, then Belong.
- Browser: the lock or tune icon in the address bar, then Notifications.

If the phone is not signed in, the switch can still be on, but the notification has nobody to find. The sheet says so.

Sample members are practice names. A message to them stays on your phone. It does not push, and it does not email.

## What is deployed

The send function is `appwrite/functions/dm-push` in this repository. It is deployed. The phone calls it after a message is stored. The FCM credential is a secret on that function and is not in git.

A live notification from one signed-in member to another has not been run. Both phones were signed out during the October 24 check. No message was sent to a real community member.

Email when a message arrives is a later item, [#570](https://github.com/neiljaywarner/refuge/issues/570). That mail will say a message is waiting. It will not include the whole message.

## How the send is decided

The same rule lives in Dart and in `appwrite/functions/dm-push/src/decide.js`:

- Alerts are on.
- The schedule is not muted.
- The token is present and is not a test placeholder (`fcm_token_calm…`).

The function stores the token in an Appwrite row the client cannot read. The public profile document stays free of tokens and email addresses. The function reads the stored message with the sender's own sign-in token. It does not trust text supplied by the phone.

A sample send and a send that never reached the database do not create a `direct_messages` document, so they cannot notify anyone.
