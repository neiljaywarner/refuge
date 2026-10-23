# 🌸 Notifications Product & Member Guide

> **Belong on the Spectrum** (powered by Refuge)  
> **Audience**: Community Members, Group Facilitators, Pastoral Care Leaders  
> **Technical Companion**: [[Notifications-Technical-Architecture]]  
> **Architectural Decisions**: [[ADR-0010-Notifications-Local-Awesome-vs-FCM]]

> **Status (22 October 2026).** The in-app bell is the surface described below. Phone launcher dots are not updated: the badge MethodChannel has no native handler, and FCM permission requests set `badge: false`. Device checks are open in [Issue #411](https://github.com/neiljaywarner/refuge/issues/411).

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
