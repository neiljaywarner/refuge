# ADR-0012: A Direct Message Push Goes Out Only After the Member Turns Alerts On

* **Status**: Accepted for the client and the function. The function is not deployed.
* **Date**: October 24, 2026
* **Deciders**: Neil Jay Warner & Engineering Team
* **Related**:
  * [Issue #571](https://github.com/neiljaywarner/refuge/issues/571)
  * [Issue #441](https://github.com/neiljaywarner/refuge/issues/441) (the message is stored; this decision is only about the phone card)
  * [Issue #570](https://github.com/neiljaywarner/refuge/issues/570) (email stays a 1.1 item and is not part of this decision)
  * [ADR-0010](../wiki/ADR-0010-Notifications-Local-Awesome-vs-FCM.md)
  * [Wiki: Direct message alerts](../wiki/ADR-0012-Direct-Message-Alerts.md)

---

## 1. Context

A direct message can already be stored in `direct_messages`. The phone can already show a silent card when a push arrives. Nothing was sending that push when the document was created.

Members have asked for a card when someone messages them, including while Belong is closed. The existing notification sheet starts off. ADR-0010 says Belong does not play a chime or add a red badge unless the member asks.

The Firebase project `belongonthespectrum` is on the Spark plan. Cloud Functions need the Blaze plan. That constraint is part of the decision, not a footnote.

## 2. Decision

1. **Off until the member asks.** `CalmNotificationPreferences.enabled` stays false until they open Notifications, open Calm Notification Preferences, and turn **Message alerts** on.
2. **A direct message is the exception to the digest wait.** Other updates still follow the delivery schedule. A new direct message is sent as soon as alerts are on and the schedule is not Completely Muted. Muted still means nothing is sent.
3. **On means a normal notification.** The Android 8+ channel is `direct_messages`, named Direct messages, with high importance and sound. Off, or Completely Muted, sends nothing. Immediate Gentle Cards is the quiet extra and still uses `calm_digest_channel_v2` with no sound. The permission request allows sound.
4. **The token is not on the public profile.** `users/{uid}` is world-readable and must not hold an email or a push token. The token lives at `users/{uid}/notification_settings/push`. Only that member can read or write it. The function uses the Admin SDK, which bypasses those rules.
5. **The phone remembers the switch.** Shared preferences keep the choice across a relaunch. When the member is signed in, the same save writes the private document. Signing in later retries that write. A signed-out phone can turn the switch on, but there is no account for the function to address.
6. **Some tokens are never used.** An empty token, or any token that starts with `fcm_token_calm`, is not sent. Widget tests use that prefix when Firebase is absent.
7. **Sample members never create the document the function watches.** A send that is only samples uses a local thread and the `localOnly` outcome. A send that never reached Firestore uses `deviceOnly`. Neither one creates `direct_messages/{id}`, so neither one can push or email.
8. **One function, one rule, two copies of the decision.** `functions/index.js` runs on `direct_messages/{messageId}` create. It skips the sender, reads each recipient's private document, and calls the same rule as `shouldSendDirectMessagePush` in Dart. `functions/decide.js` is the JavaScript copy, with node tests beside it.

The card body names the sender and includes at most 80 characters of the message. An empty name becomes "Fellow Member".

## 3. What was verified on October 24, 2026

| Check | Result |
| :--- | :--- |
| Dart policy tests | 4 passed. Off, muted, placeholder token, and a real token. |
| JavaScript decision tests | 4 passed (`node --test decide.test.js`). |
| Notification sheet and service tests | 5 passed, including the existing "Calm Notification Ethics" title. |
| In-memory mailbox tests | 2 passed. A third member cannot see the thread. |
| Pixel Left and Pixel Right, dev package, signed out | Message alerts turned on. A fresh launch still showed on. New Message opened the sample directory and the offline banner. |
| Live card from one signed-in member to another | Not run. Both phones showed Sign In. No message was sent to a real member. |
| `firebase deploy --only functions,firestore:rules` | Rules compiled. Deploy stopped because Cloud Build cannot be enabled until the project is on Blaze. The new rule and the function are not live. |

## 4. Consequences

A member who turns Message alerts on, and who is signed in, gets a private document the function can read. Until someone upgrades the Firebase project to Blaze and deploys `functions` plus `firestore:rules`, that document does not produce a card.

Email is unchanged. [Issue #570](https://github.com/neiljaywarner/refuge/issues/570) is the reminder. The subject of that future mail must name the sender and say a message is waiting. It must not include the full body or an email address.

## 5. How to finish the live card

1. Upgrade `belongonthespectrum` to Blaze.
2. From this repo, deploy functions and Firestore rules together.
3. Sign in as two different test members, turn Message alerts on both phones, and send one real direct message.
4. Confirm the other phone shows a silent Belong card, and confirm a sample-member send still stays on the sending phone.
