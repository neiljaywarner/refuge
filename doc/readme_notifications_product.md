# 🌸 Calm Notifications — Product, UX & Member Experience Guide (`readme_notifications_product.md`)

> **Belong on the Spectrum** (powered by Refuge)  
> **Audience**: Community Members, Group Organizers, Product Designers & Leadership  
> **Philosophy**: Calm Technology, Unhurried Community, Sensory Autonomy

---

## 1. Why "Calm Notifications" Matter for Belong on the Spectrum

Most modern mobile apps treat a user's attention as a resource to be harvested through panic-inducing feedback loops:
- **Red Badges**: Evolutionary psychology links bright red to danger and urgency, generating mild background anxiety.
- **Auditory Chimes**: Sudden, sharp noises cause sensory shock and auditory overload, especially for autistic adults with sound sensitivities (hyperacusis or misophonia).
- **Constant Interruptions**: Instant popups break executive functioning and hyperfocus states, leading to cognitive fatigue.

In **Belong on the Spectrum**, notifications are redesigned from first principles to be **a peaceful harbor, not a demand for attention**:
1. **Silent by Default**: Notifications never chime, ring, or trigger intrusive vibration bursts unless explicitly requested.
2. **Batched Unhurried Delivery**: Rather than dinging every minute, updates can be batched into calm, scheduled digests (such as once in the morning and once in the evening).
3. **No Red Panic Dots**: Unread indicators use soft sage green or the member's chosen sensory theme colors.
4. **Member-Controlled Quiet Hours**: Notification preferences let every person mute alerts entirely or receive weekly quiet summaries.

---

## 2. The Notifications Experience

### 2.1 Bottom Navigation Bar: The Gentle Bell
- Located on the primary bottom bar (`Notifications`).
- When new reflections, replies, or care affirmations arrive, a soft pill badge displays the count.
- Tapping the bell opens the **Calm Notifications Screen**.

### 2.2 Filter Chips: Calm Triage
At the top of the Notifications screen, members can filter their feed with one tap:
- **Inbox**: The comprehensive chronological stream of community interactions.
- **Mentions**: Places where other members specifically tagged you in an unhurried reflection or prayer request.
- **Threads**: Discussion replies and ongoing conversations you have contributed to.
- **Following**: Updates from friends and spaces you have chosen to follow.

### 2.3 Notification Cards & Avatar Badges
Each notification tile contains:
1. **Author Avatar**: Shows the member's initials or photo with a subtle badge in the lower-right corner indicating what happened:
   - 💖 **Pink Heart**: Someone gave a care reaction or liked your reflection.
   - ↩️ **Blue Reply Arrow**: Someone responded to your reflection or comment in a threaded discussion.
   - 🏷️ **Green `@` Symbol**: Someone mentioned you directly.
   - 👤 **Purple Member Icon**: Someone you follow shared an unhurried thought.
2. **Human-Readable Message**:
   - *"John Doe mentioned you in a comment on 'Markan Chiasms'"*
   - *"Sarah Jenkins liked your reflection on 'Sensory Worship'"*
3. **Unhurried Timestamps**:
   - Expressed gently: *"Just now"*, *"1 hr ago"*, *"2 days ago"*, or *"Sep 7th"*.
4. **Read State Differentiation**:
   - Unread cards have a gentle soft background tint and highlighted border.
   - Read cards blend smoothly into the calm background.

### 2.4 "Mark All as Read" Action
- Located in the upper right of the app bar.
- Features both a clean checkbox and a textual button (`Mark all read`).
- **Smart Grey-Out**: When there are zero unread notifications, the checkbox and button automatically grey out and become non-clickable, providing clear visual closure that your inbox is peaceful and up to date.
- Tapping `Mark all read` clears the in-app unread count. It does not update the phone launcher icon. The badge MethodChannel has no native handler ([#411](https://github.com/neiljaywarner/refuge/issues/411)).

---

## 3. Calm Notification Preferences (The Tune Button)

Tapping the tune icon (🎛️) in the upper right opens the **Calm Notification Preferences Sheet**:
1. **Push Notifications Toggle**: Simple switch enabling or disabling push alerts.
2. **Batching Schedules**:
   - 🌅 **Twice Daily Digest (Recommended)**: Batched quietly at 10:00 AM and 6:00 PM.
   - 🌙 **Daily Evening Digest**: A single peaceful recap delivered at 7:00 PM.
   - 🕊️ **Weekly Quiet Summary**: Sent once a week on Sunday morning.
   - 🔕 **Muted (Zen Mode)**: No device alerts whatsoever; check notifications only when you choose to open the app.
3. **Sensory & Sound Guarantee**: Reassurance that alerts remain silent and gentle.

---

## 4. Mobile Installation & Push Delivery

| Platform | Notification Delivery | Behavior & Notes |
| :--- | :--- | :--- |
| **Android APK** | FCM permission request sets `badge: false` | In-app bell exists. Launcher dots and calm FCM delivery are not fully verified on device ([#411](https://github.com/neiljaywarner/refuge/issues/411)). |
| **Android Chrome PWA** | Web Push | Full support when added to home screen or run in Chrome. |
| **iOS Safari PWA** | APNs Web Push | Apple requires adding Belong to the Home Screen via Safari (*"Add to Home Screen"*) to enable push alerts. Regular Safari tabs cannot receive notifications. |
| **Desktop Web** | Browser Notifications | Silent browser toasts conforming to OS Do-Not-Disturb settings. |

---

## 5. Summary & Vision

Belong on the Spectrum proves that modern community applications can be richly interactive without exhausting their members. By honoring sensory boundaries and emotional energy, the Calm Notifications system turns community updates into moments of gentle connection rather than demands for immediate attention.
