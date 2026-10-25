# 🧪 Manual Testing & UAT Playbook ("How Can I Help Test?")

> **Easier start:** **[How you can help — what to look for](How-You-Can-Help-Volunteer-Guide#what-to-look-for)** is the short list, including iPhone and Android home-screen steps. Use this longer page only if you want more. A few names below are older than the app. The title at the top says **Belong**. The looks you can choose are **Clean**, **Sage**, **Dark**, and **Contrast** (also called Clean Slate, Sage Botanical, Monastic Dark, and High Contrast). If this page disagrees with what you see, trust the app.

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

On **dev** Android or [dev web](https://dev-belongonthespectrum.web.app/), you can also sign in as two fixed test members (**David M.** and **Sarah K.**) via the one-tap example buttons. See **[Dev example accounts](Dev-Example-Accounts)** for emails, roles, and how `DEV_EXAMPLE_PASSWORD` fits in (password is never in the wiki).

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
*Goal: Help shape the roadmap by upvoting upcoming features, submitting community ideas, and voting on notification delivery modes.*

1. **Open the Roadmap & Feedback Sheet**:
   - Tap the **"Vote & Feedback"** button at the top of the screen (or in the Spaces directory).
2. **Tab 1: Vote on Upcoming Features**:
   - Locate **"Real-Time Instant Alerts vs. Calm Batched Digest Toggle"** (Issue [#243](https://github.com/neiljaywarner/refuge/issues/243)).
   - Tap the upvote count button.
   - **Expected**: The counter increments immediately with green visual highlight.
   - Tap it again to toggle your vote off (counter decrements).
3. **Propose a Community Feature**:
   - Scroll to the bottom of the Feature Voting board.
   - Type a title (e.g. *"Sensory Timer for Soundscapes"*) and a short description.
   - Tap **"Propose Feature"**.
   - **Expected**: Your proposed item appears instantly at the bottom of the voting board with 1 initial vote!
4. **Tab 2: Share Literal 3-Intent Feedback**:
   - Tap the **"Private Feedback"** tab.
   - Select one of the 3 clear intent cards:
     - 🌟 **Works Great** (Public praise)
     - 💡 **Idea / Tweak** (Constructive suggestion)
     - ⚠️ **Bug / Confusing** (Something felt awkward or broken)
   - Type your thought and tap **"Send Feedback"**.
   - **Expected**: A confirmation message appears. The note is stored in Firestore. The drawing stays with the note and is not presented as an https://storage.belongonthespectrum.com upload. Notes are saved in Firestore member_feedback with a clipboard handoff for organizers. The sheet does not say a note was filed on belong_feedback. The app does not embed an API token and does not create a GitHub issue by itself ([#407](https://github.com/neiljaywarner/refuge/issues/407)).

---

### Flow 6: Responsive Layout & Mobile Web Check 📱
*Goal: Ensure the layout adapts gracefully across screens without clipping or overflow.*

1. **Resize Desktop Browser Window**:
   - Shrink the window width down to mobile phone size (~380px).
   - Confirm navigation collapses smoothly into a bottom nav bar.
   - Expand to tablet/desktop width (~1000px+).
   - Confirm a clean, spacious centered layout with comfortable margins.
2. **Rotate Mobile Device**:
   - Switch between portrait and landscape.
   - Verify post text wraps cleanly and bottom bars do not obscure content.

---

### Flow 7: Google Password Manager & Browser Autofill 🔐
*Goal: Confirm that credentials save and autofill smoothly with OS password managers.*

1. **Open Auth Sheet**:
   - Tap **Sign In** from the top bar or profile sheet.
2. **Enter Credentials**:
   - Select **Create Account** or **Sign In**.
   - Type an email address and password.
3. **Submit Form**:
   - Tap **"Create Account"** or **"Sign In"**.
   - **Expected**: The native OS bottom sheet (e.g., *Google Password Manager: "Save password for refuge?"*) appears with "Save" and "Never" options.
   - Tap **"Save"**.
4. **Autofill Verification**:
   - Sign out and return to the sign-in sheet.
   - Tap the Email or Password field.
   - **Expected**: The OS suggests the saved account with 1-tap autofill.

---

### Flow 8: Sign-in wall, then signed-in top bar 👤
*Goal: A signed-out person never sees the feed. After sign-in, the top bar shows only the member avatar.*

1. **Signed-out / members-only wall**:
   - Sign out of your account, or launch with a cleared session.
   - **Expected**: Only the **Sign In to Belong** wall. No feed, no Demo Mode banner, no Vote & Feedback, no top-bar **Sign In** on a populated home screen.
   - On **dev** Android or [dev web](https://dev-belongonthespectrum.web.app/), the two example-user buttons may appear under the form (see **[Dev example accounts](Dev-Example-Accounts)**).
2. **Authenticated / Signed-In State**:
   - Sign in with a real account, or tap an example-user button on a dev build.
   - Look at the top-right corner of the app bar.
   - **Expected**: A circular initials avatar is shown. The feed is visible. There is no guest/demo browse.

---

## 💡 4. How to Submit Feedback

If you find anything confusing, broken, or delightful, please let us know:
1. **Inside the App**: Use **Flow 5** (Vote & Feedback $\rightarrow$ Share Feedback tab) to send thoughts directly.
2. **By Email / Message**: Send your notes, screenshots, or screen recordings directly to the Belong Welcome Team.

*Thank you for being part of building a welcoming, sensory-friendly refuge for autistic believers and friends!*