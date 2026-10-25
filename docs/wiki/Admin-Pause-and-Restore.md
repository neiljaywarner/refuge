# Pause and restore a member

Organizers can pause a member who is hurting the calm of the room, and they can welcome that member back. A paused member can still read. They cannot post or comment. The app does not show a reason.

This is the guide for the November walkthrough with Marty ([#566](https://github.com/neiljaywarner/refuge/issues/566)). The control itself landed in [#356](https://github.com/neiljaywarner/refuge/issues/356). Quarantine (the directory hide, the paused banner, and the posting stop) is [#562](https://github.com/neiljaywarner/refuge/issues/562) and pull request [#565](https://github.com/neiljaywarner/refuge/pull/565).

---

## Who can do this

Only a signed-in organizer whose email is on the admin list.

The list is the Firebase Remote Config parameter `admin_emails_csv`: comma-separated emails, compared without regard to capital letters. The app ships with an empty list, so a failed fetch recognizes nobody.

Production reads only that published list. A development build may add extra emails with the compile-time switch `DEV_ADMIN_EMAILS`. Production ignores that switch.

The two production organizer mailboxes were published to `admin_emails_csv` on 24 October 2026: the DFW church organizer mailbox, and the Belong admin mailbox. The addresses stay in Remote Config. This public guide does not copy them, and neither do GitHub issues or screenshots. Before the November session, Neil shares the Belong admin sign-in with Marty privately.

To change the list later, open [Firebase Remote Config](https://console.firebase.google.com/) for the Belong project, edit `admin_emails_csv`, and publish. The same steps as [updating the welcome message](Organizer-Remote-Config-Guide).

---

## What a pause does

- The member's display name disappears from the directory.
- Their existing posts stay on the feed.
- The composer is hidden.
- Choosing **Create Post** does not open a composer.
- Comments do not send.
- A calm banner says: "This account is paused. You can still read. Posting is paused for now."
- **Restore Member** turns posting back on and returns the name to the directory.

**Cancel** on the confirm step writes nothing. If the save fails, a short error snackbar appears and the member is not paused.

---

## How to pause someone

1. Sign in with an organizer mailbox from the allowlist.
2. On the feed, tap the author's name on one of their posts.
3. The profile shows a small **Admin View** mark.
4. Tap **Ban Member**, then confirm.
5. The profile now says the member is paused, and the button changes to **Restore Member**.

## How to check the member's side

1. Sign out.
2. Sign in as that member.
3. Reading the feed still works.
4. The paused banner is where the composer was.
5. **Create Post** does not open a composer.

## How to restore

1. Sign back in as the organizer.
2. Tap the author's name.
3. Tap **Restore Member**.
4. Sign in as the member again. The composer is back, and a new post appears on the feed.

---

## What we already checked

On the emulator, an organizer paused a test member and then restored them. While paused, the banner was visible and **Create Post** did nothing. After restore, that member posted again.

Automated checks on the same emulator:

- Unit, widget, and sociable tests for cancel, a failed ban, hiding the directory card, the paused banner, and restore.
- An integration test with two scenarios: pause hides the card and blocks a post, and restore brings the card back.

The committed Maestro flow only checks that a guest does not see **Ban Member**. It does not contain organizer addresses.
