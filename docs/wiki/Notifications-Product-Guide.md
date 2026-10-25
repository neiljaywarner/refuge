# 🌸 Notifications Product & Member Guide

> Members can start at **[Welcome](Home)**. The short testing notes, including whether a number on Notifications feels stressful, are on **[How you can help](How-You-Can-Help-Volunteer-Guide#what-to-look-for)**. The rest of this page is more detailed.

> **Belong on the Spectrum** (powered by Refuge)  
> **Audience**: Community Members, Group Facilitators, Pastoral Care Leaders  
> **Technical Companion**: [[Notifications-Technical-Architecture]]  
> **Architectural Decisions**: [[ADR-0010-Notifications-Local-Awesome-vs-FCM]]

> **Status (24 October 2026).** Message alerts are opt-in. See [Direct message alerts](ADR-0012-Direct-Message-Alerts) and [ADR-0012](https://github.com/neiljaywarner/refuge/blob/main/docs/adr/0012-direct-message-alerts-are-opt-in.md). The send function is in `appwrite/functions/dm-push` and is deployed. Firebase Cloud Functions stay unused because the project is still on Spark. Phone launcher dots are still not updated. [Issue #411](https://github.com/neiljaywarner/refuge/issues/411) remains open for that badge.

---

## 1. What Are Calm Notifications?

In standard social media applications, notifications are designed to induce fear-of-missing-out (FOMO) and prompt compulsive phone checking. Red notification badges, buzzing alarms, and constant banners are major contributors to sensory burnout and anxiety.

**Belong on the Spectrum** uses a **Calm Technology** approach:
* 🔕 **Silent Defaults**: No jarring chimes, loud tones, or intrusive vibration patterns.
* 🌿 **Gentle Badges**: Soft forest green or theme-accented counters instead of urgent red dots.
* 📦 **Unhurried Batching**: Group updates delivered on peaceful schedules (such as twice daily or evening digests) so you can focus during deep work or quiet moments.
* 🧹 **Effortless Inbox Clearing**: One-tap *"Mark all read"* action that automatically greys out when your inbox is clear.

---

## 2. Navigating Your Notifications

### 2.1 The Notification Bell
On the bottom navigation bar of Belong, the bell icon shows the number of unread interactions. When all notifications have been read, the counter gently disappears.

### 2.2 Filter Categories
You can filter your notifications at any time:
1. **Inbox**: All community interactions in chronological order.
2. **Mentions**: When another member tags you in a thought or prayer request.
3. **Threads**: Responses to comments and reflections you participate in.
4. **Following**: Updates from spaces and members you follow.

### 2.3 Identifying Interaction Badges
Each notification displays an avatar badge in the lower-right corner:
* 💖 **Pink Heart**: A care affirmation or like.
* ↩️ **Blue Reply**: A discussion response.
* 🏷️ **Green `@`**: A direct mention.
* 👤 **Purple Member**: An update from someone you follow.

---

## 3. Customizing Your Schedule

Tap the tune icon (🎛️) in the upper right of the Notifications screen to open **Calm Notification Preferences**:
* **Twice Daily Digest (Recommended)**: Batched quietly at 10:00 AM and 6:00 PM.
* **Daily Evening Digest**: A peaceful summary delivered at 7:00 PM.
* **Weekly Quiet Summary**: Delivered once a week on Sunday mornings.
* **Muted (Zen Mode)**: Completely quiet; check notifications only when you open the app.

## 4. A card when someone messages you

**Message alerts** is the switch at the top of Calm Notification Preferences. It starts off.

When it is on, a new direct message shows as a normal notification, with sound, including while Belong is closed. It uses the Android channel named Direct messages. Completely Muted sends nothing. Immediate Gentle Cards is the quiet extra: the notification still appears, without sound. Other community updates can still wait for the schedule you picked.

The sheet also says where the system controls live. On Android that is Settings, then Apps, then Belong, then Notifications, then the Direct messages channel. On iPhone that is Settings, then Notifications, then Belong. On Mac that is System Settings, then Notifications, then Belong. In a browser it is the lock or tune icon in the address bar, then Notifications.

Sign in on that phone. A signed-out phone can remember the switch, and it has no account for the notification to reach. Practice names in the New Message list never receive a push.

The phone half of the switch was checked on Pixel Left and Pixel Right on October 24, 2026. On October 25, 2026 a closed app on the dev build showed the system notification after Message alerts was turned on. How it is built and tested is on [Direct message push](Direct-Message-Push-Function). Details of the decision are on [Direct message alerts](ADR-0012-Direct-Message-Alerts). Email for the same moment is [issue #570](https://github.com/neiljaywarner/refuge/issues/570) and is not in this version.

## 5. If a message does not show up

Send is the ordinary button. It turns into a spinner, then one of three results:

* **OK, it worked.** The message is stored. The sheet closes.
* **Sent on this phone only.** The recipient is a practice name. The other phone does not get it.
* **Not sent.** The write failed. The sheet stays open and says the message stayed on this phone.

What the other person sees follows the platform:

* **App open.** A Material banner. Belong does not also post a system notification for that same moment.
* **App closed or in the background.** The system notification, with sound, on the Direct messages channel. Message alerts must be on. Completely Muted sends nothing. Immediate Gentle Cards is the quiet notification.

Check these before assuming the send failed:

1. Tap the person until a chip appears. Text in the search box is not a recipient.
2. Read the button. **Not sent.** and **Sent on this phone only.** do not reach the other phone. **OK, it worked** does.
3. On Android, sound and banners are under Settings, then Apps, then Belong, then Notifications, then Direct messages. On iPhone they are under Settings, then Notifications, then Belong.
4. The three practice conversations (Marty & Community Team, Sensory Game Night Group, Silent Co-Presence Fellowship) stay listed until a real conversation exists. They are not a delivery.

A first signed-in send on October 24, 2026 did not store a message, because the person chip was not selected, and the other phone still showed those practice conversations. A later send stored the message, the open app showed the banner, and on October 25 the home-screen phone showed the system notification.
