# 📱 Progressive Web App (PWA) Guide — For Community Members & Organizers

> **Audience**:
> - **Part 1 (For Community Members)**: How to install **Belong on the Spectrum** onto your iPhone, Android phone, iPad, or computer home screen in 10 seconds — no App Store password or large download needed!
> - **Part 2 (For Community Organizers & Leaders)**: What a PWA is, why it is the secret weapon for our **October 31st Circle.so cutover**, and **how long we can comfortably run on the Web/PWA before needing the Apple App Store and Google Play Store**.

---

## Part 1: For Community Members — How to Install & Use Belong on Your Phone

### What Is the Belong Web App (PWA)?
Instead of forcing you to download a heavy 150 MB app from the App Store or remember your Apple/Google password, **Belong on the Spectrum** is built as a modern **Progressive Web App (PWA)**.
- You can use it directly in any web browser (**Safari, Chrome, Edge, Firefox**) on your phone, tablet, or computer.
- Or, with **two taps**, you can **Add It to Your Home Screen** so it sits right alongside your other apps with the official **Belong** cross & gold infinity (`∞`) icon and opens in a clean, full-screen window without browser address bars!

### 🍎 How to Add Belong to Your iPhone or iPad Home Screen (Safari)
1. Open **Safari** on your iPhone or iPad and go to the Belong community link.
2. Tap the **Share** button at the bottom of Safari (the square icon with an arrow pointing up `⬆️`).
3. Scroll down slightly and tap **"Add to Home Screen"** (`➕`).
4. Tap **"Add"** in the top-right corner.
5. **Done!** The **Belong** icon (`∞`) is now on your Home Screen and opens like a full-screen native app.

### 🤖 How to Add Belong to Your Android Phone Home Screen (Chrome)
1. Open **Google Chrome** on your Android phone and go to the Belong community link.
2. Tap the **Three Dots Menu (`⋮`)** in the upper-right corner (or tap the **"Install App"** banner if Chrome shows it automatically).
3. Tap **"Add to Home screen"** or **"Install app"**.
4. Tap **"Install"**.
5. **Done!** Belong now appears on your Home Screen and in your Android App Drawer.

### 💻 How to Install Belong on Your Mac or Windows Computer
1. Open **Chrome**, **Edge**, or **Safari (macOS Sonoma+)**.
2. Click the small **Install (`⬇️` / computer)** icon on the right side of the address bar (or choose **File → Add to Dock** in Safari on Mac).
3. Belong now runs in its own calm, distraction-free window in your Dock or Taskbar!

---

## Part 2: For Community Organizers — How Long Can We Stay on the PWA Before Needing Google Play & the iOS App Store?

### Short Answer
> **We can comfortably run 100% of our October 31st Circle.so cutover — and the first 1 to 3+ months of community life — on the Web + PWA alone!**

In fact, launching as a **Web + PWA first** gives **Belong on the Spectrum** several huge advantages over waiting on the Apple App Store and Google Play Store:

### 1. Why the PWA Is Ideal for the October 31st Circle.so Cutover
| Question | Web & PWA (Ready Now for Oct 31!) | Native Apple App Store & Google Play Store |
| :--- | :--- | :--- |
| **Approval Delay?** | **Zero wait.** Updates go live globally in **60 seconds**. | Apple App Review & Google Play review can take **2 to 14 days** (plus organization D-U-N-S verification). |
| **Works on Every Device?** | **Yes** — iPhone, Android, iPad, Mac, Windows, Chromebook from a single link. | Requires separate iOS App Store and Google Play Store builds. |
| **Home Screen Icon & Full-Screen Feel?** | **Yes** — Uses our official Belong icon (`#19`) and opens full-screen without browser bars. | Yes. |
| **Can Organizers Update the Welcome Message Instantly?** | **Yes** — via **Firebase Remote Config** (`#20`) + instant web reload. | Yes (via Firebase Remote Config & In-App Messaging). |
| **Cost to the Non-Profit?** | **\$0 store fees.** | Apple charges \$99/year (unless waived for non-profits); Google Play charges \$25 one-time. |

### 2. When Do We Actually *Need* the Google Play Store & Apple iOS App Store?
You **do not** need the native app stores for the October 31st Circle.so transition. You only need to publish to Google Play and the Apple App Store when you want:
1. **1-Tap Store Search**: For members who instinctively search *"Belong on the Spectrum"* inside the Apple App Store or Google Play Store rather than clicking a website link.
2. **Native Background Push Notifications**: While iOS 16.4+ and Android support Web Push for Home Screen PWAs, native App Store / Play Store apps make enabling push notifications (`v1.0.1` / `v1.1.0`) a single automatic prompt right after sign-in.
3. **Native Firebase In-App Messaging Campaigns**: While our **Firebase Remote Config** *"Message from the Organizer"* banner works on **100% of platforms (Web, PWA, Android, and iOS)**, native `firebase_in_app_messaging` pop-up campaigns target native Android and iOS builds.

### 3. Our Phased Store Rollout Plan (Tracked in GitHub Issues)
So we never rush or block the October 31st cutover, mobile store distribution is organized into clear, stress-free stages:
1. **Stage A — Web & PWA Launch (Now → Oct 31, `v0.6.0`–`v1.0.0`)**:
   - Belong PWA manifest, maskable icons, and mobile responsiveness (**Issue #19** & **Issue #43**).
2. **Stage B — Beta Testing Tracks (`v0.9.0-rc` / `v1.0.0`)**:
   - **Apple TestFlight & Google Play Internal/Closed Beta** (**Issue #44**) so moderators and volunteers can test the native phone builds.
3. **Stage C — Public Store Listings (`v1.0.0` / `v1.0.1`)**:
   - **Google Play Store Production Release** (**Issue #45**) → unlocks the `Download the Android App` link under `Spaces -> Links` (**Issue #30**).
   - **Apple iOS App Store Production Release** (**Issue #46**) → unlocks the `Download the iOS App` link under `Spaces -> Links` (**Issue #31**).
   - Because those links are wired to **Firebase Remote Config**, the moment Apple or Google approves the app, we paste the store URL into Firebase and click **Publish** — no code update needed!
