# 📣 Organizer Guide: Updating the "Message from the Organizer" Without Coding (Firebase Remote Config)

> **Audience**: Non-Technical Community Organizers, Pastors, and Administrators at **[Belong on the Spectrum](https://www.belongonthespectrum.com/)**  
> **Tracked In**: GitHub Issue **#20** (`feat(firebase): All Core FlutterFire Packages + dev/prod Flavors + Firebase Remote Config`)

---

## 1. Why We Built This for You

In most apps, changing the welcome message at the top of the home screen or updating a community link requires asking a software developer to edit code, test it, and publish a new version.

In **Belong on the Spectrum**, we connected the **"Message from the Organizer"** banner and key community links to **[Firebase Remote Config](https://firebase.google.com/products/remote-config)**. That means **any authorized community organizer can log into a simple web dashboard, type a new message, click "Publish Changes," and see it update across the Web/PWA, Android, and iPhone apps automatically!**

- 🌐 **Product Overview for Non-Technical Leaders**: [Firebase Remote Config Official Page](https://firebase.google.com/products/remote-config)
- 🎥 **2-Minute Video Explainer**: [What is Firebase Remote Config? (YouTube)](https://www.youtube.com/watch?v=_CXXVFPO6f0)

---

## 2. What You Can Update Anytime (No Developer Needed)

| Setting Name (Parameter Key) | What It Controls in the Belong App | Default Value |
| :--- | :--- | :--- |
| **`organizer_welcome_title`** | Bold headline at the top of `Feed` and `Start Here & Introduce Yourself` | `"Welcome to Belong on the Spectrum"` |
| **`organizer_welcome_message`** | Body text of the **"Message from the Organizer"** card | `"You belong here. Take your time, choose a sensory theme that feels comfortable, and introduce yourself in Start Here when you are ready."` |
| **`organizer_banner_enabled`** | Shows (`true`) or hides (`false`) the organizer banner at the top of the feed | `true` |
| **`dfw_church_url`** | Destination URL when a member taps `DFW Church` under `Spaces -> Links` | `"https://dfwchurch.org"` |
| **`community_guidelines_markdown`** | Text shown when a member taps `Community Guidelines` under `Spaces -> Links` | Official Belong kindness & safety guidelines |
| **`android_app_download_url`** | URL for `Download the Android App` under `Links` (leave empty for *"Pending / PWA Guide"*) | `""` *(Pending until Play Store launch)* |
| **`ios_app_download_url`** | URL for `Download the iOS App` under `Links` (leave empty for *"Pending / PWA Guide"*) | `""` *(Pending until App Store launch)* |

---

## 3. Step-by-Step: How to Change the "Message from the Organizer"

1. **Open the Firebase Console**:
   - Go to [console.firebase.google.com](https://console.firebase.google.com/) and sign in with your authorized Google account.
   - Select the **Belong Production (`prod`)** project (or **Belong Dev (`dev`)** if you want to preview your change in the test app first!).
2. **Open Remote Config**:
   - In the left sidebar under **Run**, click **Remote Config**.
3. **Edit the Message**:
   - Click the pencil icon (`✏️`) next to **`organizer_welcome_title`** or **`organizer_welcome_message`**.
   - Type your new message (for example: *"Join us this Sunday for our monthly neurodivergent family fellowship! Introduce yourself in Start Here."*).
   - Click **Save**.
4. **Publish Your Changes**:
   - Click the blue **"Publish changes"** button at the top right of the screen, then confirm.
   - **That's it!** Everyone opening Belong on the Web, PWA, Android, or iOS will see your updated message.

---

## 4. How `dev` vs. `prod` Flavors Keep You Safe

We configured separate **`dev` (Development)** and **`prod` (Production)** environments (documented in **ADR 0006** and **Issue #20**):
- Developers and students testing new features use the **`dev`** flavor (`https://dev-belongonthespectrum.web.app/`), which connects to a separate test configuration so test posts and test analytics **never** mix with real **Belong on the Spectrum** community members.
- Real community members on the web app (`https://belongonthespectrum.web.app/`) always use the **`prod`** flavor. The marketing site at `belongonthespectrum.com` is separate.
- When you want to send native mobile pop-up announcements in the future, **`firebase_in_app_messaging`** is also pre-installed for Android & iOS alongside our cross-platform Web/Mobile **Remote Config** banner!
