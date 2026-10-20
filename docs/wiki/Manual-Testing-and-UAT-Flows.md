# 🧪 Manual Testing & UAT Playbook ("How Can I Help Test?")

*Last Updated: October 19, 2026 (`2026-10-19T20:25:00-05:00`)*  
*Target Audience: Community Testers, Welcomers, Organizers & Volunteers (Zero Technical Background Required)*  
*Public Web PWA: [https://belongonthespectrum.web.app](https://belongonthespectrum.web.app)*

---

## 👋 Welcome Testers!

Thank you so much for offering to test **Belong on the Spectrum**! You do **not** need any coding experience or technical background to be an incredible tester. What we need most is your authentic human experience:
- Does the app feel calm, clear, and unhurried?
- Can you navigate smoothly without sensory overload or confusion?
- Do buttons and forms respond predictably when you tap them?

This playbook breaks down everything you need to test in simple, step-by-step flows. You can test just **one flow in 3 minutes**, or spend **15 minutes** testing the entire app. Every piece of feedback helps our community flourish ahead of our October 31 cutover!

---

## 📱 1. Where to Test: Choose Your Platform

| Platform | How to Access | What to Test |
| :--- | :--- | :--- |
| **🌐 Web Browser / PWA** | Open [https://belongonthespectrum.web.app](https://belongonthespectrum.web.app) on Chrome, Safari, Edge, or Firefox. | Desktop & tablet responsiveness, mouse hover states, keyboard navigation. |
| **📱 iPhone / iPad (PWA)** | Open [https://belongonthespectrum.web.app](https://belongonthespectrum.web.app) in Safari, tap the **Share** button, and tap **"Add to Home Screen"**. | Fullscreen app feel, touch responsiveness, iOS keyboard handling. |
| **🤖 Android Phone / Tablet** | Install the latest test build via the Firebase App Distribution email invite or download the APK directly. | Physical back button, high-refresh display, push notifications. |

---

## 👥 2. Testing Personas (Pick One to Roleplay!)

1. **Alex (Autistic Community Member)**: Sensitive to bright lights, motion, and sudden popups. Wants a gentle, predictable experience where text is easy to read and colors are soothing.
2. **Marty (Community Organizer)**: Wants to verify that newcomers can easily identify their church affiliation (or declare they are a welcoming visitor) and that community announcements are clear.
3. **Jordan (Welcoming Friend / Guest)**: Not a member of any church, but wants to support neurodivergent friends and check out the public discussion spaces.

---

## 🧭 3. Step-by-Step Test Flows

### Flow 1: First Launch & Sensory Calm Audit 🌿
*Goal: Confirm that the visual environment is grounding and free of sensory overload.*

1. **Open the app**:
   - Check the top header. Does it say **Sanctuary** and **Calm Tech • Resilient**?
   - Notice the colors. Are they gentle and pleasant to look at?
2. **Switch Themes**:
   - Tap the palette / theme icon in the top app bar.
   - Try **Sage Calm** (soothing greens).
   - Try **Midnight Dark** (reduced glare for evening reading).
   - Try **High-Contrast** (bold outlines for visual clarity).
3. **Check Motion**:
   - Scroll up and down the feed. Does it scroll smoothly without disorienting zooms or bouncy springs?
4. **Bottom Navigation**:
   - Verify the 4 bottom tabs: **Home**, **Notifications**, **Msgs**, **Search**.
   - Tap each tab and confirm that you transition predictably without jarring flashing.

---

### Flow 2: Member Profile & Church Affiliation Question ⛪
*Goal: Confirm Marty the Organizer's required ICOC affiliation question works smoothly.*

1. **Open Profile**:
   - Tap the avatar / profile icon in the top right.
   - The **Member Profile & Sign-In** dialog will appear.
2. **Test Validation**:
   - Leave the church affiliation empty and tap **"Save & Continue"**.
   - **Expected**: A calm amber banner appears explaining:
     > *"Please select which ICOC church you attend, or choose 'I am not a member of an ICOC church'."*
3. **Select Your Congregation or Guest Status**:
   - Tap the **"Which ICOC church do you attend?"** dropdown.
   - If you attend an ICOC congregation (e.g., *DFW Church*, *Austin Christian Church*, *Boston Church of Christ*, etc.), select it.
   - If you are a guest, family member, or friend, select:
     > *"I am not a member of an ICOC church"*
4. **Enter Display Name & Bio**:
   - Type your preferred name and a brief note in "About Me".
   - Tap **"Save & Continue"**.
   - **Expected**: The dialog closes and your profile saves successfully.

---

### Flow 3: Account Sign-In & Passwordless Magic Link 🔑
*Goal: Confirm members can sign in with passwords or 1-tap passwordless magic links.*

1. **Open the Auth Sheet**:
   - Tap the **Sign In** button from the Profile dialog or navigation bar.
2. **Test Tab 1: Sign In**:
   - Tap **"Sign In"** with an empty email.
   - **Expected**: A clear warning prompt asking for your email address.
3. **Test Tab 2: Create Account**:
   - Tap the **"Create Account"** tab.
   - Verify fields for Name, Email, Password, and the required Church Affiliation dropdown.
4. **Test Tab 3: Passwordless Magic Link**:
   - Tap the **"Magic Link"** tab.
   - Enter your email address (e.g., `tester@belong.org`).
   - Tap **"Send Magic Link"**.
   - **Expected**: A green success card appears:
     > *"Check your inbox! We sent a 1-click sign-in link..."*

---

### Flow 4: Belong Spaces & Mindful Reflections 💬
*Goal: Confirm community rooms, post composer, and affirmations work as expected.*

1. **Explore Fellowship Spaces**:
   - Tap the **"Spaces"** tab in the main view.
   - Check the room list:
     - 📢 *Announcements*
     - 💬 *General Chat*
     - 🕊️ *Prayer Sanctuary*
     - 😄 *Calm Memes*
     - 🎥 *Online Resources & Videos*
     - 🧩 *Actually Autistic Chat*
     - 🤝 *Friends Chat*
     - 🏡 *Family Chat*
2. **Compose a Reflection**:
   - Tap the **+** (Compose) floating action button.
   - Type a gentle greeting (e.g., *"Testing the new app from Dallas! Excited for October 31."*).
   - Select an **Intent Tag** (e.g., `#fellowship`, `#encouragement`, `#question`).
   - Tap **"Post Reflection"**.
   - **Expected**: Your post appears in the feed with your selected tag.
3. **Give Care Affirmation**:
   - Tap the heart / affirmation button on any post.
   - **Expected**: The counter increments smoothly with gentle visual feedback.

---

### Flow 5: Feature Voting & Community Voice 🗳️
*Goal: Help shape the roadmap by upvoting upcoming features and sending literal feedback.*

1. **Open the Roadmap & Feedback Sheet**:
   - Tap the **"Vote & Feedback"** tab at the top of the screen.
2. **Tab 1: Vote on Features**:
   - Review upcoming items (e.g., *Audio MP3 Release Notes*, *Calm Ambient Soundscapes*, *Quiet Daily Digest*).
   - Tap the thumb / vote button on your favorite features.
   - **Expected**: The vote count increases immediately.
3. **Tab 2: Share Literal Feedback**:
   - Tap the **"Share Feedback"** tab.
   - Select one of the 3 clear intent cards:
     - 🌟 **Works Great** (Public praise)
     - 💡 **Idea / Tweak** (Constructive suggestion)
     - ⚠️ **Bug / Confusing** (Something felt awkward or broken)
   - Type your thought and tap **"Send Feedback"**.
   - **Expected**: A warm confirmation message appears thanking you for your voice.

---

### Flow 6: Offline Resilience & Diagnostics 📴
*Goal: Confirm the app handles poor connectivity gracefully without crashing.*

1. **Simulate Offline Mode**:
   - On your phone or laptop, turn on **Airplane Mode** or disconnect Wi-Fi.
   - Navigate through the app and view cached reflections.
   - **Expected**: An offline banner appears indicating you are viewing offline content. The app remains responsive and does not freeze or crash.
2. **Diagnostics & Error Logs**:
   - Tap the about / diagnostics menu option.
   - Verify that logs are readable and contain no personal passwords or sensitive keys.
   - If you ever hit an issue, you can copy the log snippet to share with the developers.

---

## 📝 4. Jargon-Free Bug Report Template

Found something confusing, awkward, or broken? Copy and paste this simple form into an email to Neil/Marty or post it in our **#bugs** space:

```text
1. What device were you using? (e.g., iPhone 15 Safari, Samsung Galaxy S23, Windows Chrome)
2. What were you trying to do? (e.g., "I tapped Save on my profile", "I tried upvoting the audio player")
3. What did you expect to happen?
4. What actually happened? (e.g., "The button didn't react", "The text overflowed off the screen")
5. How did it feel sensory-wise? (e.g., "Great", "Text was too small", "Too bright", "Colors clashed")
```

---

## 🏁 Automated Safety Checks in Our Codebase
For developers and curious mentees: this manual testing playbook is backed by automated tests:
- **Maestro E2E Script**: `.maestro/auth_and_profile_flow.yaml`
- **Patrol BDD Widget Suite**: `test/features/uat_cross_platform_flows_test.dart`
- **Unit Logic Verification**: `test/features/auth/belong_auth_sheet_widget_test.dart`
- **Physical Glass Verification**: Automated Marionette & Patrol driving on connected Pixel 9a hardware.
