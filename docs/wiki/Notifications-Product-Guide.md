# 🌸 Notifications Product & Member Guide

> Members can start at **[Welcome](Home)**. The short testing notes, including whether a number on Notifications feels stressful, are on **[How you can help](How-You-Can-Help-Volunteer-Guide#what-to-look-for)**. The rest of this page is more detailed.

> **Belong on the Spectrum** (powered by Refuge)  
> **Audience**: Community Members, Group Facilitators, Pastoral Care Leaders  
> **Technical Companion**: [[Notifications-Technical-Architecture]]  
> **Architectural Decisions**: [[ADR-0010-Notifications-Local-Awesome-vs-FCM]]

> **Status (24 October 2026).** Message alerts are opt-in. See [Direct message alerts](ADR-0012-Direct-Message-Alerts) and [ADR-0012](https://github.com/neiljaywarner/refuge/blob/main/docs/adr/0012-direct-message-alerts-are-opt-in.md). The cloud send is written and tested, and it is not deployed: the Firebase project is still on Spark. Phone launcher dots are still not updated. [Issue #411](https://github.com/neiljaywarner/refuge/issues/411) remains open for that badge.

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

Sign in on that phone. A signed-out phone can remember the switch, and it has no account for the card to reach. Practice names in the New Message list never receive a push.

The phone half of this was checked on Pixel Left and Pixel Right on October 24, 2026. The cloud function that would send the card is in the repository and is not deployed yet. Details are on [Direct message alerts](ADR-0012-Direct-Message-Alerts). Email for the same moment is [issue #570](https://github.com/neiljaywarner/refuge/issues/570) and is not in this version.
