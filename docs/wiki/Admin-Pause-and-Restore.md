# Ban a member

Organizers can ban a member who is hurting the calm of the room. This follows [Circle's ban](https://help.circle.so/p/audience/member-management/removing-members-from-your-community), except Belong does not lock IP addresses.

This is the guide for the November walkthrough with Marty ([#566](https://github.com/neiljaywarner/refuge/issues/566)). The admin control landed in [#356](https://github.com/neiljaywarner/refuge/issues/356). Quarantine is [#562](https://github.com/neiljaywarner/refuge/issues/562). Hiding the community from a paused session is [#578](https://github.com/neiljaywarner/refuge/issues/578). The Circle-style ban is [#579](https://github.com/neiljaywarner/refuge/issues/579). Whether a later ban should also block recent IP addresses is an open discussion in [#580](https://github.com/neiljaywarner/refuge/issues/580). There is no code for that.

---

## Who can do this

Only a signed-in organizer whose email is on the admin list.

The list is the Firebase Remote Config parameter `admin_emails_csv`: comma-separated emails, compared without regard to capital letters. The app ships with an empty list, so a failed fetch recognizes nobody.

Production reads only that published list. A development build may add extra emails with the compile-time switch `DEV_ADMIN_EMAILS`. Production ignores that switch.

The two production organizer mailboxes were published to `admin_emails_csv` on 24 October 2026: the DFW church organizer mailbox, and the Belong admin mailbox. The addresses stay in Remote Config. This public guide does not copy them, and neither do GitHub issues or screenshots. Before the November session, Neil shares the Belong admin sign-in with Marty privately.

To change the list later, open [Firebase Remote Config](https://console.firebase.google.com/) for the Belong project, edit `admin_emails_csv`, and publish. The same steps as [updating the welcome message](Organizer-Remote-Config-Guide).

---

## What a ban does

Circle removes the member's posts, comments, and messages, and that account can no longer use the community. Belong does the same:

- Their posts, comments, and direct messages are deleted.
- Their display name disappears from the directory.
- A matching sign-in does not open a session. The screen says: "This account can't sign in."
- While that session is still on screen, the feed, discussions, directory, messages, and search stay hidden.
- The composer is hidden, and comments do not send.
- The app does not show a ban reason.
- The app does not record or block IP addresses.
- There is no **Restore Member** button. Deleted writing stays deleted. The profile says the ban stays.

**Cancel** on the confirm step writes nothing. If the save fails, a short error snackbar appears and the member is not banned.

### What this does not copy from Circle

Circle also locks every IP address that member used in the prior 30 days. An admin cannot see that list or undo it; only Circle support can. That lock is out of scope here. [#580](https://github.com/neiljaywarner/refuge/issues/580) is the place to decide whether Belong should do it later.

Circle deletes the account, so the same email can register again as a new member from an IP that was not blocked. Belong does not delete the Firebase Auth user. The app refuses a matching session, and that email stays reserved in Firebase until the Auth user is deleted. There is no Cloud Function for that in this change.

A signed-out person sees only the sign-in wall. They cannot browse the feed, directory, or other members' posts. The ban stops that member's session and removes their writing. Firestore rules also refuse unauthenticated reads (#601).

---

## How to ban someone

1. Sign in with an organizer mailbox from the allowlist.
2. On the feed, tap the author's name on one of their posts.
3. The profile shows a small **Admin View** mark.
4. Tap **Ban Member**, then **Confirm Ban**.
5. The profile says the member is banned, their writing was removed, and the account cannot sign in. A short note says the ban stays.

## How to check the member's side

1. Sign out.
2. Sign in as that member.
3. The session does not stay open. The screen says this account can't sign in. The feed is not shown.
4. Their earlier posts, comments, and messages are gone for everyone.

---

## What we already checked

Widget and unit tests cover cancel, a failed ban, hiding the directory card, deleting a post by that author, keeping the ban record, and the missing Restore button. Device proof of the erase-and-refuse flow is still outstanding: the emulators were already in use for other work.
