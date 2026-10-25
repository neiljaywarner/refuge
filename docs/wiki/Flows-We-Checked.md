# Flows we checked

This page is for organizers. It lists community flows that automated screen checks have already exercised, in plain language.

Sample members only: David M., Fellow Member, and Sarah K. These checks do not use a live server, a second phone, or anyone's real name.

| Flow | What a person does | What they should see | Ticket |
| :--- | :--- | :--- | :--- |
| Post date | Looks at a post David M. wrote on 20 Oct | **Oct 20** beside the author's name. The date is not typed into the post itself. | [#421](https://github.com/neiljaywarner/refuge/issues/421) |
| Message date | Opens a direct message Fellow Member sent on 20 Oct | **Oct 20** beside the message. The date is not typed into the message. | [#421](https://github.com/neiljaywarner/refuge/issues/421) |
| Feedback sheet and the Android navigation bar | Opens Vote on Features while the Android navigation bar is showing | The sheet sits above the navigation bar. The home bar at the bottom is not padded twice. An open keyboard does not add the navigation bar on top of itself. | [#418](https://github.com/neiljaywarner/refuge/issues/418) |
| Praise and a feature vote (sample data) | Opens the roadmap sheet, writes a short praise note, and votes on a feature | A thank-you appears. An empty note asks for a few words. One star explains the rating. A vote count can update from sample data. Nothing is sent to a live server. | [#415](https://github.com/neiljaywarner/refuge/issues/415) |
| Notification bell (sample data) | Opens Notifications and taps one unread item from Sarah K. | That item's unread mark clears. The other item stays unread, and the bell still shows a count. A Mentions filter with nothing in it says there are no mentions right now. This is the bell inside the app. | [#415](https://github.com/neiljaywarner/refuge/issues/415) |
| Direct message (sample data) | Starts a message, chooses a sample member, and sends a short note | The conversation opens with that note. Sending with nobody chosen, or with no words, shows a gentle prompt. Choosing two people opens a group thread. This is one screen with sample people. | [#415](https://github.com/neiljaywarner/refuge/issues/415) |
| Text post and image post (sample data) | Publishes a short reflection, then a picture post with a description | The reflection appears on the feed. The picture post keeps the picture address, the description, and the topic. No live server is contacted. | [#415](https://github.com/neiljaywarner/refuge/issues/415) |

## Screen walkthrough, 24 Oct 2026

Guest demo on the **dev** app. The recording is cropped so the clock, battery, and notification shade are not in the picture. Nobody signed in, and no account was created. The only names on screen are sample members already in the demo (Marty, Sarah L., and Fellow Member).

![Home, spaces, and notifications](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/528-home-directory-notifications.gif)

[Same clip as a video](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/528-home-directory-notifications.mp4)

The clip moves through:

- The home feed while signed out, including Vote & Feedback, the topic filters, and the `dev.belongonthespectrum.com` label
- Spaces, then the member directory, with the sample organizer Marty
- Notifications in demo mode, then Calm Notification Ethics

Creating an account, and opening the Circle app, are not in this clip. Those checks stay off the public pages. Ticket [#528](https://github.com/neiljaywarner/refuge/issues/528), pull request [#537](https://github.com/neiljaywarner/refuge/pull/537).

## Not part of these checks

- A conversation between two phones was not run.
- The icon on the phone's home screen still does not show a dot ([#331](https://github.com/neiljaywarner/refuge/issues/331)). The count on the in-app bell is a separate check.
- An installed Belong web app was not on the phones, so its notifications were not checked ([#411](https://github.com/neiljaywarner/refuge/issues/411)).
- Account registration and the Circle app were not recorded. The dev package is the only target for a later local check, and credentials stay off this page.
